# Agent Codex 效率最大化规则

> 适用范围：所有使用 Codex CLI 的 Agent 会话，所有项目
> 级别：🔥 P0（强制）
> 互补规则：[agent-model-routing.md](./agent-model-routing.md)（何时用 Codex）、[agent-teams.md](./agent-teams.md)（团队并行）
> 定位：`agent-model-routing.md` 定义**何时**用 Codex，本文件定义**如何**高效用 Codex

---

## 1. 职责分工（P0 铁律）

主 Agent 和 Codex CLI 的边界不可模糊：

| 阶段 | 执行者 | 产出 |
|------|--------|------|
| 规划 | 主 Agent | 任务列表 + 依赖图 + 验收标准 |
| 编码 | **Codex CLI** | 代码变更 |
| 审查 | **Codex CLI** | 审查报告（按模块拆分） |
| 验证 | 主 Agent | 编译 + 测试 + 结果汇总 |

- 主 Agent **禁止**直接编写生产代码（降级除外，见 [agent-model-routing.md](./agent-model-routing.md) §3）
- Codex **禁止**变更需求、架构或验收标准

---

## 2. Prompt 工程（P0）

### 2.1 精准 Prompt 结构

每个 Codex prompt **必须**包含以下要素，**禁止**堆砌无关上下文：

```
[任务] 一句话描述要做什么
[范围] 只涉及哪些文件/目录
[约束] 编码规范、禁止事项
[验收] 完成后的可验证标准
```

### 2.2 Prompt 纪律

| 规则 | 约束 | 理由 |
|------|------|------|
| 单任务 prompt ≤ 500 字 | 超过则拆分为多个任务 | 减少 token 消耗，提高聚焦度 |
| 只包含相关文件上下文 | 禁止 `context_files` 传入整个 crate | 无关文件稀释注意力 |
| 明确输出格式 | 告诉 Codex 期望的输出结构 | 减少返工 |
| 中文注释约束写入 prompt | `代码注释使用中文` | Codex 不读 CLAUDE.md |
| 禁止在 prompt 中包含密钥 | Token/Secret 用环境变量 | 安全基线 |

### 2.3 上下文文件选择

```
# 好：只传入直接相关的文件
context_files: ["crates/redis/src/port.rs", "crates/common/src/ports/kv.rs"]

# 坏：传入整个目录或不相关文件
context_files: ["crates/redis/src/", "crates/common/src/"]
```

---

## 3. 三阶段流水线（P0）

每个工作单元（crate / 模块）**必须**经过三阶段：

```
exec（编码）→ review（审查）→ verify（验证）
```

### 3.1 阶段定义

| 阶段 | 执行者 | 输入 | 输出 | 失败处理 |
|------|--------|------|------|---------|
| exec | Codex CLI | prompt + context_files | 代码变更 | 重试 1 次 → 阻断下游 |
| review | Codex CLI | exec 产出的变更 | 审查报告 | 重试 1 次 → 标记风险 |
| verify | 主 Agent 或 CI | review 通过的代码 | 测试结果 | 修复 → 重跑 |

### 3.2 依赖关系

```
{unit}-exec
    ├──► {unit}-review  ─┐
    └──► {unit}-verify  ─┤  review 和 verify 可并行
                         └──► 下一阶段
```

review 和 verify 都只依赖 exec，**可以并行执行**，充分利用并发槽位。

### 3.3 禁止跳过阶段

- 禁止 exec 后直接合并（跳过 review + verify）
- 禁止只 review 不 verify（审查不等于测试）
- 紧急修复可合并 review + verify 为一步，但**必须**标注 `[FAST-TRACK]`

---

## 4. 并行调度（P0）

### 4.1 调度规则

| 规则 | 约束 | 理由 |
|------|------|------|
| 最大并发 10 | 超过 10 个 Codex 进程资源竞争严重 | API 限流 + 本地资源 |
| DAG 拓扑排序 | 有依赖的串行，无依赖的并行 | 正确性保证 |
| 长任务优先启动 | 同层内预估耗时长的先执行 | 减少墙钟时间 |
| 始终填满槽位 | 任务数 ≥ 10 时不应有空闲槽位 | 最大化吞吐 |
| 单任务超时 600s | 超时自动重试 1 次 | 防止单任务阻塞全局 |

### 4.2 任务 JSON Schema

