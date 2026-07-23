# 自主迭代规则（Autonomous Iteration）

> 来源：autoresearch 核心原则 + Harness Engineering 铁律
> 适用：所有 AI Agent 的编码/重构/优化任务
> 执行力度：🟢 强制（与 Harness 铁律同级）
> SSOT：`xhyperium/.github` → `rulesets/autonomous-iteration.md`

## 核心循环

```
Review → Ideate → Modify → Commit → Verify → Guard → Decide → Log → Repeat
```

## 1. 约束即赋能（Constraint = Enabler）

**规则**：任何 substantial 任务开始前，必须明确定义以下四项：

| 要素          | 说明                          | 示例                                                                           |
| ------------- | ----------------------------- | ------------------------------------------------------------------------------ |
| **Scope**     | 可修改的文件范围（glob 列表） | `internal/macro_data/provider/fred/*.go`                                       |
| **Metric**    | 单一可量化的成功指标          | `go test -coverprofile=c.out ./... && go tool cover -func=c.out \| grep total` |
| **Direction** | 指标越高越好还是越低越好      | `higher` / `lower`                                                             |
| **Verify**    | 产出指标数值的 shell 命令     | `go test ./... \| grep -c '^ok'`                                               |

**禁止**：使用主观指标（"看起来更好"、"应该更快"）。Metric 必须是可机械验证的。

## 2. 策略与战术分离

**规则**：

- **Human / Lead Agent** 设定方向（Goal + Scope + Metric）
- **Executor Agent** 自主执行迭代（How）
- Lead 在迭代过程中不干预具体实现选择，除非触及 scope_out 或架构边界

## 3. 指标必须可机械验证

**规则**：Metric 必须能通过命令行输出一个可解析的数字。

**验证命令模板**（按语言）：

```bash
# Go — 测试通过率
Verify: go test -count=1 ./... 2>&1 | grep -c '^ok'

# Go — 覆盖率
Verify: go test -coverprofile=c.out ./... && go tool cover -func=c.out | grep total | awk '{print $3}' | sed 's/%//'

# Go — 构建是否成功（二元）
Verify: go build ./... 2>&1 | wc -l   # 0 = 成功

# Go — lint 问题数
Verify: golangci-lint run ./... 2>&1 | grep -c '^\s*\w*\.go:'

# 通用 — 代码行数（重构目标）
Verify: find <scope> -name '*.go' -not -name '*_test.go' | xargs wc -l | tail -1 | awk '{print $1}'
```

**噪声处理**：对于 inherently noisy 的指标（benchmark 时间、ML 准确率），使用以下策略：

| 策略           | 适用场景            | 命令示例                                          |
| -------------- | ------------------- | ------------------------------------------------- | ------- | ------------ |
| 多运行取中位数 | Benchmark、性能测试 | `for i in 1 2 3; do go test -bench=. ./... ; done | sort -n | sed -n '2p'` |
| 最小改进阈值   | 噪声较大的指标      | `Min-Delta: 2.0`（仅当改进 > 2% 时保留）          |
| 确认运行       | 结果可疑时          | 第一次改善后，第二次验证确认                      |

## 4. 验证必须快速

**规则**：迭代内的验证命令必须在 **30 秒内**完成。超过此阈值的验证应拆分为：

- **快速验证**（迭代内使用）— 单元测试、lint、编译检查
- **慢速验证**（迭代结束后使用）— 完整测试套件、E2E 测试

## 5. 迭代成本决定行为

**规则**：

- 低成本迭代（<10 秒）→ 鼓励大胆探索
- 高成本迭代（>30 秒）→ 保守策略，减少实验次数

**优化建议**：

- 使用 `-run` 限定只运行相关测试
- 使用 `go test -count=1 -short` 跳过慢测试
- 使用增量编译 / 缓存

## 6. Git 作为记忆与审计轨迹

**规则**：每次迭代必须遵循以下 Git 纪律：

### 6.1 提交前验证

```bash
# 1. 每次变更前写一句话描述（强制）
DESCRIPTION="将 fred fetcher 的超时从 30s 改为 60s"

# 2. 一句话测试：如果需要 "and" 来描述，拆分为两次迭代
# ✓ "将超时从 30s 改为 60s"
# ✗ "将超时从 30s 改为 60s 并添加重试逻辑" → 拆分为两次

# 3. 仅添加 scope_in 内的文件（禁止 git add -A）
git add <file1> <file2>

# 4. 提交（在验证之前）
git commit -m "experiment(<scope>): $DESCRIPTION"
```

### 6.2 回滚策略

```bash
# 首选：git revert（保留历史，供学习）
git revert HEAD --no-edit

# 备选：revert 冲突时使用 reset（会丢失历史）
git revert --abort && git reset --hard HEAD~1
```

**禁止**：使用 `git reset --hard` 作为首选回滚方式。

### 6.3 每次迭代必须读取 Git 历史

```bash
# Phase 1（Review）必须执行：
git log --oneline -20          # 查看实验序列
git diff HEAD~1 --stat         # 查看上次保留的变更
git log --oneline -20 | grep "Revert"  # 查看失败的尝试（避免重复）
```

## 7. 原子性变更

**规则**：每次迭代只做 **一个逻辑变更**，即使涉及多个文件。

**自检查**：

