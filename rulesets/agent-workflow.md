# Agent 工作流编排规则

> 适用范围：所有 Agent 会话（Claude Code / Codex / Gemini）  
> 互补规则：  
> - [agent-discipline.md](./agent-discipline.md)（执行纪律）  
> - [agent-quality-gates.md](./agent-quality-gates.md)（质量门禁 · Rust）  
> - [agent-teams-constitution.md](./agent-teams-constitution.md)（最高治理）  
> - [agent-teams.md](./agent-teams.md)（多 Agent 波次）

---

## 工作流编排

### 1. Plan 模式默认策略

- 任何**非简单**任务（≥3 步骤或涉及架构决策）都进入 Plan 模式
- 如果事情开始跑偏，立刻**停止**并重新规划——不要硬推
- Plan 模式不仅用于"做"，也用于**验证步骤**
- 先写清楚详细规格，减少歧义

### 2. 子代理策略

- 大量使用子代理，让主上下文窗口保持干净
- 将调研、探索、并行分析下放给子代理
- 面对复杂问题，通过子代理"加算力"来推进
- 每个子代理只做一件事，保证执行聚焦

**两种并行机制的选择**：

| 场景 | 使用 Task 子代理 | 使用多 Agent / Teams |
|------|-----------------|----------------------|
| 只读调研/探索 | ✅ 首选（轻量、无副作用） | ❌ 过重 |
| 单文件/少量文件修改 | ✅ 适合（worktree 隔离） | ❌ 过重 |
| 多 crate / 多包并行实现 | ❌ 难协调文件所有权 | ✅ 首选（文件隔离 + 通信） |
| 需要波次调度 + 质量门禁 | ❌ 无内置协调机制 | ✅ 见 [agent-teams.md](./agent-teams.md) |
| 需要 agent 间通信 | ❌ 子代理间通常无法通信 | ✅ 首选 |

简单规则：**≤ 3 个独立只读任务用 Task；≥ 4 个或需要写代码协调用 Teams**。

### 3. 自我改进循环

- 用户每次纠正后：按既定模式更新 `tasks/lessons.md`（或项目约定的 lessons 路径）
- 给自己写规则，防止重复同样的错误
- 对经验教训进行迭代，直到错误率下降
- 每次会话开始时，先复盘与当前项目相关的 lessons

### 4. 完成前必须验证

- 没有证明"能工作"，就**不要**标记任务完成
- 需要时，对比主分支与改动后的行为差异（diff behavior）
- 问自己一句："资深工程师会批准这个吗？"
- 跑测试、查日志、展示正确性证据（命令按 [agent-quality-gates.md](./agent-quality-gates.md) 选语言）

### 5. 追求优雅（平衡版）

- 对非简单改动：停一下，问"有没有更优雅的做法？"
- 如果修复看起来很 hack：问自己——"以我掌握的全部信息，应该直接实现那个优雅方案"
- 对明显简单的修复跳过这一条——不要过度工程化
- 在提交前先挑战自己的方案质量

### 6. 自主修 Bug

- 收到 bug 报告：直接修，不要让用户手把手带
- 指向日志、错误信息、失败测试——然后把问题解决掉
- 不要求用户进行任何上下文切换
- CI 测试挂了就去修，不需要别人告诉你怎么修

---

## Git Worktree 规范

### 统一路径（P0）

所有项目的 worktree 目录统一使用项目根目录下的 `.worktrees/`：

```bash
.worktrees/<branch-name>    # 唯一合法路径
```

**禁止**：

- 使用 `worktrees/`（无前缀点）等变体
- 使用全局路径 `~/.config/superpowers/worktrees/`
- 在项目根目录外创建 worktree

**前提**：`.worktrees/` 必须已加入 `.gitignore`。创建 worktree 前验证：

```bash
git check-ignore -q .worktrees || echo ".worktrees/ 未被 gitignore 忽略！"
```

### Worktree 命名

```text
.worktrees/<type>-<date>-<slug>
# 或（有 issue 追踪时）
.worktrees/<type>-<issue-id>-<slug>
```

| 类型 | 前缀 | 示例 |
|------|------|------|
| 功能开发 | `feat-` | `.worktrees/feat-20260429-auth` |
| Bug 修复 | `fix-` | `.worktrees/fix-20260429-login-crash` |
| 重构 | `refactor-` | `.worktrees/refactor-20260429-provider` |
| 模块隔离 | `<module>-` | `.worktrees/infra-2026-04-29` |

### 任务-分支-Worktree 强制绑定（P0 铁律）

**每个 substantial task（见宪法附录 A）必须在独立的 git 分支上实现；推荐 + worktree。禁止在 main 或其他任务的分支上直接工作。**

完整生命周期：

```text
任务开始 → 创建 branch（+ worktree）→ 实现 → 提交 PR → Review → Merge → 删除分支 → 清理 worktree → 同步文档
```

#### 强制流程

| 步骤 | 命令 / 动作 | 说明 |
|------|-------------|------|
| 1. 创建隔离 | `git worktree add .worktrees/<name> -b <branch>` 或等价 | 任务开始时立即创建 |
| 2. 实现任务 | 在隔离工作区内编码、测试 | 不污染 main |
| 3. 提交 PR | `gh pr create` | 禁止直接 push main |
| 4. Review + Merge | CI 通过 + 审查 | 默认 squash merge |
| 5. 删除分支 | 合并后删除本地/远程功能分支 | 保持主干整洁 |
| 6. 清理 worktree | `git worktree remove …` | 合并后 7 天内 |
| 7. 同步文档 | 按项目需要更新 README/spec/任务状态 | 见下方清单 |

