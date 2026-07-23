# xhyperium Organization Rulesets

> 本目录是 **xhyperium** 组织的全局规则中心（SSOT）：Rust 规范、Agent 纪律、协作宪法、GitHub Ruleset 配置。

## 目录

```text
rulesets/
├── language.md                           # 组织语言政策：强制中文（P0）
├── agent-teams-constitution.md           # 最高治理（C/L/P）v2.9
├── agent-teams-constitution-appendix.md  # 阈值 / ACL / 仲裁 / 变更日志 v2.9
├── agent-quality-gates.md                # 验证命令矩阵（Rust）
├── self-verification.md                  # 完成声明三关卡（自查 → 比对 → 双重确认）
├── autonomous-iteration.md               # 自主迭代：Scope / Metric / Verify / Guard
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
| [`setup-global-rules.sh`](../scripts/setup-global-rules.sh) | 克隆/更新 SSOT → symlink `~/.claude/rules/` + 安装 SessionStart loader |
| [`claude-rules-loader.sh`](../scripts/claude-rules-loader.sh) | SessionStart：节流同步 + 重建常驻 symlink（与 setup 清单对齐） |
| [`sync-org-rules.sh`](../scripts/sync-org-rules.sh) | 节流 `git pull --ff-only`（默认 **6h**；main + 干净工作区才更新） |
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
self-verification.md            ← 完成声明三关卡（自查 → 比对 → 双重确认）
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

效果：克隆/更新 `~/org-config` → symlink 到 `~/.claude/rules/`（宪法、质量门禁、自验证、Rust 入口与常用专题）。

### 始终加载的 Agent 规则（摘要）

| 文件 | 职责 |
|------|------|
| `language.md` | 人类可读文本强制中文（P0） |
| `agent-teams-constitution.md` (+ appendix) | 最高原则 / 铁律 / 协作协议 |
| `agent-quality-gates.md` | 验证命令矩阵（默认 Rust） |
| `agent-discipline.md` | 执行纪律：说了就做、隐式验证、任务原子化 |
| `agent-safety.md` | 安全护栏：证据优先、先读后改、三击升级 |
| `agent-workflow.md` | 工作流编排、worktree、任务闭环 |
| `agent-context.md` | 上下文管理、文件即状态 |
| **`self-verification.md`** | **完成声明三关卡**：自查清单 → 结果比对 → 双重确认（强制） |
| `autonomous-iteration.md` | 编码迭代：Scope / Metric / Verify / Guard |
| `agent-teams.md` / `agent-codex.md` / `agent-model-routing.md` | 协作与路由 |

`self-verification.md` 与纪律/安全/质量门禁互补：后三者要求「要验证」「要有证据」，前者规定**声明完成前必须经过的固定动作序列**。  
`claude-rules-loader.sh` 与 `setup-global-rules.sh` 共用常驻清单，SessionStart 不会再抹掉 teams/codex/routing。

### 自动更新（SessionStart · 默认开启）

SessionStart 调用 loader 时，会先跑 [`sync-org-rules.sh`](../scripts/sync-org-rules.sh)：

| 项 | 默认 |
|----|------|
| 间隔 | **6 小时**（戳记 `~/.claude/rules/.last-org-sync`） |
| 条件 | `~/org-config` 在 **main** 且 **工作区干净** |
| 动作 | `git fetch` + `pull --ff-only origin main`（**绝不** `reset --hard`） |
| 失败 | fail-open，不阻断会话 |

| 环境变量 | 作用 |
|----------|------|
| `ORG_RULES_AUTO_UPDATE=0` | 关闭自动同步（同 `INFRA_ORG_RULES_AUTO_UPDATE=0`） |
| `ORG_RULES_SYNC_INTERVAL_HOURS=6` | 节流间隔（小时，正整数） |
| `ORG_RULES_SYNC_FORCE=1` | 忽略戳记强制尝试同步（仍要求 main + 干净） |
| `ORG_RULES_SYNC_QUIET=0` | 打开同步日志（SessionStart 默认 quiet） |

手动立即同步：

```bash
ORG_RULES_SYNC_FORCE=1 ORG_RULES_SYNC_QUIET=0 bash ~/org-config/scripts/sync-org-rules.sh
bash ~/.claude/rules/_loader.sh
```

**注意**：GitHub Org Ruleset 线上策略仍须 `apply-org-ruleset.sh`，不会随本同步自动变更。

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
