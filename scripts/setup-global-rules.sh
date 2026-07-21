#!/bin/bash
# setup-global-rules.sh — xhyperium 全局规则一键分发
#
# 使用方式：
#   curl -sSL https://raw.githubusercontent.com/xhyperium/.github/main/scripts/setup-global-rules.sh | bash
#   或：
#   bash scripts/setup-global-rules.sh
#
# 默认从 xhyperium/.github 克隆到 ~/org-config，并 symlink 到 ~/.claude/rules/
# 覆盖：ORG_CONFIG_DIR / CLAUDE_RULES_DIR / REPO_URL / USE_HTTPS=1

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ORG_CONFIG_DIR="${ORG_CONFIG_DIR:-${HOME}/org-config}"
CLAUDE_RULES_DIR="${CLAUDE_RULES_DIR:-${HOME}/.claude/rules}"
if [[ "${USE_HTTPS:-0}" == "1" ]]; then
  REPO_URL="${REPO_URL:-https://github.com/xhyperium/.github.git}"
else
  REPO_URL="${REPO_URL:-git@github.com:xhyperium/.github.git}"
fi

echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  xhyperium 全局规则初始化 v1.1       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "  SSOT: ${REPO_URL}"
echo -e "  本地: ${ORG_CONFIG_DIR}"
echo ""

if [ -d "${ORG_CONFIG_DIR}/.git" ]; then
  echo -e "${YELLOW}🔄 更新组织配置...${NC}"
  remote="$(git -C "${ORG_CONFIG_DIR}" remote get-url origin 2>/dev/null || true)"
  if [[ -n "${remote}" && "${remote}" != *xhyperium/.github* ]]; then
    echo -e "${YELLOW}⚠️  origin 当前为: ${remote}${NC}"
    echo -e "${YELLOW}   历史目录与 xhyperium SSOT 分叉，将备份并重新克隆${NC}"
    bak="${ORG_CONFIG_DIR}.bak.$(date +%Y%m%d%H%M%S)"
    mv "${ORG_CONFIG_DIR}" "${bak}"
    echo -e "${YELLOW}   已备份到 ${bak}${NC}"
    git clone --quiet "${REPO_URL}" "${ORG_CONFIG_DIR}"
  else
    git -C "${ORG_CONFIG_DIR}" fetch --quiet origin
    git -C "${ORG_CONFIG_DIR}" checkout main --quiet 2>/dev/null || true
    git -C "${ORG_CONFIG_DIR}" pull --ff-only --quiet origin main 2>/dev/null || \
      git -C "${ORG_CONFIG_DIR}" reset --hard origin/main --quiet
  fi
  echo -e "${GREEN}✅ 已更新到最新版本${NC}"
else
  echo -e "${YELLOW}📥 克隆组织配置...${NC}"
  if [ -d "${ORG_CONFIG_DIR}" ]; then
    echo -e "${RED}FAIL: ${ORG_CONFIG_DIR} 存在但不是 git 仓库，请手动处理${NC}"
    exit 1
  fi
  git clone --quiet "${REPO_URL}" "${ORG_CONFIG_DIR}"
  echo -e "${GREEN}✅ 克隆完成${NC}"
fi

mkdir -p "${CLAUDE_RULES_DIR}"

echo ""
echo -e "${BLUE}🔗 创建规则链接...${NC}"

link_rule() {
  local src="$1"
  local dest="$2"
  local label="$3"
  if [ -f "${src}" ]; then
    ln -sfn "${src}" "${dest}"
    echo -e "  ${GREEN}✅ ${label}${NC}"
  else
    echo -e "  ${YELLOW}⏭  跳过 ${label}（源不存在）${NC}"
  fi
}

link_rule "${ORG_CONFIG_DIR}/rulesets/rust/RULES.md" "${CLAUDE_RULES_DIR}/rust.md" "Rust 规则"
link_rule "${ORG_CONFIG_DIR}/rulesets/python/RULES.md" "${CLAUDE_RULES_DIR}/python.md" "Python 规则"
link_rule "${ORG_CONFIG_DIR}/rulesets/agent-discipline.md" "${CLAUDE_RULES_DIR}/agent-discipline.md" "Agent 执行纪律"
link_rule "${ORG_CONFIG_DIR}/rulesets/agent-workflow.md" "${CLAUDE_RULES_DIR}/agent-workflow.md" "Agent 工作流编排"
link_rule "${ORG_CONFIG_DIR}/rulesets/agent-safety.md" "${CLAUDE_RULES_DIR}/agent-safety.md" "Agent 安全护栏"
link_rule "${ORG_CONFIG_DIR}/rulesets/agent-context.md" "${CLAUDE_RULES_DIR}/agent-context.md" "Agent 上下文管理"
link_rule "${ORG_CONFIG_DIR}/rulesets/agent-teams.md" "${CLAUDE_RULES_DIR}/agent-teams.md" "Agent Teams"
link_rule "${ORG_CONFIG_DIR}/rulesets/agent-codex.md" "${CLAUDE_RULES_DIR}/agent-codex.md" "Agent Codex"
link_rule "${ORG_CONFIG_DIR}/rulesets/agent-model-routing.md" "${CLAUDE_RULES_DIR}/agent-model-routing.md" "Agent 模型路由"

echo ""
echo -e "${BLUE}📋 验证：${CLAUDE_RULES_DIR}${NC}"
ls -la "${CLAUDE_RULES_DIR}"/*.md 2>/dev/null || true

RULE_COUNT=$(find "${ORG_CONFIG_DIR}/rulesets" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  全局规则配置完成                    ║${NC}"
echo -e "${GREEN}║  规则文件约 ${RULE_COUNT} 篇                      ║${NC}"
echo -e "${GREEN}║  更新: cd ~/org-config && git pull   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
