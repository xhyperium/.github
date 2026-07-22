# xhyperium/.github

**xhyperium** 组织级共享配置仓库（Single Source of Truth）。

本仓不承载业务代码，只提供：

| 能力 | 说明 |
|------|------|
| **可复用 CI** | Rust 门禁工作流，模块仓 `uses:` 引用 |
| **编码与 Agent 规范** | 协作宪法、Rust 规范、Agent 纪律与分发脚本 |
| **治理模板** | 默认分支 / Tag / Rust PR 质量 ruleset JSON（active；应用见 apply 脚本） |
| **组织首页** | `profile/README.md`（GitHub Org Profile） |
| **安全基线** | 组织级 CodeQL 配置 |

> 组织首页展示内容见 [`profile/README.md`](./profile/README.md)。  
> 本文件是 **本仓库** 的使用说明，不是 Profile。

---

## 目录结构

```text
.github/                          # 本仓库
├── README.md                     # 本文件（仓库入口）
├── TRANSFER-CHECKLIST.md         # ZoneCNH → xhyperium 迁移清单
├── profile/
│   └── README.md                 # 组织 Profile（github.com/xhyperium）
├── workflows/                    # 可复用 CI：文档入口 + YAML 镜像
│   ├── README.md
│   ├── ci-rust-foundation.yml    # Rust P0
│   └── ci-rust-standard.yml      # Rust P1
├── .github/workflows/            # ★ GitHub Actions 可调用源（uses: 必须指向这里）
│   ├── ci-rust-*.yml             # 与 workflows/ 字节一致
│   └── meta-validate.yml         # 本仓自检（非 reusable）
├── rulesets/
│   ├── agent-teams-constitution.md  # 最高治理 C/L/P
│   ├── agent-quality-gates.md       # 验证矩阵（Rust 为主）
│   ├── rust/                        # Rust 完整版 SSOT
│   ├── agent-*.md                   # 纪律 / 工作流 / Teams …
│   └── *.json                       # 分支 / tag / PR quality 模板
├── scripts/
│   ├── setup-global-rules.sh     # 规则一键分发 → ~/org-config + ~/.claude/rules
│   └── sync-workflows.sh         # workflows/ ↔ .github/workflows/ 同步
└── codeql/
    └── codeql-config.yml
```

规范索引与层级：[rulesets/README.md](./rulesets/README.md)

---

## 1. 可复用 CI

### 调用路径（强制）

```text
uses: xhyperium/.github/.github/workflows/<name>.yml@main
```

顶层 `workflows/` 便于浏览；**真正可被 `uses:` 解析的是 `.github/workflows/`**。两边 YAML 必须一致，改完后执行：

```bash
bash scripts/sync-workflows.sh          # 同步
bash scripts/sync-workflows.sh --check  # 仅校验
```

### 工作流一览

| 文件 | 语言 | Tier | 门禁 |
|------|------|------|------|
| [`ci-rust-standard.yml`](./workflows/ci-rust-standard.yml) | Rust | P1 | fmt → clippy(-D) → test |
| [`ci-rust-foundation.yml`](./workflows/ci-rust-foundation.yml) | Rust | P0 | 上者 + doc + cargo deny（可关） |

完整参数与示例：[workflows/README.md](./workflows/README.md)

### Rust 最小接入

```yaml
# 模块仓 .github/workflows/ci-rust.yml
name: CI Rust
on:
  push:
    branches: [main]
  pull_request:
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
jobs:
  ci:
    uses: xhyperium/.github/.github/workflows/ci-rust-standard.yml@main
```

基础设施 / 核心库：

```yaml
jobs:
  ci:
    uses: xhyperium/.github/.github/workflows/ci-rust-foundation.yml@main
    with:
      rust_toolchain: "stable"
      run_deny: true
      run_doc: true
```

Rust status check 名称（供 org ruleset）：`rust-fmt` · `rust-clippy` · `rust-test` · `rust-doc` · `rust-deny`

---

## 2. 全局规范（rulesets）

| 路径 | 内容 |
|------|------|
| [rulesets/agent-teams-constitution.md](./rulesets/agent-teams-constitution.md) | Agent Teams 宪法（最高治理 C/L/P） |
| [rulesets/agent-quality-gates.md](./rulesets/agent-quality-gates.md) | 验证命令矩阵（Rust 为主） |
| [rulesets/rust/RULES.md](./rulesets/rust/RULES.md) | Rust 编码规范完整版 **v2.1.0**（P0 不可削弱） |
| [rulesets/agent-*.md](./rulesets/) | 执行纪律、工作流、安全、Teams、Codex 等 |
| [rulesets/*.json](./rulesets/) | 分支 / Tag / Rust PR 质量 ruleset **模板**（导入须谨慎） |

说明与导入注意：[rulesets/README.md](./rulesets/README.md)

### Agent 机器一键分发

```bash
curl -sSL https://raw.githubusercontent.com/xhyperium/.github/main/scripts/setup-global-rules.sh | bash

# 仅 HTTPS（无 SSH 时）：
USE_HTTPS=1 bash <(curl -sSL https://raw.githubusercontent.com/xhyperium/.github/main/scripts/setup-global-rules.sh)
```

效果：克隆/更新 `~/org-config` → 将 `rulesets` 软链到 `~/.claude/rules/`。

---

## 3. 组织 Profile

GitHub 组织页（`https://github.com/xhyperium`）渲染的是：

```text
profile/README.md
```

业务模块列表、架构图、徽章等在该文件维护。  
模块从 ZoneCNH 迁入后，按 [TRANSFER-CHECKLIST.md](./TRANSFER-CHECKLIST.md) 更新链接。

---

## 4. CodeQL

组织级配置：[codeql/codeql-config.yml](./codeql/codeql-config.yml)

- 默认查询集：`security-and-quality`
- 忽略：`vendor/`、`target/`、`.worktrees/`、生成代码等

模块仓可在自身 workflow 中引用或覆盖。

---

## 5. 本仓 CI（Meta Validate）

推送 / PR 时运行 **Meta Validate**（非 reusable）：

- `workflows/*.yml` 与 `.github/workflows/ci-*.yml` 字节一致
- `rulesets/*.json`、workflow / CodeQL YAML 可解析
- `scripts/*.sh` 通过 shellcheck

---

## 6. 维护约定

1. **不要在 `main` 直接改**；开分支 → PR → squash merge。
2. **改 reusable workflow**：只编辑 `workflows/*.yml`，再 `bash scripts/sync-workflows.sh`，两边一起提交。
3. **改规则**：更新 `rulesets/` 后，使用方 `cd ~/org-config && git pull` 或重跑 setup 脚本。
4. **Ruleset JSON** 是模板，导入 GitHub Org Rules 前确认 status check 名与目标仓 CI 一致，避免锁死合并。
5. 历史上游副本：`bytechainx/.github`；**xhyperium 以本仓为 SSOT**。

---

## 相关链接

| 资源 | URL |
|------|-----|
| 组织 | https://github.com/xhyperium |
| 本仓 | https://github.com/xhyperium/.github |
| Rust SSOT | [rulesets/rust/RULES.md](./rulesets/rust/RULES.md) |
| CI 文档 | [workflows/README.md](./workflows/README.md) |
| Rulesets | [rulesets/README.md](./rulesets/README.md) |
| 迁移清单 | [TRANSFER-CHECKLIST.md](./TRANSFER-CHECKLIST.md) |
