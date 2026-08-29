cd "E:\自然灾害\stata\基准回归"
use "E:\自然灾害\stata\基准回归\最终1.dta",clear
xtset year county_code 
* 先计算每个county_code出现的年份数
bysort county_code: gen n_years = _N

* 删除只出现一年的观察值
drop if n_years == 1

* 删除生成的辅助变量
drop n_years

gen treat×post = treat_50km*post_50km
global cv "industry_ratio log_retail log_beds pm25"

sum2docx divorce_rate marriage_rate treat×post damage affected $cv lnjinshi academy temples using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

corr2docx lndivorce lnmarriage $cv using out1.docx,replace star fmt(%9.3f) pearson(pw)title("表2:相关性分析")note("Note: *** , ** , and * indicate significance at the 1%, 5%, and 10% levels, respectively.")  spearman(ignore)

**# 基准回归
reghdfe divorce_rate treat×post , absorb(year county_code) cluster(county_code)
est store r1
reghdfe divorce_rate treat×post $cv, absorb(year county_code) cluster(county_code)
est store r2
reghdfe marriage_rate treat×post , absorb(year county_code) cluster(county_code)
est store r3
reghdfe marriage_rate treat×post $cv, absorb(year county_code) cluster(county_code)
est store r4

reg2docx r1 r2 r3 r4 using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post) addfe("Controls=YES" "County=YES" "Year=YES") 

**# 传统平行趋势检验

reghdfe divorce_rate before4_50km before3_50km before2_50km   current_50km after1_50km after2_50km after3_50km after4_50km $cv, absorb(county_code year) 

pselect3 divorce_rate before4_50km before3_50km before2_50km   current_50km after1_50km after2_50km after3_50km after4_50km $cv, absorb(county_code year) pos(after1_50km) s(0.04) cmd(reghdfe)

**# 工具变量法
xtset year county_code 
tab year, gen(dyear)

gen fault = fault_density
gen geology = geology_entropy
gen river = mean_river_density
drop IV_fault IV_geology IV_river
gen IV_fault = fault_density * year/10000
gen IV_geology = geology_entropy * year/10000
gen IV_river = mean_river_density * year/10000

sum2docx fault geology river using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

xtivreg2 divorce_rate dyear* (treat_post = IV_fault IV_geology IV_river) $cv, first fe endog(treat_post) savefirst
est store r1
xtivreg2 divorce_rate dyear* (treat_post = IV_fault IV_geology IV_river) $cv, first fe endog(treat_post) 
est store _xtivreg2_dig

xtreg divorce_rate IV_fault IV_geology IV_river $cv i.year, fe 
predict divorce_rate_hat, xb
xtreg divorce_rate divorce_rate_hat $cv i.year, fe 

* 清除之前存储的估计结果
eststo clear

* 执行回归命令
eststo m1: xtivreg2 divorce_rate dyear* (treat_post = IV_fault IV_geology IV_river) $cv, first fe endog(treat_post) savefirst savefprefix(first_)

