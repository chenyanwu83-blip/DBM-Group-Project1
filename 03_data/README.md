# 03_data — 数据与核验截图

- `source/` — 原始数据或生成说明
- `screenshots/` — 截图包（老师核验交付物的呈现形式），按用途分三个子目录：
  - `ddl/` 建表与结构核验（每表 `SELECT COUNT(*)` + `SHOW CREATE TABLE`）
  - `queries/` 每条查询的结果窗口
  - `experiments/` 索引前后 / JOIN 对比 / 并发事务实验

## 截图规范（C2 定义，全组遵循）

- 统一裁边、同比例缩放，窗口内可见表名或查询语句。
- 命名：`前缀_表名或查询号_日期.png`，例：`ddl_driver_1024.png`、`q03_driver_income_1029.png`、`exp_index_before_1030.png`。
- 截图必须可追溯：报告中出现的数字要能在截图/运行日志中找到（D8 数字关逐一对账）。
