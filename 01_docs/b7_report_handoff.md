# B7 报告 §2 交接（2026-11-03）

- B 已写 `05_report/sections/sec2_er.tex`，配图为 `05_report/figures/er_final.pdf`。图是八表 ER v1.0.1 的矢量报告版（仅记法修订），图内嵌入 Times New Roman。
- 2026-11-04 图示记法修订为 ER v1.0.1：把 PDF 中的 `1:0..1` 与 draw.io/SVG 中的 `1:1*` 统一为老师作业要求使用的 `1:1`，在图注和正文解释可选性；八表结构与 DDL 不变。E 合章时请使用新版 `er_final.pdf` 和新版 §2，旧版 PDF 不再作为报告配图。
- §2 说明了五张老师原表、三张独立扩展表、基数与可选性、D-05/D-11 查询口径，以及 Lecture 08 的 1NF–3NF 核查。B5 详细核查在 `01_docs/b5_normalization_review.md`。
- B 的章节放入最小 LaTeX 项目后，2026-11-03 编译成功。**整份报告尚未通过编译**：现有 `05_report/main.tex` 第 55 行使用未定义的 `\middot`，编译在进入 §2 前停止。按 `05_report/README.md` 的分工，`main.tex` 仅 E 可改，请 E 修正后再合章编译、检查字号和页数。
- 用户要求全部字体 Times New Roman。ER 矢量图已嵌入该字体；整份 LaTeX 报告的字体由 E 所管的 `main.tex` 统一设置，当前尚未验证达到此要求。
- C 的 B6 联签、D 的 Q1/Q2 正文、整份报告的最终复核均仍待完成，不能因为 §2 章节编译通过就标为全报告完成。

## 11 月 4 日跨章节扫盘：给 A、D、E 的具体待改处

以下只记录已在仓库正文中看到的冲突或未完成项，不代替原负责人改写其章节，也不把待办写成完成。

- **给 A 和 E（`05_report/sections/sec1_context.tex`）：**开头及利益相关者段把 Driver–Vehicle 写成 `N:1`，与官方 `Driver.vehicle_id UNIQUE` 和 §2 的实际最大 `1:1` 不一致。请统一为“一名司机恰一辆车；一辆车至多一名司机”，并保留老师示意图与 Listing 17 不一致的说明。Trip–Payment 可用 `1:1` 表示最大配对，但应补一句“每笔 Trip 可无 Payment”。
- **给 A 和 E（同一 §1 的 Dataset Selection Rationale 末句）：**原文称 80/20 留出对照“reported in Section 5”，但现有 §5 仍全是 `TODO(D)`，`03_data/source/README.md` 也说明当前生成参数仍取全量资料。取得训练段专用参数和留出 20% 数字之前，请改成“planned”或等事实完成后再写“reported”；不能把同一全量统计同时称作独立验证。
- **给 D 和 E（`05_report/sections/sec5_eval.tex`）：**整节实验和分布对照仍待写；按 D-12，生成数据与留出段的车型占比、已完成行程车费、评分覆盖与分布、高峰份额须单独给数字。车费和评分限定已完成行程，时间字段要同义且时区一致；业务查询结果与分布对照分开写。
- **给 E（`05_report/main.tex`）：**封面 `\middot` 在当前 pdfLaTeX 配置下导致编译错误，组名仍是 `TODO-GroupName`，全文 Times New Roman 也未完成统一验证。`main.tex` 属 E；B 不改主文件。请 E 合稿后提供编译成功的完整 PDF，B 再执行 B8 全文复核。
- **给 A（`01_docs/a4_dataset_decision.md` §五）：**旧草案仍含 `ALTER TABLE trip` 增列；D-11 的最终决定和 C 的 `build.sql` §3 已采用独立 `trip_detail`、`service_tier`、`pickup_zone` 三表。请把旧段标为历史提案或回填最终方案，避免扫盘者误当成现行建库说明。
