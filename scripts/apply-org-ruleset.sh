#!/usr/bin/env bash
# apply-org-ruleset.sh — xhyperium org ruleset 重建（DELETE + POST）
#
# 背景（本环境实测）：GitHub REST API 对 org ruleset 的 PATCH 恒返回 404，
#       但 DELETE / POST 正常，且 POST 时 body 里的 enforcement 会生效。
#       因此"更新/启用"一条规则采用：按 name 找到旧规则 -> DELETE -> POST 新配置。
#       切勿用 PATCH —— 它会静默 404 而不报错到业务层。
#
# 用法：
#   bash scripts/apply-org-ruleset.sh <config.json> [--org xhyperium] [--dry-run] [-f]
#
# 参数：
#   <config.json>   规则定义文件。支持含 $schema_comment 等注释键（自动剔除后上传）
#   --org           组织名（默认取 $ORG 或 xhyperium）
#   --dry-run       只打印将要执行的操作，不实际删除/创建
#   -f, --yes       跳过交互确认直接执行
#
# 前置：gh 已登录且具备 admin:org scope。
#       缺权时写操作会 404，可用：gh auth refresh -h github.com -s admin:org
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
err(){ echo -e "${RED}✗ $*${NC}" >&2; }
ok(){ echo -e "${GREEN}✓ $*${NC}"; }
info(){ echo -e "${BLUE}ℹ $*${NC}"; }
warn(){ echo -e "${YELLOW}⚠ $*${NC}"; }

ORG="${ORG:-xhyperium}"
DRY_RUN=0
FORCE=0
CONFIG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org)      ORG="$2"; shift 2;;
    --dry-run)  DRY_RUN=1; shift;;
    -f|--yes)   FORCE=1; shift;;
    -h|--help)  sed -n '2,16p' "$0"; exit 0;;
    -*)         err "未知参数: $1"; exit 2;;
    *)          CONFIG="$1"; shift;;
  esac
done

[[ -z "${CONFIG}" ]] && { err "缺少 config.json 参数"; sed -n '2,16p' "$0"; exit 2; }
[[ -f "${CONFIG}" ]] || { err "配置文件不存在: ${CONFIG}"; exit 1; }

need_cmd(){ command -v "$1" >/dev/null 2>&1 || { err "需要 $1，请先安装"; exit 1; }; }
need_cmd gh
need_cmd jq

# 提取 name 并校验 JSON
NAME="$(jq -r '.name' "${CONFIG}" 2>/dev/null)" || { err "配置文件不是合法 JSON: ${CONFIG}"; exit 1; }
[[ "${NAME}" == "null" || -z "${NAME}" ]] && { err "配置缺少 .name 字段"; exit 1; }

# 剔除 $ 开头的注释键（如 $schema_comment），得到干净 payload 供 GitHub 接受
PAYLOAD="$(jq 'with_entries(select(.key | startswith("$") | not))' "${CONFIG}")" \
  || { err "无法规范化 payload（jq 处理失败）"; exit 1; }
ENF="$(jq -r '.enforcement' <<<"${PAYLOAD}")"

info "组织: ${ORG}"
info "规则名: ${NAME}"
info "enforcement: ${ENF}"
info "dry-run: $([[ ${DRY_RUN} -eq 1 ]] && echo 是 || echo 否)"

# 查找已有同名规则
info "查询现有规则..."
EXISTING="$(gh api "orgs/${ORG}/rulesets" 2>/dev/null | jq -r --arg n "${NAME}" '.[] | select(.name==$n) | .id' || true)"
if [[ -n "${EXISTING}" ]]; then
  warn "发现同名规则 id=${EXISTING}，将删除后重建"
else
  info "无同名规则，将直接创建"
fi

if [[ ${DRY_RUN} -eq 1 ]]; then
  info "[dry-run] 计划执行："
  [[ -n "${EXISTING}" ]] && echo "  DELETE orgs/${ORG}/rulesets/${EXISTING}"
  echo "  POST   orgs/${ORG}/rulesets  (enforcement=${ENF})"
  exit 0
fi

if [[ ${FORCE} -ne 1 ]]; then
  read -r -p "确认执行上述删除/创建操作？(y/N) " ans
  [[ "${ans,,}" == "y" ]] || { warn "已取消"; exit 0; }
fi

# 1) 删除旧的（若存在）
if [[ -n "${EXISTING}" ]]; then
  info "删除旧规则 id=${EXISTING}..."
  if gh api -X DELETE "orgs/${ORG}/rulesets/${EXISTING}" >/dev/null 2>&1; then
    ok "已删除旧规则"
  else
    err "删除失败（多半缺 admin:org scope，先跑：gh auth refresh -h github.com -s admin:org）"
    exit 1
  fi
fi

# 2) 创建新的（POST 带 enforcement）
info "创建新规则..."
if ! NEW="$(gh api -X POST "orgs/${ORG}/rulesets" --input - <<<"${PAYLOAD}" --jq '{id,name,enforcement}' 2>&1)"; then
  err "创建失败：${NEW}"
  exit 1
fi
ok "已创建：${NEW}"

# 3) 复核
info "复核生效状态..."
gh api "orgs/${ORG}/rulesets/$(jq -r '.id' <<<"${NEW}")" \
  --jq '{name,enforcement,repo_exclude:.conditions.repository_name.exclude}' 2>&1 || true
