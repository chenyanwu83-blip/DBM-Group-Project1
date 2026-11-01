-- ============================================================
-- exp_concurrency.sql — C6 实验支撑 · 实验三（双会话并发事务）+ G5（约束拦截）
-- 负责人：C · 对齐 1030_M3 冻结实验 ③，报告 §5（D 主笔、C 供数据）
--
-- ── 操作编排：Workbench 开两个查询标签页 = 两个独立连接 ──
--   标签 A、标签 B 都连本地 ride_hailing（同一个库）；
--   严格按脚本里的 A/B 步序交替执行——并发实验的全部意义在"顺序"，
--   跳步或同标签执行就变成了单会话，现象不会出现。
--   每步注释里写明【预期现象】，截图时机也标注在对应步骤：
--     exp_conc_lost_update_MMDD.png（场景① B2+A3 同框或先后两张）
--     exp_conc_lock_MMDD.png       （场景② B4 阻塞转圈 + 放行后 B5）
--     exp_conc_isolation_MMDD.png  （场景③ A8 与 A9 两次读数对比）
--     exp_g5_fk_1452_MMDD.png / exp_g5_dup_1062_MMDD.png /
--     exp_g5_check_3819_MMDD.png   （G5 三张报错）
--
-- ── 数据安全 ──
--   场景①②③ 只动 trip_detail 的 trip_id=92/150 两行 rating（第 0 步自检其
--   初值必须 =3），收尾统一还原；G5 的三条写语句全部被约束拦下，零落库。
--
-- ── 为什么演示行要挑 rating=3 的行（真机踩坑 2026-11-01）──
--   最初用 trip_id=1（rating=5）演示，场景①的 @a+1 = 6 直接撞
--   CHECK chk_rating（1–5）报 Error 3819——反证了 G5-c 的 CHECK 拦截，
--   但打断并发主线。故改用 rating=3 的行：+1/-1 都在界内。
--   trip_id=92/150 在 seed=534 下全网一致，若你的库不是 3，先重导数据。
-- ============================================================

USE ride_hailing;

-- 0. 基线自检：两行 rating 都必须 = 3（否则数据版本不对，先重跑 build+import）
SELECT trip_id, rating FROM trip_detail WHERE trip_id IN (92, 150);

-- ============================================================
-- 场景① 丢失更新（lost update）：两事务"各自读旧值→各自写回"，后写覆盖先写
-- 复现手法：用各自会话的变量把读到的值"搬运"进 UPDATE——
--           应用层"读-算-写"（SELECT 后再 UPDATE 常量）正是这么丢数据的
-- 业务类比：A 给行程 +1 星（改好评），B 同时 -1 星（改差评），
--           两边都基于同一份旧评分计算，后提交的一方抹掉先提交的一方
-- ============================================================
-- A1. 开事务，把当前值读进 A 会话变量 @a（读到 3）
START TRANSACTION;
SELECT rating INTO @a FROM trip_detail WHERE trip_id = 92;
SELECT @a;
-- B1. （切到标签 B）同样读——普通快照读不加锁，B 畅通无阻也读到 3
START TRANSACTION;
SELECT rating INTO @b FROM trip_detail WHERE trip_id = 92;
SELECT @b;
-- A2. A 写回 3+1=4 并提交（库里此刻 = 4）
UPDATE trip_detail SET rating = @a + 1 WHERE trip_id = 92;
COMMIT;
-- B2. B 基于手里的旧值 3 写回 3-1=2 并提交 → A 的 4 被整行覆盖
UPDATE trip_detail SET rating = @b - 1 WHERE trip_id = 92;
COMMIT;
-- A3. 验证：结果 = 2。A 明明提交成功，+1 却凭空消失——这就是丢失更新
--     —— 截图 exp_conc_lost_update_MMDD.png（B2 的"1 row affected" + 本句结果）
SELECT trip_id, rating FROM trip_detail WHERE trip_id = 92;
-- 【预期】= 2（A2/B2 两条 UPDATE 都报成功是关键迷惑点）

