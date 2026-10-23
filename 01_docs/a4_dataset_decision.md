# A4 · 数据集选型（定稿 v1.1）

> 陈祎楠 / 角色 A · 2026-10-22 · **状态：定稿——路线 B（固定 seed 生成器）不变，标定来源由 NYC TLC 升级为 RideAustin 真实开源数据**
> **v1.2 勘误（2026-10-23）**：A/B 实测可按 RIDE_ID 行级 JOIN（旧"不同轴"结论作废）、费率实为四档结构、覆盖率/占比按全量实测校准——明细见 [a4_rideaustin_profile.md](a4_rideaustin_profile.md)
> 回应老师问询「数据现成还是生成」：**生成**（`import_data.py` 固定 seed），**分布参数标定自真实运营数据**（RideAustin，DOI 可引用）。
> 交 C 落地（C4 import_data.py，截止 10-25）；B3/B4 据第五节即可开工。

## 〇、标定数据集档案（RideAustin）

| 项 | 值 |
|---|---|
| 名称 | RideAustin Rides（美国奥斯汀非营利网约车平台开源数据） |
| 期间 / 规模 | 2016-06-02 ~ 2017-04-13，约 149.4 万行程 |
| 下载 | https://data.mendeley.com/datasets/wp5gkjbvb9 |
| 数据 DOI | 10.17632/wp5gkjbvb9.1（许可 CC0，可自由使用） |
| 论文 DOI | 10.1016/j.trc.2019.11.021（*Evaluation of Ride-Sourcing Search Frictions and Driver Productivity*, TR-C） |
| 文件 A `Rides_DataA.csv`（327MB） | 行程事实：`requested_car_category`（四档）、`driver_rating`/`rider_rating`（每单 1–5 星）、`rider_id`、`active_driver_id`、时间链（created→driver_reached→started→completed）、`distance_traveled`、`surge_factor` |
| 文件 B `Rides_DataB.csv`（319MB） | 派单/费率佐证：`base_fare`/`rate_per_mile`/`rate_per_minute`/`total_fare`、`tip`、`status`（DISPATCHED/DECLINED）、`driver_id`+`car_id` 1:1 绑定、车辆 color/make/model/year |

**使用注意（C/D 勿踩坑，v1.2 实测修订）**：① ~~A/B 不可行级 JOIN~~ → **实测两文件 RIDE_ID 同轴逐行对应、可 JOIN**（10-23 全量验证零错位，见实测档案第三节）；但司机 ID 命名空间不同：A 的 `active_driver_id` 过度脱敏近唯一，**司机粒度分析只能用 B 的 `driver_id`**（4,976 人、车严格 1:1）；② 文本列带 `b'...'` 外壳（导出痕迹），strip 掉；③ 币种为美元（无 currency 列），**全程统一 $（10-23 全组表决，D-06 v1.2）**；④ 采参数前清洗：`distance_traveled` 有 0/4.3 万公里级脏值、车型列混入 `b'HONDA'`、坐标列有占位异常（坑清单见实测档案第四节）。

## 一、双路线对比（选型过程存档）

| 维度 | 路线 A：NYC TLC FHVHV 真实子集 | 路线 B：Python 生成器（faker + 固定 seed） | 优胜 |
|---|---|---|---|
| 真实性 | 真实运营数据（Uber/Lyft 高量网约车月度记录，公开可引用） | 仿真数据；分布参数可**参照真实数据标定**（本次升级为 RideAustin：车费费率、车型占比、评分分布、时段高峰），"像真的"但不真实 | A（弱优） |
| 许可 | 公开数据集，需在报告引用来源与许可说明 | 无第三方许可问题，`03_data/source/` 放生成说明即可 | B |
| **字段适配** | **致命短板**：无乘客身份（无 psg_id）、无支付方式字段、按 base 聚合无司机-车辆 1:1 绑定——五实体中 Passenger/Driver/Vehicle/Payment 四张表的关联列都要人工捏造映射，"真实性"反而在映射中丢失 | 按官方 DDL 五表**原生生成**，外键关系、UNIQUE 约束、分布（司机:乘客≈1:20、支付方式占比、高峰时段）全部可控 | **B（决定性）** |
| 导入成本 | 下载 parquet → 清洗 → 字段映射脚本，多一道易错环节且跨机版本漂移风险 | `python import_data.py` 一条命令；依赖锁 `requirements.txt` | B |
| 可复现性 | 取决于抽样脚本（抽样行不同即数字不一致） | 固定 seed，五台机器跑出**逐行一致**的数据，截图数字对得上（协作纪律第 3 条） | B |
| 规模弹性 | 月度文件体量大，抽样到 5 万行需自定规则 | Trip 行数、分布参数即改即得，便于扩到 10 万行级 | B |

