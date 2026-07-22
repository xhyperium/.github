# Rust Clippy 全局配置

> 适用范围：所有 Rust 项目  
> 上位文档：[RULES.md](./RULES.md) §3  
> 版本：2.1.0

---

## 1. CI 基线命令（P0）

```bash
cargo clippy --workspace --all-targets --all-features -- -D warnings
```

- **零警告**策略：`warnings` 即失败
- 本地与 CI 命令一致，避免「我这边能过」

---

## 2. 推荐 lint 层级

写入 `lib.rs` / `main.rs` 或 `[lints]`（按项目选择一处 SSOT）：

```rust
// 库 crate 推荐
#![deny(clippy::unwrap_used)]
#![deny(clippy::expect_used)]
#![warn(clippy::all)]
#![warn(clippy::pedantic)]
#![allow(clippy::module_name_repetitions)]
#![allow(clippy::must_use_candidate)]
```

```toml
# Cargo.toml 示例（workspace 可集中）
[lints.clippy]
unwrap_used = "deny"
expect_used = "deny"          # 库；应用可改为 warn
all = "warn"
pedantic = "warn"
module_name_repetitions = "allow"
must_use_candidate = "allow"
```

### 分级表

| Lint / 组 | 库 | 应用 / bin | 说明 |
|-----------|----|------------|------|
| `clippy::all` | warn | warn | 基线 |
| `clippy::pedantic` | warn | warn | 风格加严；局部 allow 须注释 |
| `clippy::nursery` | 可选 warn | 可选 | 实验组，噪声大时项目自定 |
| `clippy::cargo` | warn | warn | 清单规范 |
| `clippy::unwrap_used` | **deny** | **deny** | 对齐 R-SEC-001 |
| `clippy::expect_used` | **deny** | warn | 应用启动 expect 用 allow + 注释 |
| `clippy::panic` | warn/deny | warn | 库建议 deny |
| `clippy::todo` | deny | deny | 禁止提交 todo 路径 |
| `clippy::unimplemented` | deny | deny | 同上 |
| `clippy::dbg_macro` | deny | deny | 对齐禁止 dbg! |

---

## 3. `clippy.toml` 行为阈值

项目可参考：

```toml
too-many-arguments-threshold = 8
too-many-lines-threshold = 500
type-complexity-threshold = 400
```

此文件只调**阈值**；启用/拒绝仍由 lint 级别与命令行决定。

---

## 4. allow 纪律（P0）

```rust
// ✅ 说明原因与范围
#[allow(clippy::too_many_arguments)] // 对外稳定 API，暂不破坏签名；见 issue#123
pub fn legacy_api(...) {}

// ❌
#[allow(clippy::all)]
```

- 禁止 crate 级空白 `#![allow(clippy::all)]`
- `#[allow(dead_code)]` 等同：必须有理由与清除计划
- 测试模块可放宽 unwrap 相关，但不必关闭全部 clippy

---

## 5. 与 rustc lint

推荐（库）：

```rust
#![warn(missing_docs)]
#![warn(unused_must_use)]
#![forbid(unsafe_code)] // 无 unsafe 时
```

`unexpected_cfgs` 等与自定义 cfg（如 `loom`）在 workspace lints 中 `check-cfg`。

---

## 6. 迁移策略

存量 `unwrap` 过多时：

1. CI 先对**改动文件**严格执行  
2. 主分支逐步 `deny`  
3. 禁止新增违规；旧代码随触达修复  

不得以「历史包袱」为由在新 crate 放宽 P0。
