-- ============================================================
-- exp_index.sql — C6 实验支撑 · 实验一（索引前后）+ 实验二（JOIN vs 子查询）
-- 负责人：C · 对齐 1030_M3 冻结实验 ①②，报告 §5（D 主笔、C 供数据）
--
-- 前置条件：build.sql + data_import.sql 已执行
--   （自检：SELECT COUNT(*) FROM Trip; = 60000）
--
-- ── EXPLAIN 采集方法（Workbench）──────────────────────────
-- 1. 逐段执行本脚本；每个 EXPLAIN 的 Result Grid 即采集对象；
-- 2. 本机 MySQL 8.0+/26.x 默认 EXPLAIN 输出"树形计划"（缩进算子树），
--    看耗时与算子很直观；但课程概念题讲的是"传统列视图"——
--    加 FORMAT=TRADITIONAL 才出 type/key/rows 等五列，本脚本统一用它；
-- 3. 传统视图重点读 5 列：
--    type    访问类型：ALL=全表扫描 / index=整条索引顺序扫 / range=索引范围
--                     / ref=索引等值 / eq_ref=唯一索引单行
--    key     实际用到的索引（NULL=没用上）
--    rows    优化器估算要读的行数（越小越好）
--    filtered  经 WHERE 再过滤后剩余比例
--    Extra   附加动作（Using where / Using index=覆盖索引 / Not exists=反连接）
-- 4. EXPLAIN 只给"计划"；EXPLAIN ANALYZE 才真正执行并给"实际耗时"
--    （actual time=…，本机基线 16.6ms vs 建索引后 0.46ms，
--     G2 的 P95<200ms 亦用此法取数）；
-- 5. 截图规范（C2 C 类证据）：前后成对两张——
--    exp_index_before_MMDD.png / exp_index_after_MMDD.png，
--    除索引外其余环境相同（同库同数据同语句），不裁 Output 面板。
--
-- ── 复原保证 ─────────────────────────────────────────────
-- 本脚本改动数据库的唯一动作是"建一个索引再删掉"（§1.4 / §1.8），
-- 结束后 Trip 恢复为 3 个索引（PRIMARY/psg_id/driver_id），数据零改动。
-- ============================================================

USE ride_hailing;

-- ============================================================
-- 实验一 · 索引前后：同一查询，建索引前 vs 建索引后
-- 载体：D 的 q05 WHERE 前半（status 等值 + start_time 范围）
-- ============================================================

-- 1.0 环境确认：Trip 现有索引（应只有 3 条：PRIMARY/psg_id/driver_id，FK 自动建）
SHOW INDEX FROM Trip;

-- 1.1 目标查询（本实验反复使用同一条，保证前后可比）
--     业务含义：2026-10 起完成的行程数
SELECT COUNT(*) FROM Trip
WHERE status = 'completed' AND start_time >= '2026-10-01';
--     （seed=534 实测 = 3259）

-- 1.2 【建索引前 · 基线】EXPLAIN —— 采图 exp_index_before_MMDD.png
--     实测判读（2026-11-01 本机）：type=ALL、key=NULL、rows=60261（≈全表 6 万行）
EXPLAIN FORMAT=TRADITIONAL SELECT COUNT(*) FROM Trip
WHERE status = 'completed' AND start_time >= '2026-10-01';

-- 1.3 基线实际耗时（真正执行一遍，记录毫秒数，供报告 §5 对比表）
--     实测：actual time ≈ 16.6 ms（Table scan on Trip 读 60000 行）
EXPLAIN ANALYZE SELECT COUNT(*) FROM Trip
WHERE status = 'completed' AND start_time >= '2026-10-01';

-- 1.4 建复合索引（最左前缀：status 等值在前，start_time 范围在后）
CREATE INDEX idx_trip_status_time ON Trip (status, start_time);

-- 1.5 【建索引后】EXPLAIN —— 采图 exp_index_after_MMDD.png
--     实测判读：type=range、key=idx_trip_status_time、rows=3259（60261→3259 骤降），
--     Extra 含 Using index = 覆盖索引（连回表都不用）
EXPLAIN FORMAT=TRADITIONAL SELECT COUNT(*) FROM Trip
WHERE status = 'completed' AND start_time >= '2026-10-01';

