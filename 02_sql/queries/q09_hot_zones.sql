-- Q9: Hot Zones by Accepted Trips (accepted-trip basis, per D-11)
-- 业务问题: 哪些区域已接单量最大（空间维度的运力分布）
-- 涉及表: Trip, trip_detail, pickup_zone（实际 DDL = build.sql §3.2/§3.3，C3 2026-10-25）
--   结构：trip_detail 1:1 于 Trip（主键即外键），zone_id → pickup_zone
-- 口径红线(D-11)：已接单口径 = 全部 Trip 行计数（含接单后取消；档次/区位是请求属性，接单时已确定）；
--   结论只能答"哪里已接单最多"，不得推出"哪里最缺司机"（无司机接单的请求不生成 Trip，进 §6 局限）
-- 预期(C4 标定): 15 区，头部集中 top3 ≈ 35.0%；区位分布为课程设定（无真实标定源，报告如实声明）
-- 状态: 待 C4 数据验证（验证前核对 trip_detail 行数 = Trip 行数 = 60,000）
SELECT z.zone_id,
       z.name,
       COUNT(*) AS accepted_trips          -- 已接单口径：含接单后取消的行
FROM   Trip t
       JOIN trip_detail td ON td.trip_id = t.trip_id
       JOIN pickup_zone z  ON z.zone_id   = td.zone_id
GROUP  BY z.zone_id, z.name
ORDER  BY accepted_trips DESC
LIMIT  15;
