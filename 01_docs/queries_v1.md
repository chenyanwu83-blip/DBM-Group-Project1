# 查询清单 v1.1（D2 交付物）

> 负责人：D（凌彤）· v1.1 发布：2026-10-26 · Q1–Q8 已在预研库验证；Q9/Q10 按 C3 实际 DDL（build.sql §3）重写
> 正式验证：C4 数据已到位（10-25，Trip 60,000 行）——D3 于 10-29 前逐条复测并按 C2 规范截图
> 口径同步：全程美元 $（D-06 v1.2）；status = completed/canceled/accepted/en_route（D-05）；SQL 文件见 `02_sql/queries/`

| 编号 | 文件 | 业务问题 Business Question | 涉及表 | SQL 要点 | 状态 |
|---|---|---|---|---|---|
| Q1 | q01_completed_payment.sql | Completed trips with their payments（完成且钱到账，运营对账） | Trip, Payment | INNER JOIN（1:1 via trip_id UNIQUE）；ORDER BY 保证复跑一致 | ✅ 预研已验证 |
| Q2 | q02_unpaid_drivers.sql | Drivers with completed but unpaid trips（催收名单） | Driver, Trip, Payment | NOT EXISTS 反连接 + DISTINCT；C4 留 1,442 行未支付保非空 | ✅ 预研已验证 |
| Q3 | q03_vehicle_revenue.sql | Total fare earned per vehicle（车辆资产视角营收） | Vehicle, Driver, Trip | 三表连接 + SUM + GROUP BY | ✅ 预研已验证 |
| Q4 | q04_driver_daily_income.sql | Driver daily income ranking Top10（找单王 / 尾部激励） | Trip | 窗口函数 RANK() OVER——基线 8.0.45 ≥ 8.0，正式采用（D-09）；文件内附 GROUP BY 兼容版备查 | ✅ 预研已验证 |
| Q5 | q05_unpaid_over_24h.sql | Completed >24h still unpaid（催收风险敞口） | Trip, Payment | NOT EXISTS + INTERVAL 时间过滤 | ✅ 预研已验证 |
| Q6 | q06_peak_hours.sql | Peak-hour order volume（运力调度依据；§5.5 晚高峰对照的生成段来源） | Trip | GROUP BY + HAVING 组过滤（概念题 Q7 活例） | ✅ 预研已验证 |
| Q7 | q07_monthly_revenue.sql | Monthly revenue trend（GMV 口径，供 §1 目标对照） | Trip, Payment | DATE_FORMAT 按月分组 + SUM | ✅ 预研已验证 |
| Q8 | q08_repeat_passengers.sql | Repeat passengers（不同活跃日 ≥2，留存指标） | Passenger, Trip | COUNT(DISTINCT) + HAVING | ✅ 预研已验证 |
| Q9 | q09_hot_zones.sql | Hot zones by accepted trips（热区已接单量） | Trip, trip_detail, pickup_zone | **已接单口径（D-11①钉死）**：全部 Trip 行计数含接单后取消；结论只答"哪里已接单最多"，不得推出"哪里缺司机" | 🔧 已按 C3 实际 DDL 重写，待 C4 数据验证 |
| Q10 | q10_service_tier_rating.sql | Service tier × rating（四档产品线：量/均费/评分覆盖率/平均分） | Trip, trip_detail, service_tier | **仅 completed 口径（D-11②）**；COUNT(rating) 只数非空 = 覆盖率；AVG 自动忽略 NULL；§5.5 档次/评分对照的生成段来源 | 🔧 已按 C3 实际 DDL 重写，待 C4 数据验证 |

## 条件项与备注

- **扩展结构定案（C3，10-25）**：两项扩展由单表 `trip_detail`（trip_id 主键即外键，Trip↔TripDetail 1:1）承载 + 两张字典表 `service_tier`(4 行)/`pickup_zone`(15 行)，官方五表零增列。Q9/Q10 各只需经 trip_detail 一个 JOIN（build.sql §3.3 注释明示）。
- **D3 验证时的预期数字（C4 实际生成值，对齐用）**：Trip 60,000 / Payment 51,398 / trip_detail 60,000（=Trip 行数，先核对）；completed 均费 $14.00（标定 $13.99）；未支付 completed 1,442 行（Q2 应非空）；评分覆盖 89.9%（仅 completed）；top3 区位 35.0%；晚高峰 20.5%；档次 95.1/3.7/0.9/0.3。
- **版本基线**：最低 8.0.45（≥ 8.0）——窗口函数 / CHECK 全组可用（D-09）。
- **§5.5 留出对照页（D-12，D 主笔）**：生成段统计由 Q6（晚高峰占比）与 Q10（档次/评分分布）直接产出——一材两用；留出段数字取 a4_rideaustin_profile.md §七。
- **给 A（A5 负载画像参考）**：高频候选 = Q1（日常对账）、Q6（调度高频）、Q3/Q7/Q10（定期报表）、Q5（定时催收）；写入集中在 Trip / Payment / trip_detail。

## 版本

- v1.0 · 2026-10-22：首批 8 条（官方 3 条保底 + 进阶 5 条）
- v1.1 · 2026-10-26：D-11 落号 Q9/Q10，并按 C3 实际 DDL（trip_detail 单表承载两项扩展）重写；预期数字对齐 C4 生成值
