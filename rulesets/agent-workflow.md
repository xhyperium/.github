# Agent 工作流编排规则

> 适用范围：所有 Agent 会话（Claude Code / Codex / Gemini）
> 互补规则：[agent-discipline.md](./agent-discipline.md)（执行级纪律）

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

| 场景 | 使用 Task 子代理 | 使用 claude-teams teammate |
|------|-----------------|--------------------------|
| 只读调研/探索 | ✅ 首选（轻量、无副作用） | ❌ 过重 |
| 单文件/少量文件修改 | ✅ 适合（worktree 隔离） | ❌ 过重 |
| 多 crate 并行实现 | ❌ 无法协调文件所有权 | ✅ 首选（文件隔离 + 通信） |
| 需要波次调度 + 质量门禁 | ❌ 无内置协调机制 | ✅ 首选（见 [agent-teams.md](./agent-teams.md)） |
| 需要 agent 间通信 | ❌ 子代理间无法通信 | ✅ 首选（send_message） |

简单规则：**≤ 3 个独立只读任务用 Task，≥ 4 个或需要写代码协调用 claude-teams**。

### 3. 自我改进循环

- 用户每次纠正后：按既定模式更新 `tasks/lessons.md`
- 给自己写规则，防止重复同样的错误
- 对经验教训进行"无情迭代"，直到错误率下降
- 每次会话开始时，先复盘与当前项目相关的 lessons

### 4. 完成前必须验证

- 没有证明"能工作"，就**不要**标记任务完成
- 需要时，对比主分支与改动后的行为差异（diff behavior）
- 问自己一句："资深工程师会批准这个吗？"
- 跑测试、查日志、展示正确性证据

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

```
.worktrees/<type>-<date>-<slug>
```

| 类型 | 前缀 | 示例 |
|------|------|------|
| 功能开发 | `feat-` | `.worktrees/feat-20260429-auth` |
| Bug 修复 | `fix-` | `.worktrees/fix-20260429-login-crash` |
| 重构 | `refactor-` | `.worktrees/refactor-20260429-provider` |
| 模块隔离 | `<module>-` | `.worktrees/fred-2026-04-29` |

### 任务-分支-Worktree 强制绑定（P0 铁律）

**每个 substantial task 必须在独立的 git 分支 + worktree 上实现。禁止在 main 或其他任务的分支上直接工作。**

完整生命周期：

```
任务开始 → 创建 worktree + 独立分支 → 实现 → 提交 PR → Review → Merge → 删除分支 → 清理 worktree → 同步文档
```

#### 强制流程

| 步骤 | 命令 | 说明 |
|------|------|------|
| 1. 创建 worktree | `git worktree add .worktrees/<type>-<date>-<slug> -b <branch>` | 任务开始时立即创建 |
| 2. 实现任务 | 在 worktree 内编码、测试 | 隔离工作区 |
| 3. 提交 PR | `gh pr create` | 必须走 PR 流程，禁止直接 push main |
| 4. Review + Merge | CI 通过 + 人工 approve | 遵循 R-AT-006 |
| 5. 删除分支 | `git branch -d <branch> && git push origin --delete <branch>` | 合并后立即清理远程分支 |
| 6. 清理 worktree | `git worktree remove .worktrees/<name>` | 合并后 7 天内清理 |
| 7. 同步文档 | 见下方「文档同步清单」 | 合并后必须执行 |

#### 文档同步清单（P0）

任务合并后，必须更新以下文档（按适用范围勾选）：

- [ ] **任务文档**: `.swarm/tasks/<task-id>/` 下的 spec、scope、reviews 状态更新为 `done`
- [ ] **Spec 文档**: `.swarm/specs/<domain>/` 中受影响的规范同步更新
- [ ] **模块文档**: 模块级 `AGENTS.md` 或 README 反映变更
- [ ] **验收标准**: `.swarm/acceptance/<domain>/` 中的验收项标记为已验证
- [ ] **治理文档**: 如涉及治理变更，更新 `.claude/rules/` 或 `.swarm/specs/governance/`
- [ ] **bd 事务**: `bd close <id>` 标记任务完成

**禁止**：合并后不同步文档 = 任务未完成。文档同步是任务闭环的必要步骤，不是可选项。

#### 分支命名与 bd issue 溯源（P0）

分支名必须包含 bd issue ID，确保从分支名可直接定位任务：

```
.worktrees/<type>-<bd-issue-id>-<slug>
<branch-name> = <type>/<bd-issue-id>-<slug>
```

