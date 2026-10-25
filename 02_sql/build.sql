-- ============================================================
-- build.sql — CDS534 小组项目 Topic 5 底座建库脚本（可重复执行）
-- 项目：Ride-Hailing Order & Trip Dispatch（网约车订单与派单数据库）
--
-- 用法：Workbench 打开本文件 → 整体执行（闪电按钮）
--       或命令行：mysql -u <user> -p < build.sql
-- 重建：先 DROP DATABASE 再 CREATE，任何脏状态一键复原（每人日常
--       git pull 后重跑本文件即可得到与他人一致的库）
--
-- ⚠️ 底座铁律：第 1 节为官方 Topic 5 DDL（作业文件 Section 5
--    Listing 17，仅清理了 PDF 排版空格，语义与官方完全一致），
--    永不修改；扩展表一律追加到第 3 节扩展区。
--
-- ⚠️ 版本：schema v1.0-rc（C3 · 2026-10-25）——第 3 节扩展区落地
--    三表（service_tier / pickup_zone / trip_detail），待 B4 ER v1.0
--    冻结对账确认后转正；确认前扩展区结构可能随 B4 微调，底座区
--    不受影响。
--
-- ⚠️ 版本策略：不强制升级，以组内登记的最低版本为兼容基线
--    （见 01_docs/env_record.md）。collation 用 utf8mb4_general_ci，
--    全版本通用。若基线低于 8.0：CHECK 约束会被静默忽略（不报错，
--    不影响跑通）；查询避免窗口函数/CTE，改用 JOIN/子查询写法。
-- 维护：C（实现与平台负责人），改动须 commit 到 GitHub
-- ============================================================

-- 0. 项目专用库（与个人其他 schema 完全隔离；全组统一库名）
DROP DATABASE IF EXISTS ride_hailing;
CREATE DATABASE ride_hailing
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;
USE ride_hailing;

-- ============================================================
-- 1. 官方底座 DDL（Listing 17，原样保留，勿改）
--    五实体：Passenger / Vehicle / Driver / Trip / Payment
--    关键约束：Driver.vehicle_id UNIQUE（司机绑一车 N:1）
--             Payment.trip_id   UNIQUE（行程↔支付 1:1）
-- ============================================================

CREATE TABLE Passenger (
    psg_id INT PRIMARY KEY,
    name   VARCHAR(40) NOT NULL
);

