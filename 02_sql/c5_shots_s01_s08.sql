-- ============================================================
-- c5_shots_s01_s08.sql — C5 验收截图 S01–S08 语句固化（配套脚本）
-- 执行人：C · 拍摄日 2026-11-01 · Workbench 逐条执行后截图
--
-- 用途：C5 验收清单（03_data/screenshots/C5_验收清单_1026.md）S01–S08
--      的每表两句（SHOW CREATE + COUNT）在此落盘，满足"改表=改脚本"
--      纪律——截图里出现的每条语句都能在本仓库找到出处。
--      S09–S12 的语句在 02_sql/c5_check.sql，不在此重复。
--
-- 用法：USE ride_hailing; 后逐段执行；每段两句一起跑，
--      Action Output 出两条绿灯 + Result Grid 数字与注释预期一致。
--      截图两两成对：_a 结构（SHOW CREATE 全文）/ _b 行数（COUNT+绿灯）。
--
-- 预期行数（seed=534，任何机器复现必须一致，见 build.sql §4）：
--   Passenger 3000 / Vehicle 150 / Driver 150 / Trip 60000
--   Payment 51398 / service_tier 4 / pickup_zone 15 / trip_detail 60000
-- ============================================================

USE ride_hailing;

-- S01 — Passenger（官方底座表）→ ddl_passenger_1101_a.png / _b.png，预期 3000
SHOW CREATE TABLE Passenger;
SELECT COUNT(*) FROM Passenger;   -- 3000

-- S02 — Vehicle（官方底座表，plate UNIQUE）→ ddl_vehicle_1101_a/_b.png，预期 150
SHOW CREATE TABLE Vehicle;
SELECT COUNT(*) FROM Vehicle;     -- 150

-- S03 — Driver（官方底座表，vehicle_id NOT NULL UNIQUE + FK→Vehicle）
SHOW CREATE TABLE Driver;         -- → ddl_driver_1101_a/_b.png，预期 150
SELECT COUNT(*) FROM Driver;      -- 150

-- S04 — Trip（官方底座表，FK→Passenger/Driver；fare/status 官方原样无约束）
SHOW CREATE TABLE Trip;           -- → ddl_trip_1101_a/_b.png，预期 60000
SELECT COUNT(*) FROM Trip;        -- 60000（≥5 万行要求的证明）

-- S05 — Payment（官方底座表，trip_id NOT NULL UNIQUE、CHECK amount>=0）
SHOW CREATE TABLE Payment;        -- → ddl_payment_1101_a/_b.png，预期 51398
SELECT COUNT(*) FROM Payment;     -- 51398

-- S06 — service_tier（C3 扩展·维度表，4 档 seed 随 build.sql 下发）
SHOW CREATE TABLE service_tier;   -- → ddl_service_tier_1101_a/_b.png，预期 4
SELECT COUNT(*) FROM service_tier;-- 4

-- S07 — pickup_zone（C3 扩展·维度表，name UNIQUE，15 区）
SHOW CREATE TABLE pickup_zone;    -- → ddl_pickup_zone_1101_a/_b.png，预期 15
SELECT COUNT(*) FROM pickup_zone; -- 15

-- S08 — trip_detail（C3 扩展·事实表，主键即外键 1:1 于 Trip，rating CHECK 1–5）
SHOW CREATE TABLE trip_detail;    -- → ddl_trip_detail_1101_a/_b.png，预期 60000
SELECT COUNT(*) FROM trip_detail; -- 60000
