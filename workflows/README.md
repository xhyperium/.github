# xhyperium 可复用 CI Workflows

本目录包含 xhyperium 组织共用的 **Rust** CI 工作流模板。

## 路径说明（强制）

GitHub reusable workflow 的 `uses:` 路径必须是：

```text
{owner}/{repo}/.github/workflows/{filename}@{ref}
```

因此本仓**可调用源**位于 **`.github/workflows/`**（与顶层 `workflows/` 内容同步）。
顶层 `workflows/` 便于浏览与文档链接；**改 workflow 时两边必须同改**，以免 `uses:` 与文档脱节。

本地同步：

```bash
bash scripts/sync-workflows.sh
```

本仓 `meta-validate` CI 会在两边 YAML 漂移时失败。

## 体系总览

| 工作流 | 语言 | Tier | Gates |
|--------|------|------|-------|
| `ci-rust-foundation.yml` | **Rust** | P0 | fmt → clippy(-D) → test → doc（可选）→ cargo deny（可选） |
| `ci-rust-standard.yml` | **Rust** | P1 | fmt → clippy(-D) → test |

## Rust 模块接入

### 示例：一般库（Standard）

```yaml
# .github/workflows/ci-rust.yml
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

### 示例：基础设施（Foundation）

```yaml
# .github/workflows/ci-rust.yml
name: CI Rust Foundation

on:
  push:
    branches: [main]
  pull_request:

jobs:
  ci:
    uses: xhyperium/.github/.github/workflows/ci-rust-foundation.yml@main
    with:
      rust_toolchain: "1.85"
      run_deny: true
      run_doc: true
```

### 状态检查名称（org ruleset）

可复用 workflow 内 job 名为 `rust-fmt` 等。模块仓若通过包装 job 调用：

```yaml
jobs:
  org-rust:
    uses: xhyperium/.github/.github/workflows/ci-rust-foundation.yml@main
```

则 GitHub 上报的 **required check context** 为：

| Context（ruleset 应写） | 含义 |
|-------------------------|------|
| `org-rust / rust-fmt` | rustfmt |
| `org-rust / rust-clippy` | clippy -D warnings |
| `org-rust / rust-test` | cargo test |
| `org-rust / rust-doc` | cargo doc（foundation，`run_doc`） |
| `org-rust / rust-deny` | cargo deny（foundation，`run_deny`） |

> 勿在 org ruleset 写裸名 `rust-fmt`（包装调用后永远等不到）。  
> 包装 job 名须与 ruleset 前缀一致（推荐统一 `org-rust`）。

## 规范引用

Rust 编码规范 SSOT：[`../rulesets/rust/RULES.md`](../rulesets/rust/RULES.md)  
Agent 分发：[`../scripts/setup-global-rules.sh`](../scripts/setup-global-rules.sh)
