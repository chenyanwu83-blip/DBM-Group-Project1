-- ============================================================
-- c5_check.sql — C5 干净库全流程验收配套脚本（M2 验收件）
-- 项目：CDS534 Topic 5 · schema v1.0-rc + C4 数据（seed=534）
--
-- 前置（顺序执行，一次走通即"干净库全流程"）：
--   1) mysql -u root -p < 02_sql/build.sql        建库（8 表 + 维度 seed + §4 自检）
--   2) mysql -u root -p < 02_sql/data_import.sql  导入 174,698 行
--   3) Workbench 打开本文件 → USE 后逐段执行，按
--      03_data/screenshots/C5_验收清单_1026.md 逐张截图
--
-- 每段头部注明：对应截图编号（S01–S12）/ 预期数字。
-- 预期数字由 seed=534 确定性生成，任何一台机器重跑结果相同。
-- ============================================================
USE ride_hailing;

-- ──────────────────────────────────────────────────────────
-- 【S09 · 行数总表】Trip ≥ 5 万行在此证明（M2 硬指标）
-- 预期：Passenger 3000 / Vehicle 150 / Driver 150 / Trip 60000
--       / Payment 51398 / service_tier 4 / pickup_zone 15 / trip_detail 60000
-- ──────────────────────────────────────────────────────────
SELECT 'Passenger'   AS tbl, COUNT(*) AS rows_ FROM Passenger
UNION ALL SELECT 'Vehicle',      COUNT(*) FROM Vehicle
UNION ALL SELECT 'Driver',       COUNT(*) FROM Driver
UNION ALL SELECT 'Trip',         COUNT(*) FROM Trip
UNION ALL SELECT 'Payment',      COUNT(*) FROM Payment
UNION ALL SELECT 'service_tier', COUNT(*) FROM service_tier
UNION ALL SELECT 'pickup_zone',  COUNT(*) FROM pickup_zone
UNION ALL SELECT 'trip_detail',  COUNT(*) FROM trip_detail;

-- ──────────────────────────────────────────────────────────
-- 辅助验收段（三条 A4 §四 + 两条 C3 不变量；可与 S09 同框拍一张）
-- 预期全部为 0
-- ──────────────────────────────────────────────────────────
-- 验收① D-06 取消规则违例（免费取消=NULL 无支付 / 收费取消=$1.50 恰一条）
SELECT COUNT(*) AS d06_violations FROM Trip t
LEFT JOIN Payment p ON p.trip_id = t.trip_id
WHERE t.status = 'canceled'
  AND NOT ((t.fare IS NULL AND p.pay_id IS NULL)
        OR (t.fare = 1.50 AND p.pay_id IS NOT NULL));

-- 验收② status 词表外取值（应 0；词表=completed/canceled/accepted/en_route）
SELECT COUNT(*) AS bad_status FROM Trip
WHERE status NOT IN ('completed','canceled','accepted','en_route');

-- 验收③ method 词表外取值（应 0；词表=balance/cash/card）
SELECT COUNT(*) AS bad_method FROM Payment
WHERE method NOT IN ('balance','cash','card');

-- C3 不变量：rating 出现在非 completed 行（应 0）
SELECT COUNT(*) AS rating_on_non_completed FROM Trip t
JOIN trip_detail d ON d.trip_id = t.trip_id
WHERE d.rating IS NOT NULL AND t.status <> 'completed';

-- C3 不变量：缺扩展行的 Trip（应 0）
SELECT COUNT(*) AS trips_without_detail FROM Trip t
LEFT JOIN trip_detail d ON d.trip_id = t.trip_id
WHERE d.trip_id IS NULL;

-- ──────────────────────────────────────────────────────────
-- 【S10 · 抽查 1/3】官方 Q1：完成行程及其支付（Trip↔Payment 1:1 join）
-- 官方 Listing 18 原文 + ORDER BY/ LIMIT 仅为截图可读性（结果集 47,758 行）
-- 预期前 3 行：trip_id 1（fare 8.33, cash）/ 2（17.55, cash）/ 4（45.77, card）
-- ──────────────────────────────────────────────────────────
SELECT t.trip_id, p.name AS passenger, t.fare, py.amount, py.method
FROM Trip t
JOIN Passenger p ON p.psg_id = t.psg_id
JOIN Payment py  ON py.trip_id = t.trip_id
WHERE t.status = 'completed'
ORDER BY t.trip_id
LIMIT 10;

-- ──────────────────────────────────────────────────────────
-- 【S11 · 抽查 2/3】官方 Q2：有完成未支付行程的司机（NOT EXISTS 反连接）
-- 全量 = 150 位司机（1,442 行未支付完成单分布在全部司机上）；
-- 展示版 LIMIT 10，左下角行数标签应显示 10 rows returned
-- ──────────────────────────────────────────────────────────
SELECT DISTINCT d.name
FROM Driver d
JOIN Trip t ON t.driver_id = d.driver_id
WHERE t.status = 'completed'
  AND NOT EXISTS (SELECT 1 FROM Payment py WHERE py.trip_id = t.trip_id)
ORDER BY d.name
LIMIT 10;

-- 附：反连接非空证据（官方 Q2 的"有结果"证明，预期 150）
SELECT COUNT(DISTINCT d.driver_id) AS unpaid_driver_count FROM Driver d
JOIN Trip t ON t.driver_id = d.driver_id
WHERE t.status = 'completed'
  AND NOT EXISTS (SELECT 1 FROM Payment py WHERE py.trip_id = t.trip_id);

-- ──────────────────────────────────────────────────────────
-- 【S12 · 抽查 3/3】q10：服务档次 × 评分统计（D-11② 口径：
-- 仅 completed 计入；有效评分=rating 非空；AVG 自动忽略 NULL）
-- 预期 4 行（ROUND 到 2 位）：
--   REGULAR  46795 行 / 均费 13.40 / 有评分 42084 / 均分 4.82
--   SUV       1793 行 / 均费 24.64 / 有评分  1619 / 均分 4.83
--   PREMIUM    465 行 / 均费 26.15 / 有评分   418 / 均分 4.75
--   LUXURY     147 行 / 均费 35.95 / 有评分   133 / 均分 4.86
-- ──────────────────────────────────────────────────────────
SELECT st.name                                    AS tier,
       COUNT(*)                                   AS completed_trips,
       ROUND(AVG(t.fare), 2)                      AS avg_fare,
       COUNT(td.rating)                           AS rated_trips,
       ROUND(AVG(td.rating), 2)                   AS avg_rating
FROM Trip t
JOIN trip_detail td  ON td.trip_id = t.trip_id
JOIN service_tier st ON st.tier_id = td.service_tier_id
WHERE t.status = 'completed'
GROUP BY st.tier_id, st.name
ORDER BY completed_trips DESC;
