# Agent 执行纪律规则

> 来源：Cursor `<non_compliance>` 机制分析 + 本组织实践
> 适用范围：所有 Agent 会话（Claude Code / Codex / Gemini）

---

## 1. 说了就要做（P0）

- Agent 在输出中声明了下一步动作，**必须在同一轮执行**
- 禁止只生成计划不执行（说了不做 = 违规）
- 禁止只执行不报告（做了不说 = 违规）

## 2. 实时进度播报（P0）

- 每批工具调用前，必须输出 1-3 句进度说明
- 使用正确时态：已完成用过去时，正在做用现在时
- 引用任务名称而非 ID
- 不要重印完整 todo list

## 3. 验证是隐式的（P1）

- 禁止把 "运行测试"、"lint 检查" 放进计划的 todo list
- 验证是持续的、隐式的义务，不是可选的 checkbox
- 声称代码完成前，**必须**先跑 test/build
- 质量门禁三件套（fmt + clippy + test）是空气，不是任务

## 4. 任务原子化（P1）

- 每个 task item ≤ 14 个词
- 必须以动词开头
- 必须有明确的完成标准
- 代表有意义的工作（至少 ~5 分钟）
- 同一时间只能有一个 in_progress 任务
- 完成后立即标记，禁止批量更新

## 5. 三类违规（P0）

| 违规         | 触发条件                   | 纠正动作         |
| ------------ | -------------------------- | ---------------- |
| 状态不同步   | 声称完成但 todo 未更新     | 下一轮立即对账   |
| 缺少播报     | 工具调用但无 status update | 补充进度说明     |
| 未验证就完成 | 声称完成但未跑 test/build  | 必须先验证再关闭 |

## 6. 四步工作流

```
1. Discovery Pass  — 只读扫描，理解上下文，不动手
2. Structured Plan — 产出计划（Implementation Plan / task.md）
3. Execute + Track — 执行 + 实时播报 + 即时标记完成
4. Reconcile       — 对账 todo + 验证 + 输出摘要
```

---

## 与 OpenSpec 的映射

```
Cursor                OpenSpec
─────                 ──────
Discovery Pass   →    /brainstorming / Proposal
Structured Plan  →    Tasks.md
Execute + Track  →    /opsx apply
Reconcile        →    /opsx verify → archive
```

## 关键理念

> 每个模块约束 Agent 的一个自由度，合在一起形成无死角的执行纪律。

- `flow` 定义了「该做什么」
- `todo_spec` 定义了「怎么拆分」
- `status_update_spec` 定义了「怎么汇报」
- `non_compliance` 定义了「违规怎么办」
- `completion_spec` 定义了「什么算完成」
- `summary_spec` 定义了「怎么收尾」
