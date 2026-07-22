<div align="center">

<img src="https://avatars.githubusercontent.com/u/293512006?s=200&v=4" width="120" height="120" alt="xhyperium" />

# xhyperium

**FoundationX — 量化交易基础设施（Rust-first）**

构建高性能、高可靠的金融数据与交易系统。  
以 **Rust** 为默认实现语言；**人类可读文本强制中文**；Goal 驱动、Spec 可追溯、规范与 CI 组织级统一。

<br />

<img src="https://img.shields.io/badge/Rust-stable-DEA584?logo=rust&logoColor=white&style=flat-square" alt="Rust" />
<img src="https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white&style=flat-square" alt="Python" />
<img src="https://img.shields.io/badge/TypeScript-5-3178C6?logo=typescript&logoColor=white&style=flat-square" alt="TypeScript" />
<img src="https://img.shields.io/badge/License-MIT-yellow?style=flat-square" alt="MIT" />

<br /><br />

<table>
<tr>
<td align="center"><img src="https://img.shields.io/badge/stack-Rust-DEA584?style=for-the-badge&logo=rust&logoColor=white" /><br /><sub>默认实现语言</sub></td>
<td align="center"><img src="https://img.shields.io/badge/CI-reusable-blue?style=for-the-badge" /><br /><sub>组织级 fmt/clippy/test</sub></td>
<td align="center"><img src="https://img.shields.io/badge/rules-SSOT-success?style=for-the-badge" /><br /><sub>宪法 + Rust 规范</sub></td>
<td align="center"><img src="https://img.shields.io/badge/domains-data%2Fmacro-purple?style=for-the-badge" /><br /><sub>行情 · 宏观等领域仓</sub></td>
</tr>
</table>

</div>

<br />

## 领域架构（目标分层）

```text
                           ┌─────────────────────────────────┐
        入口 Entry         │   组合根 · 前端 / 运维面          │
                           └───────────────┬─────────────────┘
                                           │
   ┌───────────────────────────────────────┴───────────────────────────┐
   │                         领域共享 / 契约层                            │
   │              十进制 · 领域模型 · 市场/宏观/交易 DTO                    │
   └───────────────────────────────────────┬───────────────────────────┘
                                           │
   ┌───────────────────────────────────────┴───────────────────────────┐
   │                    基础设施 Foundation（Rust）                       │
   │         运行时 · 配置 · 可观测 · 弹性 · 存储 adapter · 契约          │
   └───────────────────────────────────────┬───────────────────────────┘
                                           │
   ┌───────────────┬───────────────┬───────┴───────┬───────────────┬────┐
   │   数据域       │   分析域       │    决策域      │    执行域      │横切 │
   │   Data        │  Analytics    │  Decision    │  Execution   │XCUT│
   │               │               │              │              │    │
   │ 交易所 · 宏观  │ 因子 · 体制   │  信号 · 回测  │  风控 · 订单  │告警 │
   │ 链上 / 另类    │ 特征存储       │  策略 · 编排  │  仓位 · 结算  │    │
   └───────────────┴───────────────┴──────────────┴──────────────┴────┘
```

<br />

<div align="center">

## 🧠 量化大脑 · 三引擎联合决策

</div>

> 分析域的核心是 **M × S 联合决策矩阵**：宏观体制（M）与市场体制（S）交叉，输出动作、风险层级、仓位上限与交易许可。

| 引擎 | 输入 | 输出状态 |
| --- | --- | --- |
| **macro_regime** | 宏观流动 / 通胀 / 信用 | M1–M7：流动牛市 · 再通复苏 · 软着繁荣 · 鹰派通胀 · 衰退降息 · 信用去杠 · 滞胀冲击 |
| **market_regime** | 行情结构 / 波动 / 挤压 | S1–S7：多头趋势 · 挤空 · 空头 · 踩踏 · 震荡 · 低波 · 压缩 |
| **regime_engine** | M × S 联合 | 动作 A–E · risk_tier · position_caps · trade_permission |

<br />

## 🦀 当前组织仓库（Rust-first）

| 仓库 | 说明 |
| --- | --- |
| [infra.rs](https://github.com/xhyperium/infra.rs) | 基础架构 / 工具链 |
| [standard_template.rs](https://github.com/xhyperium/standard_template.rs) | Rust stdio 程序模板（infra.rs 工具链管理） |
| [market_data.rs](https://github.com/xhyperium/market_data.rs) | 行情数据域 |
| [macro_data.rs](https://github.com/xhyperium/macro_data.rs) | 宏观数据域 |
| [xhyper.rs](https://github.com/xhyperium/xhyper.rs) | xhyper 主仓 |
| [knowledge](https://github.com/xhyperium/knowledge) | 知识库（可供 xhyper.rs 以 submodule 引用） |
| [ssot](https://github.com/xhyperium/ssot) | 领域规格 SSOT |
| [.github](https://github.com/xhyperium/.github) | 组织 SSOT：可复用 CI、Rust 规范、Agent 宪法 |

<br />

## ⚙️ 组织工程约定

| 项 | 入口 |
| --- | --- |
| **语言政策** | [强制中文 language.md](https://github.com/xhyperium/.github/blob/main/rulesets/language.md) |
| **Rust 编码规范** | [rulesets/rust/RULES.md](https://github.com/xhyperium/.github/blob/main/rulesets/rust/RULES.md) |
| **可复用 CI** | `ci-rust-standard.yml` / `ci-rust-foundation.yml` |
| **Agent 宪法** | [agent-teams-constitution.md](https://github.com/xhyperium/.github/blob/main/rulesets/agent-teams-constitution.md) |
| **规则一键分发** | [`scripts/setup-global-rules.sh`](https://github.com/xhyperium/.github/blob/main/scripts/setup-global-rules.sh) |

```yaml
# 模块仓最小接入
jobs:
  ci:
    uses: xhyperium/.github/.github/workflows/ci-rust-standard.yml@main
```

<br />

<div align="center">

## 🔬 治理方法论

每一行代码都可追溯到一个可验证的业务目标。

| 管线 | 说明 |
| --- | --- |
| **Goal 驱动交付** | Goal → Spec → Design → Plan → Code → Ship |
| **Spec → Code** | 结构化规格 · 需求追溯 · 证据门禁 |
| **多源审查** | 独立审查 + 组织 rules SSOT |
| **宪法治理** | C/L/P 铁律 · 分支纪律 · 证据优先 |

组织配置与规范：[xhyperium/.github](https://github.com/xhyperium/.github)

</div>

<br />

<div align="center">

<img src="https://github-readme-stats.vercel.app/api?username=xhyperium&show_icons=true&theme=transparent&hide_border=true&card_width=320" alt="stats" />
<img src="https://github-readme-stats.vercel.app/api/top-langs/?username=xhyperium&layout=compact&theme=transparent&hide_border=true&card_width=320" alt="top langs" />

<br /><br />

**构建稳定可靠的量化基础设施 ⚡**

</div>
