# 可观测性规范

> 适用范围：所有 Rust 项目  
> 上位文档：[RULES.md](./RULES.md) §13  
> 版本：2.1.2

---

## 1. 结构化日志（P0）

### R-OBS-001：统一门面

| 要求 | 说明 |
|------|------|
| 使用 `tracing` | 新代码唯一日志门面 |
| 禁止 | 生产路径 `println!` / `eprintln!` / `dbg!` |
| `log` crate | 仅兼容第三方；本方代码不新增 |
| 格式 | 生产 JSON 或等价字段化；开发可 human-readable |

### R-OBS-002：级别语义

| 级别 | 用途 | 示例 |
|------|------|------|
| `error!` | 需处理的失败 | 主路径失败、数据损坏 |
| `warn!` | 可恢复异常 | 重试成功、降级、接近限额 |
| `info!` | 关键业务/生命周期 | 启动、配置加载摘要、请求完成（抽样后） |
| `debug!` | 排障 | 参数摘要、分支选择 |
| `trace!` | 热路径细节 | 循环、缓存命中（默认关闭） |

### R-OBS-003：字段化模板

```rust
error!(error = %err, operation = "connect", host = %host, "数据库连接失败");
info!(user_id = %id, action = "login", "用户登录成功");
warn!(attempt, max_retries, "请求失败，准备重试");

#[tracing::instrument(skip(self, body), fields(order_id = %order_id))]
async fn process_order(&self, order_id: u64, body: Bytes) -> Result<()> {
    // ...
}
```

| 规则 | 说明 |
|------|------|
| 消息 | 中文短句，稳定、可检索 |
| 字段 key | 英文 `snake_case`，保持稳定 |
| 错误 | 带 `error = %err` 或 `?err` |
| 敏感 | 遵守 [security.md](./security.md) R-SEC-006 |

### R-OBS-004：禁止事项

- 用日志代替返回错误（调用方无法处理）
- 热路径每条请求 `info!` 无采样（高 QPS 服务）
- 打印超大 body / 全量 headers
- 同一错误在每层重复 error 刷屏（边界记一次 + 上下文）

---

## 2. Span 与分布式追踪（P0 / P1）

### R-OBS-010：外部 I/O 必须可追踪（P0）

HTTP / DB / MQ / 对象存储 / 外部 gRPC：

- 创建 span：至少 `system` / `operation`（或等价约定）
- 失败时错误进入日志/事件，且保留上下文
- 支持注入/提取 `trace_id`（项目统一传播格式）

### R-OBS-011：instrument 使用（P1）

- 公共异步入口优先 `#[tracing::instrument]`
- `skip` 大对象与密钥字段
- 在 span 上用 `tracing::Span::current().record(...)` 补关键结果字段

---

## 3. 指标（P1）

### R-OBS-020：基础 RED / 资源

| 指标 | 类型 | 用途 |
|------|------|------|
| 请求量 | counter | QPS |
| 延迟 | histogram | P50/P95/P99 |
| 错误 | counter + 低基数 reason | 错误分类 |
| 重试 | counter | 依赖健康 |
| 熔断/限流触发 | counter | 过载信号 |
| 队列深度 | gauge | 背压 |

### R-OBS-021：命名与基数

- 统一前缀（如 `app_` / `xhyper_`，项目自定）
- **禁止**高基数 label：原始 user_id、完整 URL、邮件
- reason / code 使用受控枚举字符串

---

## 4. 错误可观测性（P0）

- 类型化错误 + `source` 链（见 [api-design.md](./api-design.md)）
- 日志与 metrics 的错误分类一致
- 用户可见消息与内部详情分离（对外中文友好，对内保留 source）

---

## 5. 健康检查（P1）

- 长驻服务提供 liveness / readiness 语义区分
- readiness 反映依赖是否可服务，避免「进程在但已不可用」
- 检查本身轻量，有超时

---

## 6. 本地开发

```rust
// 示例：组合根初始化（具体 subscriber 由项目选择）
tracing_subscriber::fmt()
    .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
    .init();
```

- 默认级别由 `RUST_LOG` 控制
- 测试可用 `tracing-test` 或显式 subscriber（按需）
