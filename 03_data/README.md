# 03_data — 数据与核验截图

- `source/` — 原始数据或生成说明
- `screenshots/` — 截图包（老师核验交付物的呈现形式），按用途分三个子目录：
  - `ddl/` 建表与结构核验（每表 `SHOW CREATE TABLE` + `SELECT COUNT(*)`）
  - `queries/` 每条查询的结果窗口
  - `experiments/` 索引前后 / JOIN 对比 / 并发事务实验

---

## 截图与脚本规范（C2 交付物 · 全组遵循 · D 按此执行）

> 截图在本项目里不是"留念"，是**三类证据**：给老师看的运行证据（官方交付物之一）、
> 给 D8 数字关对账的数字证据、给 M2 复跑比对的基线证据。规范只为一件事：
> **任何一张图，任何人，都能追溯出"哪台机器、哪个脚本、哪条语句产出的"。**

### 1. 三类截图，各含什么（三要素）

| 类别 | 一张合格的图必须同时拍到 | 存放 | 命名示例 |
|---|---|---|---|
| **A 结构证据**（每表，C 出） | ① `SHOW CREATE TABLE <表>;` 的完整输出 ② `SELECT COUNT(*) FROM <表>;` 的结果网格 | `screenshots/ddl/` | `ddl_driver_1024.png` |
| **B 查询证据**（D 出，C1 底座图由 C 出） | ① 查询窗口里的 SQL 原文 ② Result Grid（含列名与数据）③ 左下角行数标签（如 `5 rows returned`） | `screenshots/queries/` | `q03_driver_income_1029.png` |
| **C 实验证据**（D 出） | EXPLAIN / 耗时对比的结果网格，前后**成对**两张，其余环境可见相同 | `screenshots/experiments/` | `exp_index_before_1030.png`、`exp_index_after_1030.png` |

底座跑通图（C1 已拍）归 `screenshots/ddl/`，命名 `base_run_1016.png`。

### 2. Workbench 操作步骤（以一张 A 类图为例）

1. 查询窗口执行 `USE ride_hailing;`
2. `SHOW CREATE TABLE Driver;` → 结果网格两列（Table / Create Table）。
   **双击 Create Table 单元格**放大到 DDL 从 `CREATE TABLE` 到结尾分号**完整可读**，再截。
3. 紧接着执行 `SELECT COUNT(*) FROM Driver;`，让 Output 面板两条绿灯与结果网格同框，再截一张。
   （②③也可以合成一张：只要 SHOW CREATE 全文和 COUNT 数字都清晰可读即可）
4. macOS 截图：`Cmd+Shift+4` 框选**整个 Workbench 窗口**（含顶部连接名），PNG 存桌面 → 改名 → 拖进对应子目录 → commit。

B 类同理：跑一条查询 → SQL 与结果同框截整窗。**不裁 Output、不裁行数标签。**

### 3. 五条红线（不合格截图，验收直接打回）

1. ❌ 手机拍摄 / 屏幕翻拍（必须是系统截图）
2. ❌ 裁掉了 Output 面板或行数标签（证据链断掉）
3. ❌ `SHOW CREATE TABLE` 截不全（看不出约束/FK 就等于没截）
4. ❌ 一张图里混多件事、看不清哪段 SQL 对应哪个结果
5. ❌ 文件名随手起（规范外的名字 E 统稿时找不到图）

### 4. 命名与归档

- 统一格式：`前缀_表名或查询号_MMDD.png`（ddl_ / q\<号\>_ / exp_\<实验\>_before|after_ / base_run_）
- 同日重拍覆盖旧图（同版本只留最新），git 历史自动留底
- 图进对应子目录后**必须当次 commit**，不许堆在本地

### 5. M2 截图包验收清单（C5 用，10-26）

- [ ] base_run ×1（底座跑通，已有）
- [ ] 每表 ddl_ ×2 内容（SHOW CREATE + COUNT）：Passenger / Vehicle / Driver / Trip / Payment
- [ ] 导数后行数总表 ×1（build.sql 第 4 节 UNION 自检，Trip ≥ 5 万行在此证明）
- [ ] 抽查查询 ×≥3（C5 验收时新 schema 从零复跑后重截）
- [ ] D 的 queries/ 按查询清单补齐；experiments/ 到 M3（10-30）补齐

### 6. 附：脚本规范四条（build.sql 即活模板，改表先看它）

1. **顺序**：DROP→CREATE 库→底座 DDL（第 1 节）→官方查询（第 2 节）→扩展区（第 3 节）→自检（第 4 节）
2. **可重复执行**：任何脏状态重跑一次即复原；日常 `git pull` 后重跑 = 与他人一致
3. **底座铁律**：第 1 节官方 DDL 永不修改；扩展一律进第 3 节
4. **自检段收尾**：每次跑完看第 4 节（版本/表清单/行数），绿灯 + 数字符合预期才算跑通
