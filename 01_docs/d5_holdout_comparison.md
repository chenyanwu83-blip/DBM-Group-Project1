# D5补 · 标定-留出对照表（D-12 · 报告 §5.5 素材 · 2026-11-03）

> 产出：D（凌彤，同机纪律 D-08④）· 口径：`a4_rideaustin_profile.md` §七（v1.1 对照口径）
> 生成段数字来源：本机 C4 正式数据（seed=534）Q6/Q10 实测 + 一条星级分布补充查询
> 真实段数字来源：RideAustin 留出段（20%，≈30 万行；与全量差异可忽略，档案全量实测值并列）

## 对照表（LaTeX 版已嵌入 sec5_eval.tex §5.5）

| 维度 | RideAustin（留出段标定值） | 生成数据（60,000 行实测） | 偏差 |
|---|---|---|---|
| 车型四档占比 | REGULAR 95.0% / SUV 3.7% / PREMIUM 0.9% / LUXURY 0.3% | 95.08% / 3.75% / 0.90% / 0.30%（Q10） | ≤0.1pp |
| total_fare 均值（completed 口径） | $13.99（列原值，含 ≈$1.65 固定附加费） | $14.00（completed 均费，C4 实测） | +0.07% |
| 评分覆盖率（仅 completed） | ≈90.7%（全量实测；生成参数取 90%） | 89.9%（Q10 rating_cov_pct） | −0.8pp |
| 星级分布（有值行内占比，真实 0.5 星步长 vs 生成 1 星步长，口径注一句） | 5★≈90.3% / 4★≈5.5% / 3★≈2.0% / 2★≈0.6% / 1★≈1.7% | 【TODO-D：跑下方补充查询后回填】 | — |
| 晚高峰（17–20 时）占比 | ≈20.5%（训练段标定参数；真实侧用 created_date 口径） | 22.4%（Q6：13,459/60,000） | +1.9pp |

## 星级分布补充查询（生成段，30 秒跑完回填上表）

```sql
SELECT rating,
       COUNT(*) AS cnt,
       ROUND(COUNT(*) / (SELECT COUNT(*) FROM trip_detail WHERE rating IS NOT NULL) * 100, 1) AS pct
FROM trip_detail
WHERE rating IS NOT NULL
GROUP BY rating
ORDER BY rating DESC;
```

## 诚实边界（报告 §5.5 表下必带，D-12 话术）

- *"Parameters were calibrated on the 80\% training split of RideAustin and distributional consistency was checked on the held-out 20\% split; the check validates distribution consistency, not the external validity of business conclusions."*
- 不可比维度不进表（报告一句注明业务规则为课程设定）：status 构成 / Payment.method / 未支付率——真实数据无对应字段。
- 区位分布为课程设定（无真实标定源），不参与对照（q09 解读已声明）。

## 责任与登记

- 对照表产出 D ✓（本文件）；E 登记为 D-12 附注闭环；A 提供留出段数字口径（已按 §七取数）。
