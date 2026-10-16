# 05_report — Overleaf 报告工程

报告在 Overleaf 协作写作，此目录为工程镜像与历次导出存档（**以 GitHub 为最终版本**）。

## 工程结构（E2 于 10-17 建好骨架）

```
05_report/
├─ main.tex                    # 封面+目录+合章（仅 E 可改）
├─ sections/
│  ├─ sec1_context.tex         # §1 业务背景与目标（A）
│  ├─ sec2_er.tex              # §2 ER 模型（B）
│  ├─ sec3_impl.tex            # §3 实现：环境/DDL/导数/截图（C）
│  ├─ sec4_sql.tex             # §4 查询与概念问答（D）
│  ├─ sec5_eval.tex            # §5 实验设计与结果（D，C 供数据）
│  └─ sec6_conclusion.tex      # §6 结论与局限（A+E）
├─ references.bib              # 官方文档、MySQL 手册、教材、数据集引用
├─ appendix_contribution.tex   # 附录 A 贡献表（E）
└─ appendix_sql.tex            # 附录 B 完整脚本（C 供）
```

## 约定

- 各人只写自己的章节文件；`main.tex` 与样式只有 E 可改。
- 跨章引用用 `\ref` 自动编号，禁止手写"见第 X 页"。
- 未完成处统一 `% TODO(姓名): 说明`，例会前清零；以 Overleaf 无错编译为准。
- 每次导出 PDF 命名 `report_vYYYYMMDD.pdf` 留痕。
- 硬性要求：正文 10–12 页、字号 12、封面列组名与全员学号、ER 为矢量。
- 文字 11-03（M4）冻结。
