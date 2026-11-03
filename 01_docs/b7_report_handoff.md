# B7 报告 §2 交接（2026-11-03）

- B 已写 `05_report/sections/sec2_er.tex`，配图为 `05_report/figures/er_final.pdf`。图是八表 ER v1.0 的矢量报告版，图内嵌入 Times New Roman。
- §2 说明了五张老师原表、三张独立扩展表、基数与可选性、D-05/D-11 查询口径，以及 Lecture 08 的 1NF–3NF 核查。B5 详细核查在 `01_docs/b5_normalization_review.md`。
- B 的章节放入最小 LaTeX 项目后，2026-11-03 编译成功。**整份报告尚未通过编译**：现有 `05_report/main.tex` 第 55 行使用未定义的 `\middot`，编译在进入 §2 前停止。按 `05_report/README.md` 的分工，`main.tex` 仅 E 可改，请 E 修正后再合章编译、检查字号和页数。
- 用户要求全部字体 Times New Roman。ER 矢量图已嵌入该字体；整份 LaTeX 报告的字体由 E 所管的 `main.tex` 统一设置，当前尚未验证达到此要求。
- C 的 B6 联签、D 的 Q1/Q2 正文、整份报告的最终复核均仍待完成，不能因为 §2 章节编译通过就标为全报告完成。
