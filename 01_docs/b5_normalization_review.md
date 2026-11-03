# B5 规范化核查（八表，供报告 §2.3 和 D 的概念题 Q2）

**B｜2026-11-03｜课程依据：Lecture08.pptx 幻灯片 27–29、34、44–50；Database_week8.pdf 第 4–6 页。** 本记录用老师讲过的函数依赖（FD）、1NF、2NF、3NF 和分解概念，不把当前数据里“恰好没重复”当作对所有未来数据的证明。表结构以 `02_sql/build.sql` §1、§3 和 B4 数据字典为准。

## 判定口径

- **1NF：** 一格一个原子值，没有列表、嵌套表或重复字段组。
- **2NF：** 已满足 1NF，非主属性依赖整个候选键，不只依赖复合键的一部分。本项目每张表的主键都是**单列**，其余声明的候选键也都是单列，所以不存在针对复合键的部分依赖。
- **3NF：** 已满足 2NF，非主属性不经由另一非主属性间接依赖候选键。以下结论根据已声明的业务语义与键约束；若以后新增业务规则或列，应重新检查。

## 逐表核查

| 表 | 主键及其他候选键 | 1NF | 2NF | 3NF 与关键理由 |
|---|---|---|---|---|
| `Passenger` | PK `psg_id` | 是；姓名为单值 | 是；单列键 | 是；`psg_id → name`，没有另一非主属性作为中介。 |
| `Vehicle` | PK `vehicle_id`；`plate NOT NULL UNIQUE` 也是候选键 | 是；车牌为单值 | 是；候选键均单列 | 是；车辆 ID 与唯一车牌均能确定该车辆，没有非主属性之间的传递链。 |
| `Driver` | PK `driver_id`；`vehicle_id NOT NULL UNIQUE` 也是候选键 | 是；每列单值 | 是；候选键均单列 | 是；`driver_id → name, vehicle_id`。由于 `vehicle_id` 本身是候选键，不能把它误当作导致 3NF 违规的“普通非主属性”。车牌存于 `Vehicle`，未复制到 Driver。 |
| `Trip` | PK `trip_id` | 是；状态、时间、金额各占一列 | 是；单列键 | 是；`trip_id → psg_id, driver_id, fare, status, start_time`。乘客名、司机名和车牌不在 Trip 中，避免由外键指向的实体属性重复存储。`status` 不决定唯一 `fare`。 |
| `Payment` | PK `pay_id`；`trip_id NOT NULL UNIQUE` 也是候选键 | 是；金额和方式为单值 | 是；候选键均单列 | 是；金额、方式描述本条支付；关联 `trip_id` 为候选键。乘客名与行程状态未重复存入 Payment。 |
| `service_tier` | PK `tier_id`；`name NOT NULL UNIQUE` 也是候选键 | 是；档名、倍数为单值 | 是；候选键均单列 | 是；`tier_id → name, fare_multiplier`，唯一 `name` 也能确定该档；倍数是本档描述值，不是 Trip 的重复列。 |
| `pickup_zone` | PK `zone_id`；`name NOT NULL UNIQUE` 也是候选键 | 是；区域名为单值 | 是；候选键均单列 | 是；`zone_id → name`，无非主属性传递链。 |
| `trip_detail` | PK `trip_id`，同时 FK → `Trip` | 是；档次、区域、评分各为单值 | 是；单列键 | 是；`trip_id → service_tier_id, zone_id, rating`。档名、区域名保存在各自字典表，不复制到 detail。评分允许 `NULL`，不改变范式判断。 |

**结果：** 按当前列、键和小组业务规则，八张表都满足 1NF、2NF、3NF。这个结论不等于所有业务规则都由 DDL 强制：例如“只有完成单能评分”涉及 `Trip.status` 与 `trip_detail.rating` 两表，需由生成器及验收查询检查；它是跨表业务约束问题，不是本表范式失败。

## 本项目的传递依赖消除示例

设想未规范化设计把乘客姓名直接加到每条行程：

`TripRaw(trip_id, psg_id, psg_name, driver_id, fare, status, start_time)`。

业务规则给出 `trip_id → psg_id`，同时 `psg_id → psg_name`；故 `trip_id → psg_id → psg_name`。一个乘客可有多条 Trip，因此 `psg_id` **不是** `TripRaw` 的候选键，而 `psg_name` 是经由非主属性才依赖行程主键的。这张假想表可有 1NF、2NF，却违反 3NF。它会重复姓名：乘客改名要更新多条 Trip；删除最后一条 Trip 可能连乘客信息也失去；没有 Trip 时无法单独登记乘客。

按课件的分解方法，现行模型将它拆成 `Passenger(psg_id, name)` 和 `Trip(trip_id, psg_id, driver_id, fare, status, start_time)`。姓名只保存一次，Trip 用 `psg_id` 外键引用 Passenger；按主外键连接仍可取得行程和乘客姓名。这就是本项目已有的 3NF 设计，不需要修改老师的五表 DDL。

## 与 D 的 Q2 交接

D 可用上面的 `TripRaw` 例子解释 1NF、2NF、3NF 和传递依赖；**不要**使用 `Driver(driver_id, vehicle_id, plate)` 作为无条件的 3NF 违规例子，因为老师的 `Driver.vehicle_id UNIQUE` 使该列成为候选键，原例会产生键定义上的争议。最终问答需由 D 自己写成 150–250 英文词，B8 再复核。
