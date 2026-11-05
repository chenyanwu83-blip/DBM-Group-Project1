# C8 · SQL 关复跑记录（rerun record）

> 依据：《分工与时间线执行方案》C8——"组织另一人（D 或 A）在干净环境复跑 build.sql + 导数成功"；证据纪律按 C2（截图入对应子目录、当次 commit）。

| 项 | 内容 |
|---|---|
| 复跑人 | 凌彤（D） |
| 机器 | MacBook Air（Apple M1, 8 GB, macOS 15.x） |
| MySQL 版本 | Community Server **26.7.0**（`SELECT VERSION()` 实测） |
| 复跑基线 commit | `ba52a36441c035997664c74fba514e76cfeb57a2`（ba52a36, 2026-11-05，复跑前 `git pull` 已同步至 origin/main 最新） |
| 复跑日期 | 2026-11-05 |

## 执行的两条命令

```bash
mysql -u root -p < 02_sql/build.sql          # 重建：DROP→CREATE 库→8 表 DDL→自检段（空库 0/4/15/0）
mysql -u root -p < 02_sql/data_import.sql    # 导入（由 02_sql/import_data.py 固定 seed=534 生成）
```

注：`data_import.sql` 由 `python3 02_sql/import_data.py` 生成（产物不入库，.gitignore 约定）；本次生成段统计与 C4 验收一致（档次 95.1/3.7/0.9/0.3、评分覆盖 89.9%、completed 均费 $14.00、晚高峰 20.5%、top3 区位 35.0%）。

## §4 自检结果（八表行数）

```
mysql_version: 26.7.0
Passenger 3000 | Vehicle 150 | Driver 150 | Trip 60000
Payment 51398  | service_tier 4 | pickup_zone 15 | trip_detail 60000
```

与 C4 定稿规模逐表一致 → **复跑成功**。

## 证据截图

- `03_data/screenshots/ddl/base_rerun_D_1105.png` —— 复跑过程成功画面（终端两条命令无报错）
- `03_data/screenshots/ddl/base_rerun_D_1105_selfcheck.png` —— §4 自检结果网格（VERSION + 八表行数）

（与 C1 底座跑通图 base_run_1016.png 同目录同风格；签字照按组内口径存共享盘、不入 GitHub。）
