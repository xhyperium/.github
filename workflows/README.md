# xhyperium 可复用 CI Workflows

本目录包含 xhyperium 组织下所有 Go 模块仓库共用的 CI 工作流模板。

## 两级 CI 体系

| 工作流 | Tier | 适用 | Gates |
|--------|------|------|-------|
| `ci-foundation.yml` | P0 | 基座 Foundation（kernel, configx, redisx…） | gofmt → build → test(-race) → vet → coverage(80%) → lint → xlibgate trust + check → gitleaks |
| `ci-standard.yml` | P1 | L2.5 / 业务域（domainx, decimalx, binance…） | gofmt → build → test → coverage(60%) → vet → lint → xlibgate trust |

## 模块接入

在模块仓库中创建 `.github/workflows/ci.yml`：

```yaml
name: CI
on: [push, pull_request]
jobs:
  ci:
    uses: xhyperium/.github/.github/workflows/ci-foundation.yml@main
    # 或 uses: xhyperium/.github/.github/workflows/ci-standard.yml@main
```

### 自定义参数

```yaml
    with:
      go_version: '1.26.5'       # Go 版本
      coverage_threshold: 80     # 覆盖率门禁
      runs_on: ubuntu-latest     # Runner（替换为 self-hosted label）
```

## Runner 要求

FoundationX 铁律：**所有 CI 必须使用 self-hosted runner，禁止 GitHub-hosted。**

当前默认 `ubuntu-latest` 作为过渡——需在 xhyperium org 注册 self-hosted runner 后将 `runs_on` 切换为：
- `[self-hosted, Linux, X64, ci-governance]`（Foundation P0）
- `[self-hosted, Linux, X64, ci-go]`（Standard P1）

## 约束

- 禁止 Kubernetes 与 Docker（`docker`/`docker compose`/`k8s`）
- `xlibgate` 通过 Go module path 安装（`github.com/ZoneCNH/xlibgate`），GitHub 301 重定向至 `xhyperium/xlibgate`
- `govulncheck` 默认禁用，按需启用：`XLIB_ENABLE_VULNCHECK=1`
