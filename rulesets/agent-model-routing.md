# Agent 模型路由规则

> 适用范围：xhyperium 组织 Agent 会话（Claude Code / Codex / 其它）  
> 级别：见各节（**真红线 P0** vs **多 Agent 默认 P1**）  
> 互补规则：[agent-discipline.md](./agent-discipline.md)、[agent-workflow.md](./agent-workflow.md)、[agent-codex.md](./agent-codex.md)

### 场景分档（先读再执行）

| 场景 | 编码路由 |
|------|----------|
| **Solo**（单 Agent、无 Codex/不可用） | 主 Agent **可直接编码**；须遵守质量门禁与证据优先；**不得**因「没跑 Codex」判违宪 |
| **多 Agent / 有 Codex** | 生产代码默认委派 Codex；主 Agent 规划与验证（§1–§2） |
| **任意场景** | CI 不可由 Agent 冒充通过；L2/L3 须 Human（§1.3，**真红线 P0**） |

---

## 1. 全场景路由表

> **P1 默认（多 Agent / Codex 可用时）**。Solo 见上表降级。

| 任务类型 | 默认工具 | 禁止事项 |
|----------|---------|---------|
| 编码（Implement / Refactor / Fix） | **Codex CLI**（若可用） | 有 Codex 时主 Agent 不宜直接交生产代码 |
| 设计 / 推理 / 架构 / 计划 | **主 Agent（Claude 等）** 主导 | Codex **不得**私自变更需求或架构 |
| 批量执行（格式化 / lint / 简单实现） | **主 Agent** | 不得用于架构设计或安全变更 |
| CI 执行 / 门禁检查 | **CI Runner** | 人工/Agent 不得跳过或伪造（**P0**） |
| 最终审批（L2/L3） | **Human Reviewer** | Agent **不得**自行批准（**P0**） |
| 进化反思（Observe / Reflect） | **主 Agent** | **不得**在反思阶段改生产代码 |
| 进化纠错（Correct） | **Codex CLI**（若可用）否则主 Agent | **必须**附带回归测试 |

### 1.1 主 Agent 应主导的任务（P1）

- 架构设计、任务规划、决策分析、技术/需求文档
- 跨域分析、战略规划
- 进化反思（`observe` / `reflect`）— 禁止在反思阶段改生产代码
- 批量格式化 / lint

### 1.2 默认委派 Codex 的任务（P1 · Codex 可用时）

Codex 可用时，主 Agent 规划与验证，编码类工作默认委派：

- 代码生成、复杂重构、Bug 修复、单测生成、批量重构
- 代码审查（可双审：主 Agent + Codex）
- 进化纠错（`correct`）— 必须附带回归测试

**Solo / Codex 不可用**：主 Agent 直接执行上述任务，仍须 quality-gates + 证据。

### 1.3 非 Agent 强制处理的任务（**P0 真红线**）

以下任务**禁止** Agent 自行完成或伪造：

- CI 门禁检查 — 必须由 CI Runner 执行
- L2/L3 审批 — 必须由 Human Reviewer 批准

---

## 2. Agent Teams 模型路由（P1 · 启用 Teams 时）

使用多 Agent / Teams 时：

### 2.1 Teammate 编码委派

编码类 teammate 的 prompt **应**包含 Codex 委派指令（Codex 可用时）：

```
你是编码执行者。代码编写/修改/重构优先通过 ask_codex（或等价）执行。
你自身负责：理解任务 → 调用执行器 → 验证结果。
Codex 不可用时：直接编码，但必须跑质量门禁并报告证据。
```

### 2.2 spawn 路由表

| 任务性质       | 建议 | prompt 要点 |
| -------------- | ---- | ----------- |
| 编码实现       | 可委派 Codex | 所有权边界 + 验收 + 门禁 |
| 设计 / 规划    | 主 Agent | 禁止偷偷扩 scope 编码 |
| 代码审查       | 独立审查者 | 与实现者分离（宪法 C-3） |
| 文档生成       | 主 Agent 或 Writer | — |

### 2.3 Team Lead 职责

1. **规划** — 拆解任务、分配、定义验收标准  
2. **路由** — 按场景选择 Solo / Codex / Teams  
3. **验证** — 汇总结果、运行 [agent-quality-gates.md](./agent-quality-gates.md)  
4. **编码** — Teams 模式下 Lead 避免大包实现（见宪法 P-1）；Solo 下可直接实现

