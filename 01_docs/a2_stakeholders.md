# A2 · 利益相关者需求表（五方 × 各 2 条数据需求）

> 陈祎楠 / 角色 A · 2026-10-22 · 状态：草稿
> 用途：报告 §1 素材（Problem framing & significance，rubric 4 分）；每条需求都落到实体/字段与可支撑查询，供 D2 查询清单取材。

## 需求表

| 相关方 | # | 数据需求（白话） | 依赖的实体/字段 | 可支撑的典型查询（D2 取材） |
|---|---|---|---|---|
| **乘客**<br/>Passenger | P1 | 查自己的历史行程与车费明细（花了多少钱、用的什么支付方式） | `Trip.psg_id` ⋈ `Payment.trip_id`（1:1 连接） | 按乘客列出行程+支付明细（官方 Q1 变体，加 `WHERE psg_id=?`） |
| | P2 | 行程对账有据：每笔行程的应收 fare 与实收 amount 能对上 | `Trip.fare` vs `Payment.amount` | 两列差值核对 / 不一致行清单（LEFT JOIN 找无支付行程） |
| **司机**<br/>Driver | D1 | 查本人累计接单量与总收入 | `Trip.driver_id`, `Trip.fare`, `Trip.status` | 按司机聚合 `COUNT(*) / SUM(fare)`（GROUP BY + HAVING 可筛高收入司机） |
| | D2 | 确认自己绑定的车辆（车牌）且系统中不与他人冲突 | `Driver.vehicle_id`(UNIQUE) → `Vehicle.plate` | 司机-车辆连接查询；UNIQUE 约束 = 冲突在写入时即被拒绝 |
| **运营**<br/>Operations | O1 | 监控高峰时段订单量与取消率，指导运力调度 | `Trip.start_time`, `Trip.status` | 按小时/日 `GROUP BY` 统计单量与 `canceled` 占比（HAVING 筛异常时段）。口径注：取消率按**已入库**（派单成功后）行程计算——D-05 下匹配期取消不落库 |
| | O2 | 司机-车辆绑定关系可审计（谁在开哪辆车） | `Driver` ⋈ `Vehicle`（N:1） | 绑定关系全表 / 未绑车辆清单（RIGHT JOIN/NOT EXISTS） |
| **财务**<br/>Finance | F1 | 每笔行程与支付逐笔对账：不出现孤儿支付、不漏收 | `Payment.trip_id`(UNIQUE)，`Trip.status` | 官方 Q2 反连接：已完成但未支付的司机/行程清单（NOT EXISTS） |
| | F2 | 按日/月的营收汇总与支付方式结构 | `Payment.amount`, `Payment.method` | `SUM(amount) GROUP BY 日期/method`（车费累计=官方 Q3 同款；营收含取消费，D-06） |
| **客服**<br/>Customer Service | S1 | 接投诉后 30 秒内定位乘客的完整行程链路（司机、车辆、支付） | 五表全连接 `Passenger⋈Trip⋈Driver⋈Vehicle⋈Payment` | 按乘客/时间窗检索行程全景（多表 JOIN 范例） |
| | S2 | 争议车费快速核对：平台计费 vs 实际扣款 vs 支付渠道 | `Trip.fare` vs `Payment.amount`, `Payment.method` | 单行程三字段并排展示（fare≠amount 时进入退差价流程） |

## 给 §1 写作的三点提炼

1. **五方需求共同压出两条硬约束**：逐笔对账（F1/P2）要求 `Trip:Payment = 1:1`；车辆审计（D2/O2）要求 `Driver:Vehicle = N:1`——业务需求与 ER 特殊基数一一对应，§1→§2 呼应即得分点。
2. **乘客/司机是读多写少，行程/支付是写入密集**——为 A5 负载画像（读写比、Top5 查询）埋下伏笔。
3. 客服 S1 的"30 秒定位全链路"是 A3 中查询时延目标（P95 < 200ms）的业务来源，写目标时不要凭空给数字。
