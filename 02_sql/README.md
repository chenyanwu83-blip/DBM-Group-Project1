# 02_sql — 建库与实验脚本

| 文件 | 用途 | 负责人 |
|---|---|---|
| `build.sql` | 可重复执行的完整建库脚本（**官方交付物之一**）：按 DROP → CREATE → 约束 顺序组织，任何人从零复跑必须成功 | C（C2/C3） |
| `schema.sql` | 全量 DDL，与 build.sql 保持同步（底座 + 扩展表） | C（C3） |
| `import_data.py` | 样本数据导入：生成器（faker + 固定 seed）或 NYC TLC 子集清洗入库 | C（C4） |
| `exp_index.sql` | 实验支撑脚本三件：建/撤索引、EXPLAIN 采集、双会话并发事务演示 | C（C6） |
| `requirements.txt` | Python 依赖版本锁定（pandas/SQLAlchemy/faker），保证固定 seed 跨机器生成同一份数据 | C（C4） |

## 约定

- **各自本地 + GitHub 模式**：改表 = 改脚本 = commit；每次 `git pull` 后重跑 `build.sql` 重建库；**禁止在 Workbench 图形界面改表而不落脚本**。
- **底座永不修改**：官方 Topic 5 DDL（Passenger / Vehicle / Driver / Trip / Payment 五表）原样保留；扩展表一律增量追加，外键/唯一约束与 B 的 ER 基数一一对应。
- SQL 与对象命名一律小写下划线（`trip_id`）。
- 提交信息带任务编号（如 `C4: 样本数据导入脚本 v1`），方便回溯任务表。
- ER 于 10-21（M1）冻结；此后 schema 改动须全组同意并记版本号。
