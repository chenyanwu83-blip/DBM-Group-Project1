-- ============================================================
-- c5_shots_session_1101.sql — C5 截图会话脚本 · Workbench「SQL File 3」逐字存档
-- 执行人：C · 会话日 2026-11-01 · 产出 21 张 C5 验收截图（ddl/ 17 张 + queries/ 4 张）
--
-- 来源：Workbench 未保存标签页 SQL File 3* 的自动暂存
-- （sql_workspaces/Local_instance_3306-1.autosave），本头部注释之外，
-- 正文语句与标签页逐字一致，未做任何美化或改写——
-- 截图里出现的每一条 SQL（含 S10/S11 的 ORDER BY … LIMIT 10、
-- S11 的 COUNT(DISTINCT d.driver_id) 计数变体）都能在本文件找到出处。
--
-- 与既有脚本的关系（三者互补，非重复）：
--   · S01–S08 整理版（含预期行数注释）→ 02_sql/c5_shots_s01_s08.sql
--   · S09 段 = 02_sql/c5_check.sql 第一段（8 表 UNION 原文相同）
--   · S10–S12 无 LIMIT 变体 → 02_sql/c5_check.sql；本文件是"实际执行版"
--
-- 判读基准（seed=534，任何机器一致）：
--   S01–S08 COUNT = 3000/150/150/60000/51398/4/15/60000
--   S09 总表 8 行同上 · S10 首行 trip 1/Justin Lewis/8.33/cash
--   S11 名单 10 行 + unpaid_driver_count = 150
--   S12 四档 REGULAR 46795/13.40/4.82 · SUV 1793/24.64/4.83
--        PREMIUM 465/26.15/4.75 · LUXURY 147/35.95/4.86
-- ============================================================

# S01 — Passenger 结构 + 行数
USE ride_hailing;
  SHOW CREATE TABLE Passenger;
  SELECT COUNT(*) FROM Passenger;

# S02 — Vehicle
SHOW CREATE TABLE Vehicle;
SELECT COUNT(*) FROM Vehicle;

# S03 — Driver
SHOW CREATE TABLE Driver;
SELECT COUNT(*) FROM Driver;

# S04 - Trip
SHOW CREATE TABLE Trip;
SELECT COUNT(*) FROM Trip;

# S05 - Payment
SHOW CREATE TABLE Payment;
SELECT COUNT(*) FROM Payment;

# S06 — service_tier（扩展表）
SHOW CREATE TABLE service_tier;
SELECT COUNT(*) FROM service_tier;

# S07 — pickup_zone（扩展表）
SHOW CREATE TABLE pickup_zone;
SELECT COUNT(*) FROM pickup_zone;

# S08 — trip_detail（扩展表，核心）
SHOW CREATE TABLE trip_detail;
SELECT COUNT(*) FROM trip_detail;

# S09 — 8 表行数总表
SELECT 'Passenger'   AS tbl, COUNT(*) AS rows_ FROM Passenger
UNION ALL SELECT 'Vehicle',      COUNT(*) FROM Vehicle
UNION ALL SELECT 'Driver',       COUNT(*) FROM Driver
UNION ALL SELECT 'Trip',         COUNT(*) FROM Trip
UNION ALL SELECT 'Payment',      COUNT(*) FROM Payment
UNION ALL SELECT 'service_tier', COUNT(*) FROM service_tier
UNION ALL SELECT 'pickup_zone',  COUNT(*) FROM pickup_zone
UNION ALL SELECT 'trip_detail',  COUNT(*) FROM trip_detail;

# S10 — 抽查① 官方 Q1：完成行程及其支付
SELECT t.trip_id, p.name AS passenger, t.fare, py.amount, py.method
FROM Trip t
JOIN Passenger p ON p.psg_id = t.psg_id
JOIN Payment py  ON py.trip_id = t.trip_id
WHERE t.status = 'completed'
ORDER BY t.trip_id
LIMIT 10;

# S11 — 抽查② 官方 Q2：完成未支付的司机（反连接）
SELECT DISTINCT d.name
FROM Driver d
JOIN Trip t ON t.driver_id = d.driver_id
WHERE t.status = 'completed'
  AND NOT EXISTS (SELECT 1 FROM Payment py WHERE py.trip_id = t.trip_id)
ORDER BY d.name
LIMIT 10;

SELECT COUNT(DISTINCT d.driver_id) AS unpaid_driver_count FROM Driver d
JOIN Trip t ON t.driver_id = d.driver_id
WHERE t.status = 'completed'
  AND NOT EXISTS (SELECT 1 FROM Payment py WHERE py.trip_id = t.trip_id);

# S12 — 抽查③ q10：档次 × 评分
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
