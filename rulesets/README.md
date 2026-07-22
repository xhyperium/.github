# xhyperium Organization Rulesets

> 本目录是 **xhyperium** 组织的全局规则中心（SSOT）：Rust 规范、Agent 纪律、协作宪法、GitHub Ruleset 模板。

## 目录

```text
rulesets/
├── agent-teams-constitution.md           # 最高治理（C/L/P）v2.9
├── agent-teams-constitution-appendix.md  # 阈值 / ACL / 仲裁 / 变更日志
├── agent-quality-gates.md                # 验证命令矩阵（Rust）
├── agent-*.md                            # 纪律 / 工作流 / 安全 / Teams / Codex …
├── rust/                                 # Rust 全局规范完整版 v2.1.0
│   └── RULES.md                          # 入口
├── main-protection.json                  # 默认分支结构保护模板
├── release-tag-protection.json           # v* tag 保护模板
└── org-rust-pr-quality.ruleset.json      # 可选：Rust PR status checks（默认 disabled）
```

## 层级关系

```text
agent-teams-constitution.md     ← 最高原则 / 铁律 / 协作协议
        ↓
语言 SSOT（rust/）              ← 编码标准
        ↓
agent-discipline / workflow …   ← 执行与工作流
        ↓
agent-quality-gates.md          ← 验证命令
        ↓
GitHub Ruleset JSON             ← 平台强制（导入后生效）
```

冲突时：**宪法 > 语言 P0 > Agent 操作规则 > 局部习惯**。

## 1. Rust 项目必须显式引用

| 项 | 值 |
|----|-----|
| 上位 SSOT | `https://github.com/xhyperium/.github/tree/main/rulesets/rust` |
| 入口 | `rulesets/rust/RULES.md`（v2.1.0） |
| 关系 | 项目可加严，**不可削弱** P0 |

## 2. Agent 机器一键分发

```bash
curl -sSL https://raw.githubusercontent.com/xhyperium/.github/main/scripts/setup-global-rules.sh | bash
# HTTPS：
USE_HTTPS=1 bash <(curl -sSL https://raw.githubusercontent.com/xhyperium/.github/main/scripts/setup-global-rules.sh)
```

效果：克隆/更新 `~/org-config` → symlink 到 `~/.claude/rules/`（含宪法、质量门禁、Rust 入口）。

## 3. 可复用 CI

见 [`../workflows/README.md`](../workflows/README.md)：

| 工作流 | 语言 | Tier |
|--------|------|------|
| `ci-rust-standard.yml` | Rust | P1：fmt + clippy + test |
| `ci-rust-foundation.yml` | Rust | P0：+ doc + cargo deny（可关） |

## 4. Org Ruleset 模板（导入须谨慎）

| 文件 | 用途 | 注意 |
|------|------|------|
| [`main-protection.json`](./main-protection.json) | 默认分支：须 PR、禁 force-push/删除 | **不**绑语言 status check（正确） |
| [`release-tag-protection.json`](./release-tag-protection.json) | `v*` tag 保护 | 导入前核对 `bypass_actors` 的 team id |
| [`org-rust-pr-quality.ruleset.json`](./org-rust-pr-quality.ruleset.json) | 强制 rust-fmt/clippy/test | **默认 `enforcement: disabled`**；`include` 为显式 Rust 仓列表 |

导入：GitHub → Organization settings → Rules → Rulesets，或 REST `POST /orgs/xhyperium/rulesets`。  
与企业级 ruleset 冲突时先对齐，再 `active`。

## 5. 与历史上游的关系

| 源 | 角色 |
|----|------|
| `bytechainx/.github` 等 | 历史/跨 org 副本 |
| **`xhyperium/.github`** | **本组织 SSOT** |

同步建议：上游有重大修订时对比 diff 后开 PR，勿在下游削弱 P0。宪法与 Agent 规则以本仓版本为准。

## 6. 维护检查清单

- [ ] 改 P0 规则走 PR
- [ ] Rust 专题版本头与 `RULES.md` 主版本一致（当前 2.1.0）
- [ ] 新增规范时更新 `setup-global-rules.sh` 与本 README
- [ ] 相对 Markdown 链接可解析（本仓 `meta-validate` 会检查）
