# Rust CI/CD 标准

> 适用范围：所有 Rust 项目  
> 上位文档：[RULES.md](./RULES.md) §3  
> 版本：2.1.2  
> 组织可复用实现：`xhyperium/.github` → `ci-rust-standard.yml`（P1）/ `ci-rust-foundation.yml`（P0，含 doc + deny）

---

## 0. 落地矩阵（规范级 vs 平台级）

> **避免误解**：规范写「P0」≠ GitHub 已全局硬拦。合并时真正挡住的是你接入的 CI job + Org Ruleset 上的 required checks。

| 检查 | 规范级（RULES / 本文件） | `ci-rust-standard` | `ci-rust-foundation` | Org Ruleset `org-rust-pr-quality` |
|------|--------------------------|--------------------|----------------------|-----------------------------------|
| `fmt` | **P0** 不可豁免 | ✅ 默认 | ✅ 默认 | ✅ 强制（白名单仓） |
| `clippy -D warnings` | **P0** 不可豁免 | ✅ 默认 | ✅ 默认 | ✅ 强制 |
| `test` | **P0** 不可豁免 | ✅ 默认 | ✅ 默认 | ✅ 强制 |
| `cargo doc` | **P0**（库/workspace 推荐；原型可宪章暂缓） | ❌ | ✅ 默认可关 `run_doc` | ❌ 不绑 |
| `cargo deny` | **P0**（有依赖时；原型可宪章暂缓） | ❌ | ✅ 默认可关 `run_deny` | ❌ 不绑 |
| MSRV / coverage | P1 / P2 | ❌ | 可选 input | ❌ 不绑 |
| R-DEP-004 依赖引用 | **P0**（workspace） | 项目自接 | 项目自接 | ❌ 不绑 |

**组织平台硬门禁（当前）**：仅 `org-rust / rust-fmt` · `org-rust / rust-clippy` · `org-rust / rust-test`（见 [`org-rust-pr-quality.ruleset.json`](../org-rust-pr-quality.ruleset.json)）。  
**有意不为**：doc/deny 不进全 org quality ruleset，避免未就绪仓被锁死；需要供应链硬拦时用 **foundation** 并保持 `run_deny: true`。

---

## 1. PR 合并门禁（规范 P0）

| 检查 | 命令 | 失败策略 | 平台是否默认硬拦 |
|------|------|----------|------------------|
| 格式化 | `cargo fmt --all -- --check` | 阻断 | ✅ Org Ruleset（白名单仓） |
| 静态分析 | `cargo clippy --workspace --all-targets --all-features -- -D warnings` | 阻断 | ✅ |
| 测试 | `cargo test --workspace --all-features` 或 `cargo nextest run --workspace` | 阻断 | ✅ |
| 文档构建 | `cargo doc --workspace --no-deps --all-features` | 阻断（库/workspace 推荐） | 仅 foundation |
| 供应链 | `cargo deny check` | 阻断 | 仅 foundation |

说明：

- **fmt + clippy + test** 不可豁免（任何实质 Rust 变更）。
- **doc / deny**：规范仍要求；极简 bin 原型可在项目宪章声明暂缓 + 消除期限。平台层默认不绑，见 §0。
- Workspace 依赖引用检查见 §6.1 / [`scripts/check-workspace-deps.sh`](../../scripts/check-workspace-deps.sh)。

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
| Workspace 依赖引用 | `bash scripts/check-workspace-deps.sh`（或本仓拷贝） | P0（workspace） | 对齐 R-DEP-004 |

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

- 许可证白名单：优先从组织模板起步 → [`deny.template.toml`](./deny.template.toml)（拷贝为仓库根 `deny.toml` 后按项目收紧）
- Advisory 失败 = 阻断，例外走 R-SEC-008

### 6.1 Workspace 依赖引用（R-DEP-004）

```bash
# 在目标 Rust 仓库根执行（脚本位于 xhyperium/.github）
bash /path/to/xhyperium/.github/scripts/check-workspace-deps.sh
# 或：curl 后本地跑；项目可 vendoring 该脚本到 scripts/
```

- 非 workspace 单 crate：不跑此脚本；依赖纪律见 [RULES.md](./RULES.md) §9.2
- 建议接入 foundation 或项目 CI 的独立 step（失败即阻断）

---

## 7. Release CI

1. 校验版本号与 CHANGELOG  
2. 全量规范 P0 门禁（含 doc/deny，若项目已启用）  
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
# workspace 项目：
# bash scripts/check-workspace-deps.sh
```

项目可用 `make ci` / `just ci` 包装，语义与上表一致。

---

## 9. Agent 交付要求

Agent 声称完成前，必须在**当前会话**实际执行并保留输出证据：

1. fmt  
2. clippy `-D warnings`  
3. test  

无证据的完成声明无效（对齐组织 C-4 / L-4 精神）。

---

## 10. 新 Rust 仓接入 checklist

| 步骤 | 动作 | 验收 |
|------|------|------|
| 1 | 接入 reusable workflow（`ci-rust-standard` 或 `ci-rust-foundation`） | PR 上出现 `org-rust / rust-fmt|clippy|test`（调用方 job 名须为 `org-rust`，见 workflows README） |
| 2 | 库/基础设施工 prefer foundation；`run_deny`/`run_doc` 按需 | deny 前先落地 `deny.toml`（可从 [deny.template.toml](./deny.template.toml) 拷贝） |
| 3 | workspace 仓接入 `check-workspace-deps.sh`（可选但推荐） | 成员无内联第三方 `version` |
| 4 | 将仓名加入 [`org-rust-pr-quality.ruleset.json`](../org-rust-pr-quality.ruleset.json) 的 `include` | PR 合并模板 |
| 5 | `bash scripts/apply-org-ruleset.sh rulesets/org-rust-pr-quality.ruleset.json -f` | 线上 ruleset 更新（**git 合并 ≠ 线上生效**） |
| 6 | 用测试 PR 验证三 check 为 required | 未绿不可合 |

禁止：未接入 CI 的仓写入 quality ruleset `include`；禁止把 rust check 写进全 org 的 `main-protection.json`。
