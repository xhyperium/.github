# xhyperium 可复用 CI Workflows

本目录包含 xhyperium 组织共用的 CI 工作流模板。

## 体系总览

| 工作流 | 语言 | Tier | Gates |
|--------|------|------|-------|
| `ci-foundation.yml` | **Go** | P0 | gofmt → build → test(-race) → vet → coverage → lint → xlibgate |
| `ci-standard.yml` | **Go** | P1 | gofmt → build → test → coverage → vet → lint → xlibgate |
| `ci-rust-foundation.yml` | **Rust** | P0 | fmt → clippy(-D) → test → cargo deny |
| `ci-rust-standard.yml` | **Rust** | P1 | fmt → clippy(-D) → test |

> Go 与 Rust **分开** 复用；Rust 仓库请用 `ci-rust-*`。

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
```

### 状态检查名称（org ruleset）

| Job name | 用途 |
|----------|------|
| `rust-fmt` | rustfmt |
| `rust-clippy` | clippy -D warnings |
| `rust-test` | cargo test |
| `rust-deny` | cargo deny（仅 foundation） |

## Go 模块接入

见历史注释与 `ci-foundation.yml` / `ci-standard.yml` 文件头。

```yaml
jobs:
  ci:
    uses: xhyperium/.github/.github/workflows/ci-foundation.yml@main
    with:
      go_version: "1.26.5"
```

## 规范引用

Rust 编码规范 SSOT：[`../rulesets/rust/RULES.md`](../rulesets/rust/RULES.md)  
Agent 分发：[`../scripts/setup-global-rules.sh`](../scripts/setup-global-rules.sh)
