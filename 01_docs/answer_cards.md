# 每卡固定 5 行：灵魂句 / 定义 / 对比 / 实例 / 信息行。填空用英文。
# 哪一栏卡壳 → 直接看执行指南 D4 对应题的中文讲解（引导细节和易漏点都在那边，不堆在卡里）。

### Q1 · 主键 vs 外键（Referential Integrity）
- 灵魂句 EN：A PK is the unique address of a row; an FK is a reference to that address; together they keep every cross-table reference ___.
- 定义 EN：PK = NOT NULL + UNIQUE（例 Passenger.psg_id）；FK = 子表列，取值必须 ___ in the parent key
- 对比：插入违规子行 → ___（想：报什么错）；删除被引用父行 → RESTRICT / CASCADE / SET NULL
- 实例 EN：INSERT INTO Trip(psg_id) VALUES(99999,...) → ___；Payment.trip_id 一句带过
- 配代码：否｜复核：B｜字数：150–250 EN words

### Q2 · 范式（1NF / 2NF / 3NF）
- 灵魂句 EN：1NF requires atomic values; 2NF removes partial dependencies; 3NF removes ___ dependencies.
- 定义 EN：三级各一句（atomic value / part of a composite key / another non-key attribute）
- 对比：传递依赖三异常 = update / deletion / insertion anomaly；消除手段 = decompose
- 实例 EN：Driver(id, name, vehicle_id, plate) 里 driver_id→vehicle_id→plate；分解成 Driver + Vehicle
- 配代码：小表对照图｜复核：B｜字数：150–250 EN words

### Q3 · INNER / LEFT / RIGHT JOIN
- 灵魂句 EN：They differ only in how unmatched rows are treated: INNER keeps ___, LEFT keeps every row of ___.
- 定义 EN：三句各一行（LEFT：右侧无匹配时补 NULL）
- 对比：必用 LEFT 场景 = "0 单的新司机也要出现在统计里"（INNER 会吞掉他们）
- 实例 EN：Driver LEFT JOIN Trip ... including drivers with ___ trips; COUNT(t.trip_id) 得 0
- 配代码：是（status 条件放 ON）｜复核：C｜字数：150–250 EN words

### Q4 · 子查询 vs JOIN
- 灵魂句 EN：Which formulation is faster must be judged from the ___, not by rule of thumb.
- 定义 EN：JOIN+DISTINCT 版 / IN 版 /（选加）EXISTS = semi-join, stops at the first match
- 对比：JOIN 走索引一次成计划；MySQL 8 会把 IN/EXISTS 改写成 semi-join → 计划常常相同
- 实例 EN：passengers who rode vehicle 3（Passenger⋈Trip⋈Driver 三表）
- 配代码：是（两版 SQL）｜复核：C｜字数：150–250 EN words

### Q5 · ACID 与并发支付
- 灵魂句 EN：四性质各一句 + 丢失更新例子 + 修复手段
- 定义 EN：Atomicity / Consistency / Isolation / Durability，每条 ≤12 词
- 对比：余额 100 并发两笔各扣 50 → 终值 50≠0（lost update）；修复 = FOR UPDATE 或 SERIALIZABLE；MySQL 默认 REPEATABLE READ
- 实例 EN：two concurrent 50-dollar payments on the same passenger wallet
- 配代码：可选（预告实验③）｜复核：A｜字数：150–250 EN words

### Q6 · 索引（B+ Tree）
- 灵魂句 EN：A B+ tree turns a full scan O(n) into a tree descent O(log n); the price is ___ and ___.
- 定义 EN：结构一句话（internal nodes 路标；leaves 存键+行指针、相链便于范围扫描）
- 对比：不能每列建 = 空间 / 每次写要维护 / 低选择率列没人用 / 缓冲池与优化器开销
- 实例 EN：index Trip(driver_id) → "trips of driver 7"（数字 D5 实验①回填）
- 配代码：否｜复核：A｜字数：150–250 EN words

### Q7 · GROUP BY / HAVING vs WHERE
- 灵魂句 EN：WHERE filters rows ___ grouping; HAVING filters groups ___ aggregation.
- 定义 EN：GROUP BY 装桶、聚合函数桶内计算、HAVING 对桶过滤
- 对比：执行顺序 FROM→WHERE→GROUP BY→HAVING→SELECT→ORDER BY→LIMIT（必写）
- 实例 EN：months with ≥1000 completed trips（三步：WHERE→GROUP BY→HAVING）
- 配代码：是｜自查 + E 抽查｜字数：150–250 EN words

### Q8 · VIEW vs STORED PROCEDURE
- 灵魂句 EN：A view is a stored ___ queried like a table; a procedure is a precompiled ___ invoked with CALL.
- 定义 EN：视图 = 虚拟表、不存数据、查询时展开；过程 = 带参数、有流程控制、可执行 DML
- 对比：视图→复用/权限/逻辑独立；过程→参数化业务/批量任务；中间选项 = FUNCTION
- 实例 EN：v_completed_revenue（视图）vs sp_check_unpaid(24)（过程）
- 配代码：是（DELIMITER 先自建库跑通）｜自查 + E 抽查｜字数：150–250 EN words