补充排查记录（10-22）：Kaggle「Uber Ride Analytics 2024」为第三方合成教学数据（无司机/车辆 ID、Booking ID 疑似重复），真实性弱于 RideAustin，不采用；其他真实数据集（TLC/Chicago/Kaggle Boston）均无每单评分字段——**每单评分+车型+司乘 ID 三者齐全的真实公开数据全球仅 RideAustin 一家**，故选其作标定来源。

## 二、定稿结论：路线 B（生成器），RideAustin 作"分布标定 + 报告引用"

1. **仓库现状已按 B 铺设**：README 协作纪律第 3 条（数据同源=固定 seed 生成器）、环境表锁定 Python 3.11 + pandas + SQLAlchemy + faker；D 已用 5000 行预研数据在本机跑通验证。
2. **字段适配是一票否决项**：本题评分核心是五实体关系（1:1/N:1），真实数据集缺的恰是这些关系的源字段。
3. **标定来源由 TLC 升级为 RideAustin**：TLC 只有宏观统计；RideAustin 提供乘客/司机粒度 + 每单评分 + 四档车型 + 真实费率，恰好覆盖 B3 扩展二全部标定需求。
4. 诚实性无风险：报告 §1.4 明写"仿真数据、分布标定自 RideAustin 真实运营数据（DOI: 10.17632/wp5gkjbvb9.1）"。

## 三、样本规模与分布参数（C4 落地，标定自 RideAustin 实测）

| 表 | 行数 | 说明 |
|---|---|---|
| Passenger | 3,000 | 姓名/注册信息生成（真实数据仅提供 rider_id 粒度） |
| Driver | 150 | 司机:乘客 ≈ 1:20（方案给定比例） |
| Vehicle | 150 | 与 Driver 一一绑定（N:1，vehicle_id UNIQUE）；品牌/型号可参照 RideAustin 真实车辆分布（Toyota/Cadillac/Nissan 等） |
| Trip | **60,000** | ≥ 5 万行 M2 硬指标；status 占比（D-05 下无 requested）：completed ≈ 82%、canceled ≈ 10%（=取消两类结果：~60% 超宽限期收费取消 + ~40% 宽限期免费取消，D-06 v1.1）、accepted/en_route ≈ 8%；start_time = INSERT（派单）时刻 |
| Payment | ≈ 51,300 | completed ≈ 49,200 行按 **~97%** 生成支付（**故意留 ~2-3% 未支付**使官方 Q2 反连接非空可截图）+ canceled 收费取消行 ≈ 3,600（amount = 取消费 $1.5，D-06 v1.2） |

分布参数（RideAustin 实测标定，**参数来源 = 训练段 80%（按 RIDE_ID 哈希拆，留出 20% 供验证，见实测档案 §七）**，对齐 A3 负载假设）：

