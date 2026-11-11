# 生成数据 vs RideAustin 对照

> 2026-11-11 E 勘误：本文件原写"参数取自 80% 训练段、与 20% 留出段对照"，
> 与事实不符——生成器常量（02_sql/import_data.py）取的是 A4 **全量**实测值，
> 训练段重算值从未回填（见 03_data/source/README.md §五"遗留"）。D-12 的
> 留出验证方案未实际执行。报告已按全量口径改写为**描述性对照**（§5.5），
> 不再声称独立留出验证。

生成参数取自 RideAustin 全量统计（A4 实测档案），对照的是同一全量统计的口径。
数字都在本机跑出来。

| 维度 | RideAustin（全量） | 生成数据 | 差距 |
|---|---|---|---|
| 四档占比 | 95.0 / 3.7 / 0.9 / 0.3 % | 95.08 / 3.75 / 0.90 / 0.30 % | 很小 |
| 完成单均费 | $13.99 | $14.00 | 1 美分 |
| 评分覆盖率 | ~90.7% | 89.9% | <1pp |
| 晚高峰占比 | ~20.5% | 20.5%（12,299/60,000） | <0.1pp |

口径备注（对应老师整改单第 11 条五项）：
- RideAustin 侧 = 全部 1,494,125 行；车型取 requested_car_category；车费取 total_fare 列原值（不含 tip/credit）；评分覆盖率 = driver_rating 非空占比；晚高峰 = created_date（或修正后 driver_accepted_on，两者差秒级）17–20 时占比，美中时区。
- 生成侧 = 60,000 行样本；车费 = Trip.fare（completed 49,200 行）；评分覆盖率 = completed 行 rating 非空占比；晚高峰 = start_time（D-05 接单时刻）17–20 时占比。

星级分布补充查询（如果要填的话）：

```sql
SELECT rating, COUNT(*),
       ROUND(COUNT(*) / (SELECT COUNT(*) FROM trip_detail WHERE rating IS NOT NULL) * 100, 1) AS pct
FROM trip_detail WHERE rating IS NOT NULL
GROUP BY rating ORDER BY rating DESC;
```

几个不能比的维度（真实数据没有对应字段）：status 构成、支付方式、未支付率——这些是课程设定的规则。

报告里写的话术就一句（2026-11-11 改）：生成参数标定自 RideAustin 全量统计，对照表核验生成样本复现了标定时的边际统计量——是描述性对照，不是独立留出验证。
