*==============================================================
* 03_mechanisms.do  —— 附录 S9-S12：CFPS 与 CHARLS 机制
* 规格见 原始代码/原作者主脚本_无标题-副本.do
*==============================================================
do "D:/论文文件夹/自然灾害与婚姻/提交_复现包/code/00_config.do"

capture log close _all
log using "${logs}/03_mechanisms_results.log", replace text

*--------------------------------------------------------------
* S9  CFPS 收入
*--------------------------------------------------------------
use "${d_cfps}/家庭个人收入subsample.dta", clear
capture drop tp
generate double tp = treat_50km * post_50km
reghdfe lnpersonincome tp $cv if lnpersonincome > 6.9, absorb(countyid year)
post_est, label("S9_cfps_personal_income") coef(tp)

use "${d_cfps}/家庭收入subsample.dta", clear
capture drop tp
generate double tp = treat_50km * post_50km
reghdfe lnfamilyincome tp $cv if lnfamilyincome > 7.7200, absorb(countyid year)
post_est, label("S9_cfps_household_income") coef(tp)

*--------------------------------------------------------------
* S6  CFPS 性别压力与人口异质性（logit）
*--------------------------------------------------------------
use "${d_cfps}/性别压力 .dta", clear
capture drop tp
generate double tp = treat_50km * post_50km
logit pressure_binary tp $cv
post_est, label("S6_cfps_pressure_binary") coef(tp)

use "${d_cfps}/35和小孩1.dta", clear
capture drop tp child_dummy
generate double tp = treat_50km * post_50km
generate byte child_dummy = cond(missing(child_age), 0, child_age > 0)
logit divorced tp $cv if adult_age <  35
post_est, label("S6_cfps_age_under35") coef(tp)
logit divorced tp $cv if adult_age >= 35
post_est, label("S6_cfps_age_35plus") coef(tp)
logit divorced tp $cv if child_dummy == 0
post_est, label("S6_cfps_no_children") coef(tp)
logit divorced tp $cv if child_dummy == 1
post_est, label("S6_cfps_with_children") coef(tp)

*--------------------------------------------------------------
* S10-S12  CHARLS 心理 / 认知 / 生理
*--------------------------------------------------------------
foreach item in "cesd10" "satlife" "hope" "total_cognition" "memeory" ///
                "executive" "sleep" "bl_crp" "pulse" "systo" "diasto" {
    local fname "`item' .dta"
    if "`item'" == "pulse" local fname "pulse.dta"
    use "${d_charls}/`fname'", clear
    capture drop tp
    generate double tp = treat_50km * post_50km
    if "`item'" == "sleep" {
        reghdfe sleep tp $cv_charls if sleep > 6, absorb(city year) vce(cluster city)
    }
    else if "`item'" == "bl_crp" {
        reghdfe bl_crp tp $cv_charls if bl_crp >= 0.1 & bl_crp <= 200, ///
            absorb(city year) vce(cluster city)
    }
    else {
        reghdfe `item' tp $cv_charls, absorb(city year) vce(cluster city)
    }
    post_est, label("S10_12_charls_`item'") coef(tp)
}

display as result "MECH_AUDIT_COMPLETE"
log close
