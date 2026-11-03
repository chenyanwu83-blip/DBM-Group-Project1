# B8 — D 的概念问答 Q1/Q2 复核记录（2026-11-03）

复核对象：`01_docs/answer_cards.md` 当前 Q1、Q2。该文件目前仍是填空提纲，**不是** 150–250 词的最终答案。因此本次只完成提纲复核，待 D 提交正文后还须逐句复核，B8 不标为完成。

## Q1：主键、外键与参照完整性

- `Passenger.psg_id` 是主键：非空且唯一。`Trip.psg_id` 是外键，引用现存的 `Passenger.psg_id`；`Trip` 的这列在官方 DDL 中还有 `NOT NULL`，因此该表不能用 NULL 绕开引用要求。
- 外键的一般规则要说准确：可空外键允许 NULL；非 NULL 值必须匹配被引用的候选键。本题的 `Trip.psg_id` 和 `Trip.driver_id` 都被设为非空。
- 删除被引用的父行时，不要把 `CASCADE` 或 `SET NULL` 写成这个项目实际设置的行为。官方 `build.sql` §1 没写这些动作；提纲可以解释它们是可选的数据库策略，再明确本项目没有启用。
- `Payment.trip_id` 同时是外键和 `UNIQUE`，因此一笔 Trip 至多对应一条 Payment；没有 Payment 的 Trip 允许存在，不能把两者误说成强制一对一。
- D 的最终答案须给出一条可运行的例子，避免提纲中的 `INSERT INTO Trip(psg_id) VALUES(99999,...)`：官方 Trip 还有多个 `NOT NULL` 列，省略它们会先触发非空错误，不能清楚展示外键拒绝。可用完整列值，或先建一个最小临时示例表。

## Q2：1NF、2NF、3NF

- Lecture 08 的顺序：1NF 检查列值是否原子；2NF 在 1NF 上排除非主属性对复合键的一部分的依赖；3NF 在 2NF 上排除非主属性对键的传递依赖。写解释时需明确所用键与函数依赖。
- 当前提纲的 `Driver(id, name, vehicle_id, plate)` 例子**不能无条件宣称违反 3NF**：老师给的 `Driver.vehicle_id UNIQUE NOT NULL` 使 `vehicle_id` 也能成为候选键。用它论证 `driver_id → vehicle_id → plate` 有争议。
- 建议 D 改用 `01_docs/b5_normalization_review.md` 的 `TripRaw(trip_id, psg_id, psg_name, ...)`：`trip_id → psg_id → psg_name`；一个乘客可以有多笔 Trip，`psg_id` 不是 `TripRaw` 的候选键。拆成官方 `Passenger` 与 `Trip` 后，姓名只保留在 Passenger，外键保持联系。
- 三种异常应联系这一例：姓名修改要改多行、删掉最后一笔行程可能误删乘客姓名、尚未乘车的乘客难以单独录入。

## 后续交接

**给 D：** 请提交 Q1/Q2 各 150–250 英文词的最终正文，并按上述两处修正示例。B 收到后核对概念、实际 DDL 与字数。**给 E：** 全报告合章后才可做 B8 的最终报告复核；当前 B8 状态为“提纲已复核，正文与合章待复核”。
