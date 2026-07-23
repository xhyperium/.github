#!/usr/bin/env bash
# claude-rules-loader.sh — SessionStart：重建 ~/.claude/rules 与组织 SSOT 的 symlink
#
# SSOT：xhyperium/.github → scripts/claude-rules-loader.sh
# 安装：setup-global-rules.sh 会把本文件复制/链接为 ~/.claude/rules/_loader.sh
#
# 设计要点：
# 1. 常驻清单与 setup-global-rules.sh 对齐（禁止「setup 装了、loader 抹掉」）
# 2. 优先 ~/org-config/rulesets（组织 SSOT），不以 available/ 覆盖核心规则
# 3. 只 unlink 本脚本管理的目标名；不删除真实文件
# 4. fail-open：任何错误不阻断会话（由调用方 `|| true` 兜底；本脚本也尽量不 exit 非 0）
# 5. SessionStart 前节流同步 SSOT（默认 6h，见 sync-org-rules.sh）

set -u

RULES_DIR="${CLAUDE_RULES_DIR:-${HOME}/.claude/rules}"
ORG_CONFIG_DIR="${ORG_CONFIG_DIR:-${HOME}/org-config}"
ORG_RULES="${ORG_CONFIG_DIR}/rulesets"
AVAILABLE="${RULES_DIR}/available"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"

mkdir -p "${RULES_DIR}" 2>/dev/null || true

# --- 节流自动同步（fail-open；默认 6 小时）---
# 关闭：ORG_RULES_AUTO_UPDATE=0 或 INFRA_ORG_RULES_AUTO_UPDATE=0
# 强制：ORG_RULES_SYNC_FORCE=1
# 间隔：ORG_RULES_SYNC_INTERVAL_HOURS=6
_sync_script=""
if [[ -n "${SCRIPT_DIR}" && -f "${SCRIPT_DIR}/sync-org-rules.sh" ]]; then
  _sync_script="${SCRIPT_DIR}/sync-org-rules.sh"
elif [[ -f "${ORG_CONFIG_DIR}/scripts/sync-org-rules.sh" ]]; then
  _sync_script="${ORG_CONFIG_DIR}/scripts/sync-org-rules.sh"
fi
if [[ -n "${_sync_script}" ]]; then
  ORG_RULES_SYNC_QUIET="${ORG_RULES_SYNC_QUIET:-1}" \
    bash "${_sync_script}" 2>/dev/null || true
fi
unset _sync_script

link_from_org() {
  local rel="$1"   # rulesets 下相对路径，如 language.md 或 rust/RULES.md
  local dest_name="$2"
  local src="${ORG_RULES}/${rel}"
  local dest="${RULES_DIR}/${dest_name}"
  if [[ -f "${src}" ]]; then
    ln -sfn "${src}" "${dest}" 2>/dev/null || true
    return 0
  fi
  return 1
}

# 本 loader 管理的目标（与 setup-global-rules.sh 常驻清单一致）
MANAGED_DESTS=(
  language.md
  rust.md
  agent-teams-constitution.md
  agent-teams-constitution-appendix.md
  agent-quality-gates.md
  agent-discipline.md
  agent-workflow.md
  agent-safety.md
  agent-context.md
  self-verification.md
  autonomous-iteration.md
  agent-teams.md
  agent-codex.md
  agent-model-routing.md
  rust-security.md
  rust-async.md
  rust-testing.md
  rust-ci.md
  rust-cheatsheet.md
  rust-api-design.md
  rust-clippy.md
  rust-observability.md
  rust-release.md
)

# 仅清理我们管理的 symlink，避免误删用户真实文件或其他工具链接
for name in "${MANAGED_DESTS[@]}"; do
  path="${RULES_DIR}/${name}"
  if [[ -L "${path}" ]]; then
    unlink "${path}" 2>/dev/null || true
  fi
done

# --- 常驻：语言 / 宪法 / Agent / 自验证 ---
link_from_org "language.md" "language.md" || true
link_from_org "rust/RULES.md" "rust.md" || true
link_from_org "agent-teams-constitution.md" "agent-teams-constitution.md" || true
link_from_org "agent-teams-constitution-appendix.md" "agent-teams-constitution-appendix.md" || true
link_from_org "agent-quality-gates.md" "agent-quality-gates.md" || true
link_from_org "agent-discipline.md" "agent-discipline.md" || true
link_from_org "agent-workflow.md" "agent-workflow.md" || true
link_from_org "agent-safety.md" "agent-safety.md" || true
link_from_org "agent-context.md" "agent-context.md" || true
link_from_org "self-verification.md" "self-verification.md" || true
link_from_org "agent-teams.md" "agent-teams.md" || true
link_from_org "agent-codex.md" "agent-codex.md" || true
link_from_org "agent-model-routing.md" "agent-model-routing.md" || true

# 自主迭代：SSOT 优先；无则回退 available；项目级 harness-rules 存在时跳过以免重复
if [[ ! -f "${PROJECT_DIR}/.claude/rules/harness-rules.md" ]]; then
  if ! link_from_org "autonomous-iteration.md" "autonomous-iteration.md"; then
    if [[ -f "${AVAILABLE}/iteration/autonomous-iteration.md" ]]; then
      ln -sfn "${AVAILABLE}/iteration/autonomous-iteration.md" \
        "${RULES_DIR}/autonomous-iteration.md" 2>/dev/null || true
    fi
  fi
fi

# --- Rust 专题（入口仍是 rust.md；专题便于按需打开）---
link_from_org "rust/security.md" "rust-security.md" || true
link_from_org "rust/async-runtime.md" "rust-async.md" || true
link_from_org "rust/testing.md" "rust-testing.md" || true
link_from_org "rust/ci.md" "rust-ci.md" || true
link_from_org "rust/cheatsheet.md" "rust-cheatsheet.md" || true
link_from_org "rust/api-design.md" "rust-api-design.md" || true
link_from_org "rust/clippy.md" "rust-clippy.md" || true
link_from_org "rust/observability.md" "rust-observability.md" || true
link_from_org "rust/release.md" "rust-release.md" || true

# 组织默认 Rust：无 Cargo.toml 时仍保留 rust.md（已在上方链接）。
# 不再尝试加载已移除的 python/go 空链，避免假分发。

exit 0