* 添加第一阶段回归统计量
estadd scalar F = `e(widstat)' : first_treat_post
estadd scalar cdf1 = `e(cdf)' : first_treat_post
estadd scalar sstat1 = `e(sstat)' : first_treat_post        
estadd scalar KPLMS = `e(idstat)' : first_treat_post    
estadd scalar KPPval = `e(idp)' : first_treat_post  

* 输出保存结果
esttab first_treat_post m1 using "IV_regression_results.rtf", replace    ///
    coeflabels(_cons "Constant")     ///
    b(4) se(3) compress nogaps scalar(F)      ///
    order(IV_fault IV_geology IV_river treat_post $cv)     ///
    stats(N r2 F cdf1 sstat1 KPLMS KPPval, fmt(0 3 3 3 3 3 3) ///
    labels("Observations" "R²" "F-statistic" "CD Wald F" "SW S stat." ///
    "Kleibergen-Paap LM" "Kleibergen-Paap p-value"))     ///
    nobaselevels star(* 0.10 ** 0.05 *** 0.01)

* 清空存储
eststo clear

**# 自然灾害范围更换
* 先计算每个county_code出现的年份数
bysort county_code: gen n_years = _N

* 删除只出现一年的观察值
drop if n_years == 1

* 删除生成的辅助变量
drop n_years
pa_ears
gen treat×post_70 = treat_70km*post_70km

reghdfe divorce_rate treat×post_30 $cv ,  absorb(year county_code) cluster(county_code)
est store r1
reghdfe divorce_rate treat×post_70 $cv ,  absorb(year county_code) cluster(county_code)
est store r2

reg2docx r1 r2 using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post_30 treat×post_70) addfe("Controls=YES"  "County=YES" "Year=YES" )

**# PSM
logit treat_50km $cv 
drop pscore
predict pscore

psmatch2 treat_50km, pscore(pscore) outcome(treat×post) neighbor(1) common caliper(0.1) 

pstest $cv,both graph
reghdfe divorce_rate treat×post $cv if _weight==1 ,  absorb(year county_code) cluster(county_code)
est store r1

reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post) addfe("City=YES" "Year=YES" "Controls=YES")

**# 异质性分析

gen treat×post = treat_50km*post_50km
gen treat×post1 = treat_50km_地质类*post_50km_地质类
gen treat×post2 = treat_50km_气候类*post_50km_气候类
gen treat×post3 = treat_50km_气象类*post_50km_气象类
gen treat×post4 = treat_50km_水文类*post_50km_水文类

reghdfe divorce_rate treat×post1 $cv, absorb(year county_code) cluster(county_code)
est store r1
reghdfe divorce_rate treat×post2 $cv, absorb(year county_code) cluster(county_code)
est store r2
reghdfe divorce_rate treat×post3 $cv, absorb(year county_code) cluster(county_code)
est store r3
reghdfe divorce_rate treat×post4 $cv, absorb(year county_code) cluster(county_code)
est store r4
reg2docx r1 r2 r3 r4 using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post1 treat×post2 treat×post3 treat×post4) addfe("Controls=YES" "County=YES" "Year=YES") 

drop affected damage
gen damage = ln(total_damage_50km+1)
gen affected = ln(total_affected_50km/1000+1)
gen treat×post×damage = treat×post*damage
gen treat×post×affected = treat×post*affected

reghdfe divorce_rate damage  $cv, absorb(year county_code) cluster(county_code)
est store r1
reghdfe divorce_rate affected $cv, absorb(year county_code) cluster(county_code)
est store r2
reg2docx r1 r2 using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(damage affected) addfe("Controls=YES" "City=YES" "Year=YES" )

**# 文化

cd "E:\自然灾害\stata\文化"
use "E:\自然灾害\stata\文化\电视剧.dta", clear 
gen treat×post = treat_50km*post_50km
gen treat×post×review = treat×post*review
// gen review1 = 梁祝_年度评论数_二分类
gen treat×post×review1 = treat×post*review1
// gen review2 = 牛郎织女_年度评论数_二分类
gen treat×post×review2 = treat×post*review2
// gen review3 = 新白娘子_年度评论数_二分类
gen treat×post×review3 = treat×post*review3

sum2docx review review1 review2 review3 using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

reghdfe divorce_rate treat×post×review treat×post review $cv ,  absorb(year county_code) cluster(county_code)
est store r1
reghdfe divorce_rate treat×post×review1 treat×post review1 $cv ,  absorb(year county_code) cluster(county_code)
est store r2
reghdfe divorce_rate treat×post×review2 treat×post review2 $cv ,  absorb(year county_code) cluster(county_code)
est store r3
reghdfe divorce_rate treat×post×review3 treat×post review3 $cv ,  absorb(year county_code) cluster(county_code)
est store r4

reg2docx r1 r2 r3 r4 using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post×review treat×post×review1 treat×post×review2 treat×post×review3 treat×post review1 review2 review3) addfe("Controls=YES" "City=YES" "Year=YES")


cd "E:\自然灾害\stata\文化"
use "E:\自然灾害\stata\基准回归\最终1.dta", clear 
// gen jinshi = jinshi_50km/1000
// gen academy = academy_50km
// gen temples = temples_50km
// gen lnjinshi = ln(jinshi+1)
// gen lnacademy = ln(academy+1)
// gen lntemples = ln(temples+1)
* 先计算每个county_code出现的年份数
bysort county_code: gen n_years = _N

* 删除只出现一年的观察值
drop if n_years == 1

* 删除生成的辅助变量
drop n_years
sum2docx lnjinshi academy temples using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

gen treat×post = treat_50km*post_50km
gen treat×post×lnjinshi = treat×post*lnjinshi
gen treat×post×academy = treat×post*academy_50km
gen treat×post×temples = treat×post*temples

reghdfe divorce_rate treat×post×lnjinshi treat×post lnjinshi $cv 
est store r1
reghdfe divorce_rate treat×post×academy treat×post academy $cv 
est store r2
reghdfe divorce_rate treat×post×temples treat×post temples $cv 
est store r3
reg2docx r1 r2 r3 using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post×lnjinshi treat×post×academy  treat×post×temples lnjinshi academy temples treat×post) addfe("Controls=YES" "City=YES" "Year=YES" )

**# 地区文化特征

//耙耳朵地区
gen treat×post = treat_50km*post_50km
reghdfe divorce_rate treat×post $cv if pa_ears == 0, absorb(year county_code) cluster(county_code) 
est store r1
reghdfe divorce_rate treat×post $cv if pa_ears == 1, absorb(year county_code) cluster(county_code) 
est store r2

//大男子主义地区
reghdfe divorce_rate treat×post $cv if male_chauvinism == 0, absorb(year county_code) cluster(county_code) 
est store r3
reghdfe divorce_rate treat×post $cv if male_chauvinism == 1, absorb(year county_code) cluster(county_code) 
est store r4

//彩礼

reghdfe divorce_rate treat×post $cv if 彩礼分类 == 0, absorb(year county_code) cluster(county_code) 
est store r5
reghdfe divorce_rate treat×post $cv if 彩礼分类 == 1, absorb(year county_code) cluster(county_code) 
est store r6
reg2docx r1 r2 r3 r4 r5 r6 using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep( treat×post) addfe("Controls=YES" "County=YES" "Year=YES" )

//
reghdfe divorce_rate treat×post $cv if baishe_origin == 1, absorb(year county_code) cluster(county_code) 

reghdfe divorce_rate treat×post $cv if baishe_origin == 1, absorb(year county_code) cluster(county_code) 


**# 离婚诉讼案件
cd "E:\自然灾害\stata\耙耳朵\继续改"
drop divorce_proceedings
replace 离婚案件数 = 0 if 离婚案件数 == .
gen divorce_proceedings = ln(离婚案件数/(population（人）)+1)
sum2docx divorce_proceedings using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))
gen d = 离婚案件数/population（人）
sum population（人）
gen treat×post = treat_50km*post_50km
reghdfe divorce_proceedings treat×post $cv , absorb(year county_code) cluster(county_code) 
est store r1
reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep( treat×post) addfe("Controls=YES" "County=YES" "Year=YES" )


**# 发源地
gen treat×post = treat_50km*post_50km

reghdfe divorce_rate treat×post $cv if story_origin == 0,  absorb(year county_code) cluster(county_code)
est store r1
reghdfe divorce_rate treat×post $cv if story_origin == 1,  absorb(year county_code) cluster(county_code)
est store r2
reghdfe divorce_rate treat×post $cv if liangzhu_origin == 0,  absorb(year county_code) cluster(county_code)
est store r3
reghdfe divorce_rate treat×post $cv if liangzhu_origin == 1,  absorb(year county_code) cluster(county_code)
est store r4
reghdfe divorce_rate treat×post $cv if niulang_origin == 0,  absorb(year county_code) cluster(county_code)
est store r5
reghdfe divorce_rate treat×post $cv if niulang_origin == 1,  absorb(year county_code) cluster(county_code)
est store r6
reghdfe divorce_rate treat×post $cv if baishe_origin == 0,  absorb(year county_code) cluster(county_code)
est store r7
reghdfe divorce_rate treat×post $cv if baishe_origin == 1,  absorb(year county_code) cluster(county_code)
est store r8

reg2docx r1 r2 r3 r4 r5 r6 r7 r8 using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep( treat×post) addfe("Controls=YES" "County=YES" "Year=YES" )





**# 自然灾害对经济的影响
// CFPS
cd "E:\自然灾害\stata\CFPS"
global cv "industry_ratio log_retail log_beds pm25"
sum2docx lnpersonincome if lnpersonincome>6.9 using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

use "E:\自然灾害\stata\CFPS\家庭个人收入subsample.dta", clear
gen treat×post = treat_50km*post_50km
sum2docx lnpersonincome if lnpersonincome>6.9 using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))
reghdfe lnpersonincome treat×post $cv if lnpersonincome>6.9, absorb(countyid year) 
est store r1
reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post) addfe("County=YES" "Controls=YES"  "Year=YES" )

gen lndivorce_cases = ln(divorce_cases+1)

reghdfe lndivorce_cases  treat×post $cv if lnpersonincome>6.9

use "E:\自然灾害\stata\CFPS\家庭收入subsample.dta", clear
gen treat×post = treat_50km*post_50km
sum2docx lnfamilyincome  using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))
reghdfe lnfamilyincome treat×post $cv if lnfamilyincome>7.7200, absorb(countyid year) 
est store r1
reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post) addfe("Controls=YES"  "County=YES"  "Year=YES" )
reghdfe divorce_rate treat×post lnfamilyincome  $cv if lnfamilyincome>7.7200, absorb(countyid year) 
est store r1

gen lndivorce_cases = ln(divorce_cases+1)
reghdfe lndivorce_cases lnfamilyincome treat×post $cv if lnfamilyincome>7.7200, absorb(countyid year) 

**# 心理健康方面
//心理健康,越大越差 0-30
cd "E:\自然灾害\stata\CHARLS"
use "E:\自然灾害\stata\CHARLS\cesd10 .dta", clear

gen treat×post = treat_50km*post_50km
global cv "lnis lntfly fbr lnfbr lnrst"

sum2docx cesd10  using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

reghdfe cesd10 treat×post $cv, absorb(city year) cluster(city) 
est store r1
reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post) addfe("Controls=YES"  "County=YES"  "Year=YES" )

est store r1

//生活满意度
cd "E:\自然灾害\stata\CHARLS"
use "E:\自然灾害\stata\CHARLS\satlife .dta", clear
gen treat×post = treat_50km*post_50km
global cv "lnis lntfly fbr lnfbr lnrst"
sum2docx satlife  using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

reghdfe satlife treat×post $cv, absorb(city year) cluster(city)
est store r1
reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post) addfe("Controls=YES"  "County=YES"  "Year=YES" )


//对未来是否充满希望
cd "E:\自然灾害\stata\CHARLS"
use "E:\自然灾害\stata\CHARLS\hope .dta", clear
gen treat×post = treat_50km*post_50km
global cv "lnis lntfly fbr lnfbr lnrst"
sum2docx hope using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

reghdfe hope treat×post $cv , absorb(city year) cluster(city)
est store r1
reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post) addfe("Controls=YES"  "County=YES"  "Year=YES" )


**# 认知能力相关指标包括
// 总体认知能力
cd "E:\自然灾害\stata\CHARLS"
use "E:\自然灾害\stata\CHARLS\total_cognition .dta", clear
gen treat×post = treat_50km*post_50km
global cv "lnis lntfly fbr lnfbr lnrst"
sum2docx total_cognition  using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))
reghdfe total_cognition treat×post $cv , absorb(city year) cluster(city)
est store r1
reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post) addfe("Controls=YES"  "County=YES"  "Year=YES" )

// 情景记忆能力
cd "E:\自然灾害\stata\CHARLS"
use "E:\自然灾害\stata\CHARLS\memeory .dta", clear
gen treat×post = treat_50km*post_50km
global cv "lnis lntfly fbr lnfbr lnrst"
sum2docx memeory using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

reghdfe memeory treat×post $cv , absorb(city year) cluster(city)
est store r1
reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post) addfe("Controls=YES"  "County=YES"  "Year=YES" )

// 心智状况
cd "E:\自然灾害\stata\CHARLS"
use "E:\自然灾害\stata\CHARLS\executive .dta", clear
gen treat×post = treat_50km*post_50km
global cv "lnis lntfly fbr lnfbr lnrst"
sum2docx executive using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

reghdfe executive treat×post $cv , absorb(city year) cluster(city)
est store r1
reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post) addfe("Controls=YES"  "County=YES"  "Year=YES" )
**# 生理压力指标
// 睡眠时长
cd "E:\自然灾害\stata\CHARLS"
use "E:\自然灾害\stata\CHARLS\sleep .dta", clear
// gen treat×post = treat_50km*post_50km
global cv "lnis lntfly fbr lnfbr lnrst"
sum2docx sleep using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

reghdfe sleep treat×post $cv if sleep>6, absorb(city year) cluster(city)
est store r1
reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post) addfe("Controls=YES"  "County=YES"  "Year=YES" )

// C反应蛋白水平
cd "E:\自然灾害\stata\CHARLS"
use "E:\自然灾害\stata\CHARLS\bl_crp .dta", clear
gen treat×post = treat_50km*post_50km
global cv "lnis lntfly fbr lnfbr lnrst"
sum2docx bl_crp using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

reghdfe bl_crp treat×post $cv if bl_crp >= 0.1 & bl_crp <= 200, absorb(city year) cluster(city)
est store r1
reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post) addfe("Controls=YES"  "County=YES"  "Year=YES" )

// 脉搏
cd "E:\自然灾害\stata\CHARLS"
use "E:\自然灾害\stata\CHARLS\pulse.dta", clear
// gen treat×post = treat_50km*post_50km
global cv "lnis lntfly fbr lnfbr lnrst"
sum2docx pulse using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

reghdfe pulse treat×post $cv , absorb(city year) cluster(city)
est store r1
reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post) addfe("Controls=YES"  "County=YES"  "Year=YES" )

// 收缩压
cd "E:\自然灾害\stata\CHARLS"
use "E:\自然灾害\stata\CHARLS\systo .dta", clear
gen treat×post = treat_50km*post_50km
global cv "lnis lntfly fbr lnfbr lnrst"
sum2docx systo using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

reghdfe systo treat×post $cv , absorb(city year) cluster(city)
est store r1
reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post) addfe("Controls=YES"  "County=YES"  "Year=YES" )

// 舒张压
cd "E:\自然灾害\stata\CFPS"
use "E:\自然灾害\stata\CHARLS\diasto .dta", clear
gen treat×post = treat_50km*post_50km
global cv "lnis lntfly fbr lnfbr lnrst"
sum2docx diasto using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

reghdfe diasto treat×post $cv , absorb(city year) cluster(city)
est store r1
reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat×post) addfe("Controls=YES"  "County=YES"  "Year=YES" )

**# 进一步分析
// 1.性别压力变化

cd "E:\自然灾害\stata\CFPS"
use "E:\自然灾害\stata\CFPS\性别压力 .dta", clear

global cv "industry_ratio log_retail log_beds pm25"
* 生成新的二元变量
gen pressure_binary = .
replace pressure_binary = 1 if gender_pressure == 1  // 男性压力更大
replace pressure_binary = 0 if gender_pressure == 2  // 女性压力更大

sum2docx pressure_binary using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

//使用logit模型
gen treat×post = treat_50km*post_50km
logit pressure_binary treat×post $cv  
est store r1

reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep( treat×post) addfe("Controls=YES"  "County=YES"  "Year=YES" )

* 边际效应分析
margins, dydx(treat×post) atmeans
reghdfe gender_pressure treat×post $cv if 18<adult_age<65, absorb(countyid year) cluster(countyid)

**# 异质性分析
cd "E:\自然灾害\stata\CFPS"
use "E:\自然灾害\stata\CFPS\35和小孩1.dta", clear
sum2docx divorced using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))
gen treat×post = treat_50km*post_50km
// gen divorced = (marriage == 2)
generate child_dummy = cond(missing(child_age), 0, child_age > 0)
// 分年龄
global cv "industry_ratio log_retail log_beds pm25"
logit divorced treat×post $cv if adult_age < 35
est store r1
logit divorced treat×post $cv if adult_age >= 35 
est store r2
logit divorced treat×post $cv if child_dummy==0 
est store r3
logit divorced treat×post $cv if child_dummy==1
est store r4

reg2docx r1 r2 r3 r4 using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep( treat×post) addfe("Controls=YES"  "County=YES"  "Year=YES" )

//安慰剂检验1
clear
cd "E:\自然灾害\stata"
mat sb  = J(1000,1,0)  
mat sse = J(1000,1,0)
mat sp  = J(1000,1,0)

forvalues i=1/100{
    clear
    use "E:\自然灾害\stata\基准回归\最终1.dta", clear
    xtset county_code year
    keep treat_50km post_50km county_code year
    rsort
    gen obs_id= _n
    save random_matching_code, replace
 
    use "E:\自然灾害\stata\基准回归\最终1.dta", clear
    xtset county_code year
    gen obs_id= _n
    drop treat_50km post_50km
    merge 1:1 obs_id using random_matching_code
 
    capture drop treat_post
    gen treat_post = treat_50km * post_50km
 
    global cv "industry_ratio log_retail log_beds pm25"
 
    reghdfe divorce_rate treat_post $cv, absorb(year county_code) cluster(county_code)
    mat sb[`i',1] = _b[treat_post]
    mat sse[`i',1] = _se[treat_post]
    scalar df_r = e(N) - e(df_m) -1
    mat sp[`i',1] = 2*ttail(e(df_r),abs(_b[treat_post]/_se[treat_post]))
}

