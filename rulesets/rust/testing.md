# 测试策略

> 适用范围：所有 Rust 项目  
> 上位文档：[RULES.md](./RULES.md) §15  
> 版本：2.1.1

---

## 1. 测试分层

### 1.1 单元测试（P0）

- 与源码同文件：`#[cfg(test)] mod tests {}`
- 覆盖：核心逻辑、边界、错误路径、序列化、配置校验、重试/限流关键分支
- 不依赖真实外部网络（除非明确为集成测试）

### 1.2 集成测试（P1）

- 位置：`tests/*.rs`
- 外部依赖：mock、fakes、或 testcontainers
- 通过 feature / 环境变量控制，默认 `cargo test` 不强制依赖本地基础设施

### 1.3 故障注入（P1 关键模块）

至少覆盖：超时、断连、重试耗尽、限流/熔断触发、非法输入。

### 1.4 文档测试（P2）

- 公共示例尽量可编译；`ignore` / `no_run` 须说明原因

---

## 2. 命名（P1）

```rust
#[test]
fn connect_when_pool_exhausted_returns_timeout() { ... }
```

| 推荐 | 避免 |
|------|------|
| 行为 + 期望 | `test1`, `it_works` |
| `module_scenario_expectation` | 仅复述实现细节 |

中文注释说明业务意图；标识符保持英文。

---

## 3. 断言（P0 / P1）

```rust
// ✅
assert_eq!(err.kind(), ErrorKind::Timeout);
assert!(matches!(result, Err(Error::InvalidConfig { .. })));

// ❌
assert!(result.is_ok());
assert!(result.is_err());
```

| ID | 规则 | 级 |
|----|------|-----|
| R-TEST-001 | 成功路径断言关键字段，不只 `is_ok()` | P1 |
| R-TEST-002 | 错误路径断言类型/码，不只 `is_err()` | P0 |
| R-TEST-003 | 浮点比较用近似，禁止直接 `==`（领域允许除外） | P1 |

---

## 4. 隔离与确定性（P0）

- 测试互不依赖执行顺序
- 不共享可变全局状态；若不可避免：锁 + 清理，或 `serial_test`
- 时间：注入 clock（如 testkit ManualClock），避免真实 sleep 作为正确性条件
- 随机：可固定 seed
- 文件系统：用 `tempfile`，测后清理

---

## 5. 异步测试（P1）

```rust
#[tokio::test]
async fn retries_then_succeeds() { ... }
```

- 使用 `#[tokio::test]`（或项目统一宏）
- 避免测试中长时间真实等待；用 pause/mock 时间或极短 timeout
- 并发测试注意清理与 flaky

---

## 6. Flaky 管理（P0）

| 规则 | 说明 |
|------|------|
| 发现 flaky | 立即 `#[ignore = "原因; owner; 期限"]` 或隔离 |
| 禁止 | 长期静默 ignore、靠 CI 重试掩盖 |
| 检测 | `cargo nextest run --retries` 或多次循环 |
| 修复期限 | ignore 时写明 owner 与日期 |

---

## 7. 覆盖率（P2，项目可加严）

- 核心模块目标 **≥ 80%**
- 工具：`cargo llvm-cov`
- 覆盖率是辅助指标：关键路径质量 > 盲目刷百分比
- 禁止为刷线写无断言测试

---

## 8. 测试中的 panic 与 unwrap

- 测试内允许 `unwrap` / `expect`，但失败信息要可读：`expect("fixture 必须存在")`
- 推荐 `anyhow::Result` + `?` 的测试返回风格（可选）

```rust
#[test]
fn parses_config() -> Result<(), Box<dyn std::error::Error>> {
    let cfg = parse(sample())?;
    assert_eq!(cfg.port, 8080);
    Ok(())
}
```

---

## 9. 性能与基准（P2）

- 回归敏感路径放 `benches/` 或 CI 性能任务
- 基准结果噪声大时：多次取中位、固定机器、勿把微抖动当失败

---

## 10. 本地与 CI 命令

```bash
cargo test --workspace --all-features
cargo nextest run --workspace          # 推荐
cargo llvm-cov --workspace --lcov --output-path lcov.info
cargo test --doc --workspace
```

门禁矩阵见 [ci.md](./ci.md)。
