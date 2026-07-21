# 发布策略

> 适用范围：所有 Rust 项目  
> 上位文档：[RULES.md](./RULES.md) §17  
> 版本：2.0.0

---

## 1. 语义化版本（P0）

| 变更类型 | 版本 | 示例 |
|----------|------|------|
| 破坏性 API / 行为 / 配置 | **MAJOR** | 删字段、改语义、改错误不可匹配 |
| 向后兼容功能 | **MINOR** | 新 API、新可选配置 |
| 向后兼容修复 | **PATCH** | bugfix、文档、内部重构无行为变 |

- `stable` API 严格 SemVer
- `0.x` 可更积极，但仍须 CHANGELOG；项目可规定 `0.x` 的 breaking 策略
- `beta` / `experimental` 可快迭代，**禁止静默**改默认行为

---

## 2. Feature Flag（P1）

### 命名

- 可选集成：`with-<name>`（`with-redis`、`with-kafka`）
- 能力开关语义清晰；避免 `foo2` 式命名

### 规则

| ID | 规则 |
|----|------|
| R-REL-001 | 默认 feature **最小化** |
| R-REL-002 | Feature 切换实现，不静默改变业务语义 |
| R-REL-003 | 任意 feature 组合不得 panic / 链接失败 |
| R-REL-004 | 互斥 feature 用文档 + `compile_error!` 明确 |
| R-REL-005 | 公共 API 对 feature 门控的项在文档标明 |

---

## 3. Changelog（P0）

- 格式：[Keep a Changelog](https://keepachangelog.com/)
- 任何**对外行为**变化必须记载：API、配置项、默认值、错误码、指标名
- Breaking 必须独立小节 + 迁移步骤
- 语言：中文（与组织铁律一致）；专有名词可英文

```markdown
## [1.2.0] - 2026-07-21

### 新增
- `Client::with_timeout` 支持自定义超时

### 变更
- 默认连接超时 5s → 3s

### 破坏性变更
- 删除已废弃的 `Client::connect_insecure`；迁移：使用 `TlsConfig::insecure_for_dev`
```

---

## 4. Tag 与产物（P0 / P1）

| 项 | 规范 |
|----|------|
| 单版本仓库 | `vMAJOR.MINOR.PATCH`（`v1.2.0`） |
| 多 crate 独立发版 | `{crate}-vMAJOR.MINOR.PATCH`（可选） |
| Tag 不可变 | 组织 Ruleset 保护；禁止挪 tag |
| 发布前 | fmt + clippy + test + deny（见 [ci.md](./ci.md)） |

---

## 5. 废弃（P1）

```rust
#[deprecated(since = "1.2.0", note = "请使用 `connect_with_tls`；1.5.0 移除")]
pub fn connect_insecure() { ... }
```

- 写明 since、替代 API、计划移除版本
- 废弃期后 major/约定版本删除

---

## 6. 文档语言（P0）

| 类别 | 语言 |
|------|------|
| README / 架构 / 变更说明 / 规范 | 中文 |
| 代码注释 / `///` | 中文 |
| 标识符 | 英文 |
| LICENSE | 英文原文 |
| 英文对外技术手册 | 从项目 STE/宪章 |

---

## 7. 发版检查清单

- [ ] 版本号与 SemVer 变更类型一致
- [ ] CHANGELOG 已写
- [ ] Breaking 有迁移说明
- [ ] MSRV / feature 矩阵仍成立
- [ ] CI 全绿
- [ ] Tag 格式正确
