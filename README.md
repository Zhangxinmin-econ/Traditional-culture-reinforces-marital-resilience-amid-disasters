# Traditional culture reinforces marital resilience amid disasters

Replication package: de-identified data and Stata code.

County-level marriage records for China (2000–2018) linked to geocoded natural-disaster
exposure from EM-DAT and GDIS, with CFPS and CHARLS used for mechanism analyses.

## How to run

Requires Stata 17+ with `reghdfe`, `psmatch2`, `xtivreg2`, `ivreg2`.

```
cd logs
stata-mp -e do ../code/run_all.do
```

Each `RESULT|` line in `logs/*_results.log` is one cell of a table. The label gives the
table and column.

## Which table comes from which regression

### Main text

| Table | Label prefix | Script | Data | Specification |
|---|---|---|---|---|
| Table 1, col 1–2 (divorce rate) | `T1c1`, `T1c2` | `01_main.do` | `基准回归/最终1.dta` | `reghdfe divorce_rate treat_post [$cv], absorb(year county_code) cluster(county_code)` |
| Table 1, col 3–4 (marriage rate) | `T1c3`, `T1c4` | `01_main.do` | 同上 | 同上，因变量 `marriage_rate` |
| Table 2, col 1 (× jinshi) | `T2c1` | `01_main.do` | 同上 | `reghdfe divorce_rate tp_lnjinshi treat_post lnjinshi $cv`（无固定效应，历史文化变量不随时间变化） |
| Table 2, col 2 (× academies) | `T2c2` | `01_main.do` | 同上 | 同上，交互项为 `academy_50km` |
| Table 2, col 3 (× temples) | `T2c3` | `01_main.do` | 同上 | 同上，交互项为 `temples` |
| Table 3 (优酷评论) | `T3_youku_review*` | `01_main.do` | `文化/电视剧.dta` | `reghdfe divorce_rate tp_x treat_post review* $cv, absorb(year county_code) cluster(county_code)` |
| Table 4 (区域婚俗分样本) | `T4_pa_ears_*`, `T4_male_chauvinism_*`, `T4_彩礼分类_*` | `01_main.do` | `机制/汇总机制2_merged.dta` | 按婚俗指示变量分 0/1 子样本回归 |

### Supplementary

| Table | Label prefix | Script |
|---|---|---|
| Table S3（PSM 平衡性） | `pstest` 输出 | `02_robustness.do` |
| Table S4 col 1（PSM-DID） | `S4c1_psm_did` | `02_robustness.do` |
| Table S4 col 2（IV 一阶段） | `S4c2_iv_first_*` | `02_robustness.do` |
| Table S4 col 3（IV 二阶段） | `S4c3_iv_second_stage` | `02_robustness.do` |
| Table S4 col 4–5（30/70 km 半径） | `S4c4`, `S4c5` | `02_robustness.do` |
| Table S5（CFPS 人口异质性） | `S6_cfps_*` | `03_mechanisms.do` |
| Table S6（优酷评论） | `T3_youku_review*` | `01_main.do` |
| Table S7（故事发源地分样本） | `S7_*_origin_*` | `01_main.do` |
| Table S8（区域婚俗分样本） | `T4_*` | `01_main.do` |
| Table S9（CFPS 收入、裁判文书离婚案件） | `S9_cfps_*`, `S9_divorce_proceedings` | `03_mechanisms.do`, `01_main.do` |
| Table S10–S12（CHARLS 心理/认知/生理） | `S10_12_charls_*` | `03_mechanisms.do` |
| Table S13（灾种与严重程度） | `S13_hazard_*`, `S13_severity_*` | `01_main.do` |

IV 诊断统计量（Cragg–Donald Wald F、Anderson LM、Sargan、内生性检验）见
`logs/02_robustness_results.log` 里的 `IVSTAT|` 行。

## Controls

```
$cv         industry_ratio  log_retail  log_beds  pm25
$cv_charls  lnis  lntfly  fbr  lnfbr  lnrst
```

## Data

| Path | Obs | Used for |
|---|---|---|
| `data/基准回归/最终1.dta` | 12,231 | Table 1, Table 2, Table S3, Table S4 |
| `data/文化/电视剧.dta` | 7,227 | Table 3, Table S6 |
| `data/机制/汇总机制2_merged.dta` | 12,231 | Table 4, Table S7–S9, Table S13 |
| `data/CFPS/` (4 files) | 1,676–20,697 | Table S5, Table S9 |
| `data/CHARLS/` (11 files) | 22,669–63,355 | Table S10–S12 |

`原始代码/` contains the author's original Stata scripts.

## De-identification

Geographic identifiers have been removed or replaced (`code/05_deidentify.do`). Grouping
variables used in the regressions keep their names; their values are replaced by randomly
shuffled anonymous identifiers, so the grouping structure and all estimates are unchanged.

| Variable | De-identified values | Groups |
|---|---|---|
| `county_code` | 900001–902044, shuffled | 2,037 |
| `countyid` (CFPS) | 800001–800106, shuffled | 106 |
| `city` (CHARLS) | 700001–700115, shuffled | 115 |

Dropped: county / prefecture / province names and codes; CFPS `PAC`, `provname`, `cityname`,
`countyname`, `norm_prov`, `norm_county`; CHARLS `province` and respondent `ID`.

The random seeds are not included in this repository. The crosswalk between anonymous and
original codes is held by the author.

## Third-party survey data

CFPS is distributed by the Institute of Social Science Survey, Peking University, and CHARLS
by the National School of Development, Peking University. Both require a data-use application.
Users extending this work beyond the files provided here should obtain the data from those
providers and cite them accordingly.
