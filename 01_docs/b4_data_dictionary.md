# B4 ER v1.0.1 数据字典与 DDL 对账

**负责人：B｜模型冻结日期：2026-11-03｜图示记法修订：2026-11-04，ER v1.0.1（八表结构不变）｜依据：老师 Topic 5 Listing 17、D-05、D-06 v1.2、D-11、D-12、`02_sql/build.sql` §1/§3（C3 v1.0-rc）**

本字典与 `04_figures/er_final.drawio` 使用同一八表结构。前五表为老师的官方底座，字段与建库脚本第 1 节一致；后三表为小组表决通过的扩展层，字段与第 3 节一致。B4 冻结的是**模型与字段口径**；C 的运行复验、D 的查询及留出集数字对照须分别验收。

记号：PK=主键；FK=外键；`UNIQUE`=唯一；“可空”只表示 DDL 没有 `NOT NULL`，不表示业务必定产生空值。图中斜体主键、`*` 外键和 `1:1`、`1:N`、`N:1` 基数标注遵循老师第 4 节约定。**图上的 `1:1` 表示最大配对数，不表示双方都必须有记录**；实际可选性在下表逐条写明。Lecture 02 另教过 `(min,max)` 记法，但本图不混用未在老师作业示例中出现的 `1:0..1` 写法。

## 1 官方底座五表

### Passenger 乘客

| 列 | SQL 类型 | DDL 约束 | 业务含义 |
|---|---|---|---|
| `psg_id` | `INT` | PK，非空 | 乘客标识；被 `Trip.psg_id` 引用。 |
| `name` | `VARCHAR(40)` | `NOT NULL` | 乘客姓名。 |

### Vehicle 车辆

| 列 | SQL 类型 | DDL 约束 | 业务含义 |
|---|---|---|---|
| `vehicle_id` | `INT` | PK，非空 | 车辆标识；被 `Driver.vehicle_id` 引用。 |
| `plate` | `VARCHAR(20)` | `NOT NULL UNIQUE` | 唯一车牌。 |

### Driver 司机

| 列 | SQL 类型 | DDL 约束 | 业务含义 |
|---|---|---|---|
| `driver_id` | `INT` | PK，非空 | 司机标识；被 `Trip.driver_id` 引用。 |
| `name` | `VARCHAR(40)` | `NOT NULL` | 司机姓名。 |
| `vehicle_id` | `INT` | `NOT NULL UNIQUE`；FK → `Vehicle.vehicle_id` | 当前绑定车辆。每名司机恰有一辆；由于 `UNIQUE`，每辆车在表中至多对应一名司机。 |

### Trip 已接单行程

仅在司机接单后产生 Trip 行（D-05）；接单前的请求/取消不在本模型内。

| 列 | SQL 类型 | DDL 约束 | 业务含义 |
|---|---|---|---|
| `trip_id` | `INT` | PK，非空 | 行程标识；被 `Payment.trip_id`、`trip_detail.trip_id` 引用。 |
| `psg_id` | `INT` | `NOT NULL`；FK → `Passenger.psg_id` | 该行程的乘客。 |
| `driver_id` | `INT` | `NOT NULL`；FK → `Driver.driver_id` | 已接单司机。 |
| `fare` | `DECIMAL(8,2)` | 可空；无非负 `CHECK` | 行程应收金额，币种 USD。免费取消为 `NULL`；收费取消为课程设定的 $1.50；完成单按实际模拟车费。 |
| `status` | `VARCHAR(20)` | 可空；无值域 `CHECK` | 行程状态。生成器采用 `accepted`、`en_route`、`completed`、`canceled`；这些值不是官方 DDL 强制的。 |
| `start_time` | `DATETIME` | `DEFAULT CURRENT_TIMESTAMP`；可显式置空 | D-05 下表示司机**接单时间**，不表示乘客下单或上车时间。 |

### Payment 支付

| 列 | SQL 类型 | DDL 约束 | 业务含义 |
|---|---|---|---|
| `pay_id` | `INT` | PK，非空 | 支付记录标识。 |
| `trip_id` | `INT` | `NOT NULL UNIQUE`；FK → `Trip.trip_id` | 关联行程；一条支付必须属于一条 Trip，而一条 Trip 可有零或一条支付。 |
| `amount` | `DECIMAL(8,2)` | `CHECK (amount >= 0)`；可空 | 记录支付金额。`CHECK` 不等于 `NOT NULL`。 |
| `method` | `VARCHAR(20)` | 可空；无值域 `CHECK` | 生成器采用 `balance`、`cash`、`card`；RideAustin 无可对应的支付方式字段。 |