CREATE TABLE Vehicle (
    vehicle_id INT PRIMARY KEY,
    plate      VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE Driver (
    driver_id  INT PRIMARY KEY,
    name       VARCHAR(40) NOT NULL,
    vehicle_id INT NOT NULL UNIQUE,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicle (vehicle_id)
);

CREATE TABLE Trip (
    trip_id    INT PRIMARY KEY,
    psg_id     INT NOT NULL,
    driver_id  INT NOT NULL,
    fare       DECIMAL(8,2),
    status     VARCHAR(20),
    start_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (psg_id)    REFERENCES Passenger (psg_id),
    FOREIGN KEY (driver_id) REFERENCES Driver (driver_id)
);

CREATE TABLE Payment (
    pay_id  INT PRIMARY KEY,
    trip_id INT NOT NULL UNIQUE,
    amount  DECIMAL(8,2) CHECK (amount >= 0),
    method  VARCHAR(20),
    FOREIGN KEY (trip_id) REFERENCES Trip (trip_id)
);

-- ============================================================
-- 2. 官方三条查询（Listing 18–20，底座验证用）
--    空表执行返回空结果集即算"跑通"（证明语法/约束/连接无误）
-- ============================================================

-- Q1 完成行程及其支付（1:1 join）
SELECT t.trip_id, p.name AS passenger, t.fare, py.amount, py.method
FROM Trip t
JOIN Passenger p ON p.psg_id = t.psg_id
JOIN Payment py  ON py.trip_id = t.trip_id
WHERE t.status = 'completed';

-- Q2 完成行程但尚未获得支付的司机（NOT EXISTS 反连接）
SELECT d.name
FROM Driver d
JOIN Trip t ON t.driver_id = d.driver_id
WHERE t.status = 'completed'
  AND NOT EXISTS (SELECT 1 FROM Payment py WHERE py.trip_id = t.trip_id);

-- Q3 每辆车累计收入
SELECT v.plate, SUM(t.fare) AS earned
FROM Vehicle v
JOIN Driver d ON d.vehicle_id = v.vehicle_id
JOIN Trip t   ON t.driver_id = d.driver_id
GROUP BY v.vehicle_id, v.plate;

-- ============================================================
-- 3. 扩展区（C3 · schema v1.0-rc，2026-10-25；待 B4 ER v1.0 冻结对账确认）
--    形态依据：D-11（两项扩展都采）+ B4 数据字典草案 §7——扩展属性走
--    以 trip_id 关联的独立表，官方五表不增列（底座铁律）。
--
--    ER 基数 ↔ SQL 约束映射（C3 验收："外键/唯一约束与 B 的基数
--    一一对应"；概念基数 vs SQL 约束的辨析口径同 B2 对照记录）：
--      ServiceTier 1 ─ N Trip  ↔ trip_detail.service_tier_id NOT NULL + FK
--      PickupZone   1 ─ N Trip  ↔ trip_detail.zone_id         NOT NULL + FK
--      Trip         1 ─ 1 TripDetail ↔ trip_detail.trip_id 即 PK 又是 FK
--                                    （主键即外键 → 每 Trip 至多一行扩展）
--      官方五表内部基数不变：Vehicle 1─N Driver 由 Driver.vehicle_id
--      UNIQUE 实现到"至多一"；Trip 1─1 Payment 由 Payment.trip_id UNIQUE
--      实现（0..1，Q2 反连接需要无支付行存在，见 B2 记录 caveat 2）
--
--    生成器侧不变量（import_data.py / C4 保证，schema 不强制）：
--      ① 每 Trip 恰一行 trip_detail（含取消行：档次/区位是请求属性，
--         接单时已确定；q09 按 D-11①"已接单口径"统计全部 Trip 行）
--      ② rating 仅 Trip.status='completed' 行非 NULL（覆盖率 ≈90%，
--         D-11②；有效评分 = rating IS NOT NULL，AVG 自动忽略 NULL）。
--         该规则是跨表语义：CHECK 无法引用他表列、触发器超出课程
--         范围，故由生成器保证并在 B4 数据字典记载（报告可作为
--         "约束表达能力边界"的讨论点）。
--
--    维度表 seed（4+15 行）随 build.sql 下发而非导入脚本：档名/区名是
--    课程设定（见 D-11、A4 §三 v1.2.1），属 schema 语义而非工作负载数据，
--    五机一致不依赖 Python，C5 截图时空库即可见行数。
-- ============================================================

-- 3.1 服务档次字典（档名保留 RideAustin 原生英文名，勿直译"快车/专车"）
--     占比标定：REGULAR ≈95.0% / SUV ≈3.7% / PREMIUM ≈0.9% / LUXURY ≈0.3%
--     （A4 §三，RideAustin 全量实测）。fare_multiplier 为描述列 =
--     按 total_fare 均值口径的实测相对倍数（a4_rideaustin_profile §六），
--     生成车费直接用四档真实费率（A4 §三），不经此列计算。
CREATE TABLE service_tier (
    tier_id          TINYINT UNSIGNED PRIMARY KEY,
    name             VARCHAR(16)  NOT NULL UNIQUE,
    fare_multiplier  DECIMAL(3,1) NOT NULL
);

INSERT INTO service_tier (tier_id, name, fare_multiplier) VALUES
    (1, 'REGULAR', 1.0),
    (2, 'SUV',     1.9),
    (3, 'PREMIUM', 2.1),
    (4, 'LUXURY',  2.7);

-- 3.2 上车区域字典（课程设定：约 15 区、头部集中 top3 ≈35%，空间集中
--     度参照 NYC TLC；RideAustin 无区位字段、无真实标定源，报告如实
--     声明"区位分布为课程设定"——D-11①、A4 §三 v1.2.1。区名为占位，
--     B4 冻结时可改名、勿改 zone_id）
CREATE TABLE pickup_zone (
    zone_id  TINYINT UNSIGNED PRIMARY KEY,
    name     VARCHAR(32) NOT NULL UNIQUE
);

INSERT INTO pickup_zone (zone_id, name) VALUES
    (1,  'Downtown'),
    (2,  'East Austin'),
    (3,  'South Congress'),
    (4,  'South Lamar'),
    (5,  'West Campus'),
    (6,  'Riverside'),
    (7,  'Hyde Park'),
    (8,  'Mueller'),
    (9,  'Airport'),
    (10, 'North Loop'),
    (11, 'Crestview'),
    (12, 'Cherrywood'),
    (13, 'Barton Hills'),
    (14, 'Zilker'),
    (15, 'Tarrytown');

-- 3.3 行程扩展表（1:1：主键即外键，每 Trip 至多一行；单表承载 D-11
--     两项扩展——②服务档次×评分 + ①上车区位；q09/q10 各只需一个 JOIN）
CREATE TABLE trip_detail (
    trip_id         INT PRIMARY KEY,              -- 主键即外键 → Trip 1:1
    service_tier_id TINYINT UNSIGNED NOT NULL,    -- 请求属性，接单时已确定
    zone_id         TINYINT UNSIGNED NOT NULL,    -- 上车区位（q09 热区统计）
    rating          TINYINT UNSIGNED NULL,        -- 乘客评司机 1–5 星，仅
                                                   -- completed 行有值 ≈90%
    FOREIGN KEY (trip_id)         REFERENCES Trip (trip_id),
    FOREIGN KEY (service_tier_id) REFERENCES service_tier (tier_id),
    FOREIGN KEY (zone_id)         REFERENCES pickup_zone (zone_id),
    CONSTRAINT chk_rating CHECK (rating BETWEEN 1 AND 5)
);

-- ============================================================
-- 4. 自检（截图用）：版本 + 表清单 + 各表行数
-- ============================================================
SELECT VERSION() AS mysql_version;
SHOW TABLES;
-- 各表行数（底座阶段应为 0）
SELECT 'Passenger' AS tbl, COUNT(*) AS rows_ FROM Passenger
UNION ALL SELECT 'Vehicle',  COUNT(*) FROM Vehicle
UNION ALL SELECT 'Driver',   COUNT(*) FROM Driver
UNION ALL SELECT 'Trip',     COUNT(*) FROM Trip
UNION ALL SELECT 'Payment',  COUNT(*) FROM Payment;