批量任务**必须**通过结构化 JSON 描述，禁止在调度脚本中硬编码任务：

```json
{
  "id": "string — 唯一任务 ID（必填）",
  "type": "exec | review | verify（必填）",
  "crate": "string — 关联模块名（可选）",
  "prompt": "string — exec/review 必填",
  "cmd": "string — verify 必填（shell 命令）",
  "priority": "int — 1=最高，默认 99（可选）",
  "depends_on": ["string[] — 依赖的任务 ID（可选）"],
  "timeout": "int — 超时秒数，默认 600（可选）",
  "retries": "int — 重试次数，默认 1（可选）"
}
```

标准三阶段示例：

```json
[
  {"id": "{mod}-exec",   "type": "exec",   "crate": "{mod}", "priority": 1,
   "prompt": "..."},
  {"id": "{mod}-review", "type": "review", "crate": "{mod}", "priority": 2,
   "prompt": "...", "depends_on": ["{mod}-exec"]},
  {"id": "{mod}-verify", "type": "verify", "crate": "{mod}", "priority": 3,
   "cmd": "cargo test -p {mod}", "depends_on": ["{mod}-exec"]}
]
```

### 4.4 Review 必须按模块拆分

```
# 正确：每个模块独立 review，可并行
redis-review (depends_on: redis-exec)
kafka-review (depends_on: kafka-exec)
postgres-review (depends_on: postgres-exec)

# 错误：单个 review 审查所有变更
review-all (depends_on: redis-exec, kafka-exec, postgres-exec)
```

### 4.5 互斥资源

以下资源需要排他锁，同一时刻只允许一个 Codex 进程操作：

- `Cargo.toml`（workspace 级）/ `Cargo.lock`
- `cargo test`（全 workspace）/ `cargo build`（全 workspace）
- 数据库 migration 文件

---

## 5. 证据强制（P0）

### 5.1 输出必须附带证据

Codex 的每份输出**必须**包含可验证的证据，禁止纯文字描述。

| 证据字段 | 必填 | 说明 |
|---------|------|------|
| 路径 | ✅ | 文件路径（含行号） |
| 符号 | ✅ | 函数/类型/模块名 |
| 命令 | ✅ | 执行的验证命令（未执行标注 `N/A`） |
| 结果 | ✅ | 命令输出摘要或可验证结论 |

### 5.2 最低证据要求

- 每份交接至少 **1 条**证据
- 每条发现/结论绑定**至少 1 条**证据
- 证据必须可复现（路径可定位，命令可运行）

### 5.3 交接模板

多角色协作时，每种角色的输出**必须**遵循对应模板：

**Explorer（探索者）**：
```
- Scope: {分析范围}
- Entry points: {入口文件/函数}
- Invariants: {不变量/约束}
- Test gaps: {测试缺口}
- Suggested plan: {建议方案}
- Evidence:
  - 路径: {file:line}
    符号: {function/type}
    命令: {验证命令}
    结果: {输出摘要}
```

**Reviewer（审查者）**：
```
- Findings: [severity][topic] {location} -> {impact}
- Fix recipe: {修复步骤}
- Verification: {验证方法}
- Evidence:
  - 路径: {file:line}
    符号: {function/type}
    命令: {验证命令}
    结果: {输出摘要}
```

**Worker（执行者）**：
```
- Diff summary: {变更摘要}
- Tests: {测试结果}
- Risk notes: {风险说明}
- Evidence:
  - 路径: {file:line}
    符号: {function/type}
    命令: {验证命令}
    结果: {输出摘要}
```

Worker 命令白名单：仅允许 `cargo fmt` / `cargo clippy` / `cargo test`。其他命令需主 Agent 明确授权。

### 5.4 违规处理

缺失证据字段的输出 → 退回重做，不计入完成。

---

## 6. 角色化调用（P1）

### 6.1 agent_role 选择

调用 `ask_codex` 时**必须**指定 `agent_role`，匹配任务性质：

| 任务性质 | agent_role | 说明 |
|---------|-----------|------|
| 架构分析 | `architect` | 模块边界、依赖关系、设计评审 |
| 实现规划 | `planner` | 任务拆分、执行顺序、风险评估 |
| 代码审查 | `code-reviewer` | 质量、模式、一致性检查 |
| 安全审查 | `security-reviewer` | OWASP、依赖漏洞、unsafe 审计 |
| 批判性分析 | `critic` | 方案挑战、反驳、替代方案 |
| 测试驱动 | `tdd-guide` | 测试策略、覆盖率、边界条件 |
| 通用分析 | `analyst` | 数据分析、趋势、度量 |

