# source — 数据来源与生成说明（C4 交付，2026-10-25 定稿）

> **路线 2 已激活**（D-10 定稿 v1.1）：Python 固定 seed 生成器 + RideAustin 真实数据标定。
> 生成器：`02_sql/import_data.py`（seed=534 写死在脚本头部）；产物 `02_sql/data_import.sql`
> 可随时重跑逐字节复现（D-08③ 数据同源），**产物不进仓库**（.gitignore 已忽略）。
> 路线 1（NYC TLC 子集）为选型过程存档，未采用，见 01_docs/a4_dataset_decision.md §一。

## 一、用法

```bash
python3 02_sql/import_data.py            # 生成 02_sql/data_import.sql + 数据级自验（零第三方依赖）
python3 02_sql/import_data.py --load     # 生成后直连本机 MySQL 导入并跑 SQL 级验收（需 pymysql；
                                         #   密码用 --password 或环境变量 MYSQL_PWD 指定）
# 标准流程（C5 截图用）：先建库再导数
mysql -u root -p < 02_sql/build.sql
mysql -u root -p < 02_sql/data_import.sql
```

只依赖标准库（random/datetime/argparse），**不用 faker**——第三方库版本漂移会破坏五机
逐行一致，姓名/车牌由脚本内置表生成（D-08③ 口径）。生成逻辑全部走 `random.Random(534)`
单实例；曾出现的两个缺陷均已修复并经双跑 md5 校验（当前 068a62f7…）：①未播种
random.shuffle；②字符串免引号优化导致 MySQL 把裸 status/method 当列名（真机导入
报 Unknown column，2026-10-27 C5 预验时发现修复）。

## 二、行数与构成（本次实际产出，seed=534）

| 表 | 行数 | 说明 |
|---|---|---|
| Passenger | 3,000 | 姓名内置表生成（真实数据仅 rider_id 粒度） |
| Vehicle / Driver | 150 / 150 | 1:1 绑定（driver_id ↔ vehicle_id 同号）；车牌 TX 风格唯一 |
| Trip | **60,000** | ≥5 万行 M2 硬指标；start_time=派单时刻（D-05） |
| Payment | 51,398 | = completed 支付 47,758 + 收费取消 3,640；completed 留 1,442（2.9%）未支付 |
| trip_detail | 60,000 | 每 Trip 恰一行（C3 扩展表，含取消行） |
| service_tier / pickup_zone | 4 / 15 | 维度 seed 随 build.sql 下发（非本脚本生成） |

**status 构成**（精确行数）：completed 49,200（82%）/ canceled 6,000（10%＝收费 3,640 +
免费 2,360，D-06 v1.2 三分钟宽限期口径）/ accepted+en_route 4,800（8%）。

## 三、分布参数与来源

| 参数 | 取值 | 来源 |
|---|---|---|
| 四档费率（base/per_min/per_mile） | REGULAR $1.5/$0.25/$0.99→$1.50（两期占比 0.8/0.2）；SUV $3.0/$0.35/$2.60；PREMIUM $3.0/$0.40/$2.75；LUXURY $5.0/$0.50/$3.75 | A4 §三 v1.2 全量实测；两期占比为拟合均值口径（课程设定） |
| 固定附加费 | +$1.65 | 实测档案 v1.1 勘误：total_fare=计价核心+$1.6–1.7 固定费，不含 tip/free_credit/round_up；**surge 不做乘法还原**（生成器不建模 surge） |
| 里程/时长 | 对数正态 μ=ln4.55/σ=0.55（均值≈5.3 英里）；分钟=2.5×里程+对数正态开销 | 课程拟合：使 completed 均费命中 total_fare 均值口径 |
| completed 均费（实测） | **$14.00**（标定参照 $13.99；min $4.49 / max $136.65） | 生成结果 vs 实测档案 §二 |
| 档次占比 | REGULAR 95.1%（含 0.1% HONDA 脏值归并）/ SUV 3.7 / PREMIUM 0.9 / LUXURY 0.3 | D-11②、A4 §三（精确行数池） |
| 上车区位 | 15 区，top3=35%（12/12/11%），其余 12 区各 5.42% | D-11① 课程设定（无真实标定源，参照 TLC 集中度） |
| 评分 | 仅 completed 行、覆盖率 89.9%（目标 90%）；有值行 5★90.1/4★5.7/3★2.0/2★0.6/1★1.7 | D-11②、A4 §三（实测 90.7% 覆盖） |
| 取消费 | 免费取消 fare=NULL 无 Payment；收费取消 fare=$1.50 恰一条 Payment(amount=1.5) | D-06 v1.2（全程美元） |
| 未支付 | completed 留 2–3%（实际 1,442 行）不生成 Payment | A4 §三（保证官方 Q2 反连接非空可截图） |
| 支付方式 | balance/cash/card ≈ 45.0/29.6/25.3%（实际） | A3 假设（真实数据无此字段） |
| 高峰 | 17–20 时合计 20.5%；凌晨 2–4 时 <1.2%（q06 HAVING≥2000 有过滤效果） | A4 §三（≈20%）+ q06 展示性微调 |
| 时间窗 | 2025-10-26 ~ 2026-10-25（365 天均匀） | 课程设定（贴近当前日历，避免 q05"超 24h 未支付"全表命中） |

## 四、验收结果（A4 §四 三条 + C3 不变量，脚本自动断言）

- ① D-06 取消规则违例 **0**（免费=NULL 无支付；收费=$1.5 恰 1 条 Payment）；
- ② status 词表 = {completed, canceled, accepted, en_route} ✓（无 requested/ongoing）；
- ③ method 词表 = {balance, cash, card} ✓；
- C3 不变量：每 Trip 恰一行 trip_detail、rating 仅 completed 非空 ✓；车牌唯一、
  Driver↔Vehicle 严格 1:1 ✓；Q2 反连接非空（1,442 行未支付）✓。
- SQL 文件经 sqlglot（MySQL 方言）全量解析通过（352 条语句、行数逐一核对）。
- 真机导入的 SQL 级验收查询已内置（`--load` 模式末尾自动执行并打印）。

## 五、与 D-12 对照表的衔接（§5 留出对照）

对照基底 = RideAustin 留出段（RIDE_ID 哈希 20%）；本脚本常量 = A4 已发布**全量**实测值，
训练段（80%）重算值"与全量几乎不动"（实测档案 §七）——A 交付训练段重算值后仅改
`import_data.py` 常量区即可，生成逻辑零改动。可比维度口径已对齐 §七：车费对照仅取
completed、同币种美元、均含 $1.65 固定附加费、不含 tip/credit（生成侧天然满足）；
status 构成 / method / 未支付率为课程规则假设，不进对照表。

## 六、遗留

- [ ] C5（10-26）：干净库全流程验收截图包（build.sql → data_import.sql → 抽查查询）；
- [ ] A：A4 §五 旧 ALTER TABLE 草案改写为 C3 扩展表版；E：扩展形态补登记（D-13）；
- [ ] B4 ER v1.0 冻结对账（C3 v1.0-rc 转正前置）。
