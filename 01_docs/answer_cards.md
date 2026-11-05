# CDS534 · 概念问答答案卡（D1 骨架 → D4 成稿 · v2 已填 · 2026-11-03）

> 状态：**八卡填空完成（英文成稿）**——正文以 05_report/sections/sec4_sql.tex §4.2 为准，本卡为复核底稿。
> 复核安排：Q1/Q2→B · Q3/Q4→C · Q5/Q6→A（已过卡复核，必改已吸收）· Q7/Q8→D 自查+E 抽查。
> Q4/Q6 文中 `___` 为 D5 实验数字回填位（实验②/①），跑完即补。

### Q1 · 主键 vs 外键（Referential Integrity）
- 灵魂句 EN：A primary key is the unique address of a row; a foreign key is a reference to that address; together they keep every cross-table reference traceable.
- 定义 EN：PK = NOT NULL + UNIQUE (Passenger.psg_id); FK = child column whose values must exist in the parent key (Trip.psg_id).
- 对比：INSERT Trip(psg_id=99999) → rejected, error 1452; deleting a referenced parent → RESTRICT by default, or CASCADE / SET NULL.
- 实例 EN：Payment.trip_id (NOT NULL UNIQUE + FK) enforces "every payment attaches to exactly one real trip" — the 1:1 implementation itself.
- 配代码：否｜复核：B｜字数：~180 ✓

### Q2 · 范式（1NF / 2NF / 3NF）
- 灵魂句 EN：1NF requires atomic values; 2NF removes partial dependencies; 3NF removes transitive dependencies.
- 定义 EN：1NF single atomic value per cell; 2NF no non-key attribute depends on part of a composite key; 3NF none depends on another non-key attribute.
- 对比：transitive chain causes update / deletion / insertion anomalies; cure = decompose. Our five tables all use single-column surrogate keys → 2NF holds by construction.
- 实例 EN：Driver(id, name, vehicle_id, plate) has driver_id→vehicle_id→plate; decomposed into Driver + Vehicle — exactly our schema.
- 配代码：小表对照图｜复核：B｜字数：~195 ✓

### Q3 · INNER / LEFT / RIGHT JOIN
- 灵魂句 EN：They differ only in how unmatched rows are treated: INNER keeps matched pairs only, LEFT keeps every row of the left table.
- 定义 EN：LEFT fills right-side columns with NULL when no match; RIGHT is the mirror image.
- 对比：mandatory-LEFT scenario "every driver with completed-trip count, including zero-trip newcomers" — INNER silently drops them.
- 实例 EN：Driver LEFT JOIN Trip ON … AND t.status='completed' + COUNT(t.trip_id) → 0 for newcomers (status filter in ON, not WHERE; COUNT of right-table column, not COUNT(*)).
- 配代码：是（已入 sec4）｜复核：C｜字数：~170 ✓

### Q4 · 子查询 vs JOIN
- 灵魂句 EN：Which formulation is faster must be judged from the execution plan, not by rule of thumb.
- 定义 EN：JOIN+DISTINCT / IN / EXISTS (= semi-join, stops at the first match).
- 对比：JOIN exploits join-column indexes in one plan; MySQL 8 rewrites IN/EXISTS as semi-joins → plans often identical; NOT IN is unsafe if the subquery column can be NULL (Payment.trip_id is NOT NULL, so safe here).
- 实例 EN：Experiment 2 on the 60,000-row Trip: three anti-join formulations return the same 1,442 rows with the same plan (Extra: Not exists; Using index); run times ___ / ___ / ___ ms.
- 配代码：是（三写法）｜复核：C｜字数：~190 ✓（数字待回填）

### Q5 · ACID 与并发支付
- 灵魂句 EN：Four guarantees + one lost-update story + the fix.
- 定义 EN（A 的成品句）：Atomicity: all writes succeed together or leave no trace. Consistency: every committed state satisfies all declared constraints. Isolation: concurrent transactions never see each other's intermediate states. Durability: once committed, changes survive crash and restart.
- 对比：balance=100, two concurrent −50 → final 50 ≠ 0 (lost update). **前提（A 必改①）**：the lost update arises from SELECT-then-UPDATE across two sessions; a single atomic `UPDATE … SET balance = balance − 50` would not lose updates. **（A 必改②）**hypothetical wallet column; dual defense = Payment.trip_id UNIQUE (schema layer, prevents double payment) + SELECT … FOR UPDATE (isolation layer, prevents lost update). Default REPEATABLE READ uses snapshot reads without locks — hence FOR UPDATE is needed.
- 实例 EN：demonstrated live in Experiment 3 (lost update → FOR UPDATE fix → RR vs RC).
- 配代码：必配（预告实验③）｜复核：A ✓ 已吸收｜字数：~210 ✓

### Q6 · 索引（B+ Tree）
- 灵魂句 EN：A B+ tree turns a full scan O(n) into a tree descent O(log n); the price is storage space and write maintenance.
- 定义 EN：internal nodes only route searches; leaves hold keys with row pointers and are linked, making range scans sequential.
- 对比：why not every column — storage; every INSERT/UPDATE/DELETE maintains all indexes; low-selectivity columns (status alone) rarely chosen; buffer-pool/optimizer overhead. **原则（A 建议②）**：index high-selectivity columns; composite indexes follow the leftmost-prefix rule (our idx_trip_status_time: status equality first, start_time range second). FK columns already carry indexes automatically (Trip.psg_id/driver_id) — that is why our before/after baseline uses (status, start_time).
- 实例 EN：Experiment 1: type ALL → range, rows 60,261 → 3,259, actual time ___ ms → ___ ms (covering index, Using index).
- 配代码：否（挂数字）｜复核：A ✓ 已吸收｜字数：~205 ✓（数字待回填）

### Q7 · GROUP BY / HAVING vs WHERE
- 灵魂句 EN：WHERE filters rows before grouping; HAVING filters groups after aggregation.
- 定义 EN：GROUP BY buckets rows into one output row per bucket; aggregates computed in-bucket; HAVING may reference aggregates, WHERE cannot (syntax error).
- 对比：logical order FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT.
- 实例 EN："months with ≥1,000 completed trips": WHERE status='completed' → GROUP BY ym → HAVING COUNT(*) ≥ 1000.
- 配代码：是｜自查 + E 抽查｜字数：~170 ✓

### Q8 · VIEW vs STORED PROCEDURE
- 灵魂句 EN：A view is a stored query used like a table; a procedure is a precompiled program invoked with CALL.
- 定义 EN：view = virtual table, no data, expanded at query time; procedure = parameters + control flow + DML, server-side. Why DELIMITER: the body contains semicolons.
- 对比：view → reuse / access control / logical independence; procedure → parameterized jobs (CALL sp_check_unpaid(24)); FUNCTION in between.
- 实例 EN：v_completed_revenue (finance view) vs sp_check_unpaid(24) (collection job).
- 配代码：是（先自建库跑通）｜自查 + E 抽查｜字数：~170 ✓
