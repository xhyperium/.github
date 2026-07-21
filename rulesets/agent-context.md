# Agent 上下文管理规则

> 来源：Planning with Files (14k⭐) + Boris Tane (Cloudflare) + best-practice (3.5k⭐) + Superpowers
> 适用范围：所有 Agent 会话（跨语言、跨项目）

---

## 1. 注意力刷新（P1）

> Attention Manipulation — Planning with Files (Manus 原则)

- 长任务（10+ 工具调用）时，**每批操作前重读计划文件**
- 50+ 工具调用后模型会忘记原始目标（"lost in the middle" 效应）
- 刷新方式：读取计划/任务文件的前 30 行，将目标重新注入上下文末尾
- 成本极低（读 30 行文本），效果显著

## 2. 文件即状态（P1）

> Boris Tane (Cloudflare 工程主管，9 个月实战)

- 关键信息**写入文件**而非留在聊天中
- 文件存活于 compaction，聊天不会
- 研究产出 → `research.md`
- 实现计划 → `plan.md` / Implementation Plan
- 文件是可审查的产物，聊天不是

## 3. 回退优先（P2）

> Git Revert + 缩小范围 — Boris Tane

- Agent 偏离时：**整体 git revert + 缩小范围重来** > 增量修补
- 反直觉但经过验证的策略
- 回退后缩小任务范围再重试
- 适用场景：实现偏离计划、引入意外副作用、修复导致更多问题

## 4. 渐进式上下文加载（P2）

> CLAUDE.md ≤ 150 行 — best-practice (3.5k⭐)

- 启动时**只加载 P0 规则**，详细规则按需拉取
- CLAUDE.md 保持精简，详细规则放在 Skills / Rules 文件中
- Agent 会话初始上下文 = 最小必要信息
- 触发相关场景时再加载专项规则

## 5. 双阶段审查（P2）

> Superpowers v4.0+

验证分为两步，**顺序不可颠倒**：

```
阶段一：需求合规（做对了没？）
  → 对照计划/需求检查实现是否符合
  → 不通过 → 修复 → 重新审查

阶段二：代码质量（做好了没？）
  → fmt / clippy / test / 代码审查
  → 不通过 → 修复 → 重新审查
```

- 代码质量审查**必须**在需求合规通过之后才能开始
- 避免"代码漂亮但不符需求"的问题
