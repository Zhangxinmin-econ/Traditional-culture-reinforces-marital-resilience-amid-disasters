*==============================================================
* 01_main.do  —— 正文 Table 1-4 + 附录 Table S6 / S7 / S9 / S13
* 规格见 原始代码/原作者主脚本_无标题-副本.do
*==============================================================
do "D:/论文文件夹/自然灾害与婚姻/提交_复现包/code/00_config.do"

capture log close _all
log using "${logs}/01_main_results.log", replace text

*--------------------------------------------------------------
* Table 1  基准回归（Table 1）
*--------------------------------------------------------------
use "${f_base}", clear
capture drop tp_check
generate double tp_check = treat_50km * post_50km
count if tp_check != treat_post
display as result "CHECK|treat_post_mismatch=" r(N)
drop tp_check
count if academy != academy_50km
display as result "CHECK|academy_vs_academy50km_mismatch=" r(N)

reghdfe divorce_rate  treat_post,      absorb(year county_code) cluster(county_code)
post_est, label("T1c1_divorce_nocontrols") coef(treat_post)
reghdfe divorce_rate  treat_post $cv,  absorb(year county_code) cluster(county_code)
post_est, label("T1c2_divorce_controls")   coef(treat_post)
reghdfe marriage_rate treat_post,      absorb(year county_code) cluster(county_code)
post_est, label("T1c3_marriage_nocontrols") coef(treat_post)
reghdfe marriage_rate treat_post $cv,  absorb(year county_code) cluster(county_code)
post_est, label("T1c4_marriage_controls")   coef(treat_post)

summarize divorce_rate treat_post $cv

*--------------------------------------------------------------
* Table 2  历史传统文化交互（Table 2）
*--------------------------------------------------------------
capture drop tp_lnjinshi tp_academy tp_temples
generate double tp_lnjinshi = treat_post * lnjinshi
generate double tp_academy  = treat_post * academy_50km
generate double tp_temples  = treat_post * temples

reghdfe divorce_rate tp_lnjinshi treat_post lnjinshi $cv
post_est, label("T2c1_x_lnjinshi") coef(tp_lnjinshi)
post_est, label("T2c1_treat_post") coef(treat_post)
reghdfe divorce_rate tp_academy  treat_post academy  $cv
post_est, label("T2c2_x_academy")  coef(tp_academy)
post_est, label("T2c2_treat_post") coef(treat_post)
reghdfe divorce_rate tp_temples  treat_post temples  $cv
post_est, label("T2c3_x_temples")  coef(tp_temples)
post_est, label("T2c3_treat_post") coef(treat_post)

*--------------------------------------------------------------
* Table 4 / S7  区域婚俗与故事发源地（Table 4 与 Table S7 / S8）
*--------------------------------------------------------------
use "${f_mech}", clear
capture drop treat_post
generate double treat_post = treat_50km * post_50km

foreach spec in pa_ears male_chauvinism 彩礼分类 {
    forvalues v = 0/1 {
        reghdfe divorce_rate treat_post $cv if `spec' == `v', ///
            absorb(year county_code) cluster(county_code)
        post_est, label("T4_`spec'_`v'") coef(treat_post)
    }
}
foreach spec in story_origin liangzhu_origin niulang_origin baishe_origin {
    forvalues v = 0/1 {
        reghdfe divorce_rate treat_post $cv if `spec' == `v', ///
            absorb(year county_code) cluster(county_code)
        post_est, label("S7_`spec'_`v'") coef(treat_post)
    }
}

*--------------------------------------------------------------
* S9  裁判文书离婚案件（Table S9）
*--------------------------------------------------------------
replace 离婚案件数 = 0 if missing(离婚案件数)
capture drop divorce_proceedings
generate double divorce_proceedings = ln(离婚案件数/population（人） + 1)
reghdfe divorce_proceedings treat_post $cv, absorb(year county_code) cluster(county_code)
post_est, label("S9_divorce_proceedings") coef(treat_post)

*--------------------------------------------------------------
* S13  灾种与严重程度（Table S13）
*--------------------------------------------------------------
capture drop tp_geo tp_cli tp_met tp_hyd damage affected
generate double tp_geo = treat_50km_地质类 * post_50km_地质类
generate double tp_cli = treat_50km_气候类 * post_50km_气候类
generate double tp_met = treat_50km_气象类 * post_50km_气象类
generate double tp_hyd = treat_50km_水文类 * post_50km_水文类
generate double damage   = ln(total_damage_50km + 1)
generate double affected = ln(total_affected_50km/1000 + 1)

foreach h in geo cli met hyd {
    reghdfe divorce_rate tp_`h' $cv, absorb(year county_code) cluster(county_code)
    post_est, label("S13_hazard_`h'") coef(tp_`h')
}
reghdfe divorce_rate damage   $cv, absorb(year county_code) cluster(county_code)
post_est, label("S13_severity_damage")   coef(damage)
reghdfe divorce_rate affected $cv, absorb(year county_code) cluster(county_code)
post_est, label("S13_severity_affected") coef(affected)

*--------------------------------------------------------------
* Table 3  优酷评论（Table 3 与 Table S6）
*--------------------------------------------------------------
use "${f_drama}", clear
capture drop treat_post
generate double treat_post = treat_50km * post_50km
forvalues k = 0/3 {
    if `k' == 0  local rv "review"
    else         local rv "review`k'"
    capture drop tp_x
    generate double tp_x = treat_post * `rv'
    reghdfe divorce_rate tp_x treat_post `rv' $cv, ///
        absorb(year county_code) cluster(county_code)
    post_est, label("T3_youku_`rv'") coef(tp_x)
    drop tp_x
}

display as result "MAIN_AUDIT_COMPLETE"
log close