| 类型 | 前缀 | 示例 worktree | 示例分支 |
|------|------|---------------|----------|
| 功能开发 | `feat-` | `.worktrees/feat-x.go-mlt3-provider-verify` | `feat/x.go-mlt3-provider-verify` |
| Bug 修复 | `fix-` | `.worktrees/fix-x.go-4r8-panic-recover` | `fix/x.go-4r8-panic-recover` |
| 重构 | `refactor-` | `.worktrees/refactor-x.go-3d3-db-pool` | `refactor/x.go-3d3-db-pool` |
| 治理 | `chore-` | `.worktrees/chore-x.go-5bp-spec-sync` | `chore/x.go-5bp-spec-sync` |

**禁止**：不含 issue ID 的分支名（如 `feat/my-feature`）视为匿名任务，违反 R-AT-002。

#### 任务中止/延迟处置

| 场景 | worktree 处置 | 分支处置 | 文档处置 |
|------|--------------|----------|----------|
| 任务完成 | 合并后 7 天内清理 | 合并后立即删除 | 同步文档 → `bd close` |
| 任务中止 | 立即清理 | 立即删除 | `bd close --reason="aborted"` |
| 任务延迟 | 保留 worktree | 保留分支 | `bd defer <id> --until="date"` |
| PR 被拒需重做 | **保留 worktree** | 保留分支，在原 worktree 修复 | 更新 reviews/ |

**关键规则**：PR 处于 review 或 rework 阶段时，worktree 和分支**禁止清理**，直到 PR 最终 merge 或 abandon。

#### 分支同步策略

当分支落后 main 时：

```bash
# 首选：rebase（保持线性历史）
git fetch origin main
git rebase origin/main

# 备选：rebase 冲突过多时使用 merge
git fetch origin main
git merge origin/main
```

- **首选 rebase**：保持线性历史，PR 更干净
- **冲突过多时可 merge**：但需在 PR 描述中说明
- **禁止 force push**：rebase 后使用 `git push --force-with-lease`（如已 push 过）

#### 合并策略

- **默认使用 squash merge**：`gh pr merge --squash`
- 保持 main 分支历史整洁，每个 task 对应一个 commit
- squash 后的 commit message 必须包含 bd issue ID：`feat(x.go-mlt3): 描述`

#### Main 分支禁区（P0 铁律）

**main 分支是受保护的集成分支，禁止一切直接开发行为（本地 + 远程）。**

| 维度 | 禁止行为 | 运行时拦截 |
|------|----------|-----------|
| **本地写入** | 在 main 上 Write/Edit 任何文件 | `iron-law-gate.sh` → BLOCK |
| **本地提交** | 在 main 上执行 `git commit` | `block-dangerous-git.sh` → BLOCK |
| **远程推送** | `git push origin main` | `block-dangerous-git.sh` → BLOCK |
| **远程保护** | GitHub branch protection 禁止直接 push | GitHub 设置（需人工配置） |
| **合并方式** | 所有变更必须通过 PR + Review + Merge | R-AT-006 |

**唯一合法路径**：`feature branch → PR → Review → Merge into main`

#### 禁止行为

| ID | 禁止行为 | 后果 |
|----|----------|------|
| WF-F01 | 在 main 分支修改任何文件（不限类型） | 违宪（L-3），运行时 BLOCK |
| WF-F01a | 在 main 分支执行 git commit | 违宪（L-3），运行时 BLOCK |
| WF-F02 | 多任务混用同一 worktree/分支 | 违宪（L-3） |
| WF-F03 | 合并后不删除分支 | WARN，7 天后强制清理 |
| WF-F04 | 合并后不同步文档 | 任务状态不得标记为 done |
| WF-F05 | 跳过 PR 直接 push main | 违宪（R-AT-006），运行时 BLOCK |
| WF-F06 | 分支名不含 bd issue ID | 违宪（R-AT-002 匿名任务） |
| WF-F07 | PR review 期间清理 worktree | 阻断，丢失 review 上下文 |

---

### 清理

任务完成后，worktree 必须在 7 天内清理：
```bash
git worktree remove .worktrees/<name>
```

---

## 任务管理

1. **先写计划** — 把计划写到 `tasks/todo.md`，用可勾选条目
2. **验证计划** — 开始实现前先"回报/确认"一次
3. **跟踪进度** — 边做边把条目标记完成
4. **解释改动** — 每一步给出高层摘要
5. **记录结果** — 在 `tasks/todo.md` 添加 review 小节
6. **沉淀经验** — 被纠正后更新 `tasks/lessons.md`

---

## 核心原则

- **简单优先** — 每次改动尽可能简单，改动范围/影响尽量小
- **拒绝偷懒** — 追根溯源，不做临时修补；按资深开发标准交付
- **最小影响** — 只改必须改的部分，避免引入新 bug
