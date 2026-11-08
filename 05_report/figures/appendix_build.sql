-- ============================================================
-- build.sql -- CDS534 group project, Topic 5: full database build script
-- Project: Ride-Hailing Order and Trip Dispatch database
-- (re-runnable: DROP + CREATE restores a clean, identical schema)
--
-- Usage: MySQL Workbench: open this file and execute all (lightning button),
--        or command line: mysql -u <user> -p < build.sql
--
-- Base rule: Section 1 is the official Topic 5 DDL (course handout Section 5,
-- Listing 17; only PDF layout whitespace cleaned, semantics identical). It is
-- never modified; extension tables are appended in Section 3 only.
--
-- Version: schema v1.0 (finalised 2026-11-05; ER v1.0.1 frozen and the
-- ER-DDL reconciliation closed). Structure is unchanged from v1.0-rc; only
-- comments and the version tag were updated.
--
-- Version policy: no forced upgrades; compatibility baseline = the lowest
-- registered member version (8.0.45, see env_record.md). Collation
-- utf8mb4_general_ci works on all versions. Below 8.0, CHECK constraints
-- would be silently ignored (still runs); queries avoid window functions
-- and CTEs in favour of JOIN / subquery forms.
-- Maintainer: C (implementation lead); changes must be committed to GitHub.
--
-- NOTE (display copy): this file is the appendix rendering of 02_sql/build.sql
-- with comments translated to English (report language). DDL and SQL
-- statements are byte-identical to 02_sql/build.sql (schema v1.0).
-- ============================================================

-- 0. Dedicated project database (isolated from personal schemas; group-wide name)
DROP DATABASE IF EXISTS ride_hailing;
CREATE DATABASE ride_hailing
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;
USE ride_hailing;

-- ============================================================
-- 1. Official base DDL (Listing 17, kept verbatim -- do not modify)
--    Five entities: Passenger / Vehicle / Driver / Trip / Payment
--    Key constraints: Driver.vehicle_id NOT NULL UNIQUE -- each driver is
--    bound to exactly one vehicle, and UNIQUE additionally caps each vehicle
--    at most one driver (the 1:1 on the ER diagram is maximum pairing; the
--    1:N arrow in the course figure is the business direction, unreachable
--    in practice). Payment.trip_id NOT NULL UNIQUE -- each trip has at most
--    one payment, and unpaid trips may exist (exactly what the official Q2
--    anti-join relies on).
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
-- 2. Official three queries (Listing 18-20, base verification)
--    On a fresh empty database, empty result sets already count as
--    "runs through" (syntax, constraints and joins are valid).
-- ============================================================

-- Q1 completed trips and their payments (1:1 join)
SELECT t.trip_id, p.name AS passenger, t.fare, py.amount, py.method
FROM Trip t
JOIN Passenger p ON p.psg_id = t.psg_id
JOIN Payment py  ON py.trip_id = t.trip_id
WHERE t.status = 'completed';

-- Q2 drivers of completed trips not yet paid (NOT EXISTS anti-join)
SELECT d.name
FROM Driver d
JOIN Trip t ON t.driver_id = d.driver_id
WHERE t.status = 'completed'
  AND NOT EXISTS (SELECT 1 FROM Payment py WHERE py.trip_id = t.trip_id);

-- Q3 cumulative income per vehicle
SELECT v.plate, SUM(t.fare) AS earned
FROM Vehicle v
JOIN Driver d ON d.vehicle_id = v.vehicle_id
JOIN Trip t   ON t.driver_id = d.driver_id
GROUP BY v.vehicle_id, v.plate;

