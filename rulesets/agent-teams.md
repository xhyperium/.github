# Agent Teams 效率最大化规则

> 适用范围：**已启用**多 Agent / Teams 的会话（非 Solo）  
> 级别：启用 Teams 时的操作规范（**P0 真红线** = 文件隔离 + 波次门禁；其余多为 P1）  
> 互补规则：[agent-model-routing.md](./agent-model-routing.md)、[agent-discipline.md](./agent-discipline.md)、[agent-quality-gates.md](./agent-quality-gates.md)  
> **Solo 单 Agent**：本文件不适用；见 routing 场景分档与 workflow，不得因未开 Teams 判违宪

---

## 1. 波次调度（P0 · Teams 时）

多 Agent 并行时**必须**按波次（Wave）组织，禁止一次性 spawn 全部 agent 且无门禁。

```
Wave 1: 所有独立任务（无前置依赖）→ 最大并行
    ↓ 质量门禁通过
Wave 2: 依赖 Wave 1 产出的任务 → 并行
    ↓ 质量门禁通过
Wave N: 依赖 Wave N-1 的任务 → 并行
    ↓ 最终质量门禁
完成
```

### 1.1 波次规则

| 规则 | 约束 | 理由 |
|------|------|------|
| 每波最多 5 个 agent | 超过 5 个 git 冲突概率陡增 | 实测经验 |
| 波次间必须跑质量门禁 | 见 [agent-quality-gates.md](./agent-quality-gates.md)（Rust：fmt/clippy/test） | 防止错误级联 |
| 同波 agent 文件零重叠 | 见 §2 文件隔离 | 消除合并冲突 |
| 长链任务优先启动 | 关键路径决定总耗时 | 减少墙钟时间 |

### 1.2 依赖图构建

spawn 前**必须**画出任务依赖图，识别：

- 独立任务（立即并行）
- 依赖链（串行不可压缩）
- 关键路径（决定总耗时的最长链）

```
# 示例：识别三类任务
独立: T01, T03, T04, T09  → Wave 1（全部并行）
依赖: T03 → T02 → T08    → Wave 1(T03) → Wave 2(T02) → Wave 3(T08)
关键路径: T03→T02→T08→T14 = 8.5h（不可压缩）
```

---

## 2. 文件隔离（P0 · Teams 时）

### 2.1 Crate 级隔离（推荐）

每个 agent 拥有**整个 crate** 的独占写权限，粒度为 crate 而非文件。

```
Agent A: crates/common/src/error/ + crates/common/src/secure/
Agent B: crates/etcd/ + crates/taos/ + crates/rabbitmq/
Agent C: crates/common/src/health/ + crates/common/src/middleware/
```

### 2.2 隔离铁律

| 规则 | 违规后果 |
|------|---------|
| 一个文件只能有一个 owner | 违规 agent 的改动被 revert |
| 共享文件（Cargo.toml/lib.rs）由 Team Lead 串行修改 | 禁止 agent 直接改 workspace 级文件 |
| 新建文件必须在 ownership 边界内 | 越界文件不合并 |
| 接口契约（trait 签名）不可单方面修改 | 需 Team Lead 协调 |

### 2.3 互斥资源

以下资源需要排他锁，同一时刻只允许一个 agent 操作：

- `Cargo.toml`（workspace 级）
- `Cargo.lock`
- `cargo test`（全 workspace）
- `cargo build`（全 workspace）

---

## 3. Agent 分组策略（P0）

### 3.1 按改动域分组

将任务按**涉及的 crate / 目录**分组，同组任务分配给同一 agent。

```
# 好：同域聚合
Agent A: T01(common/error) + T03(common/secure)  → 同一 crate 子目录
Agent B: T04(taos) + T09(common/Cargo.toml)       → 不同 crate，零重叠

# 坏：跨域分散
Agent A: T01(common/error) + T05(common/health)   → 同 crate 不同子目录，可能冲突
```

### 3.2 分组优先级

1. **文件零重叠** — 最高优先，不可妥协
2. **语义相关** — 相关任务合并减少上下文切换
3. **工作量均衡** — 各 agent 预估工时差距 ≤ 2x

---

## 4. Team Lead 职责（P1 · 对齐宪法 P-1）

Team Lead（主 Agent）**以协调为主**；substantial 实现委派 teammate（Lead 小修改阈值见宪法附录 A）：

| 职责 | 动作 |
|------|------|
| 分析依赖图 | 画出任务依赖关系，识别关键路径 |
| 划分波次 | 按依赖关系分波，每波 ≤ 5 agent |
| 分配文件所有权 | 确保零重叠，共享文件自己串行处理 |
| spawn + 分发任务 | 每个 agent 的 prompt 包含：任务描述 + 文件所有权清单 + 验收标准 |
| 波次间质量门禁 | `cargo fmt` + `clippy` + `test`（见 [agent-quality-gates.md](./agent-quality-gates.md)） |
| 合并结果 | 每波结束后合并各 agent 的改动到主分支 |
| 处理冲突 | 共享文件的修改由 Lead 统一执行 |

