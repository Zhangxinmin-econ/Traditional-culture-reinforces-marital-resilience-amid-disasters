*==============================================================
* 02_robustness.do  —— 附录 Table S4
*   第1列  PSM-DID
*   第2列  工具变量 一阶段
*   第3列  工具变量 二阶段
*   第4列  30km 半径
*   第5列  70km 半径
* 附录 Table S3：PSM 匹配前后协变量平衡性
*==============================================================
do "D:/论文文件夹/自然灾害与婚姻/提交_复现包/code/00_config.do"

capture log close _all
log using "${logs}/02_robustness_results.log", replace text

use "${f_base}", clear
bysort county_code: generate n_years = _N
drop if n_years == 1
drop n_years

*--------------------------------------------------------------
* Table S4 第4、5列：替换灾害暴露半径
*--------------------------------------------------------------
capture drop tp30 tp70
generate double tp30 = treat_30km * post_30km
generate double tp70 = treat_70km * post_70km

reghdfe divorce_rate tp30 $cv, absorb(year county_code) vce(cluster county_code)
post_est, label("S4c4_radius_30km") coef(tp30)
reghdfe divorce_rate tp70 $cv, absorb(year county_code) vce(cluster county_code)
post_est, label("S4c5_radius_70km") coef(tp70)

*--------------------------------------------------------------
* Table S3：倾向得分匹配平衡性
* Table S4 第1列：PSM-DID
*--------------------------------------------------------------
logit treat_50km $cv
capture drop pscore
predict double pscore
psmatch2 treat_50km, pscore(pscore) outcome(treat_post) neighbor(1) common caliper(0.1)
pstest $cv, both
reghdfe divorce_rate treat_post $cv if _weight == 1, ///
    absorb(year county_code) vce(cluster county_code)
post_est, label("S4c1_psm_did") coef(treat_post)

*--------------------------------------------------------------
* Table S4 第2、3列：地理工具变量
*   IV_fault    断裂带密度 × 年份
*   IV_geology  地质复杂度（熵）× 年份
*   IV_river    河网密度 × 年份
*--------------------------------------------------------------
xtset year county_code
capture drop dyear*
tabulate year, generate(dyear)
capture drop IV_fault IV_geology IV_river
generate double IV_fault   = fault_density      * year/10000
generate double IV_geology = geology_entropy    * year/10000
generate double IV_river   = mean_river_density * year/10000
summarize fault_density geology_entropy mean_river_density

xtivreg2 divorce_rate dyear* (treat_post = IV_fault IV_geology IV_river) $cv, ///
    first fe endog(treat_post) savefirst savefprefix(first_)
post_est, label("S4c3_iv_second_stage") coef(treat_post)
display as result "IVSTAT|CraggDonaldWaldF=" %12.6f e(cdf) ///
    "|AndersonLM_p=" %12.6f e(idp) ///
    "|Sargan_p=" %12.6f e(jp) ///
    "|Endogeneity_p=" %12.6f e(estatp)

estimates restore first_treat_post
post_est, label("S4c2_iv_first_fault")   coef(IV_fault)
post_est, label("S4c2_iv_first_geology") coef(IV_geology)
post_est, label("S4c2_iv_first_river")   coef(IV_river)

log close
