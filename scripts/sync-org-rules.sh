#!/usr/bin/env bash
# sync-org-rules.sh — 节流拉取组织规则 SSOT（xhyperium/.github → ~/org-config）
#
# 设计：
# - 默认每 6 小时最多同步一次（ORG_RULES_SYNC_INTERVAL_HOURS）
# - 仅在 main + 工作区干净时 ff-only pull（绝不 reset --hard）
# - 全程 fail-open：网络失败 / 非 main / 有本地改动 → 跳过，exit 0
# - 可由 SessionStart loader 调用，也可 cron / 手动执行
#
# 环境变量：
#   ORG_CONFIG_DIR                 默认 ~/org-config
#   CLAUDE_RULES_DIR               默认 ~/.claude/rules（戳记目录）
#   ORG_RULES_SYNC_INTERVAL_HOURS  默认 6
#   ORG_RULES_AUTO_UPDATE=0         关闭自动同步（兼容 INFRA_ORG_RULES_AUTO_UPDATE=0）
#   ORG_RULES_SYNC_FORCE=1         忽略节流戳记，仍遵守 main/干净约束
#   ORG_RULES_SYNC_QUIET=1         少输出（SessionStart 建议开启）

set -u

ORG_CONFIG_DIR="${ORG_CONFIG_DIR:-${HOME}/org-config}"
CLAUDE_RULES_DIR="${CLAUDE_RULES_DIR:-${HOME}/.claude/rules}"
INTERVAL_H="${ORG_RULES_SYNC_INTERVAL_HOURS:-6}"
STAMP="${CLAUDE_RULES_DIR}/.last-org-sync"
QUIET="${ORG_RULES_SYNC_QUIET:-0}"

log() {
  if [[ "${QUIET}" != "1" ]]; then
    printf '%s\n' "$*" >&2
  fi
}

# 统一关闭开关
if [[ "${ORG_RULES_AUTO_UPDATE:-1}" == "0" ]] || [[ "${INFRA_ORG_RULES_AUTO_UPDATE:-1}" == "0" ]]; then
  log "org-rules sync: disabled by env"
  exit 0
fi

# 间隔必须是正整数
if ! [[ "${INTERVAL_H}" =~ ^[1-9][0-9]*$ ]]; then
  INTERVAL_H=6
fi

mkdir -p "${CLAUDE_RULES_DIR}" 2>/dev/null || true

# --- 节流 ---
now_epoch="$(date +%s 2>/dev/null || echo 0)"
if [[ "${ORG_RULES_SYNC_FORCE:-0}" != "1" ]] && [[ -f "${STAMP}" ]] && [[ "${now_epoch}" -gt 0 ]]; then
  last="$(tr -d '[:space:]' <"${STAMP}" 2>/dev/null || echo 0)"
  if [[ "${last}" =~ ^[0-9]+$ ]]; then
    elapsed=$((now_epoch - last))
    limit=$((INTERVAL_H * 3600))
    if [[ "${elapsed}" -lt "${limit}" ]]; then
      log "org-rules sync: skip (last ${elapsed}s ago, interval ${INTERVAL_H}h)"
      exit 0
    fi
  fi
fi

# --- 前置条件 ---
if [[ ! -d "${ORG_CONFIG_DIR}/.git" ]]; then
  log "org-rules sync: skip (not a git repo: ${ORG_CONFIG_DIR})"
  exit 0
fi

if ! command -v git >/dev/null 2>&1; then
  log "org-rules sync: skip (git not found)"
  exit 0
fi

branch="$(git -C "${ORG_CONFIG_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
if [[ "${branch}" != "main" ]]; then
  log "org-rules sync: skip (branch is '${branch}', need main)"
  exit 0
fi

# 工作区必须干净（含未跟踪会挡 ff；用 porcelain 检测已跟踪变更 + 暂存）
if [[ -n "$(git -C "${ORG_CONFIG_DIR}" status --porcelain 2>/dev/null)" ]]; then
  log "org-rules sync: skip (dirty worktree)"
  exit 0
fi

# --- fetch + ff-only pull ---
if ! git -C "${ORG_CONFIG_DIR}" fetch --quiet origin 2>/dev/null; then
  log "org-rules sync: skip (fetch failed)"
  exit 0
fi

# 无 origin/main 则放弃
if ! git -C "${ORG_CONFIG_DIR}" rev-parse --verify -q origin/main >/dev/null 2>&1; then
  log "org-rules sync: skip (origin/main missing)"
  exit 0
fi

local_sha="$(git -C "${ORG_CONFIG_DIR}" rev-parse HEAD 2>/dev/null || echo "")"
remote_sha="$(git -C "${ORG_CONFIG_DIR}" rev-parse origin/main 2>/dev/null || echo "")"

if [[ -n "${local_sha}" && "${local_sha}" == "${remote_sha}" ]]; then
  # 已最新：仍写戳记，避免无意义重复 fetch
  printf '%s\n' "${now_epoch}" >"${STAMP}" 2>/dev/null || true
  log "org-rules sync: already up to date (${local_sha:0:7})"
  exit 0
fi

# 仅快进；失败不 hard reset
if git -C "${ORG_CONFIG_DIR}" pull --ff-only --quiet origin main 2>/dev/null; then
  new_sha="$(git -C "${ORG_CONFIG_DIR}" rev-parse --short HEAD 2>/dev/null || echo "?")"
  printf '%s\n' "${now_epoch}" >"${STAMP}" 2>/dev/null || true
  log "org-rules sync: updated → ${new_sha}"
  exit 0
fi

log "org-rules sync: skip (ff-only pull failed; leave worktree untouched)"
exit 0
