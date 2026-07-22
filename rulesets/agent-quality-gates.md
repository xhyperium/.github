# Agent 质量门禁

> 适用范围：所有 Agent 会话（xhyperium · 默认 Rust）  
> 级别：P0（验证义务）  
> 互补： [agent-discipline.md](./agent-discipline.md) · [agent-teams.md](./agent-teams.md) · [rust/RULES.md](./rust/RULES.md)

xhyperium 组织默认语言为 **Rust**。声称完成前必须有 fresh 的 fmt / clippy / test 证据。

---

## 1. 通用原则（P0）

| 规则 | 说明 |
|------|------|
| 声称完成前必须验证 | 有 fresh 的 test/build/lint 输出（C-4 / L-4） |
| 验证是隐式义务 | 不要把「跑测试」当成可选 todo checkbox |
| 按变更范围收窄 | 优先 crate 级命令，全 workspace 慢测放交付前 |
| 展示证据 | 贴命令与关键输出，禁止口头「应该过了」 |

---

## 2. Rust 门禁

```bash
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo test --workspace --all-features
# Foundation / 库（推荐）
# cargo doc --workspace --no-deps --all-features
# cargo deny check   # 若存在 deny.toml
# workspace：bash scripts/check-workspace-deps.sh  # R-DEP-004
```

组织可复用 CI：`ci-rust-standard.yml`（P1）/ `ci-rust-foundation.yml`（P0）。  
规范 SSOT：[rust/RULES.md](./rust/RULES.md)  
**门禁落地真相表**（哪些是规范 P0、哪些是 Org 硬拦）：[rust/ci.md §0](./rust/ci.md)

### 文档 / 配置仓

| 仓类型 | 最低验证 |
|--------|----------|
| 纯文档 / rules | 链接与渲染自检；本仓 `meta-validate` 或等价 |
| 仅 YAML/JSON 模板 | 语法校验（python / actionlint 等） |

---

## 3. Agent Teams / 波次门禁

波次间与 agent 完成后，执行 §2 Rust 门禁（可按 crate 收窄）。

```text
## 质量要求
完成后运行：
cargo fmt --check && cargo clippy … && cargo test …
全部通过后再报告完成。
```

---

## 4. Codex Worker 白名单

| 角色 | 默认可执行 |
|------|------------|
| Worker | `cargo fmt` / `cargo clippy` / `cargo test`（及主 Agent 明确授权的 `cargo doc` / `cargo deny`） |
| 其他命令 | 主 Agent 在 prompt 中显式授权 |

禁止：Worker 擅自改 CI 配置、部署脚本、密钥文件。
