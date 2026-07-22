# xhyperium Organization Rulesets

> 本目录是 **xhyperium** 组织的全局规则中心（SSOT）：Rust 规范、Agent 纪律、协作宪法、GitHub Ruleset 配置。

## 目录

```text
rulesets/
├── language.md                           # 组织语言政策：强制中文（P0）
├── agent-teams-constitution.md           # 最高治理（C/L/P）v2.9
├── agent-teams-constitution-appendix.md  # 阈值 / ACL / 仲裁 / 变更日志 v2.9
├── agent-quality-gates.md                # 验证命令矩阵（Rust）
├── agent-*.md                            # 纪律 / 工作流 / 安全 / Teams / Codex …
├── rust/                                 # Rust 全局规范完整版 v2.1.1
│   └── RULES.md                          # 入口
├── main-protection.json                  # 默认分支结构保护（active · ~ALL）
├── release-tag-protection.json           # v* tag 保护（active · ~ALL）
└── org-rust-pr-quality.ruleset.json      # Rust PR status checks（active · 显式仓列表）
```

配套脚本（仓库 `scripts/`）：

| 脚本 | 用途 |
|------|------|
| [`setup-global-rules.sh`](../scripts/setup-global-rules.sh) | 克隆/更新 SSOT → symlink `~/.claude/rules/` |
| [`apply-org-ruleset.sh`](../scripts/apply-org-ruleset.sh) | 将 JSON **应用到线上** org ruleset（DELETE+POST；本环境 PATCH 不可用） |

## 层级关系

```text
language.md                     ← 人类可读文本：强制中文（P0）
        ↓
agent-teams-constitution.md     ← 最高原则 / 铁律 / 协作协议
        ↓
语言编码 SSOT（rust/）          ← Rust 编码标准
        ↓
agent-discipline / workflow …   ← 执行与工作流
        ↓
agent-quality-gates.md          ← 验证命令（Rust）
        ↓
GitHub Ruleset JSON             ← 平台强制（git 合并 ≠ 线上生效，需 apply）
```

冲突时：**语言政策 / 宪法 > 编码 P0 > Agent 操作规则 > 局部习惯**。

## 0. 强制中文（P0）

组织**强制**人类可读文本使用简体中文。细则：[language.md](./language.md)。

- 文档、注释、用户可见错误、Agent 对用户输出、commit/PR 叙述 → **中文**
- 标识符、crate 名、协议专有名、机器键名 → **可英文**（白名单见 language.md §2）
- **不**把 ASD-STE100 / 全文英文文档作为默认交付

## 1. Rust 项目必须显式引用

| 项 | 值 |
|----|-----|
| 上位 SSOT | `https://github.com/xhyperium/.github/tree/main/rulesets/rust` |
| 入口 | `rulesets/rust/RULES.md`（v2.1.1） |
| 关系 | 项目可加严，**不可削弱** P0 |

## 2. Agent 机器一键分发

```bash
curl -sSL https://raw.githubusercontent.com/xhyperium/.github/main/scripts/setup-global-rules.sh | bash
# HTTPS：
USE_HTTPS=1 bash <(curl -sSL https://raw.githubusercontent.com/xhyperium/.github/main/scripts/setup-global-rules.sh)
```

效果：克隆/更新 `~/org-config` → symlink 到 `~/.claude/rules/`（宪法、质量门禁、Rust 入口与常用专题）。

## 3. 可复用 CI

见 [`../workflows/README.md`](../workflows/README.md)：

| 工作流 | 语言 | Tier |
|--------|------|------|
| `ci-rust-standard.yml` | Rust | P1：fmt + clippy + test |
| `ci-rust-foundation.yml` | Rust | P0：+ doc + cargo deny（可关） |

## 4. Org Ruleset：三份 JSON 的分工（真相）

| 文件 | enforcement | 范围 | 作用 |
|------|-------------|------|------|
| [`main-protection.json`](./main-protection.json) | **active** | `~ALL` 默认分支 | **结构门禁**：须走 PR、禁 force-push/删分支；**不**绑语言 status check；当前 `required_approving_review_count: 0` |
| [`release-tag-protection.json`](./release-tag-protection.json) | **active** | `v*` tag · `~ALL` | 禁随意建/删/改 tag；bypass：OrgAdmin + maintainers team（**导入前核对 `actor_id`**） |
| [`org-rust-pr-quality.ruleset.json`](./org-rust-pr-quality.ruleset.json) | **active** | 显式 include 仓列表 | **质量门禁**：`org-rust / rust-fmt` 等（见 workflows/README）（**无** doc/deny，有意） |

### 叠加语义

```text
main-protection（全 org 结构）
    +
org-rust-pr-quality（白名单仓的 CI check）
```

- **禁止**把 rust check 写进 main-protection（会锁死无 Rust CI 的仓）。
- **禁止**对 `org-rust-pr-quality` 使用 `~ALL`；只 include **已接入** `ci-rust-*.yml` 且 job 名一致的仓。
- 当前 include 示例：`infra.rs` · `market_data.rs` · `macro_data.rs`（见 JSON；未接入的 `standard_template.rs` / `xhyper.rs` 及文档仓不在 scope）。

### 应用到线上（必做）

git 合并只更新本仓模板，**不会**自动改 GitHub Org Rules：

```bash
# 预览
bash scripts/apply-org-ruleset.sh rulesets/org-rust-pr-quality.ruleset.json --dry-run

# 执行（需 gh 具备 admin:org）
bash scripts/apply-org-ruleset.sh rulesets/org-rust-pr-quality.ruleset.json -f
```

同理可对 `main-protection.json` / `release-tag-protection.json` 执行。  
**新仓接入 checklist**：① 接入 `ci-rust-*.yml` → ② 把仓名加入 `include` → ③ `apply-org-ruleset.sh` → ④ 用 PR 验证三 check 出现。

## 5. 与历史上游的关系

| 源 | 角色 |
|----|------|
| `bytechainx/.github` 等 | 历史/跨 org 副本（非本 org 权威） |
| **`xhyperium/.github`** | **本组织 SSOT** |

上游重大修订时：对比 diff → 开 PR 合入本仓；**勿削弱 P0**。宪法与 Agent 规则以本仓版本为准。同步记录见 [CHANGELOG.md](./CHANGELOG.md)。

## 6. 维护检查清单

- [ ] 改 P0 规则走 PR
- [ ] Rust 专题版本头与 `RULES.md` 主版本一致（当前 2.1.1）
- [ ] 新增文档/规则使用中文（[language.md](./language.md)）
- [ ] 改 ruleset JSON 后：PR 合并 **且** `apply-org-ruleset.sh`（若需线上生效）
- [ ] 新 Rust 仓：CI + include + apply
- [ ] 更新 `setup-global-rules.sh` / 本 README / [CHANGELOG.md](./CHANGELOG.md)
- [ ] 相对 Markdown 链接可解析（本仓 `meta-validate`）
