# 查询清单 v1.1

10 条查询（官方 3 条保底 + 7 条自选），全部在正式数据上验证通过。
SQL 文件在 `02_sql/queries/`，截图在 `03_data/screenshots/queries/`。

| # | 文件 | 干什么 | 涉及表 | 主要语法 |
|---|---|---|---|---|
| Q1 | q01_completed_payment.sql | 查完成行程及对应支付 | Trip, Payment | INNER JOIN |
| Q2 | q02_unpaid_drivers.sql | 找有完成未支付行程的司机 | Driver, Trip, Payment | NOT EXISTS |
| Q3 | q03_vehicle_revenue.sql | 每辆车的累计车费 | Vehicle, Driver, Trip | 三表 JOIN + SUM |
| Q4 | q04_driver_daily_income.sql | 司机日收入排行 | Trip | RANK() OVER |
| Q5 | q05_unpaid_over_24h.sql | 超过24小时未支付的完成行程 | Trip, Payment | NOT EXISTS + INTERVAL |
| Q6 | q06_peak_hours.sql | 订单量超过2000的小时段 | Trip | GROUP BY + HAVING |
| Q7 | q07_monthly_revenue.sql | 月度营收走势 | Trip, Payment | DATE_FORMAT + SUM |
| Q8 | q08_repeat_passengers.sql | 两个以上不同日乘车的乘客 | Passenger, Trip | COUNT(DISTINCT) |
| Q9 | q09_hot_zones.sql | 各上车区域的接单量 | Trip, trip_detail, pickup_zone | JOIN + ORDER BY |
| Q10 | q10_service_tier_rating.sql | 各档次的完成量/均费/评分 | Trip, trip_detail, service_tier | AVG + NULL 处理 |

## 备注

- Q4 用了窗口函数，组内最低 MySQL 版本 8.0.45 支持所以直接用了
- Q2 中 生成器故意留了约 3% 未支付行程，保证反连接非空
- Q9 和 Q10 依赖扩展表 trip_detail，DDL 在 build.sql 第 3 节
- 高频查询大致是 Q6（调度）、Q1（对账）、Q5（催收）、Q3/Q7（报表）