## 2 D-11 扩展层三表

### service_tier 服务档次

| 列 | SQL 类型 | DDL 约束 | 业务含义 |
|---|---|---|---|
| `tier_id` | `TINYINT UNSIGNED` | PK，非空 | 服务档次标识。 |
| `name` | `VARCHAR(16)` | `NOT NULL UNIQUE` | 原数据档名：`REGULAR`、`SUV`、`PREMIUM`、`LUXURY`。 |
| `fare_multiplier` | `DECIMAL(3,1)` | `NOT NULL` | 与 REGULAR 相比的描述性均费倍数（1.0/1.9/2.1/2.7）；**生成车费不靠该列计算**。 |

四行字典值由 `build.sql` §3.1 插入。车型份额来自 RideAustin 参照；按 D-12，训练段参数和 20% 留出段对照的实际执行状态须另核，不把全量统计写成已完成的独立验证。

### pickup_zone 上车区域

| 列 | SQL 类型 | DDL 约束 | 业务含义 |
|---|---|---|---|
| `zone_id` | `TINYINT UNSIGNED` | PK，非空 | 上车区域标识。 |
| `name` | `VARCHAR(32)` | `NOT NULL UNIQUE` | 上车区域名称；脚本预置 15 个 Austin 风格占位名称。 |

区域分布为课程设定，约 15 区、前三约 35%；RideAustin 没有与本项目一致的区域标定字段。q09 只能回答**已接单行程最多的区域**，不能推出未满足需求或哪里最缺司机。

### trip_detail 行程扩展记录

| 列 | SQL 类型 | DDL 约束 | 业务含义 |
|---|---|---|---|
| `trip_id` | `INT` | PK；FK → `Trip.trip_id` | 一条扩展记录属于一条 Trip；主键即外键保证每个 Trip **至多一条**扩展记录。 |
| `service_tier_id` | `TINYINT UNSIGNED` | `NOT NULL`；FK → `service_tier.tier_id` | 接单时确定的服务档次；包含后来取消的行程。 |
| `zone_id` | `TINYINT UNSIGNED` | `NOT NULL`；FK → `pickup_zone.zone_id` | 接单时确定的上车区域；q09 按全部已接单 Trip 行计数。 |
| `rating` | `TINYINT UNSIGNED` | 可空；`CHECK (rating BETWEEN 1 AND 5)` | 乘客对**本次行程**给司机的 1–5 整数评分；只有完成单可能有值，完成单也允许无评分。 |

`rating` 不是 RideAustin 文件 B 的司机历史均分；与真实每单评分对应的是文件 A 的 `driver_rating`。`CHECK` 只约束非空评分的范围，不能跨表验证 Trip 是否 `completed`。生成器负责“每 Trip 恰一条 `trip_detail`”和“非完成单评分为空”；C8 干净复跑时再核验。

## 3 ER 与 DDL 一致性对账

| 图中关系 | 建库脚本约束 | 数据库能保证的基数 | 业务/生成器补充 |
|---|---|---|---|
| Passenger → Trip | `Trip.psg_id NOT NULL` + FK | 每 Trip 恰一乘客；每乘客 0..N Trip | — |
| Driver → Trip | `Trip.driver_id NOT NULL` + FK | 每 Trip 恰一司机；每司机 0..N Trip | D-05：司机接单后才入库 |
| Vehicle → Driver | `Driver.vehicle_id NOT NULL UNIQUE` + FK | 每司机恰一车辆；每车辆 0..1 司机 | 老师文字描述为 Driver→Vehicle N:1，Figure 5 的连线写 1:N；但 Listing 17 的 `UNIQUE` 将实际最大配对限制为 1:1，以官方 SQL 为实现事实 |
| Trip → Payment | `Payment.trip_id NOT NULL UNIQUE` + FK | 每 Payment 恰一 Trip；每 Trip 0..1 Payment | 官方 Q2 需要已完成但尚无 Payment 的 Trip；D-06 免费取消无 Payment |
| Trip → trip_detail | `trip_detail.trip_id` 同时 PK + FK | 每 detail 恰一 Trip；每 Trip 0..1 detail | C4 生成器保证每 Trip 恰一 detail，须数据验收 |
| service_tier → trip_detail | `service_tier_id NOT NULL` + FK | 每 detail 恰一档；每档 0..N detail | 对应 q10 |
| pickup_zone → trip_detail | `zone_id NOT NULL` + FK | 每 detail 恰一区；每区 0..N detail | 对应 q09 |

