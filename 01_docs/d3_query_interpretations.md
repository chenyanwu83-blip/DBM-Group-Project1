# 查询验证记录

10 条查询在正式数据（60,000 行 Trip）上全部跑通，截图按规范归档。

截图在 `03_data/screenshots/queries/`。

英文解读直接进报告 §4，中文注释只是给自己看的参考。

## 数字核对

- 档次分布：95.08 / 3.75 / 0.90 / 0.30%（跟标定值基本一致）
- 评分覆盖率：89.9%
- top3 区位占比：34.6%（标定 35%）
- 晚高峰 17-20 时：13,459 单（22.4%）
- 完成未支付：1,442 行（Q2 结果非空，符合预期）
- 月度营收从 2025-11 到 2026-10 稳步上升

## 各条查询的英文解读

**Q1** — This reconciliation view pairs every completed trip with its payment and confirms the 1:1 Trip–Payment mapping — fare equals amount row by row. Card dominates the payment mix in the latest sample, and the newest-first ordering supports daily operations review.

**Q2** — All 150 drivers carry some unpaid completed trips: the calibrated 2.9% unpaid rate (1,442 trips) spreads across the whole fleet rather than a few outliers, roughly ten outstanding trips per driver. Collections should therefore run as a routine batch process instead of exception handling.

**Q3** — Per-vehicle revenue is well balanced: head vehicles accumulate roughly 440–460 trips against a fleet average of 400, with no dominant asset. This supports using the vehicle dimension for stable asset-level accounting.

**Q4** — The top driver-day earns $292, noticeably above a typical day, showing how earnings concentrate on peak days; the RANK() window computes placement over the aggregated daily income in a single pass, avoiding a self-join formulation.

**Q5** — Every one of the 1,442 unpaid completed trips is already far beyond the 24-hour threshold (the simulated history ends before load time), so the filter currently passes all of them and the total exposure is roughly the sum of their fares. In production the threshold would isolate genuinely overdue receivables.

**Q6** — Demand concentrates in the evening block 17:00–20:00 (13,459 trips, 22.4% of all accepted trips) with a secondary morning shoulder around 8:00–10:00, peaking at 3,915 trips in hour 18. Dispatch should pre-position supply before 17:00.

**Q7** — Monthly paid revenue rises steadily from $49.3k in 2025-11 to $54.8k in 2026-10 (about +11% over the year) with no seasonal dips, supporting the growth assumption stated in Section 1.

**Q8** — Repeat usage is the norm rather than the exception: the list exceeds the 1,000-row display cap, and the heaviest passenger rides 79 trips across 74 distinct days — roughly one trip every five days. Retention-oriented metrics can be computed directly from this pattern.

**Q9** — The top three zones — Downtown (16.9%), West Campus (9.4%) and South Congress (8.2%) — absorb 34.6% of accepted trips, matching the calibrated spatial concentration of ≈35%. Note this counts accepted trips only: requests that never got a driver are outside the data and cannot be inferred (Section 6 limitation).

**Q10** — The tier mix matches calibration (95.1% REGULAR, 3.7% SUV, 0.9% PREMIUM, 0.3% LUXURY). Average fare climbs from $13.85 to $41.62 (≈3×) across tiers while ratings stay flat around 4.85 with ~90% coverage — premium products monetize without hurting satisfaction.