-- ============================================================
-- 3. Extension zone (C3, schema v1.0; built 2026-10-25, finalised 11-05)
--    Shape per D-11 (both extensions adopted) + B4 data dictionary:
--    extension attributes live in separate tables keyed by trip_id; the
--    official five tables gain no columns (base rule).
--
--    ER cardinality <-> SQL constraint mapping:
--      ServiceTier 1-N Trip      <-> trip_detail.service_tier_id NOT NULL + FK
--      PickupZone   1-N Trip      <-> trip_detail.zone_id NOT NULL + FK
--      Trip         1-1 TripDetail <-> trip_detail.trip_id is both PK and FK
--                                      (PK-is-FK -> at most one extension row
--                                      per Trip)
--      Cardinalities inside the official five tables are unchanged (1:1 on
--      the diagram = maximum pairing; optionality is what UNIQUE encodes):
--      Vehicle 1:1 Driver via vehicle_id UNIQUE -> each vehicle has 0..1
--      drivers; Trip 1:1 Payment via trip_id UNIQUE -> each trip has 0..1
--      payments (the Q2 anti-join needs unpaid rows to exist).
--
--    Generator-side invariants (import_data.py / C4; not schema-enforced):
--      (1) every Trip has exactly one trip_detail row, cancelled rows
--          included: tier and zone are request attributes fixed at dispatch
--          (q09 counts all Trip rows per D-11 item 1);
--      (2) rating is non-NULL only for status='completed' rows (~90%
--          coverage, D-11 item 2; AVG ignores NULLs automatically). This
--          rule is cross-table semantics: a CHECK cannot reference another
--          table's column and triggers are beyond course scope, so the
--          generator guarantees it and the B4 data dictionary records it
--          (discussed in the report as a boundary of declarative constraint
--          expressiveness).
--
--    Dimension seeds (4 + 15 rows) ship with build.sql rather than the
--    import script: tier and zone names are course settings (D-11), part of
--    schema semantics rather than workload data; identical across machines
--    without Python, and visible in C5 screenshots on an empty database.
-- ============================================================

-- 3.1 Service tier dictionary (names keep RideAustin's native English terms;
--     do not translate to local ride-hailing product names)
--     Calibrated mix: REGULAR ~95.0% / SUV ~3.7% / PREMIUM ~0.9% /
--     LUXURY ~0.3% (RideAustin full-data measurement). fare_multiplier is a
--     descriptive column = measured relative multiple of mean total_fare;
--     generated fares use the four real rate cards directly (A4 section 3),
--     not this column.
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

-- 3.2 Pickup zone dictionary (course setting: ~15 zones, top-3 ~35% share;
--     spatial concentration referenced from NYC TLC; RideAustin has no zone
--     field, hence no real calibration source -- the report declares the
--     zone distribution as a course setting per D-11 item 1. Names are
--     placeholders: rename freely, keep zone_id)
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

-- 3.3 Trip extension table (1:1: PK-is-FK, at most one row per Trip; carries
--     both D-11 extensions -- service tier x rating and pickup zone -- so
--     q09/q10 each need a single JOIN)
CREATE TABLE trip_detail (
    trip_id         INT PRIMARY KEY,              -- PK-is-FK -> 1:1 with Trip
    service_tier_id TINYINT UNSIGNED NOT NULL,    -- request attribute, fixed at dispatch
    zone_id         TINYINT UNSIGNED NOT NULL,    -- pickup zone (q09 hot-zone stats)
    rating          TINYINT UNSIGNED NULL,        -- passenger rates driver, 1-5 stars;
                                                   -- non-NULL only for completed rows (~90%)
    FOREIGN KEY (trip_id)         REFERENCES Trip (trip_id),
    FOREIGN KEY (service_tier_id) REFERENCES service_tier (tier_id),
    FOREIGN KEY (zone_id)         REFERENCES pickup_zone (zone_id),
    CONSTRAINT chk_rating CHECK (rating BETWEEN 1 AND 5)
);

-- ============================================================
-- 4. Self-check (for screenshots): version + table list + row counts
-- ============================================================
SELECT VERSION() AS mysql_version;
SHOW TABLES;
-- Row counts right after this script (before data import): base five
-- tables = 0; dimension tables already seeded = service_tier 4 /
-- pickup_zone 15; trip_detail is generated together with Trip by C4 = 0.
SELECT 'Passenger'   AS tbl, COUNT(*) AS rows_ FROM Passenger
UNION ALL SELECT 'Vehicle',      COUNT(*) FROM Vehicle
UNION ALL SELECT 'Driver',       COUNT(*) FROM Driver
UNION ALL SELECT 'Trip',         COUNT(*) FROM Trip
UNION ALL SELECT 'Payment',      COUNT(*) FROM Payment
UNION ALL SELECT 'service_tier', COUNT(*) FROM service_tier
UNION ALL SELECT 'pickup_zone',  COUNT(*) FROM pickup_zone
UNION ALL SELECT 'trip_detail',  COUNT(*) FROM trip_detail;
