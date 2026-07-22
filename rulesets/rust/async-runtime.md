# 异步运行时与并发规则

> 适用范围：所有使用异步的 Rust 项目  
> 上位文档：[RULES.md](./RULES.md) §12  
> 版本：2.1.0

---

## 1. 运行时统一（P0）

| ID | 规则 |
|----|------|
| R-RT-001 | Workspace **统一 tokio**（或组织批准的单一 runtime） |
| R-RT-002 | 禁止多 runtime 混用（`async-std` + `tokio` 等），除非书面例外 |
| R-RT-003 | **库代码禁止**擅自 `block_on`、`Runtime::new` 全局阻塞 |
| R-RT-004 | 需要「同步包装异步」时，由**应用组合根**提供，并文档化线程模型 |

理由：嵌套 runtime / 在已有异步上下文 `block_on` 易死锁。

---

## 2. 异步代码规范（P0）

### R-RT-010：禁止隐式阻塞

见 [security.md](./security.md) R-SEC-003。摘要：

- `std::thread::sleep` → `tokio::time::sleep`
- `std::fs` → `tokio::fs`
- 重 CPU / 同步 SDK → `spawn_blocking`

### R-RT-011：Mutex 不跨 await

```rust
// ✅ guard 在 await 前结束
let snapshot = {
    let guard = state.lock().await;
    guard.clone_snapshot()
};
do_io(snapshot).await?;

// ❌ 持锁跨 await —— 死锁 / 延迟放大
let guard = state.lock().await;
do_io(guard.x).await?;
```

- 优先缩小临界区；热路径考虑 `tokio::sync` 与消息传递
- `std::sync::Mutex` 在 async 中若可能阻塞其他任务，需论证或改用 async Mutex / 拆分

### R-RT-012：JoinHandle 必须可监督

```rust
// ✅
let handle = tokio::spawn(worker(rx));
// 关闭路径：
handle.abort(); // 或协作式 cancellation
let _ = handle.await;

// ❌ fire-and-forget
tokio::spawn(worker(rx)); // 丢弃 JoinHandle，panic 被吞
```

- 后台任务必须有：生命周期所有者、取消策略、错误上报（log/metrics）
- 使用 `JoinSet` / 监督树模式管理多任务时，在模块文档说明

### R-RT-013：Cancellation 安全

- 使用 `tokio::select!` 时注意 cancel 丢失半完成副作用
- 关键状态变更尽量可回滚或幂等
- 优先协作式取消（`CancellationToken` / 关闭 channel）而非到处 `abort`

---

## 3. 背压与资源（P0）

### R-RT-020：有界队列

```rust
// ✅
let (tx, rx) = tokio::sync::mpsc::channel::<Msg>(1024);

// ❌ 默认无界
let (tx, rx) = tokio::sync::mpsc::unbounded_channel::<Msg>();
```

无界仅在：证明生产者受控 + 文档化内存上限 + 书面例外。

### R-RT-021：溢出策略必须明确

| 策略 | 适用 |
|------|------|
| 等待（背压） | 生产者可减速 |
| 超时失败 | 调用方需快速错误 |
| 丢弃最旧/最新 | 可接受数据丢失的遥测 |
| 断路 / 拒绝 | 过载保护 |

### R-RT-022：缓存有界

- 禁止无限增长 HashMap 当缓存
- 必须：最大条目 / TTL / 淘汰策略（LRU 等）
- 日志采样限速，禁止错误风暴打满磁盘

### R-RT-023：并发上限

- 对下游调用使用 semaphore / 限流，防止雪崩
- `buffer_unordered(n)` 的 `n` 必须可配置且有默认上限

---

## 4. 重试、熔断、超时（P0 / P1）

### R-RT-030：超时（P0）

| 场景 | 连接超时（参考） | 请求超时（参考） |
|------|------------------|------------------|
| 数据库 | 5s | 30s |
| 缓存 | 2s | 5s |
| 消息队列 | 5s | 10s |
| HTTP API | 5s | 15s |

参考值可按项目调整，但**必须存在且可配置**。

### R-RT-031：重试（P1）

```text
max_retries: 3
initial_delay: 100ms
max_delay: 5s
backoff: exponential
jitter: full or equal jitter
```

- 区分可重试（超时、429、连接重置）与不可重试（4xx 业务拒绝）
- **非幂等**写操作默认不重试，除非有幂等键
- 记录重试次数与最终失败

### R-RT-032：熔断与限流（P1）

- 触发与恢复必须可观测（metrics + log）
- 半开状态探测要限制并发
- 限流键避免高基数

### R-RT-033：幂等（P1）

- 对外写 API 文档标注幂等性
- 重试预算与幂等键策略写在接口文档

---

## 5. 优雅关闭（P0）

```text
启动: Config → Log/Tracing → Infrastructure → Services → API/Listeners
关闭: 停听新请求 → 排空 inflight → Services → Infrastructure → Log
```

| 要求 | 说明 |
|------|------|
| 可取消 | 根 `CancellationToken` 或等价 |
| 有超时 | 关闭总时长上限，超时强制退出并打 error |
| 顺序 | 依赖倒序释放 |
| 可测 | 至少有单元/集成级关闭路径测试（P2） |

---

## 6. 同步与 `Send` 边界（P1）

- 跨 await 持有的状态需满足 `Send`（多线程 runtime）
- `Rc` / `RefCell` 不进多线程 async 热路径
- `!Send` 类型困在 `spawn_local` / 单线程 runtime 时文档标明

---

## 7. 检查清单

- [ ] 无 `block_on` 藏在库里
- [ ] 无持锁跨 await
- [ ] 所有 spawn 有主人
- [ ] channel / 缓存有界
- [ ] 外部调用有 timeout
- [ ] 重试不破坏非幂等写
- [ ] 关闭路径可执行
