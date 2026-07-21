# Rust 开发规范速查卡

> 完整版：[RULES.md](./RULES.md) · 版本 2.0.0  
> 用途：日常编码一页纸；冲突以 RULES.md P0 为准

---

## 禁止清单（P0）

```text
❌ 非测试裸 unwrap()              → ? / map_err / 类型化错误
❌ 库代码 expect/panic            → 返回 Result
❌ 应用 expect 无注释             → // PANIC: 原因
❌ println! / eprintln! / dbg!    → tracing
❌ async 里 std::fs / sleep / net → tokio::* 或 spawn_blocking
❌ 无界 channel / 无界缓存         → 有界 + 策略
❌ 无 timeout 的外部调用           → 可配置超时
❌ 拼接 SQL / 危险 shell          → 参数化
❌ 硬编码密钥 / 日志打全量 token   → env + 脱敏
❌ pub use crate::*               → 显式导出
❌ 无 SAFETY 的 unsafe            → // SAFETY: 不变量
❌ 无说明 #[allow] / 跳过 CI      → 注释原因 / 门禁全绿
```

---

## 必须做（P0）

```text
✅ cargo fmt --check
✅ cargo clippy -- -D warnings
✅ cargo test --workspace
✅ 公共 API 中文 /// 文档
✅ 库：thiserror + source 链 + non_exhaustive（默认）
✅ 配置：结构体 + 校验 + fail-fast
✅ JoinHandle 有主人；关闭可优雅退出
✅ 敏感配置走 env / secret provider
```

---

## 命名

| 项 | 规则 | 例 |
|----|------|----|
| 类型/Trait | PascalCase | `OrderService` |
| 函数/变量 | snake_case | `create_order` |
| 常量 | SCREAMING_SNAKE | `MAX_RETRY` |
| 模块 | snake_case 单数 | `handler` |
| Crate | kebab-case | `my-crate` |
| Feature | with-* | `with-redis` |

---

## 错误

```rust
#[derive(Debug, thiserror::Error)]
#[non_exhaustive]
pub enum MyError {
    #[error("连接失败: {0}")]
    Connect(#[source] std::io::Error),
}
pub type Result<T> = std::result::Result<T, MyError>;

let data = fetch().await?; // 传播
```

| 层级 | 类型 |
|------|------|
| 库 | thiserror |
| bin 组合根 | anyhow 可接受 |

---

## 异步

```rust
// 有界
let (tx, rx) = mpsc::channel::<Msg>(1024);

// 不跨 await 持锁
let v = { state.lock().await.clone() };
work(v).await?;

// 监督任务
let h = tokio::spawn(worker());
h.await??;

// 阻塞 → 线程池
tokio::task::spawn_blocking(move || heavy()).await??;
```

---

## 日志

```rust
error!(error = %e, op = "connect", "连接失败");
info!(id = %id, "处理完成");
#[tracing::instrument(skip(self))]
async fn handle(&self, id: u64) -> Result<()> { ... }
```

---

## 提交

```text
<type>(<scope>): <中文说明>

feat|fix|refactor|docs|test|chore|perf|ci|style
```

---

## 工具

```bash
cargo fmt --all
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo test --workspace --all-features
cargo nextest run --workspace
cargo doc --workspace --no-deps --open
cargo deny check
cargo llvm-cov --workspace
```

---

## 专题导航

| 主题 | 文档 |
|------|------|
| 完整规范 | [RULES.md](./RULES.md) |
| 安全 | [security.md](./security.md) |
| 异步 | [async-runtime.md](./async-runtime.md) |
| API/错误 | [api-design.md](./api-design.md) |
| 测试 | [testing.md](./testing.md) |
| 可观测 | [observability.md](./observability.md) |
| 发布 | [release.md](./release.md) |
| Clippy | [clippy.md](./clippy.md) |
| CI | [ci.md](./ci.md) |
