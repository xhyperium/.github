# Agent 安全护栏规则

> 来源：Superpowers (58k⭐) + Planning with Files (14k⭐) + Boris Tane (Cloudflare) + review-loop + Amp
> 适用范围：所有 Agent 会话（跨语言、跨项目）

---

## 1. 证据优先（P0）

> "Evidence before claims, always." — Superpowers

- 完成声明**必须**附带当前上下文的验证输出
- 禁止以下借口：
  - "I'm confident" → 信心 ≠ 证据
  - "It should pass" → 应该 ≠ 实际
  - "I just ran it" → 展示输出
- 验证五步：识别命令 → 执行 → 读输出 → 确认匹配 → 声明完成

## 2. 先读后改（P0）

> 2-Action Rule — Planning with Files

- **编辑文件前必须先读取目标文件**
- 禁止连续盲改：`if !read(file): deny(edit(file))`
- 每 2 次浏览/搜索操作后，将关键发现保存到文件

## 3. 三击升级（P0）

> 3-Strike Error Protocol — Planning with Files

```
第 1 次失败：诊断 + 修复
第 2 次失败：换方法
第 3 次失败：重新思考假设
3 次之后：上报用户
```

- 永不重复失败：`if action_failed: next_action != same_action`
- 错误必须记录，不可静默丢弃

## 4. 阶段守卫（P0）

> "don't implement yet" — Boris Tane (Cloudflare 工程主管)

- 每个阶段**显式禁止**下一阶段行为
- 研究阶段：禁止写代码
- 规划阶段：禁止实现
- 实现阶段：禁止跳过验证
- 不加守卫，Agent 会过早编码

## 5. 反规避机制（P1）

> Anti-Rationalization — Superpowers v3.2+

Agent 会持续寻找跳过流程的理由。常见规避模式及反驳：

| #   | 规避借口                   | 反驳                   |
| --- | -------------------------- | ---------------------- |
| 1   | "这个任务太简单不需要规划" | 简单任务也有隐含依赖   |
| 2   | "我已经知道怎么做了"       | 知道 ≠ 验证过          |
| 3   | "规划会浪费时间"           | 返工浪费更多时间       |
| 4   | "只是一个小改动"           | 小改动也可能破坏接口   |
| 5   | "测试通过了所以没问题"     | 测试覆盖 ≠ 100%        |
| 6   | "之前类似的работа做过了"   | 上下文不同结果可能不同 |
| 7   | "用户说了快速修复"         | 快速 ≠ 跳过验证        |
| 8   | "文档以后补"               | 以后 = 永远不会        |

## 6. Fail-open 设计（P1）

> 安全设计原则 — review-loop

- 所有自动化 Hook **出错时放行**而非阻塞
- Hook 脚本必须 `exit 0`，永不阻塞用户
- 审查失败 → 记录日志 + 继续 → 事后处理
- 禁止把用户困在自动化流程中

## 7. 四条行为护栏（P1）

> Amp (Sourcegraph) GPT-5 Prompt 四条护栏

1. **Simple-first** — 选择最简单的正确方案
2. **Reuse-first** — 优先复用现有代码/模式
3. **No surprise edits** — 不修改用户未要求的文件
4. **No new deps** — 不引入新依赖除非明确要求
