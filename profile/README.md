<div align="center">

<img src="https://avatars.githubusercontent.com/u/293512006?s=200&v=4" width="120" height="120" alt="xhyperium" />

# xhyperium

**FoundationX — 量化交易基础设施**

构建高性能、高可靠的金融数据与交易系统。
从基座原语到执行域，一套 Goal 驱动、Spec 可追溯的模块化量化生态。

<br />

<img src="https://img.shields.io/badge/Go-1.26.5-00ADD8?logo=go&logoColor=white&style=flat-square" alt="Go" />
<img src="https://img.shields.io/badge/Rust-stable-DEA584?logo=rust&logoColor=white&style=flat-square" alt="Rust" />
<img src="https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white&style=flat-square" alt="Python" />
<img src="https://img.shields.io/badge/TypeScript-5-3178C6?logo=typescript&logoColor=white&style=flat-square" alt="TypeScript" />
<img src="https://img.shields.io/badge/License-MIT-yellow?style=flat-square" alt="MIT" />

<br /><br />

<table>
<tr>
<td align="center"><img src="https://img.shields.io/badge/modules-60+-blue?style=for-the-badge" /><br /><sub>全域模块</sub></td>
<td align="center"><img src="https://img.shields.io/badge/factory_grade-25-success?style=for-the-badge" /><br /><sub>基座 + L2.5</sub></td>
<td align="center"><img src="https://img.shields.io/badge/exchanges-12-orange?style=for-the-badge" /><br /><sub>行情连接器</sub></td>
<td align="center"><img src="https://img.shields.io/badge/macro_sources-10-purple?style=for-the-badge" /><br /><sub>宏观央行数据</sub></td>
</tr>
</table>

</div>

<br />

## 分层架构