-- 1.6 建索引后实际耗时（与 1.3 对比，毫秒数写进报告）
--     实测：actual time ≈ 0.46 ms（覆盖索引 range scan，约 36 倍提升）
EXPLAIN ANALYZE SELECT COUNT(*) FROM Trip
WHERE status = 'completed' AND start_time >= '2026-10-01';

-- 1.7 反例：函数包住索引列（non-sargable），范围访问"用不上"
--     1.7a DATE() 包列 → type=index：整条索引顺序扫 6 万条，range 退化
--         （注意不是"完全不用索引"，而是退化为全量顺序读——一样慢）
EXPLAIN FORMAT=TRADITIONAL SELECT COUNT(*) FROM Trip
WHERE DATE(start_time) = '2026-10-15';
--     1.7b 改写为半开区间 → 立刻回到 type=range（rows≈6694，
--         本机还能看到 Using index for skip scan：不带最左列 status 时的补救）
EXPLAIN FORMAT=TRADITIONAL SELECT COUNT(*) FROM Trip
WHERE start_time >= '2026-10-15' AND start_time < '2026-10-16';
--     （q06 的 GROUP BY HOUR(start_time) 同理：聚合函数包列，只配全量扫；
--       按“小时”过滤时改写成 HOUR 范围的双边界区间才能吃索引。）

-- 1.8 复原：删索引，回到实验前状态（再跑 SHOW INDEX 应回到 3 条）
DROP INDEX idx_trip_status_time ON Trip;
SHOW INDEX FROM Trip;

-- ============================================================
-- 实验二 · JOIN vs 子查询：同一问题三种写法，EXPLAIN 计划对比
-- 载体：D 的 q05 反连接——"完成但未支付"的行程数（联动概念题 Q4）
-- ============================================================

-- 2.1 写法甲：NOT EXISTS（反连接的标准写法）
SELECT COUNT(*) FROM Trip t
WHERE t.status = 'completed'
      AND NOT EXISTS (SELECT 1 FROM Payment p WHERE p.trip_id = t.trip_id);

-- 2.2 写法乙：NOT IN 子查询
SELECT COUNT(*) FROM Trip t
WHERE t.status = 'completed'
      AND t.trip_id NOT IN (SELECT trip_id FROM Payment);
--     注意：NOT IN 的安全前提是子查询列 NOT NULL（Payment.trip_id 恰好
--     NOT NULL；若含 NULL，NOT IN 会一行都不返回——课堂经典坑，报告 Q4 提及）

-- 2.3 写法丙：LEFT JOIN … IS NULL（老式反连接）
SELECT COUNT(*) FROM Trip t
LEFT JOIN Payment p ON p.trip_id = t.trip_id
WHERE t.status = 'completed' AND p.pay_id IS NULL;

-- 2.4 三写法 EXPLAIN 对比（三张 Result Grid 连续采集，或分别截图拼对照）
--     实测判读（2026-11-01 本机）：甲/乙计划完全一致——
--     Trip 全扫（type=ALL）+ Payment 走 trip_id 唯一索引（type=eq_ref，1 行/趟），
--     Extra 同现 "Not exists; Using index" = 优化器把两种子查询都改写成了反连接；
--     丙（LEFT JOIN…IS NULL）同型，仅 p 侧 filtered=10% 有差。
--     重点比较：访问类型、第二行的 key=trip_id、读行数。
EXPLAIN FORMAT=TRADITIONAL SELECT COUNT(*) FROM Trip t
WHERE t.status = 'completed'
      AND NOT EXISTS (SELECT 1 FROM Payment p WHERE p.trip_id = t.trip_id);

EXPLAIN FORMAT=TRADITIONAL SELECT COUNT(*) FROM Trip t
WHERE t.status = 'completed'
      AND t.trip_id NOT IN (SELECT trip_id FROM Payment);

EXPLAIN FORMAT=TRADITIONAL SELECT COUNT(*) FROM Trip t
LEFT JOIN Payment p ON p.trip_id = t.trip_id
WHERE t.status = 'completed' AND p.pay_id IS NULL;

-- 2.5 结论判读（写进报告 §5 / 概念题 Q4 答案）：
--     三种写法结果一致（实测均 = 1442 条完成未支付行程）；
--     现代优化器把 NOT EXISTS 与 NOT IN 改写成同一个反连接计划（Extra: Not exists），
--     LEFT JOIN…IS NULL 也走相近代价——"JOIN vs 子查询"没有绝对赢家，
--     语义正确（NOT IN 的 NULL 陷阱）+ EXPLAIN 验证 才是选型依据。
