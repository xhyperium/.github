# API 设计规则

> 适用范围：所有 Rust 项目  
> 上位文档：[RULES.md](./RULES.md) §7 / §8 / §14  
> 版本：2.0.0

---

## 1. 稳定性分级（P1）

| 级别 | 含义 | 约束 |
|------|------|------|
| `stable` | 稳定 | 严格 SemVer；breaking 仅 major |
| `beta` | 可能调整 | 须 CHANGELOG；避免无声息破坏 |
| `experimental` | 随时变 | 隔离在 `experimental` 模块或 feature 后 |

标注方式（择一，项目内统一）：

- rustdoc：`/// 稳定性：stable`
- 模块路径：`pub mod experimental { ... }`
- feature：`with-experimental-foo`

---

## 2. 最小暴露面（P0 / P1）

| ID | 规则 | 级 |
|----|------|-----|
| R-API-001 | 默认私有；需要时再 `pub` / `pub(crate)` | P0 |
| R-API-002 | 禁止暴露内部实现类型（除非稳定性承诺） | P1 |
| R-API-003 | 导出集中在 `lib.rs` / 明确 prelude | P0 |
| R-API-004 | 禁止 `pub use crate::*` | P0 |
| R-API-005 | 公共 API 优先返回抽象：trait 对象 / 新类型 / DTO | P1 |

---

## 3. 类型设计（P1）

### 3.1 newtype

- 对 ID、金额、符号等易混类型使用 newtype，避免 `String` / `u64` 满天飞
- newtype 按需实现 `From`/`TryFrom`/`Display`/`serde`

### 3.2 枚举

```rust
#[derive(Debug, Clone, PartialEq, Eq)]
#[non_exhaustive]
pub enum OrderState {
    New,
    Open,
    Closed,
}
```

- 对外可扩展 enum：`#[non_exhaustive]`
- 增 variant 的 wire 兼容策略写进文档

### 3.3 Builder / 参数对象

- 参数 ≥ 4 个且多可选时，优先 builder 或 config 结构体
- builder 在 `build()` 做校验，返回 `Result`

---

## 4. 配置驱动（P0）

与 [RULES.md](./RULES.md) §10 一致：

- 可变行为可配置 + 默认值 + 校验 + 文档
- 禁止硬编码生产 endpoint / 密钥 / 路径
- 校验失败 fail-fast
- 兼容：新增字段 + 默认值；删除走迁移

```rust
#[derive(Debug, Clone)]
pub struct HttpClientConfig {
    /// 请求总超时
    pub timeout: Duration,
    /// 最大重试次数
    pub max_retries: u32,
}

impl HttpClientConfig {
    pub fn validate(&self) -> Result<(), ConfigError> {
        if self.timeout.is_zero() {
            return Err(ConfigError::Invalid {
                field: "timeout".into(),
                msg: "必须大于 0".into(),
            });
        }
        Ok(())
    }
}
```

---

## 5. 错误设计（P0）

| ID | 规则 |
|----|------|
| R-API-010 | 每 crate 定义自有 `Error` + `Result` 别名 |
| R-API-011 | 库用 `thiserror`；实现 `Debug` + `Display` + `Error` |
| R-API-012 | 保留 `source` 链 |
| R-API-013 | 公共 API 禁止 `String` / `anyhow::Error` 作为错误类型 |
| R-API-014 | `anyhow` / `eyre` 仅限 bin 与组合根 |
| R-API-015 | 公共错误 `#[non_exhaustive]`（稳定冻结者除外并文档声明） |
| R-API-016 | 错误文案中文；字段名 / 机器码可用英文 |

```rust
#[derive(Debug, thiserror::Error)]
#[non_exhaustive]
pub enum ClientError {
    #[error("连接失败: {message}")]
    Connect {
        message: String,
        #[source]
        source: Option<std::io::Error>,
    },

    #[error("配置无效: {field} — {msg}")]
    InvalidConfig { field: String, msg: String },

    #[error(transparent)]
    Http(#[from] reqwest::Error),
}

pub type Result<T> = std::result::Result<T, ClientError>;
```

### 错误映射

- 边界层把下游错误映射为本地语义，避免泄漏无关 crate 细节（或显式 `#[from]` 并稳定依赖）
- 需要区分可重试时，提供 `fn is_retryable(&self) -> bool` 或专用枚举分支

---

## 6. 破坏性变更（P0）

任何破坏性变更必须：

1. CHANGELOG 记载  
2. PR 标题或正文标 `BREAKING`  
3. SemVer major（stable API）  
4. 提供迁移说明（删什么、替什么、如何双读）

### 兼容技巧

| 场景 | 策略 |
|------|------|
| 配置新字段 | 可选 + 默认 |
| trait 扩展 | 新 trait 或默认方法 |
| enum 扩展 | `non_exhaustive` + 版本协商 |
| 改名 | 旧名 `#[deprecated]` 过渡期 |

---

## 7. 生命周期与泛型（P1）

- 生命周期名有意义：`'conn`, `'data`
- 多约束用 `where`
- 返回复杂类型可用 `impl Trait`（注意 opaque type 稳定性）
- 公共 API 避免不必要 `'static` 束缚

---

## 8. 文档义务（P1）

公共 API 文档应覆盖：

- 做什么 / 不做什么  
- 错误条件（`# Errors`）  
- Panic 条件（`# Panics`，应尽量无）  
- Safety（`# Safety`，unsafe 函数）  
- 示例（推荐）

---

## 9. 与 async API

- 公共 async fn 的 cancel 语义尽量写清  
- 避免在 API 中强制用户持有跨 await 的特殊 guard  
- Stream / 回调 API 明确所有权与背压