```bash
FILES_CHANGED=$(git diff --name-only | wc -l)
if [ "$FILES_CHANGED" -gt 5 ]; then
  echo "WARN: ${FILES_CHANGED} 个文件变更 — 验证是否为单一意图"
fi
```

**多文件原子变更的合法场景**：

- 同一配置项在 Dockerfile + compose + nginx 中的同步修改
- 同一接口在定义 + 实现 + 测试中的同步修改
- 同一依赖版本在 go.mod + vendor 中的同步修改

## 8. Guard（回归保护）

**规则**：如果定义了 Guard 命令，它必须在 Verify 之后运行，且必须始终通过。

| 命令类型   | 用途                   | 示例                                 |
| ---------- | ---------------------- | ------------------------------------ |
| **Verify** | "指标是否改善？"       | `go test -coverprofile=c.out ./...`  |
| **Guard**  | "是否破坏了其他功能？" | `go test ./...`、`golangci-lint run` |

**Guard 失败处理**：

1. 回滚当前变更
2. 分析 Guard 输出，理解什么被破坏了
3. 重试优化（最多 2 次），**绝不修改 Guard/测试文件**
4. 2 次重试后仍失败 → 丢弃该思路，记录并转向新方向

## 9. 决策逻辑（无歧义）

```
IF metric_improved AND (no guard OR guard_passed):
    STATUS = "keep"
    # 保留提交，Git 历史记录此成功

ELIF metric_improved AND guard_failed:
    safe_revert()
    # 重试优化（最多 2 次），不修改 Guard/测试
    IF 重试后 guard_passed:
        STATUS = "keep (reworked)"
    ELSE:
        STATUS = "discard"

ELIF metric_same_or_worse:
    STATUS = "discard"
    safe_revert()

ELIF crashed:
    # 尝试修复（最多 3 次）
    IF fixable:
        修复 → 重新提交 → 重新验证
    ELSE:
        STATUS = "crash"
        safe_revert()
```

**简化优先**：如果指标仅微幅改善（<0.1%）但增加了显著复杂度，视为 "discard"。如果指标不变但代码更简洁，视为 "keep"。

## 10. 结果日志

**规则**：每次迭代必须记录到结果日志（TSV 格式）：

```
iteration  commit   metric   status        description
42         a1b2c3d  82.5%    keep          添加边界值测试
43         -        82.3%    discard       重构为泛型（无改善）
44         -        0        crash         循环引用导致栈溢出
45         -        -        no-op         修改了只读配置（无 diff）
```

**日志位置**：`.swarm/runs/<task-id>/iteration-log.tsv`

## 11. 卡住时的恢复策略

**规则**：当连续 **5 次 discard** 时，必须执行以下恢复步骤：

1. 重新读取所有 scope_in 文件（从头开始理解）
2. 重新阅读原始 Goal 和 Direction
3. 审查完整的结果日志，寻找模式
4. 尝试组合 2-3 次之前成功的变更
5. 尝试与之前失败方向相反的方法
6. 尝试激进的架构变更

## 12. 与 Harness 铁律的映射

| 自主迭代规则                      | 对应 Harness 铁律              | 关系                           |
| --------------------------------- | ------------------------------ | ------------------------------ |
| 约束即赋能（Scope/Metric/Verify） | 铁律 2（scope freeze）         | 强化 + 量化                    |
| 指标必须可机械验证                | 铁律 3（无 verify 不声称完成） | 细化（机械验证）               |
| Git 作为记忆                      | 铁律 4（无 evidence 不算交付） | 扩展（Git history = evidence） |
| 原子性变更                        | 铁律 5（scope_out 不动）       | 互补（变更粒度控制）           |
| Guard 回归保护                    | 铁律 3/4                       | 新增（防止回归）               |
| 结果日志                          | 铁律 4（evidence 路径）        | 细化（iteration-log.tsv）      |
| 卡住恢复策略                      | 铁律 6（新需求记 follow-up）   | 新增（stuck 处理）             |

## 13. 适用范围

| 场景       | 是否启用自主迭代 | 说明                          |
| ---------- | ---------------- | ----------------------------- |
| 新功能开发 | ✅ 是            | 通过迭代优化实现质量          |
| Bug 修复   | ✅ 是            | 验证修复是否有效 + 未引入回归 |
| 重构       | ✅ 是            | 验证行为等价 + 指标改善       |
| 性能优化   | ✅ 是            | 核心场景                      |
| 测试补全   | ✅ 是            | 覆盖率作为 metric             |
| 文档更新   | ⚪ 可选          | 通常不需要迭代                |
| 配置调整   | ⚪ 可选          | 单步即可                      |
| 紧急热修复 | ❌ 否            | 跳过迭代，直接修复 + 验证     |

## 14. 执行检查清单

开始自主迭代前，确认以下事项：

- [ ] Scope 已定义（文件 glob 列表）
- [ ] Metric 已定义（可机械验证的数字）
- [ ] Direction 已明确（higher / lower）
- [ ] Verify 命令已测试（在当前代码库上 dry-run 通过）
- [ ] Guard 命令已定义（可选但推荐）
- [ ] Git 工作区干净（无未提交变更）
- [ ] 在 feature branch 上（非 main）
- [ ] 迭代日志路径已确定（`.swarm/runs/<task-id>/iteration-log.tsv`）
