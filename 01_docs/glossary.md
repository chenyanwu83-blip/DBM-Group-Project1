# 术语与写法统一表（E2 交付物 · 三件套之三）

> 维护人：E（胡中远）· v1.0 · 2026-10-22 · **全员写作前必读**；新增术语直接加行，写报告以本表为准
> 配套：Overleaf 写作约定见 `05_report/README.md`；决策口径见 `01_docs/design_decisions.md`

## 一、命名规范

- 表名 / 字段名 / SQL 与脚本一律**小写下划线**：`trip_id`、`psg_id`、`driver_id`、`vehicle_id`、`pay_id`、`start_time`
- 库名统一 `ride_hailing`；截图命名 `前缀_表名或查询号_日期.png`（如 `q03_driver_income_1029.png`、`ddl_driver_1024.png`）
- `status` 值域（小组约定，D-05 下**无 requested**）：`accepted / en_route / completed / canceled`
- LaTeX：跨章引用一律 `\ref` / `\autoref`，禁止手写"见第 X 页"；Figure / Table / Listing 自动编号

## 二、中英术语对照（正文首现给英文，之后从简）

| 中文 | 英文 | 备注 |
|---|---|---|
| 派单 | dispatch | Trip 于派单成功时入库（D-05） |
| 已接单行程 | accepted trip | 口径 = 全部 Trip 行（含接单后取消） |
| 取消费 | cancellation fee | CNY 8 课程简化值（D-06） |
| 宽限期 | grace period | 宽限期内取消免费（D-06） |
| 热区 | hot zone | q09，待 B3 扩展表决 |
| 高峰时段 | peak hours | Q6（晚高峰 17–20 时 ≈ 20%） |
| 反连接 | anti-join | Q2 / Q5 的 NOT EXISTS 写法 |
| 窗口函数 | window function | Q4 RANK()，需 MySQL ≥ 8.0（已备兼容版） |
| 丢失更新 | lost update | 概念题 Q5，read-modify-write 前提要写清 |
| 隔离级别 | isolation level | 概念问答 + 实验③ |
| 引用完整性 | referential integrity | G5：FK 违反须被数据库拒绝 |
| 仿真数据 | synthetic (generated) dataset | 路线 B，seed=42，分布参照 NYC TLC（D-10） |

## 三、数字与单位写法

- 金额：CNY + 两位小数（如 CNY 35.00），与 `DECIMAL(8,2)` 对齐；中文语境可写 ¥35.00，全文统一一种
- 时延：ms（P95 < 200 ms）；吞吐：TPS；行数：千分位（60,000）
- 百分比：数字 + %（≈ 82%）；区间用短横线（CNY 10–120）
- 版本号如实照抄登记表：MySQL 8.0.45 / 26.7.0 / 9.6.0（以 `env_record.md` 为准）
- "≥ 5 万行"这类硬指标在正文出现时，同时给出实际值（60,000）与来源（自检截图编号）