#### 文档同步清单（P0，按项目勾选）

任务合并后，按**项目实际存在**的路径更新（没有的项跳过，不要伪造）：

- [ ] 模块 README / `AGENTS.md` 反映变更
- [ ] 受影响的 spec / design（若项目有）
- [ ] 任务追踪系统关闭或更新状态（GitHub Issue / 项目看板 / 可选 bd）
- [ ] 治理规则变更时同步 `rulesets/` 或项目宪章

**禁止**：合并后对「项目已定义的闭环步骤」置之不理。

#### 分支命名与可追溯性（P0）

分支名必须可追溯到任务（满足宪法 C-7）。推荐：

```text
<type>/<issue-or-slug>
# 例: feat/ci-meta-validate  或  fix/123-nil-panic
```

| 有 issue 系统时 | 无 issue 系统时 |
|----------------|----------------|
| 分支名含 Issue/PR 编号或稳定 slug | 分支名含语义化 slug + PR 关联 |
| squash commit 引用同一编号 | PR 描述写清动机与范围 |

**禁止**：完全匿名的大改动（无法对应 PR/Issue/任务说明）。

#### 任务中止 / 延迟处置

| 场景 | worktree | 分支 | 文档 |
|------|----------|------|------|
| 任务完成 | 合并后 7 天内清理 | 合并后删除 | 同步闭环 |
| 任务中止 | 立即清理 | 可删除 | 记录原因 |
| 任务延迟 | 可保留 | 可保留 | 标注 defer |
| PR rework | **保留** | **保留** | 更新 review 记录 |

**关键规则**：PR 处于 review / rework 时，禁止清理 worktree 与分支。

#### 分支同步与合并

- 落后 main 时**首选 rebase**；冲突过多可 merge，并在 PR 说明
- 已推送后的 rebase 使用 `git push --force-with-lease`（勿裸 `--force`）
- **默认 squash merge**：`gh pr merge --squash`
- commit / squash 说明使用 Conventional Commits，中文说明即可

#### Main 分支禁区（P0 铁律）

**main（或默认分支）禁止直接开发。**

| 维度 | 禁止行为 |
|------|----------|
| 本地写入 | 在 main 上改业务/源码并当作交付 |
| 本地提交 | 在 main 上 `git commit` 交付 substantial 变更 |
| 远程推送 | `git push origin main` 绕过 PR |
| 合并方式 | 所有 substantial 变更走 PR → Review → Merge |

**唯一合法路径**：`feature branch → PR → Review → Merge into main`

若项目部署了本地 hook（如 block-dangerous-git），以其拦截为准；**无 hook 时本条仍为 Agent 自律铁律**（宪法 L-3）。

#### 禁止行为（通用）

| ID | 禁止行为 | 后果 |
|----|----------|------|
| WF-F01 | 在 main 上直接交付 substantial 变更 | 违宪 L-3 |
| WF-F02 | 多任务混用同一 worktree/分支 | 违宪 L-3 |
| WF-F03 | 合并后长期不删分支 | WARN |
| WF-F04 | 跳过项目已定义的文档/任务闭环 | 不得标 done |
| WF-F05 | 跳过 PR 直接 push main | 违宪 |
| WF-F06 | 匿名大改动（无可追溯 ID/PR） | 违宪 C-7 |
| WF-F07 | review 期间清理 worktree | 阻断 |

---

## 任务管理（通用）

1. **先写计划** — 可勾选条目（`tasks/todo.md` 或等价）
2. **验证计划** — 实现前确认一次范围
3. **跟踪进度** — 边做边标记
4. **解释改动** — 高层摘要
5. **记录结果** — review / 验证证据
6. **沉淀经验** — 被纠正后更新 lessons

---

## 核心原则

- **简单优先** — 改动范围与影响尽量小
- **拒绝偷懒** — 不做无验证的临时修补
- **最小影响** — 只改必须改的部分

---

## 附录：Harness / 项目增强（可选，非全局 P0）

> 以下仅在项目**显式启用** Harness、beads（`bd`）、或本地 iron-law hook 时生效。  
> **未启用的项目不得因本附录未执行而判违宪。**

### H1. beads（`bd`）任务追踪

若项目使用 beads：

- 分支名可含 bd issue ID：`<type>/<bd-id>-<slug>`
- 合并后：`bd close <id>`（中止用 `--reason=`）
- squash message 可引用 bd id

### H2. `.swarm` 任务目录

若项目使用 `.swarm/tasks` / `.swarm/specs`：

- 合并后更新 task 状态、spec、acceptance
- 证据可落在 `.swarm/runs/<task-id>/`

### H3. 本地 hook 拦截

若部署了 `iron-law-gate.sh` / `block-dangerous-git.sh` 等：

- main 上 Write/commit/push 可被 BLOCK
- 以项目 hook 文档为准；失败应 fail-open 或明确报错（见 agent-safety）

### H4. 历史 ID（R-AT-*）

部分上游文档使用 `R-AT-002` / `R-AT-006` 等编号。在 xhyperium 全局规则中，语义分别对应：

| 历史 ID | 本文件 / 宪法对应 |
|---------|-------------------|
| R-AT-002 匿名任务 | WF-F06 + 宪法 C-7 |
| R-AT-006 必须 PR | WF-F05 + 宪法 L-3 |

新文档优先使用本文件 ID 与宪法 C/L/P 编号。
