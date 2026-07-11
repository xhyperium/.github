# xhyperium 可复用 CI Workflows

本目录包含 xhyperium 组织下所有 Go 模块仓库共用的 CI 工作流模板。

## 两级 CI 体系

| 工作流 | Tier | 适用 | Gates |
|--------|------|------|-------|
| `ci-foundation.yml` | P0 | 基座 Foundation（kernel, configx, redisx…） | gofmt → build → test(-race) → vet → coverage(80%) → lint → xlibgate trust + check → gitleaks |
| `ci-standard.yml` | P1 | L2.5 / 业务域（domainx, decimalx, binance…） | gofmt → build → test → coverage(60%) → vet → lint → xlibgate trust |

## 模块接入

### 示例 1：Foundation 基座模块（完整门禁）

适用：kernel、configx、redisx、kafkax 等 20 个基座模块。

```yaml
# .github/workflows/ci.yml
name: CI — Foundation

on:
  push:
    branches: [main]
  pull_request:
    paths-ignore:
      - '**/*.md'
      - 'docs/**'
      - '**/evidence/**'
  workflow_dispatch:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  ci:
    uses: xhyperium/.github/.github/workflows/ci-foundation.yml@main
    with:
      go_version: '1.26.5'
      coverage_threshold: 80
      runs_on: ubuntu-latest
```

### 示例 2：L2.5 领域层模块（标准门禁）

适用：decimalx、domainx、domain_market、domain_macro、domain_exchange。

```yaml
# .github/workflows/ci.yml
name: CI — Standard

on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  ci:
    uses: xhyperium/.github/.github/workflows/ci-standard.yml@main
    with:
      go_version: '1.26.5'
      coverage_threshold: 60
      runs_on: ubuntu-latest
```

### 示例 3：最低覆盖率调整（存储 adapter 模块）

适用：postgresx、taosx、clickhousex 等需要外部服务的模块。

```yaml
jobs:
  ci:
    uses: xhyperium/.github/.github/workflows/ci-foundation.yml@main
    with:
      coverage_threshold: 50   # 外部依赖模块可适度降低阈值
```

### 示例 4：启用安全扫描（govulncheck）

按需启用（符合 CONSTITUTION §9.4 — `XLIB_ENABLE_VULNCHECK=1` 按需策略）。

```yaml
jobs:
  ci:
    uses: xhyperium/.github/.github/workflows/ci-foundation.yml@main
    with:
      enable_govulncheck: true
```

### 示例 5：Self-hosted runner（生产环境）

⚠ FoundationX 铁律：生产环境禁止使用 GitHub-hosted runner。

```yaml
jobs:
  ci:
    uses: xhyperium/.github/.github/workflows/ci-foundation.yml@main
    with:
      runs_on: >-
        ["self-hosted", "Linux", "X64", "ci-governance"]
```

### 示例 6：固定版本引用（推荐生产使用）

```yaml
jobs:
  ci:
    uses: xhyperium/.github/.github/workflows/ci-foundation.yml@v1   # 或具体 commit SHA
    with:
      go_version: '1.26.5'
      coverage_threshold: 80
```

## 参数速查

### `ci-foundation.yml`（P0 完整）

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `go_version` | string | `1.26.5` | Go 工具链版本，`GOTOOLCHAIN=local` 锁定 |
| `coverage_threshold` | number | `80` | 全局覆盖率最低百分比 |
| `runs_on` | string | `ubuntu-latest` | Runner（生产须 self-hosted） |
| `enable_govulncheck` | boolean | `false` | 安全扫描（默认关闭 §9.4） |

### `ci-standard.yml`（P1 标准）

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `go_version` | string | `1.26.5` | Go 工具链版本 |
| `coverage_threshold` | number | `60` | 全局覆盖率最低百分比 |
| `runs_on` | string | `ubuntu-latest` | Runner（生产须 self-hosted） |

## 约束

- 禁止 Kubernetes 与 Docker（`docker`/`docker compose`/`k8s`）
- `xlibgate` 通过 Go module path 安装（`github.com/ZoneCNH/xlibgate`），GitHub 301 重定向至 `xhyperium/xlibgate`
- `govulncheck` 默认禁用，按需启用：`XLIB_ENABLE_VULNCHECK=1`
