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
-- ⚠️ 版本要求：MySQL 8.0+（utf8mb4_0900_ai_ci 排序规则为 8.0 特有，
--    若报 Unknown collation 说明服务器是 5.7，需先升级）
-- 维护：C（实现与平台负责人），改动须 commit 到 GitHub
-- ============================================================

-- 0. 项目专用库（与个人其他 schema 完全隔离；全组统一库名）
DROP DATABASE IF EXISTS ride_hailing;
CREATE DATABASE ride_hailing
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
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
-- 3. 扩展区（C3 起在此追加扩展表 DDL，如车型表/服务区域表/司机评分表；
--    以 10-21（M1）B4 冻结的 ER v1.0 为准；底座永不修改）
-- ============================================================
-- （暂无）

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
