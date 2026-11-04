# B6 ER 图与建库脚本一致性对账

**B 核对日期：2026-11-03；图示复核：2026-11-04｜C 口头确认已由 B 转述记录，B+C 联签证据待留存｜模型：ER v1.0.1（仅记法修订，`04_figures/er_final.drawio`）｜脚本：`02_sql/build.sql` §1/§3。** 这是一份可供 C 联签的核对清单，不能替 C 声称已签字或替代 C8 的独立复跑。

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

C5 已上传八表 `SHOW CREATE TABLE` 与行数截图，以及 `row_counts_1101.png`。截图显示 Passenger 3,000、Vehicle 150、Driver 150、Trip 60,000、Payment 51,398、service_tier 4、pickup_zone 15、trip_detail 60,000。这证明当次 C 的库里有八张表及相应样本行。

**B 于 2026-11-04 增补截图核查：**逐张读了 `03_data/screenshots/ddl/ddl_*_1101_a.png` 八张结构图。截图中的官方五表仍为原字段；`Driver.vehicle_id` 与 `Payment.trip_id` 均有 `UNIQUE` 和对应 FK；`Trip` 的两条 FK 均在；扩展层有 `service_tier.name UNIQUE`、`pickup_zone.name UNIQUE`、`trip_detail.trip_id` PK+FK、两条维度 FK 和 `rating BETWEEN 1 AND 5` CHECK。与本清单和 `build.sql` §1/§3 的相应约束一致。截图只能证明 **11-01 当次运行库**，不能代替 C 对当前运行库的联签或 C8 的独立干净复跑。

**B 于 2026-11-04 增补查询适配核查：**`02_sql/queries/q09_hot_zones.sql` 使用全 Trip 行按上车区域计数；`q10_service_tier_rating.sql` 仅筛 `completed`，分别计算完成数、平均 `Trip.fare`、非空评分数与平均评分。字段连接及口径符合 D-11 和本 ER 模型。两份 SQL 的注释仍写“待 C4 数据验证”，但仓库已经有 D3 的查询结果和截图；这属于 D 的注释更新，不改变 B6 对账结论。

## 4 联签请求与结论边界

- **B 已核对：** 模型、字典与当前仓库脚本的八表 26 列和七条关系一致；图注如实说明老师示例标签与官方 DDL 的实际可选基数差别。
- **C 的口头确认（由 B 于 2026-11-04 转述记录）：** C 表示 11-01 截图之后没有修改表结构，建表语句按 B 先前交付的数据字典编写。结合 B 的图、字典、脚本和截图核对，B6 的实质对账已经闭环。此句是 B 对沟通结果的记录，**不冒充 B+C 已完成计划中的联签**。
- **待留存的形式证据：** 原分工计划第 7 页 B6 要求“与 C 联签”，第 15 页“双人联签节点”要求打勾签字、拍照或截图入共享盘。请 B 与 C 按此完成即可；在 GitHub 文件亲笔留名不是原计划的硬性要求。`build.sql` §3 的 `schema v1.0-rc` 是否转正式 v1.0 可由 C 另行决定。C8 的另一人独立干净复跑是另一个验收任务，不能从本清单推定完成。
- **图示记法勘误（2026-11-04）：**曾出现 PDF 的 `1:0..1` 与可编辑图的 `1:1*` 不一致。现统一为课件和老师作业要求使用的 `1:1` 最大基数标签；“每 Trip 0..1 Payment/detail、每 Vehicle 0..1 Driver”在图注和 B4 字典说明。八表 26 列、七条关系、DDL 及 C 的运行版均不变。
- **给 C 的注释清理提示：**`build.sql` §1 和 §3 的文字注释仍把 Vehicle–Driver 写成 `1:N`/`N:1`、把 Trip–Payment 写成笼统 `1:1`；SQL 约束本身正确。若 C 更新这些注释，应补充 `UNIQUE` 与可选性的实际含义，勿改官方 DDL 正文。这不影响 B6 的结构对账结论。
