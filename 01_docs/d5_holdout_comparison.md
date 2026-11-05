# 生成数据 vs RideAustin 留出段对照

生成参数取自 RideAustin 80% 训练段，验证时和剩下 20% 留出段比。数字都在本机跑出来。

| 维度 | RideAustin | 生成数据 | 差距 |
|---|---|---|---|
| 四档占比 | 95.0 / 3.7 / 0.9 / 0.3 % | 95.08 / 3.75 / 0.90 / 0.30 % | 很小 |
| 完成单均费 | $13.99 | $14.00 | 1 美分 |
| 评分覆盖率 | ~90.7% | 89.9% | <1pp |
| 晚高峰占比 | ~20.5% | 22.4% | ~2pp |

星级分布补充查询（如果要填的话）：

```sql
SELECT rating, COUNT(*),
       ROUND(COUNT(*) / (SELECT COUNT(*) FROM trip_detail WHERE rating IS NOT NULL) * 100, 1) AS pct
FROM trip_detail WHERE rating IS NOT NULL
GROUP BY rating ORDER BY rating DESC;
```

几个不能比的维度（真实数据没有对应字段）：status 构成、支付方式、未支付率——这些是课程设定的规则。

报告里写的话术就一句：参数标定自训练段，在留出段上做了分布一致性检验，验证的是分布一致而非业务结论的外部效度。
