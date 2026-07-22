# Go 编码规范（薄规范 / 组织入口）

> **效力**：xhyperium 组织 Go 模块的**组织入口**（薄层）  
> **版本**：0.1.0  
> **状态**：P0 基线强制；细则可在各 Foundation 模块宪章中加严  
> **SSOT 位置**：[`xhyperium/.github`](https://github.com/xhyperium/.github) → `rulesets/go/RULES.md`  
> **可复用 CI**：`ci-standard.yml`（P1）/ `ci-foundation.yml`（P0）

完整领域不变量（金额精度、import 边界、xlibgate trust 等）以 **各模块 CONSTITUTION / xlib_standard** 为准。  
本文件只固定跨模块的最低共同标准，避免与模块宪章双写冲突。

---

## 1. 提交前三件套（P0）

```bash
# 格式
test -z "$(gofmt -l .)"

# 构建 + 静态检查
go build ./...
go vet ./...

# 测试（P1 标准）
go test ./...

# Foundation P0 额外
# go test -race ./...
# 覆盖率门禁见 reusable workflow 的 coverage_threshold
```

Agent 声称完成前必须在当前会话执行并保留输出（对齐宪法 C-4 / L-4）。

---

## 2. 硬性基线（P0）

| ID | 规则 |
|----|------|
| G-ERR-001 | 生产路径禁止裸 `panic` 处理可恢复错误；库代码返回 `error` |
| G-ERR-002 | 错误必须带上下文（`fmt.Errorf` / `%w`），禁止吞错 |
| G-CON-001 | 配置可校验；密钥走 env / secret，禁止硬编码 |
| G-CON-002 | 外部 I/O 必须 timeout / 可取消 context |
| G-MOD-001 | `go mod tidy` 后提交；CI 可用 `go mod tidy -diff` |
| G-SEC-001 | 禁止日志/错误中输出完整 token / 密码 |
| G-BND-001 | 模块依赖边界以 xlibgate / 项目 DEPS 为准，禁止静默跨层 import |

---

## 3. 风格（P1）

- `gofmt` 为准，不争论风格
- 导出符号有 GoDoc；包注释说明职责
- 测试与实现同包或 `*_test` 包；断言具体行为，禁止只检查 `err != nil` 而不看类型
- 新增依赖说明原因；优先标准库

---

## 4. 与可复用 CI 的映射

| Tier | Workflow | 要点 |
|------|----------|------|
| P1 | `ci-standard.yml` | gofmt、build、test、coverage、vet、lint、xlibgate trust |
| P0 | `ci-foundation.yml` | + race、xlibgate check、可选 govulncheck、有配置时 gitleaks |

接入：`uses: xhyperium/.github/.github/workflows/ci-foundation.yml@main`

---

## 5. 与 Rust SSOT 的关系

| 语言 | 入口 |
|------|------|
| Go | 本文件（薄）+ 模块宪章 |
| Rust | [../rust/RULES.md](../rust/RULES.md)（完整版） |

跨语言 Agent 门禁命令见 [../agent-quality-gates.md](../agent-quality-gates.md)。

---

## 6. 变更协议

- 本薄规范升版：breaking 升 minor（0.x），笔误升 patch
- 模块级加严放在模块仓，**不可削弱**本节 P0
- 厚规范若未来从模块上收，以 PR 迁入 `rulesets/go/` 并更新本入口