### 4.1 spawn_teammate prompt 模板

每个 teammate 的 prompt **必须**包含以下结构：

```
## 任务
{任务描述，1-3 句}

## 文件所有权
你只能修改以下文件/目录：
- {path1}
- {path2}
禁止修改其他任何文件。需要改共享文件时，通过 send_message 通知 team-lead。

## 验收标准
- {标准1}
- {标准2}

## 质量要求
完成后运行（见 org rulesets/agent-quality-gates.md）：
cargo fmt --check && cargo clippy … && cargo test -p {crate}
全部通过后，通过 send_message 报告完成。
```

---

## 5. 质量门禁（P0 · Teams 时）

完整命令见 [agent-quality-gates.md](./agent-quality-gates.md)。

### 5.1 波次间门禁

每波结束后，Team Lead **必须**执行：

```bash
cargo fmt --all -- --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
```

全部通过才能启动下一波。任何失败必须在当前波修复。

### 5.2 Agent 级门禁

每个 agent 完成任务后，**必须**对**自己改动的 crate** 执行收窄后的门禁（`cargo … -p {crate}`），禁止跳过验证。

---

## 6. 团队生命周期（P1）

### 6.1 创建

```
team_create → spawn_teammate × N → task_create × N → 开始工作
```

- 团队名称应语义化（如 `infra-wave1`），禁止无意义随机名
- 模型选择见 [agent-model-routing.md](./agent-model-routing.md)；不必强制全员同一 model

### 6.2 波次间上下文传递

Wave 2 的 agent **必须**在 prompt 中包含 Wave 1 的关键产出摘要：

```
## 前序波次结果
Wave 1 已完成以下改动（你的任务依赖这些结果）：
- Agent A: {改动摘要，1-2 句}，涉及文件：{file1, file2}
- Agent B: {改动摘要，1-2 句}，涉及文件：{file3, file4}

## 你的任务
{基于上述结果的新任务描述}
```

禁止让 Wave 2 agent 自行探索 Wave 1 做了什么——这浪费上下文窗口且容易遗漏。

### 6.3 销毁与清理

每波结束后，Team Lead **必须**执行清理：

```
1. 确认所有 agent 已报告完成或失败
2. send_message(type="shutdown_request") 给每个 agent
3. 等待 shutdown_approved 响应
4. process_shutdown_approved 清理配置
5. 超时 60s 未响应 → force_kill_teammate
6. 验证：read_config 确认成员列表为空
```

禁止以下行为：
- 不清理就启动下一波（tmux 残留会耗尽资源）
- 跨波复用 agent（上下文污染，不如重新 spawn）
- 团队完成后不删除（`team_delete` 释放资源）

---

## 7. 通信纪律（P0）

| 场景 | 方式 | 禁止 |
|------|------|------|
| 任务完成报告 | `task_update` 标记完成 + `send_message` 给 lead | 只标记不通知 |
| 遇到阻塞 | `send_message` 给 lead，说明阻塞原因 | 静默等待 |
| 需要改共享文件 | `send_message` 给 lead 请求 | 直接修改 |
| 全队通知 | 仅 Team Lead 可 `broadcast` | agent 之间 broadcast |
| 进度查询 | `task_list` + `task_get` | 轮询 inbox |

---

## 8. 失败处理（P1）

### 8.1 Agent 失败

```
Agent 报告失败
    ↓
Team Lead 评估：任务可重试？
    ├─ 是 → 同一 agent 重试 1 次
    ├─ 否 → 换方法或缩小范围后重新分配
    └─ 3 次失败 → 标记为 blocked，上报用户
```

### 8.2 波次失败

```
质量门禁失败
    ↓
定位失败 agent 的改动
    ├─ 可快速修复 → 修复后重跑门禁
    └─ 不可快速修复 → revert 该 agent 改动，缩小范围重来
```

---

## 9. 效率度量（P2）

| 指标 | 计算方式 | 目标 |
|------|---------|------|
| 并行加速比 | 串行总耗时 / 实际墙钟时间 | ≥ 2x |
| 波次利用率 | 实际 agent 数 / 每波上限(5) | ≥ 60% |
| 冲突率 | 合并冲突次数 / 总 agent 数 | 0% |
| 一次通过率 | 门禁一次通过的波次 / 总波次 | ≥ 80% |
| 关键路径占比 | 关键路径耗时 / 总墙钟时间 | ≤ 50% |