-- ============================================================
-- 场景② 悲观锁修复：SELECT … FOR UPDATE 让 B 排队，不再丢
-- ============================================================
-- A4. A 锁定该行（FOR UPDATE 排他锁）
START TRANSACTION;
SELECT rating FROM trip_detail WHERE trip_id = 92 FOR UPDATE;
-- B4. B 同样 FOR UPDATE → 【预期】B 卡住转圈（等 A 释放行锁）
--     ⚠️ A 必须在 innodb_lock_wait_timeout（默认 50s）内走完 A5，
--     否则 B 报 Error 1205 lock wait timeout（那也是有效证据，但建议重跑）
--     —— B 卡住时截图 exp_conc_lock_MMDD.png 第一张
START TRANSACTION;
SELECT rating FROM trip_detail WHERE trip_id = 92 FOR UPDATE;
-- A5. A 加 1 并提交（锁释放，B 立刻被放行）
UPDATE trip_detail SET rating = rating + 1 WHERE trip_id = 92;
COMMIT;
-- B5. B 拿到锁后读到的是 A 提交后的新值（FOR UPDATE 是"当前读"），再 +1
UPDATE trip_detail SET rating = rating + 1 WHERE trip_id = 92;
COMMIT;
-- A6. 验证：两次 +1 全部生效——截图 exp_conc_lock_MMDD.png 第二张
SELECT trip_id, rating FROM trip_detail WHERE trip_id = 92;
-- 【预期】= 4（场景①结束值 2 → 3 → 4，一步不丢）

-- ============================================================
-- 场景③ 隔离级别：REPEATABLE READ（默认） vs READ COMMITTED
-- 同一事务内两次读，别人提交的修改能不能"看见"（联动概念题 Q5/Q6）
-- 演示行换 trip_id=150（rating=3），与场景①②互不干扰
-- ============================================================
-- A7. RR 级别（默认），开事务先读（记为 R0=3）
START TRANSACTION;
SELECT rating FROM trip_detail WHERE trip_id = 150;
-- B7. B 直接改并提交（自动提交单语句）：3 → 5
UPDATE trip_detail SET rating = 5 WHERE trip_id = 150;
-- A8. A 不结束事务，同一事务内再读——【预期 RR】仍是 3（快照读）
SELECT rating FROM trip_detail WHERE trip_id = 150;
COMMIT;
-- 截图 exp_conc_isolation_MMDD.png 第一张（A7=3 与 A8=3 同框，B7 夹在中间）
-- A9. 换 READ COMMITTED 重演（先读、B 改、再读）
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT rating FROM trip_detail WHERE trip_id = 150;   -- R1（此刻 = B7 提交的 5）
-- B9. （切 B）UPDATE trip_detail SET rating = 3 WHERE trip_id = 150;  执行后回 A
SELECT rating FROM trip_detail WHERE trip_id = 150;   -- 【预期 RC】= 3（能看见已提交的新值）
COMMIT;
-- 截图 exp_conc_isolation_MMDD.png 第二张（RC 下两读不同）
-- A10. 恢复默认隔离级别（SET SESSION 只影响本会话，保险起见仍显式改回）
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- ============================================================
-- G5 · 约束拦截证据：错误码本身就是"约束在守门"的证明（三张截图）
-- ============================================================
-- G5-a 外键拦截：给不存在的行程写明细 → Error 1452
-- 【预期】ERROR 1452: Cannot add or update a child row: a foreign key
--         constraint fails（trip_detail 的 trip_id → Trip.trip_id）
--         —— 截图 exp_g5_fk_1452_MMDD.png（红色报错 + 语句同框）
INSERT INTO trip_detail (trip_id, service_tier_id, zone_id, rating)
VALUES (999999, 1, 1, 5);

-- G5-b 唯一键拦截：同一行程付两次款 → Error 1062
-- （trip_id=1 已有支付记录，q01 首行即它；pay_id 取远离现有区间的 987654 避免主键干扰）
-- 【预期】ERROR 1062: Duplicate entry '1' for key 'trip_id'
--         —— 截图 exp_g5_dup_1062_MMDD.png
INSERT INTO Payment (pay_id, trip_id, amount, method)
VALUES (987654, 1, 9.99, 'cash');

-- G5-c CHECK 拦截：评分越界（合法行改 9 分）→ Error 3819
-- （这条是 11-01 真机踩坑时"意外抓到"的证据：CHECK 不只管 INSERT 也管 UPDATE）
-- 【预期】ERROR 3819: Check constraint 'chk_rating' is violated
--         —— 截图 exp_g5_check_3819_MMDD.png
UPDATE trip_detail SET rating = 9 WHERE trip_id = 92;

-- ============================================================
-- 收尾：把演示行 rating 还原成初值 3，并核对库未被实验污染
-- ============================================================
UPDATE trip_detail SET rating = 3 WHERE trip_id IN (92, 150);
SELECT trip_id, rating FROM trip_detail WHERE trip_id IN (92, 150);  -- 应均为 3
SELECT COUNT(*) FROM Payment;   -- 仍 = 51398（G5-b 被拦截，无新行）
