# 04_figures — ER 图与报告插图

| 文件 | 内容 | 负责人 |
|---|---|---|
| `er_baseline.drawio` | 官方 Topic 5 五实体基线复绘（B2），逐项对照官方图打勾 | B |
| `er_final.drawio` | 八实体 ER v1.0.1 可编辑源文件；B4 于 11-03 冻结结构，11-04 只统一基数记法 | B |
| `er_final.svg` | 与可编辑图同一记法的矢量展示版；报告另用 `05_report/figures/er_final.pdf` | B |

## 官方 ER 约定（评分点，务必遵循）

- 矩形 = 实体，属性写在框内，**主键斜体**
- 子实体中外键属性以 `*id` 标注
- 每条连线标注基数：`1:N` / `N:M` / `1:1`
- N:M 必须用关联实体拆成两个 1:N

`.drawio` 源文件必须提交（可编辑、可追溯）。

最终图对应的数据字典与逐关系对账见 `01_docs/b4_data_dictionary.md`。图上的 `1:1` 标最大配对数；Payment/detail 对 Trip、Driver 对 Vehicle 的可选性写在图注和字典中。旧 PDF 的 `1:0..1` 和旧 draw.io 的 `1:1*` 已在 v1.0.1 统一，八表结构未变。
