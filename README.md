# xhyperium/.github

**xhyperium** 组织级共享配置与 SSOT 仓库。

| 路径 | 职责 |
|------|------|
| [`profile/`](./profile/) | 组织首页 Profile README |
| [`workflows/`](./workflows/) | 可复用 CI 文档入口与 YAML 镜像 |
| [`.github/workflows/`](./.github/workflows/) | **GitHub Actions 可调用源**（`uses:` 必须指向这里） |
| [`rulesets/`](./rulesets/) | Rust 全局规范 + Agent 规则 + 分支/tag 保护模板 |
| [`scripts/`](./scripts/) | 规则一键分发、workflow 同步 |
| [`codeql/`](./codeql/) | 组织 CodeQL 配置 |
| [`TRANSFER-CHECKLIST.md`](./TRANSFER-CHECKLIST.md) | ZoneCNH → xhyperium 迁移清单 |

## 快速链接

- **Rust 规范入口**：[rulesets/rust/RULES.md](./rulesets/rust/RULES.md)（v2.1.0）
- **CI 接入说明**：[workflows/README.md](./workflows/README.md)
- **Agent 规则分发**：

```bash
curl -sSL https://raw.githubusercontent.com/xhyperium/.github/main/scripts/setup-global-rules.sh | bash
# HTTPS：
USE_HTTPS=1 bash <(curl -sSL https://raw.githubusercontent.com/xhyperium/.github/main/scripts/setup-global-rules.sh)
```

## 可复用 CI 一览

| 工作流 | 语言 | Tier |
|--------|------|------|
| `ci-rust-standard.yml` | Rust | P1 fmt+clippy+test |
| `ci-rust-foundation.yml` | Rust | P0 + doc + deny |
| `ci-standard.yml` | Go | P1 |
| `ci-foundation.yml` | Go | P0 |

```yaml
jobs:
  ci:
    uses: xhyperium/.github/.github/workflows/ci-rust-standard.yml@main
```

## 维护约定

1. **改 workflow**：编辑 `workflows/*.yml` 后运行 `bash scripts/sync-workflows.sh`，再提交两边。
2. **改规则**：更新 `rulesets/`；Agent 侧执行 setup 脚本或 `cd ~/org-config && git pull`。
3. **禁止在 `main` 直接开发**；走 PR，由 `meta-validate` 门禁校验同步与语法。
4. 与历史上游 `bytechainx/.github` 的关系见 [rulesets/README.md](./rulesets/README.md)。

## 本仓 CI

`Meta Validate`（`.github/workflows/meta-validate.yml`）在 push/PR 时校验：

- `workflows/` ↔ `.github/workflows/` YAML 字节一致
- `rulesets/*.json` 可解析
- workflow / CodeQL YAML 可解析
- `scripts/*.sh` 通过 shellcheck
