# 概念问答复核底稿

正式答案在 sec4_sql.tex §4.2，这里只是给复核人看的要点提纲。
Q5/Q6 已按复核意见改过（丢失更新加了 SELECT-then-UPDATE 前提，索引题补了最左前缀）。

**Q1 主键 vs 外键** — 复核人：B
核心：PK 是行的地址，FK 是指向该地址的引用。插入不存在的乘客会报 1452，删除被引用的父行走 RESTRICT。Payment.trip_id 同时是 FK + UNIQUE，这就是 1:1 的实现。

**Q2 范式** — 复核人：B
核心：传递依赖造成三种异常（更新/删除/插入）。用 Driver(id, name, vehicle_id, plate) 举例，分解成 Driver + Vehicle 就消掉了。我们的表全是单列代理键，天然满足 2NF。

**Q3 JOIN 三种** — 复核人：C
核心：LEFT JOIN 必须用在"零单新司机也要出现在统计里"的场景。状态条件放 ON 不放 WHERE，COUNT 用右表列不用 COUNT(*)。

**Q4 子查询 vs JOIN** — 复核人：C
核心：没有绝对赢家，看 EXPLAIN。实验②三写法计划一样（Not exists; Using index），耗时差 8ms。NOT IN 有 NULL 陷阱。

**Q5 ACID** — 复核人：A（已过）
核心：丢失更新发生在先 SELECT 再 UPDATE 的跨会话场景。两层防线：UNIQUE 防重复支付（模式层），FOR UPDATE 防丢失更新（隔离层）。RR 的普通 SELECT 是快照读不加锁，所以默认级别不够。

**Q6 索引** — 复核人：A（已过）
核心：B+ 树把 O(n) 变 O(log n)。代价：空间 + 写维护 + 低选择率列不值得建。FK 列自动带索引，所以对比实验选了 (status, start_time) 做基线。实验① 16.6ms → 0.46ms。

**Q7 GROUP BY / HAVING vs WHERE** — 自查
核心：WHERE 分组前筛行，HAVING 分组后筛组。执行顺序 FROM→WHERE→GROUP BY→HAVING→SELECT→ORDER BY→LIMIT。

**Q8 VIEW vs 存储过程** — 自查
核心：视图是保存的查询（被 SELECT），过程是保存的程序（用 CALL）。DELIMITER 是因为过程体内有分号。
