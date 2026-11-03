# B6 ER 图与建库脚本一致性对账

**B 核对日期：2026-11-03｜C 联签状态：待 C 确认｜模型：ER v1.0（`04_figures/er_final.drawio`）｜脚本：`02_sql/build.sql` §1/§3。** 这是一份可供 C 联签的核对清单，不能替 C 声称已签字或替代 C8 的独立复跑。

## 1 表和字段

| 核对项 | ER/字典 | `build.sql` | B 结果 |
|---|---|---|---|
| 官方五表 | Passenger、Vehicle、Driver、Trip、Payment | §1 同名五表；未增列 | ✓ |
| 扩展三表 | `service_tier`、`pickup_zone`、`trip_detail` | §3 同名三表 | ✓ |
| 官方五表字段数 | 2 + 2 + 3 + 6 + 4 = 17 | §1 同名同型同约束 | ✓ |
| 扩展三表字段数 | 3 + 2 + 4 = 9 | §3 同名同型同约束 | ✓ |
| 总数 | 八表、26 列 | 八表、26 列 | ✓ |

字段类型与 `NOT NULL`、`UNIQUE`、`CHECK`、默认值逐列见 `01_docs/b4_data_dictionary.md`；B 的字段名核对没有发现漏列或额外列。

## 2 主外键与基数

| ER 关系 | SQL 落点 | B 结果 | 需要说明的实际基数 |
|---|---|---|---|
| Passenger–Trip | `Trip.psg_id NOT NULL` + FK | ✓ | 每 Trip 一乘客；每乘客 0..N Trip |
| Driver–Trip | `Trip.driver_id NOT NULL` + FK | ✓ | 每 Trip 一司机；每司机 0..N Trip |
| Vehicle–Driver | `Driver.vehicle_id NOT NULL UNIQUE` + FK | ✓ | 每 Driver 一车；每车 **0..1 Driver**，不能只照老师图写成无限 N |
| Trip–Payment | `Payment.trip_id NOT NULL UNIQUE` + FK | ✓ | 每 Payment 一 Trip；每 Trip **0..1 Payment**，官方 Q2 需要零支付情况 |
| Trip–trip_detail | `trip_detail.trip_id` PK + FK | ✓ | 每 detail 一 Trip；每 Trip **0..1 detail**；生成器另保证恰一 |
| service_tier–trip_detail | `service_tier_id NOT NULL` + FK | ✓ | 每 detail 一档；每档 0..N detail |
| pickup_zone–trip_detail | `zone_id NOT NULL` + FK | ✓ | 每 detail 一上车区域；每区 0..N detail |

扩展三表均在 §3；官方 §1 未被 B 的 ER 扩展修改。`trip_detail.rating` 的 `CHECK (rating BETWEEN 1 AND 5)` 只约束非空值范围；只有完成单可有评分、每 Trip 恰一 detail 两项跨表规则由生成器实现，不可写成 SQL `CHECK` 已保证。

## 3 与运行证据的对应

C5 已上传八表 `SHOW CREATE TABLE` 与行数截图，以及 `row_counts_1101.png`。截图显示 Passenger 3,000、Vehicle 150、Driver 150、Trip 60,000、Payment 51,398、service_tier 4、pickup_zone 15、trip_detail 60,000。这证明当次 C 的库里有八张表及相应样本行；**单张行数截图不证明所有 FK/UNIQUE/CHECK 均正确**，结构证据应由 C 对照各表的 `SHOW CREATE TABLE` 图或真机输出复核。

## 4 联签请求与结论边界

- **B 已核对：** 模型、字典与当前仓库脚本的八表 26 列和七条关系一致；图注如实说明老师示例标签与官方 DDL 的实际可选基数差别。
- **待 C 确认：** `build.sql` §3 当前标记 `schema v1.0-rc`；请 C 按本清单复核运行版八表结构、特别是 `trip_detail.trip_id` PK+FK、两条维度 FK、`rating` CHECK，并确认是否可把 rc 标记转为 v1.0。C 的确认日期/方式或提交号：**待填**。
- **B6 状态：** B 单方核对完成，**双方联签未完成**。C8 的另一人独立干净复跑是另一个验收任务，不能从本清单推定完成。
