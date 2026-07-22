# xhyperium/.github

**xhyperium** 组织级共享配置仓库（Single Source of Truth）。

本仓不承载业务代码，只提供：

| 能力 | 说明 |
|------|------|
| **可复用 CI** | Go / Rust 门禁工作流，模块仓 `uses:` 引用 |
| **编码与 Agent 规范** | Rust 全局 RULES、Agent 纪律与分发脚本 |
| **治理模板** | 默认分支 / Tag / Rust PR 质量 ruleset JSON |
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
│   ├── ci-foundation.yml         # Go P0
│   ├── ci-standard.yml           # Go P1
│   ├── ci-rust-foundation.yml    # Rust P0
│   └── ci-rust-standard.yml      # Rust P1
├── .github/workflows/            # ★ GitHub Actions 可调用源（uses: 必须指向这里）
│   ├── ci-*.yml                  # 与 workflows/ 字节一致
│   └── meta-validate.yml         # 本仓自检（非 reusable）
├── rulesets/
│   ├── rust/                     # Rust 全局规范 SSOT（入口 RULES.md）
│   ├── agent-*.md                # Agent 纪律 / 工作流 / 安全 …
│   ├── main-protection.json
│   ├── release-tag-protection.json
│   └── org-rust-pr-quality.ruleset.json
├── scripts/
│   ├── setup-global-rules.sh     # 规则一键分发 → ~/org-config + ~/.claude/rules
│   └── sync-workflows.sh         # workflows/ ↔ .github/workflows/ 同步
└── codeql/
    └── codeql-config.yml
```

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
| [`ci-standard.yml`](./workflows/ci-standard.yml) | Go | P1 | gofmt → build → test → coverage → vet → lint → xlibgate trust |
| [`ci-foundation.yml`](./workflows/ci-foundation.yml) | Go | P0 | 上者 + race + xlibgate check + gitleaks（有配置时） |

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

### Go 最小接入

```yaml
jobs:
  ci:
    uses: xhyperium/.github/.github/workflows/ci-foundation.yml@main
    with:
      go_version: "1.26.5"
      # 迁移后可覆盖 xlibgate 安装路径：
      # xlibgate_module: "github.com/xhyperium/xlibgate/cmd/xlibgate@v1.0.2"
```

---

## 2. 全局规范（rulesets）

| 路径 | 内容 |
|------|------|
| [rulesets/rust/RULES.md](./rulesets/rust/RULES.md) | Rust 编码规范完整版 **v2.1.0**（P0 不可削弱） |
| [rulesets/rust/](./rulesets/rust/) | security / async / testing / ci / clippy / … 专题 |
| [rulesets/agent-*.md](./rulesets/) | Agent 执行纪律、工作流、安全、Teams、Codex 等 |
| [rulesets/*.json](./rulesets/) | 分支 / Tag / Rust PR 质量 ruleset **模板**（需 org admin 导入） |

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
