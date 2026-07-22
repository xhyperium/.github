# Rust CI/CD 标准

> 适用范围：所有 Rust 项目  
> 上位文档：[RULES.md](./RULES.md) §3  
> 版本：2.1.1  
> 组织可复用实现：`xhyperium/.github` → `ci-rust-standard.yml`（P1）/ `ci-rust-foundation.yml`（P0，含 doc + deny）

---

## 1. PR 合并门禁（P0）

| 检查 | 命令 | 失败策略 |
|------|------|----------|
| 格式化 | `cargo fmt --all -- --check` | 阻断 |
| 静态分析 | `cargo clippy --workspace --all-targets --all-features -- -D warnings` | 阻断 |
| 测试 | `cargo test --workspace --all-features` 或 `cargo nextest run --workspace` | 阻断 |
| 文档构建 | `cargo doc --workspace --no-deps --all-features` | 阻断（库/workspace 推荐） |
| 供应链 | `cargo deny check` | 阻断 |

说明：极简 bin 原型可在项目宪章中声明暂缓 `doc`/`deny`，但 **fmt + clippy + test** 不可豁免。

---

## 2. 强烈建议（P1 / P2）

| 检查 | 命令 | 级 | 场景 |
|------|------|----|------|
| 漏洞扫描 | `cargo audit` | P1 | 有外部依赖 |
| 无用依赖 | `cargo udeps`（nightly） | P2 | 定期 |
| 重复依赖 | `cargo tree -d` | P2 | 定期 |
| MSRV | 按 `rust-version` 构建 | P1 | 发布库 |
| 覆盖率 | `cargo llvm-cov` | P2 | 核心库 ≥ 80% |
| 基准 | `cargo bench` | P2 | 性能敏感 |
| Miri | `cargo miri test` | P1 | 含 unsafe |
| 加速测试 | `cargo nextest run` | P1 | 中大型 |

---

## 3. 工具链矩阵

| 项 | 策略 |
|----|------|
| 默认 | `stable` |
| MSRV | `Cargo.toml` 的 `rust-version`；CI 独立 job |
| Nightly | 仅额外检查（udeps 等），默认不阻断合并 |
| 目标平台 | 至少 CI 声明的 primary target（通常 `x86_64-unknown-linux-gnu`） |

---

## 4. 执行顺序

```text
fmt ──► clippy ──► test ──► doc ──► deny
         │
         └── 任一步失败即失败，避免烧后续分钟数
```

- 缓存：`Swatinem/rust-cache` 或等价
- Workspace 大时：按变更路径做 **检测是否需要跑 Rust job**（仍不得跳过有代码变更的门禁）

---

## 5. 测试策略（CI）

- 默认 `--all-features` 与「最小 feature」至少一个 job（防 feature 组合腐烂）
- Flaky：见 [testing.md](./testing.md)；CI 不得无限 `--retries` 掩盖
- 需要密钥的集成测试：用 secrets，失败要脱敏日志
- `#[ignore]` 测试可另 job `cargo test -- --ignored` 夜间跑

---

## 6. 安全与合规

```bash
cargo deny check licenses bans advisories sources
```

- 许可证白名单项目自定，组织可统一 deny.toml 模板
- Advisory 失败 = 阻断，例外走 R-SEC-008

---

## 7. Release CI

1. 校验版本号与 CHANGELOG  
2. 全量 P0 门禁  
3. 打 tag / 发布 artifacts  
4. Tag 不可变（组织 Ruleset）  

详见 [release.md](./release.md)。

---

## 8. 本地一键模拟

```bash
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo test --workspace --all-features
cargo doc --workspace --no-deps --all-features
cargo deny check
```

项目可用 `make ci` / `just ci` 包装，语义与上表一致。

---

## 9. Agent 交付要求

Agent 声称完成前，必须在**当前会话**实际执行并保留输出证据：

1. fmt  
2. clippy `-D warnings`  
3. test  

无证据的完成声明无效（对齐组织 C-4 / L-4 精神）。