svmat sb, names(scoef)
svmat sse, names(sse)
svmat sp, names(spvalue)  
drop if spvalue1 == .
 
twoway ///
(kdensity scoef1,  /// 
   yaxis(1) ///
   ytitle(`"{fontface "Times New Roman":Probability Density}"') ///
   xtitle(`"{fontface "Times New Roman":Estimated Coefficient}"')  ///
   xlabel(-0.2(0.05)0.2,nogrid) ///
   xline(-0.144, lp(shortdash)) ///    
   title(`"{fontface "Times New Roman":(a) Randomizing Treatment and Post Jointly}"') ) /// 
(scatter spvalue1 scoef1, ///
   yaxis(2) ///
   ytitle(`"{fontface "Times New Roman":p-value}"',axis(2)) ///
   ylabel(0(0.5)2,nogrid axis(2)) ///
   xline(0, lp(shortdash)) ///
   xlabel(,nogrid) ///
   msymbol(smcircle_hollow) ///
   mcolor(grey) ///
   legend(off)) 
   
graph save placebo_test, replace

//安慰剂检验2
clear
mat sb  = J(1000,1,0)   
mat sse = J(1000,1,0)
mat sp  = J(1000,1,0)

forvalues i=1/1000{     
    use "E:\自然灾害\stata\基准回归\最终1.dta", clear
    xtset county_code year
    keep treat_50km
    rsort 
    gen obs_id= _n
    save random_matching_code, replace
    
    use "E:\自然灾害\stata\基准回归\最终1.dta", clear
    xtset county_code year
    gen obs_id= _n
    drop treat_50km
    merge 1:1 obs_id using random_matching_code
    drop _merge
    save placebo, replace
    
    use placebo, clear
    xtset county_code year
    keep post_50km obs_id
    rsort
    save random_matching_code_2, replace
    
    use placebo, clear
    xtset county_code year
    drop post_50km
    merge 1:1 obs_id using random_matching_code_2
    drop _merge
    save placebo_2, replace
    
    use placebo_2, clear
    capture drop treat_post
    gen treat_post = treat_50km * post_50km
    global cv "industry_ratio log_retail log_beds pm25"
    
    reghdfe divorce_rate treat_post $cv, absorb(year county_code) cluster(county_code)
    mat sb[`i',1] = _b[treat_post]
    mat sse[`i',1] = _se[treat_post]
    scalar df_r = e(N) - e(df_m) -1
    mat sp[`i',1] = 2*ttail(e(df_r),abs(_b[treat_post]/_se[treat_post]))
}

svmat sb, names(scoef)
svmat sse, names(sse)
svmat sp, names(spvalue)
drop if spvalue1 == .

twoway ///
(kdensity scoef1, ///
yaxis(1) ///
ytitle(`"{fontface "Times New Roman":Probability Density}"') ///
xtitle(`"{fontface "Times New Roman":Estimated Coefficient}"') ///
xlabel(-2(0.5)2,nogrid) ///
xline(0.2966, lp(shortdash)) ///
title(`"{fontface "Times New Roman":(b) Randomizing Treatment and Post Separately}"')) ///
(scatter spvalue1 scoef1, ///
yaxis(2) ///
ytitle(`"{fontface "Times New Roman":p-value}"',axis(2)) ///
ylabel(0(0.5)2,nogrid axis(2)) ///
xline(0, lp(shortdash)) ///
xlabel(,nogrid) ///
msymbol(smcircle_hollow) ///
mcolor(grey) ///
legend(off))

graph save placebo_test_2, replace