- **车型档次占比**（B3 扩展二，v1.2 全量实测）：REGULAR ≈ 95.0% / SUV ≈ 3.7% / PREMIUM ≈ 0.9% / LUXURY ≈ 0.3%（另有 0.1% `b'HONDA'` 脏值清洗后归并；60,000 行 → 约 57,000 / 2,220 / 540 / 180，各档样本量充足）
- **车费结构**：fare = 基础价 + 单价×时长 + 单价×里程；**四档费率实测**（REGULAR $1.5 起 + $0.25/min + $0.99→$1.50/mi 含平台真实调价；SUV $3.0/$2.60/$0.35；PREMIUM $3.0/$2.75/$0.40；LUXURY $5.0/$3.75/$0.50），total_fare 全量均值 ≈ **$13.99**；canceled 收费取消行固定 = 取消费 **$1.5**（=REGULAR 档基础价，D-06 v1.2，help.uber.com 口径，课程简化值，全程美元）
- **评分**（B3 扩展二，v1.2 实测修订）：1–5 整数，仅 completed 行程，**≈ 90.7% 有值**（空置率 9.26%，v1.1 误将空置率数字记为覆盖率；NULL 语义真实存在）；有值行中 ≈ 5★90.3% / 4★5.5% / 3★2.0% / 2★0.6% / 1★1.7%
- `start_time` 晚高峰（17–20 时）集中 ≈ 20%；`method` 占比：balance/cash/card ≈ 45/30/25%（真实数据无支付方式字段，此项沿用 A3 假设）

## 四、遗留动作

- [x] 全组确认选型（10-22，群讨论收敛：生成器路线不变）→ M1 补票
- [x] **v1.2 勘误 + 全量实测档案**（10-23，`a4_rideaustin_profile.md`：A/B 可 JOIN、费率四档、数字校准）→ 建议 E3 同步修订决策表 D-10 论证（原始数据路线的"不可 JOIN"障碍已消除，剩余障碍见档案第三节）
- [x] **已表决（10-23）：全程美元 $**（避免汇率时点）；取消费 ¥8 → $1.5（=REGULAR 档基础价，课程简化值，D-06 v1.2）
- [ ] C4 按第三节参数实现 `import_data.py`（固定 seed 写死在脚本头部，写入 `03_data/source/` 生成说明 + 本文档链接）——**验收三条（D-06 v1.1）**：① canceled 行要么 fare=NULL 且无 Payment、要么 fare=取消费且**恰 1 条** Payment；② status 只用 completed/canceled/accepted/en_route（无 requested/ongoing）；③ Payment.method 取值统一 balance/cash/card
- [ ] B3/B4 按第五节建表开工（不再被数据集阻塞）
- [ ] **留出验证对照表**（10-23 组内收敛）：D 同机产出"生成 60,000 行 vs RideAustin 留出段"分布对照（可比维度清单见实测档案 §七），报告 §5 引用；E 登记标定-留出方案（D-10 附注或 D-11）
- [ ] E3 收档：References 收录数据 DOI + 论文 DOI；报告 §1.4 数据来源声明（回应老师问询）

## 五、B3 扩展二落地（ServiceTier + 评分）

B 的 B3 采用"服务档次 + 乘客评分"扩展，与本数据集对齐（档名保留数据原生英文名，报告可注中文对照，勿未定义直译"快车/专车"）：

```sql
CREATE TABLE service_tier (
  tier_id   TINYINT UNSIGNED PRIMARY KEY,
  name      VARCHAR(16) NOT NULL UNIQUE,      -- REGULAR / SUV / PREMIUM / LUXURY
  fare_multiplier DECIMAL(3,1) NOT NULL       -- 课程演示设定：1.0 / 1.5 / 2.0 / 2.5
);

ALTER TABLE trip
  ADD COLUMN service_tier_id TINYINT UNSIGNED NOT NULL,
  ADD CONSTRAINT fk_trip_tier FOREIGN KEY (service_tier_id) REFERENCES service_tier(tier_id),
  ADD COLUMN rating TINYINT UNSIGNED NULL,    -- 乘客给司机的评分，可为空（≈92.6% completed 有值）
  ADD CONSTRAINT chk_rating CHECK (rating BETWEEN 1 AND 5),
  ADD CONSTRAINT chk_rating_status CHECK (status = 'completed' OR rating IS NULL);
```

扩展二目标查询（D 可预排）：按档次统计已完成行程数、平均 `fare`、收到评分行程数（`COUNT(rating)`）、平均评分（`AVG(rating)` 自动忽略 NULL）——展示 NULL 语义 + 分组聚合。