核对结果：八张表、26 个列、七条关系与 `build.sql` §1/§3 一致；官方五表未增加列。`Driver.vehicle_id UNIQUE` 和 `Payment.trip_id UNIQUE` 的实际基数与老师示意标签的差异已在图注保留，不隐瞒。**B4 模型对账完成；B6 实质对账已完成，B+C 联签证据仍待留存。**原分工计划第 7 页要求 B6 与 C 联签，第 15 页说明打勾签字的照片或截图入共享盘；没有规定 C 必须在 GitHub 文件中亲笔留名。

**2026-11-04 图示勘误：**早先的报告 PDF 把可选性直接写在连线比值中（如 `1:0..1`），而可编辑图曾用 `1:1*`，三个图版本不一致，且 `*` 与“外键”记号冲突。ER v1.0.1 统一将三条最大一对一关系标为课程常用的 `1:1`，在图注和本字典说明谁可以缺席。只更正表达方式，不修改字段、外键、生成器或 `build.sql`。

## 4 查询与数据对照执行注释（供 C、D、E 扫盘）

此注释落实 D-11/D-12，**不修改已冻结决定，也不代表已经产生留出集数字**。

1. q09 按全部已接单 Trip 统计上车区，包含后来取消的行程；q10 只纳入 `Trip.status='completed'`，输出各档完成数、平均 `Trip.fare`、有效评分数和平均评分。`AVG` 忽略 `NULL`；平均车费为描述性差异，不作档次因果效应。
2. “生成数据 vs 留出 20%”的车费、评分只在合适的**已完成行程**上比较。真实侧每单评分用文件 A 的 `driver_rating`；车费用文件 B 的 `total_fare` 原值，先对齐票价组成、美元币种、缺失值和分母，不重算附加费。真实侧半星评分、生成侧整数星的粒度差异要注明。
3. 晚高峰 17–20 时对照必须采用**同义时间字段和同一时区**。`Trip.start_time` 是司机接单；真实侧候选为修正时区后的 `driver_accepted_on`，不可把下单时间 `created_date` 直接当作接单时间。A 的资料指出真实时间戳有时区错位，D 在报数前应记录最终字段映射与修正方法。
4. C 提供按 `RIDE_ID` 可复现哈希划分、仅训练 80% 得到的参数和生成数据；D 在同一环境产出一页数字对照，列出车型份额、已完成单车费、评分覆盖/分布和晚高峰份额。**业务查询 q09/q10 的结果**与**生成/留出分布对照**分开陈述。RideAustin 无法验证取消、未支付、支付方式或区域分布；这些是课程情境规则，靠约束、预设案例和查询检查。
5. 当前仓库 `03_data/source/README.md` 写明生成器常量仍取 A4 已发布的**全量**实测值，待 A 提供训练段重算值后由 C 更新。因此在实际完成训练专用标定和留出计算前，报告只能写“参照 RideAustin 标定，留出对照待完成”，不能声称已做独立验证。

## 5 交付与后续

- **给 C：** C 已口头确认当前建表结构未改、语句依照 B 的字典；按原计划与 B 完成对账清单联签，并把签字照片或截图存组内共享盘即可。若选择在仓库补文字记录，也只是可选留痕方式。C 可另行决定是否把脚本注释中的 `v1.0-rc` 转为正式版；实际 MySQL 建库/导数仍由 C 验收。
- **给 D：** 按上述口径实现 q09/q10；B5 范式论证和 B6 对账结果随后供 D 的概念问答引用。
- **给 E：** 将最终 ER 放入报告 §2，按 B 的最终字典撰写实体、键、基数和约束说明；D-12 一页对照只在数字真正产生后写“已验证”。