### 6.2 禁止无角色调用

不指定 `agent_role` 的调用缺乏专业视角，输出质量显著下降。

---

## 7. 降级与恢复（P1）

### 7.1 降级链

```
Codex CLI 执行
    ↓ 失败/超时
自动重试 1 次
    ↓ 仍然失败
回退到主 Agent 执行（标注 [FALLBACK]）
    ↓ 记录降级事件
```

### 7.2 降级记录

每次降级**必须**记录：

```
[FALLBACK] 任务: {task_id}, 原因: {error}, 时间: {timestamp}, 最终执行方: Claude Code
```

### 7.3 断点续跑

批量任务中断后，使用 `--resume` 跳过已成功的任务，不重复执行。

---

## 8. 安全约束（P0）

| 规则 | 约束 |
|------|------|
| 沙箱模式 | `--full-auto`（workspace-write），禁止 `danger-full-access` |
| 密钥隔离 | prompt 中禁止包含 Token/Secret/Password |
| 日志截断 | stdout ≤ 5000 字符，stderr ≤ 2000 字符 |
| 命令白名单 | Worker 角色只能执行 `cargo fmt` / `cargo clippy` / `cargo test` |
| 越权禁止 | Codex 不得修改 CI 配置、部署脚本、密钥文件 |

---

## 9. 双审协议（P0）

当变更涉及 ≥2 个文件或风险 ≥ P1 时，**必须**执行双审（Claude + Codex 独立审查）。

### 9.1 双审流程

```
exec 完成
    ├──► Claude 审查（review-claude.md）
    └──► Codex 审查（review-codex.md）
              ↓ 两份齐全
         review-summary.md（综合结论）
              ↓ 若冲突
         decision.md（仲裁记录）
```

- 两份 Review **必须独立生成**，禁止互相抄结论
- 单审（仅 Codex review）仅允许用于：单文件变更 + 风险 P2 + 无架构影响

### 9.2 单份 Review 结构要求

每份 review 必须包含：

| 字段 | 必填 | 说明 |
|------|------|------|
| Verdict | ✅ | 三选一：`Approve` / `Request changes` / `Block` |
| Blocking Issues | 条件 | Request changes / Block 时 ≥ 1 条 |
| Evidence | ✅ | ≥ 1 条（file:line、diff、命令输出摘要） |
| Risk | ✅ | P0 / P1 / P2 + 缓解建议 |

### 9.3 review-summary 要求

`review-summary.md` 必须包含：

- 最终结论：`Pass` / `Changes Required` / `Blocked`
- 阻塞项 owner（至少一个角色名或 @handle）
- 若两份 review 结论冲突：**必须**引用 `decision.md`

### 9.4 冲突检测与仲裁

**冲突定义**：一方 Approve，另一方 Request changes 或 Block。

冲突触发时**必须**：

1. 生成 `decision.md`，包含：
   - 背景与问题
   - 备选方案（≥ 2）
   - 双方证据引用
   - 最终决策与理由
   - 回滚方案
2. 更新 `review-summary.md` 引用 `decision.md`
3. 若风险 ≥ P0：**必须**人工确认（Human-in-the-loop）

### 9.5 仲裁触发条件（完整清单）

满足任一即触发仲裁：

- 双审结论冲突（Approve vs Request changes/Block）
- Spec 变更导致验收标准变化
- 风险等级 ≥ P1（安全、资金、不可逆）
- 依赖升级/协议变化缺乏验证证据

---

## 10. 效率度量（P2）

| 指标 | 计算方式 | 目标 |
|------|---------|------|
| 槽位利用率 | 活跃 Codex 进程数 / 10 | ≥ 80% |
| 单任务 token 消耗 | 平均 token / 任务 | ≤ 300K |
| 一次通过率 | exec 无需重试的任务 / 总任务 | ≥ 85% |
| 三阶段完整率 | 经过 exec+review+verify 的单元 / 总单元 | 100% |
| 降级率 | 降级到 Claude Code 的任务 / 总任务 | ≤ 5% |
