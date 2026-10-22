# 查询清单 v1（D2 交付物）

> 负责人：D（凌彤）· 发布：2026-10-22 · 全部 8 条已在本地 5000 行预研库（seed=42）验证通过
> 正式验证：待 C4 五万行同源数据（10-25）到位后逐条复测并按 C2 规范截图（D3，10-29 交付）
> 官方 3 条保底（Q1–Q3）语义与作业 Section 5 一致，展示版有增强（见备注）；SQL 文件见 `02_sql/queries/`

| 编号 | 文件 | 业务问题 Business Question | 涉及表 | SQL 要点 | 状态 |
|---|---|---|---|---|---|
| Q1 | q01_completed_payment.sql | Completed trips with their payments（完成且钱到账，运营对账） | Trip, Payment | INNER JOIN（1:1 via trip_id UNIQUE）；ORDER BY 保证复跑一致 | ✅ 已验证 |
| Q2 | q02_unpaid_drivers.sql | Drivers with completed but unpaid trips（催收名单） | Driver, Trip, Payment | NOT EXISTS 反连接 + DISTINCT（官方原版无 DISTINCT，展示版补去重） | ✅ 已验证 |
| Q3 | q03_vehicle_revenue.sql | Total fare earned per vehicle（车辆资产视角营收） | Vehicle, Driver, Trip | 三表连接 + SUM + GROUP BY | ✅ 已验证 |
| Q4 | q04_driver_daily_income.sql | Driver daily income ranking Top10（找单王 / 尾部激励） | Trip | 窗口函数 RANK() OVER（亮点版）；同文件附 GROUP BY 兼容版（MySQL <8.0 可跑） | ✅ 已验证（双版本） |
| Q5 | q05_unpaid_over_24h.sql | Completed >24h still unpaid（催收风险敞口） | Trip, Payment | NOT EXISTS + INTERVAL 时间过滤 | ✅ 已验证 |
| Q6 | q06_peak_hours.sql | Peak-hour order volume（运力调度依据） | Trip | GROUP BY + HAVING 组过滤（概念题 Q7 活例） | ✅ 已验证 |
| Q7 | q07_monthly_revenue.sql | Monthly revenue trend（GMV 口径，供 §1 目标对照） | Trip, Payment | DATE_FORMAT 按月分组 + SUM | ✅ 已验证 |
| Q8 | q08_repeat_passengers.sql | Repeat passengers（不同活跃日 ≥2，留存指标） | Passenger, Trip | COUNT(DISTINCT) + HAVING | ✅ 已验证 |

## 条件项与备注

- **热区版查询（待 B3 扩展表决）**：官方五实体无区域字段；若服务区域表提案表决通过，追加 `q09_hot_zones.sql`（Zone ⋈ Trip，GROUP BY + HAVING TopN）。时段版 Q6 已可独立交付。
- **版本基线**：Q4 窗口函数需 MySQL ≥ 8.0；已登记 A=8.0.45 / C=26.7.0 / D=26.7.0，B、E 待登记；若最终基线 <8.0，切换 Q4 兼容版即可。
- **给 A（A5 负载画像参考）**：高频候选 = Q1（日常对账）、Q6（调度高频）、Q3/Q7（定期报表）、Q5（定时催收）；写入集中在 Trip / Payment。

## 版本

- v1.0 · 2026-10-22：首批 8 条（官方 3 条保底 + 进阶 5 条），提交 M1 补充评审