```text
                           ┌─────────────────────────────────┐
        入口 Entry         │   composer  ·  frontend          │
                           └───────────────┬─────────────────┘
                                           │
   ┌───────────────────────────────────────┴───────────────────────────┐
   │                         L2.5 领域共享层                              │
   │   decimalx · domainx · domain_market · domain_macro · domain_exchange │
   └───────────────────────────────────────┬───────────────────────────┘
                                           │
   ┌───────────────────────────────────────┴───────────────────────────┐
   │                    基座 Foundation（20 模块 · 全 factory-grade）     │
   │                                                                    │
   │  标准  xlib_standard · xlib_harness · xlib_evidence · xlibgate      │
   │  L0    kernel                                                       │
   │  L1    configx · observex · resiliencx · schedulex · bootstrap      │
   │        testkitx                                                     │
   │  存储  redisx · kafkax · natsx · postgresx · taosx · ossx           │
   │        clickhousex                                                  │
   │  契约  contracts · transportx                                       │
   └───────────────────────────────────────┬───────────────────────────┘
                                           │
   ┌───────────────┬───────────────┬───────┴───────┬───────────────┬────┐
   │   数据域       │   分析域       │    决策域      │    执行域      │横切 │
   │   Data        │  Analytics    │  Decision    │  Execution   │XCUT│
   │               │               │              │              │    │
   │ 12 交易所连接  │ 因子计算/评估  │  信号生成     │  风控         │告警 │
   │ 10 宏观央行源  │ 三引擎识别     │  回测/优化    │  订单/仓位    │    │
   │ 链上/另类数据  │ 特征存储       │  策略/编排    │  结算对账     │    │
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

## 🏗️ 基座 · Foundation（20 模块 · 全 factory-grade）

| 模块 | 职责 | 版本 |
| --- | --- | --- |
| [kernel](https://github.com/xhyperium/kernel) | L0 标准库原语（error/time/context/lifecycle/health/sync） | `v1.1.0` |
| [configx](https://github.com/xhyperium/configx) | 显式配置加载、多源合并、SecretString 脱敏、热更新回滚 | `v1.1.0` |
| [observex](https://github.com/xhyperium/observex) | vendor-neutral 日志/指标/追踪/健康/脱敏契约 | `v0.3.4` |
| [resiliencx](https://github.com/xhyperium/resiliencx) | 运行时弹性（timeout/retry/circuit/bulkhead/rate/fallback） | `v1.0.2` |
| [schedulex](https://github.com/xhyperium/schedulex) | 任务调度（cron/interval/delay、Overlap/Misfire 策略） | `v1.0.0` |
| [bootstrap](https://github.com/xhyperium/bootstrap) | L1 进程组装层（7 存储 adapter 可选构造） | `v0.2.0` |
| [testkitx](https://github.com/xhyperium/testkitx) | 测试专用 evidence/golden/fixture/boundary | `v1.0.0` |
| [redisx](https://github.com/xhyperium/redisx) | Redis L2 adapter · *live* | `v1.1.1` |
| [kafkax](https://github.com/xhyperium/kafkax) | Kafka L2 adapter · *live* | `v1.1.0` |
| [natsx](https://github.com/xhyperium/natsx) | NATS L2 adapter（Core + JetStream）· *live* | `v1.0.4` |
| [postgresx](https://github.com/xhyperium/postgresx) | PostgreSQL L2 adapter · *live* | `v1.1.2` |
| [taosx](https://github.com/xhyperium/taosx) | TDengine L2 adapter · *live* | `v1.0.2` |
| [ossx](https://github.com/xhyperium/ossx) | Aliyun OSS 对象存储 L2 adapter · *live* | `v1.2.0` |
| [clickhousex](https://github.com/xhyperium/clickhousex) | ClickHouse OLAP L2 adapter · *live* | `v1.0.9` |
| [contracts](https://github.com/xhyperium/contracts) | 跨域稳定端口、事件协议与 DTO 契约 | `v0.4.7` |
| [transportx](https://github.com/xhyperium/transportx) | 应用通信底座（Envelope/RPC/EventBus/Outbox） | `v1.1.1-spec` |
| [xlib_standard](https://github.com/xhyperium/xlib_standard) | 标准事实源 · Go Reference Template | `v1.0.1` |
| [xlib_harness](https://github.com/xhyperium/xlib_harness) | 模块生成器与门禁执行器 | `v0.1.6` |
| [xlib_evidence](https://github.com/xhyperium/xlib_evidence) | 证据收集与发布运行时 | `v0.2.4` |
| [xlibgate](https://github.com/xhyperium/xlibgate) | import / go.mod / baseline / release 机器门禁 | `v1.0.0` |

<br />

## 🔗 L2.5 领域共享层（5 模块 · 全 v1.0+）

| 模块 | 职责 | 版本 |
| --- | --- | --- |
| [decimalx](https://github.com/xhyperium/decimalx) | 高精度十进制（Decimal/Price/Qty/Ratio/Money） | `v1.0.0` |
| [domainx](https://github.com/xhyperium/domainx) | 领域共享值对象（Order/Position/Trade/Portfolio） | `v1.0.1` |
| [domain_market](https://github.com/xhyperium/domain_market) | 市场数据域模型（Tick/Quote/Bar/OrderBook） | `v1.1.0` |
| [domain_macro](https://github.com/xhyperium/domain_macro) | 宏观经济模型（MacroPoint/MacroState、no-lookahead） | `v1.0.1` |
| [domain_exchange](https://github.com/xhyperium/domain_exchange) | 交易域模型（VenueAdapter 13 方法 SPI） | `v1.0.0` |

<br />

## 📡 数据域 · Data

<details open>
<summary><b>行情连接（12 交易所 + 聚合层）</b></summary>

| 模块 | 说明 |
| --- | --- |
| [market_data](https://github.com/ZoneCNH/market_data) | 下游分发端口：校验 / 幂等 / 排序 / 分发 |
| [binance](https://github.com/ZoneCNH/binance) | Binance · Spot / USDⓈ-M / COIN-M / Options · **production** |
| [okx](https://github.com/ZoneCNH/okx) · [bybit](https://github.com/ZoneCNH/bybit) · [bitget](https://github.com/ZoneCNH/bitget) | OKX · Bybit · Bitget |
| [kucoin](https://github.com/ZoneCNH/kucoin) · [gate](https://github.com/ZoneCNH/gate) · [mexc](https://github.com/ZoneCNH/mexc) | KuCoin · Gate.io · MEXC |
| [htx](https://github.com/ZoneCNH/htx) · [coinbase](https://github.com/ZoneCNH/coinbase) · [upbit](https://github.com/ZoneCNH/upbit) | HTX · Coinbase · Upbit |
| [hyperliquid](https://github.com/ZoneCNH/hyperliquid) · [lighter](https://github.com/ZoneCNH/lighter) | Hyperliquid · Lighter |
| [coinglass](https://github.com/ZoneCNH/coinglass) · [orderbook](https://github.com/ZoneCNH/orderbook) | 加密聚合数据 · 订单簿引擎 |

</details>

<details>
<summary><b>宏观与央行数据（10 源 + 聚合层）</b></summary>

| 模块 | 说明 |
| --- | --- |
| [macro_data](https://github.com/ZoneCNH/macro_data) | 宏观数据聚合调度（Receiver + DualWriteSink） |
| [fred](https://github.com/ZoneCNH/fred) · [treasury](https://github.com/ZoneCNH/treasury) · [yield_curve](https://github.com/ZoneCNH/yield_curve) | 美联储 FRED · 美国国债 · 收益率曲线 |
| [bea](https://github.com/ZoneCNH/bea) · [ecb](https://github.com/ZoneCNH/ecb) | 美国经济分析局 · 欧洲央行 |
| [uk_cb](https://github.com/ZoneCNH/uk_cb) · [japan_cb](https://github.com/ZoneCNH/japan_cb) | 英国央行 · 日本央行 |
| [eastmoney](https://github.com/ZoneCNH/eastmoney) · [jin10](https://github.com/ZoneCNH/jin10) · [yahoo](https://github.com/ZoneCNH/yahoo) | 东方财富 · 金十数据 · Yahoo Finance |

</details>

<details>
<summary><b>另类数据</b></summary>

| 模块 | 说明 |
| --- | --- |
| [alternative_data](https://github.com/ZoneCNH/alternative_data) | 链上数据 · 社交情绪 · 新闻 NLP |

</details>

<br />

## 🧮 分析域 · Analytics

| 模块 | 说明 |
| --- | --- |
| [factor_engine](https://github.com/ZoneCNH/factor_engine) | 因子计算引擎 |
| [feature_store](https://github.com/ZoneCNH/feature_store) | 特征存储与版本管理 |
| [factor_eval](https://github.com/ZoneCNH/factor_eval) | 因子评估 |
| [market_regime](https://github.com/ZoneCNH/market_regime) | 市场体制识别（S1–S7） |
| [macro_regime](https://github.com/ZoneCNH/macro_regime) | 宏观体制识别（M1–M7） |
| [regime_engine](https://github.com/ZoneCNH/regime_engine) | M × S 联合决策引擎 |
| [ms_brain](https://github.com/ZoneCNH/ms_brain) | M ×S 系统架构分析体系 |
| [flowx](https://github.com/ZoneCNH/flowx) | 数据流管线（流式 ETL · 窗口聚合 · 背压） |

<br />

## 🎯 决策域 · Decision

| 模块 | 说明 |
| --- | --- |
| [signal_factory](https://github.com/ZoneCNH/signal_factory) | 信号生成与组合 |
| [backtestx](https://github.com/ZoneCNH/backtestx) | 回测引擎（事件驱动 · Walk-Forward · 蒙特卡洛） |
| [optimizer](https://github.com/ZoneCNH/optimizer) | 参数优化 |
| [strategyx](https://github.com/ZoneCNH/strategyx) | 策略工厂（注册 · 参数 · 信号组合） |
| [maestro](https://github.com/ZoneCNH/maestro) | 工作流编排（DAG · 状态机 · 错误恢复） |

<br />

## ⚡ 执行域 · Execution

| 模块 | 说明 |
| --- | --- |
| [riskx](https://github.com/ZoneCNH/riskx) | 风控引擎（事前风控 · 回撤控制 · 熔断） |
| [orderx](https://github.com/ZoneCNH/orderx) | 订单管理器（生命周期 · SOR · 状态机） |
| [positionx](https://github.com/ZoneCNH/positionx) | 仓位管理器（实时追踪 · PnL · 敞口监控） |
| [settlement](https://github.com/ZoneCNH/settlement) | 结算与对账 |

<br />

## 🚪 入口 · 🔔 横切

| 模块 | 说明 |
| --- | --- |
| [composer](https://github.com/ZoneCNH/composer) | 组合根：25 进程编排 + Docker Compose + RegimeCoordinator 全链路 |
| [frontend](https://github.com/ZoneCNH/frontend) | 统一前端平台（React 19 + Vite + Tailwind 4）· **production** |
| [alertx](https://github.com/ZoneCNH/alertx) | 告警引擎 |
| [stdio.rs](https://github.com/xhyperium/stdio.rs) | Rust 标准库扩展模板（trait · 组合子 · 宏） |

<br />

<div align="center">

## 🔬 治理方法论

每一行代码都可追溯到一个可验证的业务目标。

| 管线 | 说明 |
| --- | --- |
| **Goal 驱动交付** | G0–G11 全生命周期，Goal → Spec → Design → Plan → Code → Ship |
| **Spec → Code** | 23 节结构化规格 · 需求追溯矩阵（FR→AC→TC→Evidence） |
| **四源评分** | Claude + Codex + Copilot + rules 四源独立评分 · composite ≥ 98 门禁 |
| **三 SSOT 分立** | registry（身份）· FOUNDATION-DEPS（依赖）· index.json（成熟度） |
| **宪法治理** | CONSTITUTION §0–§20 · 分支纪律 · 受控递归改进 |

[CONSTITUTION](https://github.com/ZoneCNH/ZoneCNH/blob/main/CONSTITUTION.md) ·
[架构文档](https://github.com/ZoneCNH/ZoneCNH/tree/main/docs/architecture) ·
[治理工作流](https://github.com/ZoneCNH/ZoneCNH/tree/main/docs/governance) ·
[模块规格库](https://github.com/ZoneCNH/ZoneCNH/tree/main/module)

</div>

<br />

<div align="center">

<img src="https://github-readme-stats.vercel.app/api?username=xhyperium&show_icons=true&theme=transparent&hide_border=true&card_width=320" alt="stats" />
<img src="https://github-readme-stats.vercel.app/api/top-langs/?username=xhyperium&layout=compact&theme=transparent&hide_border=true&card_width=320" alt="top langs" />

<br /><br />

**构建稳定可靠的量化基础设施 ⚡**

</div>