---

## 3. 降级策略（P0 · 有 Codex 时）

```
Codex CLI 执行
    ↓ 失败/超时（120s）
自动重试（最多 1 次）
    ↓ 仍然失败
回退到主 Agent 执行（标注 [FALLBACK]）
    ↓ 记录降级事件
```

**无 Codex / Solo**：不适用本链；直接主 Agent 执行 + 门禁，不算违规。

- 每次降级**必须**记录：任务 ID、失败原因、降级时间、最终执行方
- 降级后 Claude Code 可直接编码（豁免 §1 禁令），但必须标注 `[FALLBACK]`

---

## 4. 决策速查

```
任务进入
    │
    ├─ Solo / Codex 不可用？
    │   └─ 是 → 主 Agent 直接执行 + quality-gates（合法降级）
    │
    ├─ 需要写/改代码？
    │   ├─ 是 → 优先 Codex（可用时）；否则主 Agent
    │   └─ 否 → 下一判断
    │
    ├─ 需要设计/规划/推理？
    │   ├─ 是 → 主 Agent
    │   └─ 否 → 下一判断
    │
    ├─ 批量 fmt / lint？
    │   ├─ 是 → 主 Agent
    │   └─ 否 → 下一判断
    │
    ├─ CI 门禁？
    │   ├─ 是 → CI Runner（Agent 不得伪造）【P0】
    │   └─ 否 → 下一判断
    │
    ├─ L2/L3 审批？
    │   ├─ 是 → Human【P0】
    │   └─ 否 → 下一判断
    │
    └─ 其他 → 主 Agent（默认）
```

---

## 5. RACI 矩阵（多 Agent 时参考）

明确每个阶段的责任归属，防止越权或责任真空。Solo 时 Claude 列可兼任 Implementer。

### 5.1 角色定义

| 角色 | 身份 | 核心职责 |
|------|------|---------|
| Claude（Planner/Architect） | 主 Agent | Spec 质量、架构决策、独立 Review |
| Codex（Implementer） | Codex CLI | 代码实现、独立 Review、修复 CI |
| Verifier（QA/Runner） | 主 Agent 或 CI | 可复现验证、验收标准逐条对齐 |
| Arbiter（Judge） | 主 Agent | 冲突仲裁、decision.md 输出 |
| Human（Owner） | 用户 | P0 高风险确认、最终业务决策 |

### 5.2 阶段 × 角色矩阵

> R = Responsible（执行）、A = Accountable（负责）、C = Consulted（咨询）、I = Informed（知会）

| 阶段 | Claude | Codex | Verifier | Arbiter | Human |
|------|--------|-------|----------|---------|-------|
| Plan（规划） | **A/R** | C | I | I | C |
| Implement（编码） | C | **R** | I | I | I |
| Review（审查） | **R** | **R** | I | 条件触发 | I |
| Verify（验证） | C | I | **A/R** | I | I |
| Merge（合并） | **A** | I | C | 条件触发 | 条件触发 |
| Reflect（复盘） | **A/R** | C | C | I | I |
| Learn（改进） | **A/R** | I | I | I | C |

### 5.3 权限边界（不可越界）

| 角色 | 禁止事项 |
|------|---------|
| Claude | 未通过 Plan Gate 前不得指示合并；不得绕过高风险人工确认 |
| Codex | 不得擅自修改规则文件以"通过门禁"；不得引入未声明依赖 |
| Verifier | 不得用"我本地跑过"替代可复现命令与证据 |
| Arbiter | 不得在缺乏证据时强行裁决；不得替代 Human 做 P0 确认 |
| Human | 无限制（最终决策权） |

### 5.4 冲突升级路径

```
角色间分歧
    ├─ Review 结论冲突 → Arbiter 仲裁 → decision.md
    ├─ 风险 ≥ P1 → Arbiter 仲裁 → decision.md
    └─ 风险 = P0 → Arbiter 仲裁 → Human 确认 → decision.md
```

---

## 6. 项目级扩展

各项目可在项目级规则中继承本文件并细化（Codex 并发、crate 路由等），但**不得**削弱 §1.3 真红线（CI 不可伪造、L2/L3 须 Human），也**不得**把 Solo 合法降级重新标成违宪。
