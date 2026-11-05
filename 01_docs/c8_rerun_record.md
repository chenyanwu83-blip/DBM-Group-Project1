# 复跑记录

在另一台机器上从零重建数据库，确认 build.sql + 数据导入脚本可以完整复现。

- 谁跑的：凌彤
- 机器：MacBook Air M1, macOS
- MySQL 版本：26.7.0
- 仓库 commit：ba52a36（2026-11-05，跑之前 pull 到最新）

跑了两条命令：

```bash
mysql -u root -p < 02_sql/build.sql
mysql -u root -p < 02_sql/data_import.sql
```

八张表的行数：

```
Passenger    3000    Vehicle     150    Driver     150
Trip       60000    Payment   51398    service_tier    4
pickup_zone   15    trip_detail  60000
```

和预期完全一致，复跑通过。

截图：`03_data/screenshots/ddl/base_rerun_D_1105.png` 和 `base_rerun_D_1105_selfcheck.png`
