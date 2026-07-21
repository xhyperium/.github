# 安全基线规则

> 适用范围：所有 Rust 项目  
> 上位文档：[RULES.md](./RULES.md) §11  
> 版本：2.0.0

---

## 1. Panic 与错误路径（P0）

### R-SEC-001：禁止裸 unwrap / 失控 panic

- **触发**：编写非测试 Rust 代码
- **违规**：
  - `.unwrap()`
  - 无理由 `.expect()`
  - `panic!` / `unreachable!` / `todo!` / `unimplemented!` 出现在库的可调用路径
  - `unwrap_or_else(|_| panic!(...))` 等变相 panic
- **正确做法**：
  - 传播：`?`
  - 转换：`map_err` / `ok_or_else`
  - 可恢复默认：`unwrap_or` / `unwrap_or_else` / `unwrap_or_default`（默认值语义必须正确）
- **例外**：
  | 场景 | 条件 |
  |------|------|
  | `#[cfg(test)]` / `tests/` | 可使用 unwrap/expect |
  | 应用启动 fail-fast | `// PANIC: <不变量>` 注释 |
  | 静态永真不变量 | 优先 `debug_assert!`；release 仍需类型保证时文档化 |

### R-SEC-001a：库 vs 应用

| 代码位置 | unwrap | expect | panic! |
|----------|--------|--------|--------|
| 库 `src/` 公共/内部 API | ❌ | ❌ 默认 | ❌ 默认 |
| 应用 `main` / 组合根启动 | ❌ | ⚪ 仅启动 + `// PANIC:` | ⚪ 同上 |
| 测试 | ✅ | ✅ | ✅ |

---

## 2. Unsafe（P0）

### R-SEC-002：unsafe 必须有 SAFETY 注释

```rust
// SAFETY: `src` 与 `dst` 均来自 validate_buf()，长度 ≥ len，且不重叠。
unsafe {
    std::ptr::copy_nonoverlapping(src, dst, len);
}
```

- 注释必须说明：**为何满足安全不变量**，而非复述代码
- 优先安全封装；`unsafe` 块尽量小
- 含 unsafe 的 crate：
  - 文档说明安全契约
  - CI 建议 `miri` / 专项测试（见 [ci.md](./ci.md)）
- 无 unsafe 的库 crate 推荐：`#![forbid(unsafe_code)]`

---

## 3. 异步阻塞（P0）

### R-SEC-003：async 禁止阻塞调用

| 禁止 | 替代 |
|------|------|
| `std::thread::sleep` | `tokio::time::sleep` |
| `std::fs::*` | `tokio::fs::*` |
| 同步 `std::net::*` | `tokio::net::*` |
| 重 CPU + 同步锁长时间占用 | `spawn_blocking` / 拆分任务 |

```rust
// ✅
let content = tokio::fs::read_to_string(path).await?;
let out = tokio::task::spawn_blocking(move || heavy_cpu(input)).await??;
```

---

## 4. 网络安全（P0）

### R-SEC-004：TLS 与传输

- 默认**开启** TLS 证书校验
- 禁止默认 `danger_accept_invalid_certs` 或等价跳过
- 开发期临时关闭必须：显式配置 + 非默认 + 文档警告
- 禁止默认明文传输密钥；生产凭据仅走 TLS / 安全通道
- HTTP 客户端优先 `rustls` 生态（与项目统一即可）

### R-SEC-004a：超时

- 所有出站连接 / 请求必须有 timeout（连接超时 + 总体超时）
- 禁止无截止时间的无限等待作为默认

---

## 5. 注入与数据层（P0）

### R-SEC-005：查询与命令

- SQL / 类 SQL：参数化绑定，禁止字符串拼接用户输入
- Shell：禁止把未净化输入拼进命令行；优先避免 shell
- 路径：防止路径穿越（规范化 + 根目录约束）
- 反序列化：不信任输入；限制大小与分配

---

## 6. 敏感信息（P0）

### R-SEC-006：脱敏与密钥

| 禁止 | 要求 |
|------|------|
| 代码硬编码 token/密码/私钥 | env 或 secret provider |
| 日志打印完整密钥 | 脱敏（如前后 2–4 位）或只打 fingerprint |
| 错误/`Display` 带密钥 | 错误类型分层，敏感侧不进 Display |
| panic 消息含密钥 | 同上 |
| 把密钥写入仓库、issue、PR | 立即轮换 |

### 推荐模式

```rust
// 日志字段：只记录是否存在或哈希前缀，不记录原值
debug!(has_token = !token.is_empty(), "已加载凭证");
```

实现 `Debug` 时对敏感字段手动省略或脱敏（避免 `#[derive(Debug)]` 全量泄露）。

---

## 7. 供应链（P0 / P1）

| ID | 规则 | 级 |
|----|------|----|
| R-SEC-007 | CI 运行 `cargo deny check`（或 audit 等价） | P0 |
| R-SEC-008 | 高危漏洞阻断合并，除非书面例外 + 期限 | P0 |
| R-SEC-009 | 锁定 `Cargo.lock`（应用/workspace 二进制）；库策略按项目文档 | P1 |
| R-SEC-010 | 审慎 `git`/`path` 依赖；生产发布避免未钉版本 git 依赖 | P1 |

---

## 8. 正反例

```rust
// ✅ 错误传播
pub async fn connect(&self) -> Result<Connection, DbError> {
    self.pool.get().await.map_err(DbError::from)
}

// ❌
pub async fn connect(&self) -> Connection {
    self.pool.get().await.unwrap()
}

// ✅ SAFETY
// SAFETY: idx 已在 get_unchecked 调用前通过 check_bounds(idx)。
let v = unsafe { slice.get_unchecked(idx) };

// ❌ 无注释
let v = unsafe { slice.get_unchecked(idx) };
```

---

## 9. 自动检查

```bash
# 推荐 clippy（库）
cargo clippy --all-targets -- -D warnings \
  -D clippy::unwrap_used \
  -W clippy::expect_used

# 粗搜 unsafe 缺 SAFETY（需人工复核）
rg -n "unsafe\s*\{" --glob '*.rs' -g '!**/*test*' 

# 密钥误提交（示例）
rg -n "AKIA[0-9A-Z]{16}|BEGIN (RSA |OPENSSH )?PRIVATE KEY" --glob '!target/**'
```

更细 lint 策略见 [clippy.md](./clippy.md)。
