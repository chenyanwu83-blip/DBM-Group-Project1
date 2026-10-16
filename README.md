# DBM-Group-Project1 · CDS534 数据库管理小组项目

**选题（已定）**：Topic 5 — Ride-Hailing Order & Trip Dispatch（网约车订单与派单数据库）

- 课程：CDS 534 Database Management
- 官方截止：**2026-11-12（周四）20:00**（内部红线：11-10 白天正式提交）
- 交付物（4 项，全部 compulsory）：PDF 报告（10–12 页、字号 12）｜ `build.sql` + 样本数据截图 ｜ ER 矢量图 ｜ 8 道概念问答 + ≥8 条查询及解读
- 官方作业要求与《分工与时间线执行方案》两份 PDF 存共享盘（版权原因不入 public 仓库）

## 协作模式：各自本地 MySQL + GitHub 同步

每人用自己的本地 MySQL（Workbench 连本机 localhost，版本不强制升级），**以 GitHub 上的脚本为唯一事实来源**——任何人在任何电脑上用同一份脚本都能重建出一模一样的库。四条纪律：

1. **版本登记**：每位组员跑 `SELECT VERSION();` 并登记到 [01_docs/env_record.md](01_docs/env_record.md)（10-17 M0 前完成）。**以组内最低版本为兼容基线**——`build.sql` 与所有查询必须能在每台机器跑通；若基线低于 8.0，注意 CHECK 约束会被静默忽略（不影响跑通）、查询避免窗口函数/CTE（用 JOIN/子查询改写）。
2. **脚本唯一事实**：改表 = 改 `02_sql/build.sql` = commit（build.sql 仅 C 可改）。禁止在 Workbench 图形界面手工建表/改表而不落脚本，否则各人库结构会悄悄分叉。
3. **数据同源**：样本数据由 `import_data.py` 固定 seed 生成（依赖版本锁 `requirements.txt`），保证每人数据一致、查询截图数字对得上。
4. **实验数字同机**：出报告用的实验数据（索引前后/JOIN 对比/并发事务）统一由 D 在自己机器上跑，避免跨机器性能差异导致数字打架。

## 角色分工

| 角色 | 定位 | 负责报告章节 | 姓名 |
|---|---|---|---|
| A｜业务与需求负责人 | 业务场景、利益相关者、可量化目标、数据集选型、负载画像 | §1 主笔、§6 合写 | 陈祎楠 |
| B｜ER 建模负责人 | ER 图、数据字典、范式论证、官方约定遵循 | §2 主笔 | 张奕杰 |
| C｜实现与平台负责人 | MySQL 环境、build.sql、样本数据入库、全套截图、干净复跑 | §3 主笔、附录 B | 陈妍吾 |
| D｜查询与实验负责人 | ≥8 条查询、8 道概念问答、索引/JOIN/事务三组实验 | §4、§5 主笔 | 凌彤 |
| E｜PM 与写作整合负责人 | 进度、Overleaf 统稿、贡献表、对外提交 | 封面、References、统稿 | 胡中远 |

> 交叉复核：A↔B 互查业务/ER；C 复核 D 的查询可运行性；D 复核 C 的脚本规范性；E 抽查四道关卡。

## 目录结构

```
DBM-Group-Project1/
├─ 01_docs/      会议纪要、方案、决策登记、签字扫描
├─ 02_sql/       schema.sql、build.sql、import_data.py、exp_index.sql
├─ 03_data/      source/ + screenshots/（按 DDL/查询/实验分三子目录）
├─ 04_figures/   er_baseline.drawio、er_final.drawio、导出 PDF/SVG
├─ 05_report/    Overleaf 工程 + report_vYYYYMMDD.pdf
├─ 06_slides/    （条件）Pre 幻灯
└─ README.md     环境安装、执行顺序、复现说明
```

每个目录内有单独的 `README.md`，写明放什么、怎么命名、谁负责。

## 每人日常工作流（pull → 重建 → 干活 → push）

```bash
git pull                                    # 1. 拉最新脚本
mysql -u <user> -p < 02_sql/build.sql       # 2. 重建库（DROP→CREATE 可重复执行；也可在 Workbench 里跑）
python 02_sql/import_data.py                # 3. 导入同源样本数据（固定 seed，Trip ≥ 5 万行）
# 4. 干自己的活：跑查询 / 验证 → 截图按命名规范放 03_data/screenshots/ 对应子目录
git add ... && git commit -m "任务编号: 说明" && git push   # 5. 提交成果
```

> 脚本逐步到位（底座 build.sql 由 C1 于 10-17 提供；导数脚本 C4 于 10-25 提供），当前阶段先按 C1 任务跑通底座。

## 环境（2026-10-17 锁定后不再更换）

| 组件 | 选型 | 说明 |
|---|---|---|
| MySQL Server | **各自本地安装，版本不强制升级** | Workbench 连 localhost；版本登记进 [01_docs/env_record.md](01_docs/env_record.md)，脚本以组内最低版本为兼容基线（utf8mb4_general_ci 全版本通用） |
| 图形客户端 | MySQL Workbench | 人人已有，仅作客户端 |
| 造数/导数 | Python 3.11 + pandas + SQLAlchemy + faker | 依赖锁 `02_sql/requirements.txt`，固定 seed 跨机一致 |
| ER 绘制 | draw.io | `.drawio` 源文件入 04_figures/ |
| 报告写作 | Overleaf | 工程镜像同步 05_report/ |

## 协作约定

- **一切版本以 GitHub 提交记录为准，口头定稿无效。**
- 命名：SQL/脚本/表字段一律小写下划线（`trip_id`）；截图 `前缀_表名或查询号_日期.png`（如 `ddl_driver_1024.png`、`q03_driver_income_1029.png`）。
- 提交信息带任务编号，如 `C3: 新增扩展表 DDL`、`D5: 索引前后对比实验脚本`。
- **冻结令**：10-21 ER 冻结（M1）｜10-30 实验冻结（M3）｜11-03 文字冻结（M4）。冻结后改动须全组同意并记版本号。
- 官方 Topic 5 DDL 为"底座"，**永不修改**；一切扩展基于底座增量。
- 白天提交纪律：导出 PDF、对外提交等动作在白天完成并留回执，绝不压 20:00 死线。

## 里程碑

| 里程碑 | 日期 | 验收要点 |
|---|---|---|
| M0 启动就绪 | 10-17 | 角色落名；底座跑通截图群内展示；Overleaf 骨架可编译；环境登记表填齐 |
| M1 设计冻结 | 10-21 | ER v1.0 + 数据字典冻结；A3 目标含数字；A4 数据集定稿；D2 查询清单 v1 |
| M2 实现冻结 | 10-26 | 干净库全流程跑通 + 他人复跑；Trip ≥ 5 万行；截图包归档 |
| M3 实验冻结 | 10-30 | 查询验证包齐；问答 8 题成稿；实验三件套齐 |
| M4 内部定稿 | 11-03 | 10–12 页、字号 12、四道关卡签字、全员已读无异议 |
| M5 提前完成版 | 11-05 | 全部交付物打包就位（距截止整 7 天） |
| M6 正式提交 | 11-10 白天 | 对外提交并保存回执 |
