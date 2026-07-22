# Agent 质量门禁（跨语言）

> 适用范围：所有 Agent 会话  
> 级别：P0（验证义务）/ 命令按语言选择  
> 互补： [agent-discipline.md](./agent-discipline.md) · [agent-teams.md](./agent-teams.md) · 语言 SSOT

Agent **不得**假定「门禁 = cargo」。先识别仓库主语言，再执行对应门禁。

---

## 1. 通用原则（P0）

| 规则 | 说明 |
|------|------|
| 声称完成前必须验证 | 有 fresh 的 test/build/lint 输出（C-4 / L-4） |
| 验证是隐式义务 | 不要把「跑测试」当成可选 todo checkbox |
| 按变更范围收窄 | 优先包级 / 模块级命令，全仓慢测放交付前 |
| 展示证据 | 贴命令与关键输出，禁止口头「应该过了」 |

---

## 2. 语言矩阵

### 2.1 Rust

```bash
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo test --workspace --all-features
# Foundation / 库（推荐）
# cargo doc --workspace --no-deps --all-features
# cargo deny check   # 若存在 deny.toml
```

组织可复用 CI：`ci-rust-standard.yml`（P1）/ `ci-rust-foundation.yml`（P0）。  
规范 SSOT：[rust/RULES.md](./rust/RULES.md)

### 2.2 Go

```bash
gofmt -l .          # 非空即失败
go build ./...
go test ./...       # Foundation 加 -race
go vet ./...
# 有配置时
# golangci-lint run --timeout=5m
# xlibgate trust && xlibgate check   # Foundation
```

组织可复用 CI：`ci-standard.yml`（P1）/ `ci-foundation.yml`（P0）。  
薄规范：[go/RULES.md](./go/RULES.md)

### 2.3 混合 / 文档 / 配置仓

| 仓类型 | 最低验证 |
|--------|----------|
| 纯文档 / rules | 链接与渲染自检；本仓 `meta-validate` 或等价 |
| 双语言 monorepo | 只对 **本次变更触及** 的语言跑门禁 |
| 仅 YAML/JSON 模板 | 语法校验（python/yq/actionlint 等） |

---

## 3. Agent Teams / 波次门禁

波次间与 agent 完成后，使用 **§2 中与本仓库匹配** 的命令，而不是写死 `cargo`。

Prompt 模板占位示例：

```text
## 质量要求
识别本仓主语言后执行对应门禁（见 org rulesets/agent-quality-gates.md）：
- Rust: cargo fmt --check && cargo clippy … && cargo test …
- Go: gofmt + go test + go vet …
全部通过后再报告完成。
```

---

## 4. Codex Worker 白名单

Worker 默认可执行的验证命令随语言变化：

| 语言 | 默认可执行 |
|------|------------|
| Rust | `cargo fmt` / `cargo clippy` / `cargo test`（及明确授权的 `cargo doc` / `cargo deny`） |
| Go | `gofmt` / `go test` / `go vet` / `go build`（及明确授权的 `golangci-lint` / `xlibgate`） |
| 其他 | 主 Agent 在 prompt 中显式授权 |

禁止：Worker 擅自改 CI 配置、部署脚本、密钥文件。
