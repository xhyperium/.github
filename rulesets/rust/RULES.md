# Rust 编码规范（完整版）

> **效力**：组织下所有 Rust 项目的**全局标准规范（SSOT）**  
> **版本**：2.1.2  
> **语言**：人类可读文本强制中文（见 [language.md](../language.md)）  
> **状态**：强制（P0 条款不可削弱；项目可加严）  
> **位置（xhyperium SSOT）**：[`xhyperium/.github`](https://github.com/xhyperium/.github) → `rulesets/rust/`  
> **上游镜像来源**：[`bytechainx/.github`](https://github.com/bytechainx/.github) → `rulesets/rust/`（历史/跨 org 副本）  
> **Agent 分发**：`scripts/setup-global-rules.sh` → `~/org-config` + `~/.claude/rules/rust.md`  
> **专项规则**：同目录 9 篇专题文档；冲突时以本文件 P0 条款为准

---

## 0. 文档定位

```
Constitution / 组织铁律
        ↓
  本文件（Rust 全局标准 · 完整版）
        ↓
  专项规则（security / async / api / testing / …）
        ↓
  项目宪章 / AGENTS.md（可加严，不可削弱）
        ↓
  局部实现选择
```

| 标识 | 含义 | 违反后果 |
|------|------|----------|
| **P0** | 强制；CI / Review 必须拦截 | 阻断合并 |
| **P1** | 默认强制；需书面例外 | 阻断或要求补齐 |
| **P2** | 强烈建议 | Review 标注，可迭代 |

**规则编号**：`R-<域>-<序号>`（如 `R-ERR-001`）。专项文档可扩展同域编号。

---

## 1. 适用范围

| 适用 | 说明 |
|------|------|
| ✅ 组织内全部 Rust crate / binary / workspace | 含库、服务、CLI、adapter、examples 中的生产路径 |
| ✅ Agent 生成代码 | 与人类代码同一标准 |
| ❌ 第三方 vendored 源码 | 不改；升级时评估 |
| ⚪ 生成代码（`build.rs` / protobuf 输出） | 不强制风格；生成器模板应尽量合规 |

**例外流程**：PR 描述写明条款 ID、原因、消除期限；`// EXCEPTION(R-XXX): 原因` 就近标注。

---

## 2. 语言与编码（P0）

| 类别 | 要求 |
|------|------|
| 字符编码 | **UTF-8（无 BOM）**，换行 **LF** |
| 代码注释（`//` `///` `//!`） | **中文**（强制） |
| 用户可见错误（`Display` / 业务文案） | **中文**（强制） |
| 设计/规格/README 等人类文档 | **中文**（强制，见 [language.md](../language.md)） |
| 标识符 | 英文（Rust 惯例） |
| 提交说明 | Conventional Commits：`type(scope): 中文说明` |
| 技术术语 | 中文叙述 + 可保留 API / CI / crate / workspace 等英文本体 |
| STE / 全文英文交付 | **非默认**；须书面豁免，见 [language.md](../language.md) §5 |

禁止：GBK/UTF-16、提交 `U+FFFD`、对已是 UTF-8 的中文二次错误转码；**禁止**无豁免的英文全文技术文档作为默认交付。

上位语言政策（组织全局）：[../language.md](../language.md)。

---

## 3. 工具链与质量门禁（P0）

### 3.1 提交前三件套（空气，不是可选 checkbox）

```bash
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo test --workspace --all-features
```

推荐补充（按项目开启，见 [ci.md](./ci.md)）：

```bash
cargo doc --workspace --no-deps --all-features
cargo deny check
# workspace：scripts/check-workspace-deps.sh（R-DEP-004）
```

### 3.1.1 落地矩阵（规范 P0 ≠ 平台必绑）

| 检查 | 规范 | Org Ruleset 硬拦 | 说明 |
|------|------|------------------|------|
| fmt / clippy / test | **P0** | ✅ 白名单仓 | 任何实质 Rust 变更不可豁免 |
| doc / deny | **P0**（库/有依赖推荐） | ❌ | 经 `ci-rust-foundation` 落地；原型可宪章暂缓 |
| R-DEP-004 | **P0**（workspace） | ❌ | 用 [`check-workspace-deps.sh`](../../scripts/check-workspace-deps.sh) |

完整四列表（含 standard vs foundation）：[ci.md §0](./ci.md)。  
**禁止**把「规范写了 P0」误读成「GitHub 已对全 org 强制」。

### 3.2 工具链约定

| 项 | 约定 |
|----|------|
| 默认工具链 | `stable` |
| Edition | 新项目优先 **2024**（或 workspace 统一 edition） |
| MSRV | 在根 `Cargo.toml` 声明 `rust-version`；CI 应验证 |
| Formatter | `rustfmt`（配置入仓，不争论风格） |
| Linter | `clippy`，`-D warnings` |
| 依赖审计 | `cargo-deny`（许可证 + 漏洞 + 来源） |

### 3.3 Lint 属性

- 禁止无说明的 crate 级 `#[allow(...)]` / `#![allow(unused)]`
- 局部 `#[allow]` 必须同行或上行注释原因
- 库 crate 推荐 `#![forbid(unsafe_code)]`；确需 unsafe 见 [security.md](./security.md)
- Clippy 分级见 [clippy.md](./clippy.md)

---

## 4. 代码风格（P0 / P1）

### 4.1 格式（P0）

- 以 `rustfmt` 输出为准，禁止手工对抗格式化
- 项目可提供 `rustfmt.toml`（如 `max_width = 100`），全 workspace 统一

### 4.2 打印与调试（P0）

| 禁止 | 替代 |
|------|------|
| `println!` / `eprintln!` | `tracing` 宏 |
| `dbg!` | `tracing::debug!` / `trace!` |
| 生产路径 `log` 门面（新代码） | `tracing`（第三方被迫依赖除外） |

**例外**：`examples/`、一次性 bin 原型、测试输出；合并前应清理或改为 tracing。

### 4.3 文档注释（P1）

- 所有 `pub` 类型、函数、trait、宏必须有 `///` 文档
- crate / 模块顶层用 `//!` 说明职责与边界
- 文档注释使用中文；代码示例可编译时优先可运行
- 公共 API 的 panic / 错误 / 安全条件用 `# Panics` / `# Errors` / `# Safety` 小节

### 4.4 复杂度（P2，建议阈值）

| 指标 | 建议上限 | 处置 |
|------|----------|------|
| 单文件 | ~300–500 行 | 按职责拆模块 |
| 函数参数 | ≤ 8 | 合成参数结构体 |
| 函数长度 | 一眼可读 | 提取私有函数 |
| 嵌套深度 | ≤ 4 | early return / 拆分 |

---

## 5. 命名约定（P0）

| 元素 | 风格 | 示例 |
|------|------|------|
| 类型 / Trait / Enum | `PascalCase` | `OrderService`, `ConnectError` |
| 函数 / 方法 / 变量 | `snake_case` | `create_order`, `base_url` |
| 常量 / 静态 | `SCREAMING_SNAKE_CASE` | `MAX_RETRY_COUNT` |
| 模块 / 源文件 | `snake_case`，**单数** | `handler`（非 `handlers`） |
| Crate / 包目录 | `kebab-case`，目录与包名一致 | `my-crate` → `crates/my-crate/` |
| Feature flag | `with-` 前缀 + `kebab-case` | `with-redis`, `with-serde` |
| 生命周期 | 短小有意义 | `'a`, `'conn`（避免无意义 `'x`） |
| 类型参数 | 单字母大写或有意义 Pascal | `T`, `E`, `Conn` |
| 测试函数 | `snake_case`，描述行为 | `connect_when_pool_full_returns_timeout` |

### 5.1 命名语义

- 布尔：`is_` / `has_` / `can_` / `enable_` 前缀
- 转换：`from_` / `as_` / `to_` / `into_` 遵循 Rust API 指南
- 失败可能：返回 `Result` / `Option`，不靠「魔法值」
- 禁止匈牙利命名、无意义缩写（`tmp2`, `data1`）；领域缩写（`id`, `url`, `tx`）除外

---

## 6. 项目与模块结构（P1）

### 6.1 推荐 crate 布局

```text
crate/
├── src/
│   ├── lib.rs          # 入口：模块声明 + 受控 re-export（禁止 glob 导出）
│   ├── main.rs         # 仅 binary
│   ├── error.rs        # Error + Result 别名
│   ├── config.rs       # 配置结构体 + 校验
│   └── <module>/       # 功能模块（mod.rs 或 module.rs）
├── tests/              # 集成测试
├── benches/            # 基准（可选）
├── examples/           # 示例（可选）
└── Cargo.toml
```

### 6.2 模块规则

- **默认私有**：优先 `pub(crate)`，对外再 `pub`
- **导出面唯一入口**：在 `lib.rs`（或明确的 `prelude`）集中导出
- **禁止** `pub use crate::*` 及无审核的通配 re-export
- 单元测试与源码同文件：`#[cfg(test)] mod tests {}`
- 一个模块一个清晰职责；循环依赖用拆分或依赖注入消除

### 6.3 Workspace

- 共享依赖版本放 `[workspace.dependencies]`；成员统一 `*.workspace = true` 引用（见 **§9.1 / R-DEP-004**）
- 公共 lint 放 `[workspace.lints]`，成员 `[lints] workspace = true`
- 包元数据（edition / license / rust-version）尽量 workspace 继承
- **禁止** crate 间循环依赖

---

## 7. 错误处理（P0）

### 7.1 分层策略

| 层级 | 策略 | 类型 |
|------|------|------|
| **库 / crate** | 类型化错误 | `thiserror` 枚举 + `pub type Result<T> = …` |
| **应用 / bin 组合根** | 上下文聚合 | `anyhow`（或等价）仅限顶层 |
| **公共 API** | 永不泄漏实现细节 | 禁止直接返回 `String` / `anyhow::Error` |

### 7.2 硬性规则

> **条款分工**：unwrap / expect / panic 的**编码主条款**在本表（R-ERR-*）。  
> [security.md](./security.md) 的 **R-SEC-001** 引用本表，并补充安全视角（变相 panic、库路径 todo 等），**不重复定义**另一套标准。

| ID | 规则 |
|----|------|
| R-ERR-001 | **禁止裸 `.unwrap()`**（非测试） |
| R-ERR-002 | **禁止无注释的 `.expect()`**；库代码默认禁止 expect，返回 `Result` |
| R-ERR-003 | 应用启动期 fail-fast 可用 `expect` / `panic!`，必须 `// PANIC: 原因` |
| R-ERR-004 | 错误必须保留 **`source` 链**（`#[source]` / `#[from]`） |
| R-ERR-005 | 错误消息含定位上下文（资源名、操作、关键 ID） |
| R-ERR-006 | 捕获后必须处理：传播 / 转换 / 记录；**禁止吞错** |
| R-ERR-007 | 公共错误枚举加 `#[non_exhaustive]`（除非稳定性已冻结且文档声明） |

```rust
// ✅ 库错误
#[derive(Debug, thiserror::Error)]
#[non_exhaustive]
pub enum ConfigError {
    #[error("缺少必填配置项: {key}")]
    MissingKey { key: String },

    #[error("读取配置文件失败")]
    Io(#[from] std::io::Error),
}

pub type Result<T> = std::result::Result<T, ConfigError>;

// ✅ 传播
let raw = std::fs::read_to_string(path)?;

// ❌ 裸 unwrap
let raw = std::fs::read_to_string(path).unwrap();
```

更细的 API / 错误设计见 [api-design.md](./api-design.md)。

---

## 8. 类型、所有权与 API 形状（P1）

### 8.1 所有权与借用

- 函数参数优先 `&str` / `&[T]` / `&Path`，避免无必要的 `String` / `Vec` / `PathBuf`
- 需要所有权时再收 `impl Into<String>` 或 `String`
- 避免无必要的 `.clone()`；共享只读状态优先 `Arc`
- 可变共享优先单一所有权或明确同步原语，禁止「先 clone 绕过借用检查」作为默认手段

### 8.2 Option / Result

- 用类型表达缺席与失败，禁止哨兵值（`-1`、空字符串当错误）
- 组合优先 `?`、`map`、`and_then`、`ok_or_else`；避免深层嵌套 match（可读性优先时 match 可保留）
- `unwrap_or` / `unwrap_or_else` / `unwrap_or_default` 仅用于**明确默认值**场景

### 8.3 Trait 与泛型

- 超过两个约束时使用 `where` 子句
- 公共 trait 新增方法考虑 `#[non_exhaustive]` 或提供默认实现以降低断裂
- 对象安全与 `async_trait` 的取舍写在模块文档中
- 优先标准库 trait（`From`/`TryFrom`/`Display`/`Debug`/`Default`）

### 8.4 序列化

- 公共 DTO 显式 `serde` 属性；字段 rename 策略全 crate 一致
- 枚举对外 wire 格式变更视为 breaking（见 [release.md](./release.md)）

---

## 9. 依赖管理（P0 / P1）

| ID | 规则 | 级 |
|----|------|----|
| R-DEP-001 | 新增依赖必须说明：原因、替代方案、维护状态 | P1 |
| R-DEP-002 | 能用标准库则不用第三方 | P1 |
| R-DEP-003 | `Cargo.toml` 依赖条目按字母序（或工具强制） | P2 |
| R-DEP-004 | **统一依赖引用**：第三方依赖版本与默认 feature 集中在根 `[workspace.dependencies]`；成员 crate **禁止**内联钉 `version`（细则 §9.1） | P0（workspace 项目） |
| R-DEP-005 | 禁止引入未评估许可证的依赖；CI `cargo deny` | P0 |
| R-DEP-006 | `default-features = false` 后按需开 feature，避免特性膨胀 | P1 |
| R-DEP-007 | 禁止循环依赖 | P0 |
| R-DEP-008 | 新增第三方依赖须先查 workspace 是否已有同名/等价条目；无则写入根再引用 | P1 |

安全相关依赖策略见 [security.md](./security.md)。

### 9.1 Workspace 依赖统一引用（R-DEP-004 细则 · P0）

> **目标**：一处声明版本、处处 `workspace = true` 引用；消除「同依赖多版本 / 成员各自钉版」漂移。

#### 强制模式

1. **根** `Cargo.toml` 的 `[workspace.dependencies]` 声明第三方依赖的 **version** 与默认 **features**（及 `default-features`）。
2. **成员** crate（含 `dev-dependencies` / `build-dependencies`）只通过 workspace 继承，不写版本号：

```toml
# 根 Cargo.toml
[workspace.dependencies]
serde = { version = "1", features = ["derive"] }
tokio = { version = "1", features = ["rt-multi-thread", "macros", "sync", "time"] }
thiserror = "2"

# 成员 crates/foo/Cargo.toml
[dependencies]
serde.workspace = true
thiserror.workspace = true
# 仅叠加本 crate 需要的 feature（不重复 version）
tokio = { workspace = true, features = ["macros"] }
```

3. **禁止**在成员中出现以下绕过形式（path 依赖除外，见下）：

```toml
# ❌ 禁止
serde = "1"
tokio = { version = "1", features = ["macros"] }
anyhow = { version = "1.0", default-features = false }
```

#### 允许例外

| 例外 | 条件 |
|------|------|
| **工作区内 path 依赖** | `foo = { path = "../foo", version = "x.y.z" }`；`version` 须与目标 `[package].version` 一致（项目可另有 VERSIONING 加严） |
| **单 crate 专属、确认无复用** | 可临时内联 version，**须在 PR 说明**，并在合理期限内提升到 `[workspace.dependencies]` |
| **`[patch.crates-io]` / 本地调试** | 仅开发期；合并主干前须移除，或在项目文档显式声明并设消除期限 |

#### 新增依赖流程（R-DEP-001 + R-DEP-008）

1. 查根 `[workspace.dependencies]` 是否已有同名或功能等价依赖  
2. 无则写入根表（版本、features、`default-features`），PR 说明原因与替代方案  
3. 成员仅 `*.workspace = true` 或 `{ workspace = true, features = [...] }`  
4. `cargo deny check`（及项目既有依赖门禁）通过  

#### 审查检查点

- [ ] 成员 `Cargo.toml` 无第三方 `version = "…"` 内联（path 依赖除外）  
- [ ] 根表无重复语义依赖的双轨版本（如两套 HTTP 客户端无文档说明）  
- [ ] feature 膨胀受控（R-DEP-006）：根表默认最小化，crate 按需叠加  
- [ ] CI 或本地跑过 [`check-workspace-deps.sh`](../../scripts/check-workspace-deps.sh)（推荐）  

### 9.2 单 crate（非 workspace）依赖纪律（P1）

R-DEP-004 **仅对 Cargo workspace 强制**。单包仓库不适用 `workspace = true`，改为：

| 要求 | 说明 |
|------|------|
| 版本钉死 | 直接依赖写明确 version（或兼容范围）；合并前 `Cargo.lock` 对应用/bin **入库**（R-SEC-009） |
| 新增依赖 | 仍走 R-DEP-001（原因 / 替代 / 维护状态）+ R-DEP-005（deny） |
| 升级为 workspace | 一旦拆成多 crate，**必须**在同 PR 或紧随 PR 上收至 `[workspace.dependencies]` |
| 检查脚本 | `check-workspace-deps.sh` 对非 workspace 根目录 **exit 0 并跳过**（打印提示） |

---

## 10. 配置管理（P0）

| ID | 规则 |
|----|------|
| R-CFG-001 | 配置 = **结构体 + 校验 + 文档**，禁止散落魔法常量 |
| R-CFG-002 | 加载优先级：**默认值 < 文件 < 环境变量 < 远端覆盖**（项目可文档化调整，但须单一明确顺序） |
| R-CFG-003 | 校验失败 **启动 fail-fast**，禁止带病运行 |
| R-CFG-004 | 超时、端口、endpoint、路径、重试次数必须可配置 |
| R-CFG-005 | Token / Secret **禁止**进配置仓库明文；走 env 或 secret provider |
| R-CFG-006 | 配置变更兼容：新增字段 + 默认值；删除/改名走 major 或迁移期双读 |

---

## 11. 安全约束（P0 摘要）

完整条款与示例：[security.md](./security.md)

| ID | 摘要 |
|----|------|
| R-SEC-001 | 禁止失控 panic 路径（**主条款见 R-ERR-001~003**；安全补充见 [security.md](./security.md)） |
| R-SEC-002 | `unsafe` 必须紧邻 `// SAFETY:` 说明不变量 |
| R-SEC-003 | `async` 中禁止阻塞 I/O；必要时空 `spawn_blocking` |
| R-SEC-004 | 默认 TLS 校验开启；禁止默认跳过证书验证 |
| R-SEC-005 | SQL / 查询参数化；禁止字符串拼接查询 |
| R-SEC-006 | 密钥与 PII 禁止写入日志、错误消息、panic 文本 |
| R-SEC-007 | CI 漏洞扫描；高危阻断合并 |

---

## 12. 异步与并发（P0 摘要）

完整条款：[async-runtime.md](./async-runtime.md)

| 要点 | 要求 |
|------|------|
| 运行时 | Workspace 统一 **tokio**；禁止多 runtime 混用 |
| 禁止 | 库内擅自 `block_on` / 自建 runtime |
| 锁 | Mutex guard **不得跨 `.await`** |
| 任务 | `JoinHandle` 必须保留并处理结果；禁止无监督 fire-and-forget |
| 通道 | **有界** channel + 明确溢出策略 |
| 缓存 | 必须有上限与淘汰策略 |
| 外部调用 | 必须 timeout；重试用指数退避 + 抖动 |
| 关闭 | 优雅关闭：停新请求 → 排空 → 释放依赖（倒序） |

---

## 13. 可观测性（P0 摘要）

完整条款：[observability.md](./observability.md)

- 统一 `tracing`；结构化字段，避免纯字符串拼接堆上下文
- 级别：`error` / `warn` / `info` / `debug` / `trace` 按语义使用
- 外部 I/O 必须有 span（系统名、操作名、关键 ID）
- 指标避免高基数 label（如原始 user_id）
- 错误日志带 `error = %err` 或 `?err`，保留可排障信息且不泄密

---

## 14. API 设计（P1 摘要）

完整条款：[api-design.md](./api-design.md)

- 稳定性分级：`stable` / `beta` / `experimental`
- 最小暴露面；内部类型不外泄
- 破坏性变更：CHANGELOG + PR 标 `BREAKING` + SemVer major
- 公共 enum / 可扩展结构优先 `#[non_exhaustive]`

---

## 15. 测试（P0 / P1 摘要）

完整条款：[testing.md](./testing.md)

| 要求 | 级 |
|------|----|
| 核心逻辑与错误路径有测试 | P0 |
| 断言具体值 / 错误类型，禁止只 `is_ok()` / `is_err()` | P1 |
| 测试独立、无顺序依赖 | P0 |
| Flaky 必须 `#[ignore]` + owner + 期限 | P0 |
| 核心模块覆盖率目标 ≥ 80% | P2（项目可升为 P0） |
| 异步测试用 `#[tokio::test]` | P1 |

---

## 16. 性能（P1 / P2）

| 规则 | 级 |
|------|----|
| 参数优先借用（`&str` 等） | P1 |
| 热路径避免无必要分配与 clone | P1 |
| 大集合优先 iterator 链，保持可读 | P2 |
| 禁止无界队列 / 无界缓存 / 无界重试 | P0 |
| 性能优化必须有 benchmark 或指标证据 | P1 |
| 同步代码中禁止为「方便」拉满异步运行时 | P1 |

---

## 17. 发布与 Feature（P1 摘要）

完整条款：[release.md](./release.md)

- SemVer；breaking → major
- Feature：`with-*` 前缀；默认 feature 最小化
- Feature 只切换实现，不静默改变业务语义
- CHANGELOG（Keep a Changelog）；Tag `vMAJOR.MINOR.PATCH`

---

## 18. 全局禁止清单（P0）

```text
❌ 非测试裸 unwrap() / 无 PANIC 注释的 expect/panic
❌ 无 SAFETY 注释的 unsafe
❌ println! / eprintln! / dbg!（生产路径）
❌ 异步中的阻塞 I/O（std::fs / thread::sleep / 同步 net）
❌ 无界 channel / 无界缓存作为默认
❌ 无 timeout 的外部网络调用
❌ 字符串拼接 SQL / 命令
❌ 硬编码密钥、证书、生产 endpoint 凭据
❌ 日志/错误中输出完整 token / 密码 / 隐私数据
❌ pub use crate::* 扩散导出面
❌ 循环依赖 / 绕过 workspace 私自钉死分叉版本（无说明）
❌ 成员 crate 内联钉第三方 version（绕过 `[workspace.dependencies]`，R-DEP-004）
❌ 无说明的 #[allow] 压制 lint
❌ 跳过 fmt / clippy / test 强行合并
```

---

## 19. 全局必须做（P0）

```text
✅ 提交前 fmt + clippy -D warnings + test
✅ 公共 API 中文 /// 文档
✅ 库：thiserror 错误类型 + source 链
✅ 配置可校验、可文档、fail-fast
✅ unsafe 旁 SAFETY 不变量
✅ 外部 I/O：timeout + 可观测 + 错误上下文
✅ JoinHandle / 子任务生命周期可解释
✅ 敏感配置走 env / secret provider
✅ 第三方依赖：根 [workspace.dependencies] + 成员 workspace = true（R-DEP-004）
```

---

## 20. 与项目宪章的关系

1. 本完整版是组织 **Rust 全局基线**
2. 项目可在 `docs/constitution/`、`AGENTS.md` 等**加严**（例如更严 MSRV、覆盖率强制、禁止 expect）
3. 项目**不可削弱**本文件 P0 条款
4. 冲突裁决：**不可削弱，可以加严**
5. 项目特有领域不变量（如金额禁用 `f64`）放在项目领域规范，并引用本文件作为上位编码标准

---

## 21. 规则导航

| 文件 | 职责 | 何时精读 |
|------|------|----------|
| [RULES.md](./RULES.md) | ⬅ **完整版核心（本文件）** | 始终 |
| [security.md](./security.md) | 安全基线、unsafe、脱敏、供应链 | 涉 I/O、密钥、unsafe |
| [async-runtime.md](./async-runtime.md) | tokio、背压、重试、熔断、关闭 | 异步服务 |
| [api-design.md](./api-design.md) | 稳定性、错误类型、配置 API | 设计公共 API |
| [testing.md](./testing.md) | 分层测试、flaky、覆盖率 | 写测试 / 门禁 |
| [observability.md](./observability.md) | tracing、指标、追踪 | 日志与排障 |
| [release.md](./release.md) | SemVer、Feature、Changelog | 发版 / breaking |
| [clippy.md](./clippy.md) | lint 分级与推荐属性 | 配置 CI lint |
| [ci.md](./ci.md) | PR 门禁、落地矩阵、新仓接入 | 搭 CI / 接入 org ruleset |
| [deny.template.toml](./deny.template.toml) | cargo-deny 组织起点模板 | 新建 deny.toml |
| [cheatsheet.md](./cheatsheet.md) | 一页速查 | 日常编码 |

---

## 22. 变更协议

| 项 | 要求 |
|----|------|
| 存储 | `org-config`（或组织 `.github`）仓库版本化 |
| 评审 | 修改 P0 须 PR + 至少一人审查 |
| 版本 | 本文档顶部版本号：breaking 规则升 major，新增 P1/P2 升 minor，笔误升 patch |
| 分发 | `~/.claude/rules/rust.md` → 本文件 symlink；更新后 `git pull` 即生效 |
| 生效 | 合并入组织规则主干后立即作为 Agent / 人类默认标准 |

---

## 23. 速查：常见决策

| 场景 | 选择 |
|------|------|
| 库内失败 | `Result` + `thiserror`，不用 anyhow |
| bin 主函数 | `anyhow::Result` 可接受 |
| 需要 panic | 仅启动期不变量 + `// PANIC:` |
| 共享只读配置 | `Arc<Config>` |
| 跨 await 状态 | 拆锁范围 / 消息传递，不持 guard |
| 新依赖 | 先 std → 再根 `[workspace.dependencies]` 已有 → 再写入根表并 `workspace = true` 引用（R-DEP-004/008） |
| 成员 Cargo.toml | `serde.workspace = true`；**禁止** `serde = "1"` |
| path 依赖 | `foo = { path = "…", version = "与目标 package 一致" }` |
| 公开 enum | `#[non_exhaustive]` + 显式文档 |
| 日志 | `tracing`，字段化，中文消息 + 英文 key |

---

**维护者**：组织规则所有者  
**关联**：组织 SSOT 与分发见仓库根 [README.md](../../README.md) 与 [rulesets/README.md](../README.md)；初始化脚本见 `scripts/setup-global-rules.sh`
