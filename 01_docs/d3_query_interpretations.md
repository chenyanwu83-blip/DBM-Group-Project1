# D3 · 查询验证包解读（入报告 §4 素材）

> 负责人：D（凌彤）· 2026-10-29 · 10 条查询全部在 C4 正式数据（Trip 60,000 行，seed=534，10-27 hotfix 版）上验证
> 截图：`03_data/screenshots/queries/q01…q10_*_1029.png`（C2 B 类三要素：SQL 原文 + Result Grid + 行数标签）
> 用法：每条英文解读放进报告 §4 对应 Listing/Figure 下方；**中文括注仅供组内理解，不进报告**

## 核验结论

- 10/10 截图符合 C2 B 类三要素（q06 曾裁掉标题栏已重拍换新）
- 关键数字全部对上预期：档次 95.08/3.75/0.90/0.30%（标定 95.1/3.7/0.9/0.3）；评分覆盖 ≈89.9%；top3 区位 34.6%（标定 35%）；晚高峰 17–20 时 13,459 单（22.4%）；未支付 completed 1,442 行（Q2 非空 ✓）；月度营收 2025-11→2026-10 共 12 个月稳步上行
- 遗留自查两项（不影响归档）：① q04 截图 rnk 列放大确认应为 1–10；② q10 行数标签应显示 "4 row(s) returned"
- 可选增强（D8 对账更稳，非必需）：q01/q05/q08 被 Workbench 1000 行截断，可在同窗补一条 COUNT（q05 加 SUM(fare)）后重截

## 逐条解读（英文为报告成稿句）

### Q1 Completed Trips with Their Payments — `q01_completed_payment_1029.png`
*This reconciliation view pairs every completed trip with its payment and confirms the 1:1 Trip–Payment mapping — fare equals amount row by row. Card dominates the payment mix in the latest sample, and the newest-first ordering supports daily operations review.*
（对账视图：1:1 逐行实证；card 为主渠道；最新在前便于运营复核。注：结果集约 49,200 行，网格因 Workbench 默认 Limit 1000 显示前 1000 行）

### Q2 Drivers with Completed but Unpaid Trips — `q02_unpaid_drivers_1029.png`
*All 150 drivers carry some unpaid completed trips: the calibrated 2.9% unpaid rate (1,442 trips) spreads across the whole fleet rather than a few outliers, roughly ten outstanding trips per driver. Collections should therefore run as a routine batch process instead of exception handling.*
（150 名司机全员有应收——数据设计使然非查询错误；催收应例行化。查询用 NOT EXISTS 反连接 + DISTINCT）

### Q3 Total Fare Earned per Vehicle — `q03_vehicle_revenue_1029.png`
*Per-vehicle revenue is well balanced: head vehicles accumulate roughly 440–460 trips against a fleet average of 400, with no dominant asset. This supports using the vehicle dimension for stable asset-level accounting.*
（头部车 440+ 单 vs 均值 400，运力分布均衡；车辆口径适合资产核算）

### Q4 Driver Daily Income Ranking — `q04_driver_daily_income_1029.png`
*The top driver-day earns $292, noticeably above a typical day, showing how earnings concentrate on peak days; the RANK() window computes placement over the aggregated daily income in a single pass, avoiding a self-join formulation.*
（单日收入头部 $292；窗口函数一次扫描出排名，替代自连接写法）

### Q5 Completed Trips Unpaid for Over 24 Hours — `q05_unpaid_over_24h_1029.png`
*Every one of the 1,442 unpaid completed trips is already far beyond the 24-hour threshold (the simulated history ends before load time), so the filter currently passes all of them and the total exposure is roughly the sum of their fares. In production the threshold would isolate genuinely overdue receivables.*
（诚实口径：快照数据全部远超 24h，阈值暂不筛人；生产环境该阈值用于圈定真正逾期。总敞口≈未支付车费合计，可补 SUM 增强截图）

### Q6 Peak-Hour Order Volume — `q06_peak_hours_1029.png`
*Demand concentrates in the evening block 17:00–20:00 (13,459 trips, 22.4% of all accepted trips) with a secondary morning shoulder around 8:00–10:00, peaking at 3,915 trips in hour 18. Dispatch should pre-position supply before 17:00.*
（晚高峰 22.4%、18 时 3,915 单；调度 17 点前预热运力。两次拍摄结果一致，查询稳定可复现）

### Q7 Monthly Revenue Trend — `q07_monthly_revenue_1029.png`
*Monthly paid revenue rises steadily from $49.3k in 2025-11 to $54.8k in 2026-10 (about +11% over the year) with no seasonal dips, supporting the growth assumption stated in Section 1.*
（12 个月 +11% 稳步上行、无季节回落，与 §1 目标闭环）

### Q8 Repeat Passengers — `q08_repeat_passengers_1029.png`
*Repeat usage is the norm rather than the exception: the list exceeds the 1,000-row display cap, and the heaviest passenger rides 79 trips across 74 distinct days — roughly one trip every five days. Retention-oriented metrics can be computed directly from this pattern.*
（复购是常态，最重度乘客≈每 5 天一单；留存指标可直接从该模式计算）

### Q9 Hot Zones by Accepted Trips — `q09_hot_zones_1029.png`
*The top three zones — Downtown (16.9%), West Campus (9.4%) and South Congress (8.2%) — absorb 34.6% of accepted trips, matching the calibrated spatial concentration of ≈35%. Note this counts accepted trips only: requests that never got a driver are outside the data and cannot be inferred (Section 6 limitation).*
（top3 34.6% 对上标定 35%；**必须保留末句局限声明**——D-11 口径红线：只答"哪里已接单最多"）

### Q10 Service Tier × Rating — `q10_service_tier_rating_1029.png`
*The tier mix matches calibration (95.1% REGULAR, 3.7% SUV, 0.9% PREMIUM, 0.3% LUXURY). Average fare climbs from $13.85 to $41.62 (≈3×) across tiers while ratings stay flat around 4.85 with ~90% coverage — premium products monetize without hurting satisfaction.*
（档次结构对上标定；高档 3 倍定价、评分不掉不降覆盖——产品线健康。本条数字同时供 §5.5 留出对照页使用，一材两用）

## 与 §5.5 留出对照页的衔接

生成段对照数字直接取自本包：Q6（晚高峰 22.4% vs 标定 20.5%）、Q10（档次占比/评分覆盖 89.9%/星级均值 4.85）；留出段数字取 `a4_rideaustin_profile.md` §七。
