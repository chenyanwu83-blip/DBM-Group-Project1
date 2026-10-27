-- Q10: Service Tier × Rating Statistics (completed only, per D-11②)
-- 业务问题: 四个服务档（REGULAR/SUV/PREMIUM/LUXURY）各自的完成量、平均车费、评分覆盖率与平均评分
-- 涉及表: Trip, trip_detail, service_tier（实际 DDL = build.sql §3.1/§3.3，C3 2026-10-25）
--   结构：trip_detail 1:1 于 Trip（主键即外键），service_tier_id → service_tier；rating 在 trip_detail 上
-- SQL要点: 仅 completed 计入口径(D-11②)；COUNT(td.rating) 只数非空 = 覆盖率；AVG 自动忽略 NULL（NULL 语义展示点）
-- 预期(C4 实际生成值): 档次 ≈ REGULAR 95.1% / SUV 3.7% / PREMIUM 0.9% / LUXURY 0.3%；
--   评分覆盖 ≈ 89.9%（仅 completed）；completed 均费 $14.00（标定 $13.99）
-- 状态: 待 C4 数据验证；档名保留英文原名，勿直译"快车/专车"
SELECT st.name                      AS tier,
       COUNT(*)                     AS completed_trips,
       ROUND(AVG(t.fare), 2)        AS avg_fare,
       COUNT(td.rating)             AS rated_trips,
       ROUND(COUNT(td.rating) / COUNT(*) * 100, 1) AS rating_cov_pct,
       ROUND(AVG(td.rating), 2)     AS avg_rating   -- AVG 自动忽略 NULL
FROM   Trip t
       JOIN trip_detail td    ON td.trip_id = t.trip_id
       JOIN service_tier st   ON st.tier_id = td.service_tier_id
WHERE  t.status = 'completed'
GROUP  BY st.tier_id, st.name
ORDER  BY completed_trips DESC;
