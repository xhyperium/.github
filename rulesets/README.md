# xhyperium Organization Rulesets

> 本目录是 **xhyperium** 组织的全局规则中心（从 `bytechainx/.github` 同步/复制的 Rust 与 Agent 规则 + 本 org 专用模板）。

## 目录

```text
rulesets/
├── rust/                         # Rust 全局规范完整版 v2.1.0（SSOT）
│   ├── RULES.md                  # 入口
│   ├── security.md | async-runtime.md | testing.md | …
├── agent-*.md                    # Agent 纪律 / 工作流 / 安全 …
├── main-protection.json          # 分支保护模板
├── release-tag-protection.json
└── org-rust-pr-quality.ruleset.json  # 可选：org ruleset 要求 fmt/clippy/test
```

## 1. Rust 项目必须显式引用

每个 Rust 仓库的 `CONSTITUTION.md` / `docs/constitution/04-code-standards.md` / `AGENTS.md` 应声明：

| 项 | 值 |
|----|-----|
| 上位 SSOT | `https://github.com/xhyperium/.github/tree/main/rulesets/rust` |
| 入口 | `rulesets/rust/RULES.md` |
| 关系 | 项目可加严，**不可削弱** P0 |

## 2. Agent 机器一键分发

```bash
curl -sSL https://raw.githubusercontent.com/xhyperium/.github/main/scripts/setup-global-rules.sh | bash
# 或 HTTPS：
USE_HTTPS=1 bash <(curl -sSL https://raw.githubusercontent.com/xhyperium/.github/main/scripts/setup-global-rules.sh)
```

效果：克隆/更新 `~/org-config` → symlink `~/.claude/rules/rust.md` 等。

## 3. 可复用 CI（Rust）

见 [`workflows/README.md`](../workflows/README.md)：

- `ci-rust-standard.yml` — P1：fmt + clippy + test  
- `ci-rust-foundation.yml` — P0：上者 + cargo deny  

（既有 `ci-standard.yml` / `ci-foundation.yml` 为 **Go** 模块门禁，勿与 Rust 混用。）

## 4. 可选：Org ruleset

模板：[`org-rust-pr-quality.ruleset.json`](./org-rust-pr-quality.ruleset.json)

- 要求 status checks：`rust-fmt` / `rust-clippy` / `rust-test`
- **前提**：目标仓库已接入 `ci-rust-*.yml` 且 check 名称一致
- 需 **org owner** 在 GitHub → Organization settings → Rules → Rulesets 导入，或 REST `POST /orgs/xhyperium/rulesets`

当前 org 可能已有 Enterprise 级 ruleset；导入前请与企业策略对齐，避免冲突。

## 5. 与 bytechainx 的关系

| 源 | 角色 |
|----|------|
| `bytechainx/.github` | 历史/跨 org 上游副本 |
| `xhyperium/.github` | **xhyperium 组织 SSOT（本仓）** |

同步建议：上游有重大修订时 `rsync`/`cp` rulesets/rust 并发 PR，勿在下游长期分叉削弱 P0。
