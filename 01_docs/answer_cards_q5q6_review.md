# A · answer_cards 复核意见（Q5 / Q6）

> 复核人：陈祎楠（A）· 2026-10-22 · 依据：answer_cards.md 卡头标注「复核：A」
> 结论先行：**两卡内容均无硬伤，可通过（PASS）**；下列批注为增强建议与易漏点提醒，供 D4 执行指南与 §4 成稿时采纳。格式核对：两卡均为固定 5 行、填空用英文、目标字数 150–250 EN words ✓

---

## Q5 · ACID 与并发支付 — PASS，4 条批注

| # | 位置 | 意见 | 级别 |
|---|---|---|---|
| Q5-1 | 对比行「终值 50≠0」 | 数字核算正确：两事务同读余额 100 → 各写 50 → 终值 50（正确应为 0）。**但成稿时必须写清前提**：丢失更新发生在"应用侧先 SELECT 再 UPDATE"（read-modify-write）模式；若写成单条原子语句 `UPDATE wallet SET balance = balance - 50`，InnoDB 会取当前已提交版本加锁，并不会丢更新。一句 "the lost update arises from SELECT-then-UPDATE across two sessions" 即可堵住评分人追问 | 必改 |
| Q5-2 | 实例行 "passenger wallet" | 官方五实体**没有钱包表**。两个处理选项：① 若 B 的扩展实体（M1 已过、待补交）含 wallet/balance，直接挂钩；② 否则成稿时明写 "hypothetical wallet column"，并**加一句更贴本题的双重防线**：`Payment.trip_id UNIQUE` 在模式层阻止同一行程被重复支付（1:1），`FOR UPDATE` 在隔离层守护余额——constraint 防重、lock 防丢，两层各管一件事，正好呼应 §1/§2 | 必改（二选一） |
| Q5-3 | 对比行「MySQL 默认 REPEATABLE READ」 | ✓ 正确。可补一个易漏点：RR 并**不能**阻止上述应用侧丢失更新（普通 SELECT 是一致性读、不加锁），所以才需要 `SELECT ... FOR UPDATE` 或 `SERIALIZABLE`——把"默认级别"与"为什么默认级别不够"连起来写，是这题的区分点 | 建议 |
| Q5-4 | 配代码「可选」 | 建议改「必配」：D5 实验③（双会话并发）本来就要演示丢失更新与修复，Q5 直接预告并回填实验数字，比"可选"多拿"结论有据"的分 | 建议 |

**给 D4 的英文成品句（可直接用）**：
- Atomicity: *all writes in a transaction succeed together or leave no trace.*（8 词 ✓）
- Consistency: *every committed state satisfies all declared constraints.*（8 词 ✓）
- Isolation: *concurrent transactions never see each other's intermediate states.*（9 词 ✓）
- Durability: *once committed, changes survive crash and restart.*（8 词 ✓）

---

## Q6 · 索引（B+ Tree） — PASS，3 条批注

| # | 位置 | 意见 | 级别 |
|---|---|---|---|
| Q6-1 | 灵魂句两个空 | 预期答案：**storage space** 和 **write maintenance**（每次 INSERT/UPDATE/DELETE 都要同步维护索引）。四条理由卡里已列全（空间/写维护/低选择率/缓冲池与优化器开销），与官方答案键一致 ✓ | 核对 |
| Q6-2 | 对比行 | 建议补两个官方键提到、卡里没有的点：① **选择性原则**——给高选择性列建（如 `psg_id`），性别/状态这类低选择率列不值得；② **复合索引最左前缀**（leftmost prefix）一句带过。都在 150–250 词预算内放得下 | 建议 |
| Q6-3 | 实例行 "trips of driver 7" | ✓ 与 D5 实验①对齐良好。补一个加分点：FK 列（`Trip.psg_id`/`Trip.driver_id`）MySQL 建外键时**已自动建索引**，实验①若想展示"前后对比"，应选一条尚无索引的列（或先 DROP 再建），否则"无索引基线"根本不存在——这个坑建议写进 D4 指南，避免实验截图前后计划一样 | 必改（影响实验设计） |

**给 D4 的英文成品句（可直接用）**：
- 结构：*internal nodes only route searches; leaves hold keys with row pointers and are linked, making range scans sequential.*
- 代价：*the price is storage space and write maintenance — every INSERT/UPDATE/DELETE must keep each tree consistent.*

---

## 复核流程登记（供 E3 收档）

- Q5：PASS（2 必改 + 2 建议）｜复核人 A｜2026-10-22
- Q6：PASS（1 必改 + 2 建议）｜复核人 A｜2026-10-22
- 待确认：Q1/Q2（复核 B）、Q3/Q4（复核 C）目前未见复核记录，请 B/C 补；Q7/Q8 为 D 自查 + E 抽查
