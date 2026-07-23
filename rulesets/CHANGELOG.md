# rulesets 变更日志

> 记录组织规则 SSOT 的可感知变更。宪法正文/附录的细项历史另见  
> [agent-teams-constitution-appendix.md](./agent-teams-constitution-appendix.md) 变更日志。

| 日期 | 摘要 |
|------|------|
| 2026-07-23 | **自验证 + 管道修复**：新增 `self-verification.md`（完成声明三关卡）；入库 `autonomous-iteration.md`；新增 `scripts/claude-rules-loader.sh` 与 setup 常驻清单对齐；setup v1.6 分发自验证/自主迭代并安装 loader；discipline/safety/quality-gates 交叉引用 |
| 2026-07-22 | **强制中文**：新增 `language.md`（P0）；rust RULES 2.1.1 对齐；setup 分发；取消默认英文/STE 交付 |
| 2026-07-22 | 续：Teams/双审 Solo 分档；根 README 补 apply 运维闭环与维护约定 |
| 2026-07-22 | Wave A–B 全量修复：README 与线上 active 对齐；document apply-org-ruleset；附录标题 v2.9；model-routing/codex solo 降级；去掉「跨语言」误导与 python 空链；setup 补全 rust 专题链接 |
| 2026-07-22 | org-rust-pr-quality 与线上对齐：`enforcement=active`，显式 include 三仓；新增 `scripts/apply-org-ruleset.sh` |
| 2026-07-22 | 移除 Go 规范与引用；quality-gates 收敛 Rust；宪法源码定义偏 `*.rs` |
| 2026-07-22 | Wave 1–2：宪法入库、workflow 解耦 harness、跨语言门禁矩阵（后改为 Rust）、专题版本 2.1.0 |
| 更早 | Rust RULES v2.1.0（R-DEP-004 等）；从历史上游副本迁入并确立 xhyperium SSOT |

## 与上游

| 项 | 说明 |
|----|------|
| 历史上游 | `bytechainx/.github` 等副本仅作参考 |
| 本仓 pin | **以本仓 `main` 为准**；不自动跟踪上游 |
| 同步方式 | 人工 diff → PR；禁止静默削弱 P0 |
