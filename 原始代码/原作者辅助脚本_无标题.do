cd "C:\Users\ZhangX\Desktop\生态保护\数据1\数据中转1"
import excel "C:\Users\ZhangX\Desktop\生态保护\数据1\数据中转1\subsample初始_with_codes_sorted.xlsx", firstrow clear
duplicates list 行政区域代码 时间
duplicates drop 行政区域代码 时间,force
xtset 行政区域代码 时间
gen lndivorce = ln离婚率
gen lnmarriage = ln结婚率

sum lndivorce lnmarriage $cv

global cv "lnis lntfly lnfbr lnrst lnser"

sum2docx lndivorce lnmarriage treat_post_2year $cv using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

corr2docx lndivorce lnmarriage $cv using out1.docx,replace star fmt(%9.3f) pearson(pw)title("表2:相关性分析")note("Note: *** , ** , and * indicate significance at the 1%, 5%, and 10% levels, respectively.")  spearman(ignore)

reghdfe lndivorce treat_post_2year , absorb(行政区域代码 时间 ) cluster(行政区域代码)
est store r1
reghdfe lndivorce treat_post_2year $cv, absorb(行政区域代码 时间 ) cluster(行政区域代码)
est store r2
reghdfe lnmarriage treat_post_2year , absorb(行政区域代码 时间 ) cluster(行政区域代码)
est store r3
reghdfe lnmarriage treat_post_2year $cv, absorb(行政区域代码 时间 ) cluster(行政区域代码)
est store r4

reg2docx r1 r2 r3 r4 using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat_post_2year) addfe("City=YES" "Year=YES" "Controls=YES") 



**# 传统平行趋势检验

drop event_time pre4 pre3 pre2 pre1 post1 post2 post3 post4
* 第一步：生成相对时间变量
gen event_time = .
levelsof 行政区域代码, local(regions)
foreach region of local regions {
    * 对每个地区找出第一次灾害发生的时间
    qui sum 时间 if 行政区域代码 == `region' & post_current == 1, meanonly
    if r(N) > 0 {
        local event_date = r(min)
        replace event_time = 时间 - `event_date' if 行政区域代码 == `region'
    }
}

* 第二步：生成相对时间的虚拟变量，省略-1期作为基准
* 生成前期变量（包括-2期，但不包括-1期）
forvalues i = 2/4 {  // 从-2期开始，到-4期
    gen pre`i' = (event_time == -`i')
}
gen current = (event_time == 0)     // 灾害发生当期
* 生成后期变量
forvalues i = 1/4 {
    gen post`i' = (event_time == `i')
}

* 第三步：回归分析
reghdfe lndivorce pre4 pre3 pre2 current post1 post2 post3 post4 $cv, absorb(行政区域代码 时间) 

**# Baker、Larcker和Wang (2022)的平行趋势检验

gen aaa=时间 if treat_post_2year==1
bys 行政区域代码: egen action=min(aaa)
gen never = (action ==.)

gen pd = 时间 - action
forvalues i = 4(-1)1 {
    gen pre_`i' = (pd == -`i')
}

// gen current = (pd == 0)

forvalues j = 1(1)4 {
    gen post_`j' = (pd == `j')
}

eventstudyinteract lndivorce pre_4 pre_3 pre_2  current post_1 post_2 post_3 post_4, absorb(时间 行政区域代码 )  cohort(action) control_cohort(never) covariates($cv)

**# 安慰剂检验
graph set window fontface "Times New Roman"

//表示开始自定义主题
grstyle init  
//设置背景（没有网格线，没有边框）
grstyle set plain, nogrid nobox 
grstyle set graphsize 5 7
reghdfe lndivorce treat_post_2year $cv, absorb(行政区域代码 时间 ) cluster(行政区域代码)
est store did_reghdfe
didplacebo did_reghdfe ,treatvar(treat_post_2year) pbotime(1(1)5) pbomix(1) repeat(500) rantimescope(2000 2022)

**# 修改时间

reghdfe lndivorce treat_post_1year $cv, absorb(行政区域代码 时间 ) cluster(行政区域代码)
est store r1
reghdfe lnmarriage treat_post_1year $cv, absorb(行政区域代码 时间 ) cluster(行政区域代码)
est store r2
**# FGLS
xtgls ln离婚率 treat_post_2year $cv i.时间 i.行政区域代码, panels(heteroskedastic) corr(ar1) force
est store r3

**# PSM
logit treat $cv 
drop pscore
predict pscore

psmatch2 treat, pscore(pscore) outcome(ln离婚率) neighbor(1) common caliper(0.2) noreplacement

pstest $cv,both graph
reghdfe lndivorce treat_post_2year $cv if _weight==1 ,  absorb(行政区域代码 时间 ) cluster(行政区域代码)
est store r4

reg2docx r1 r2 r3 r4 using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep(treat_post_1year treat_post_2year) addfe("City=YES" "Year=YES" "Controls=YES")

**# 机制分析
// 1.经济机制

cd "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析\数据中转1"
import excel "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析\数据中转1\subsample1个人收入.xlsx", firstrow clear

sum2docx lnpersonincome if lnpersonincome>6.9 using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

gen lnpersonincome = ln(personincome)
reghdfe lnpersonincome treat_post_2year $cv if lnpersonincome>6.9, absorb(行政区域代码 时间 ) 
est store r1

reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep( treat_post_2year) addfe("City=YES" "Year=YES" "Controls=YES")

cd "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析\数据中转1"
import excel "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析\数据中转1\subsample1_家庭收入.xlsx", firstrow clear

sum2docx lnfamily_income using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

gen lnfamily_income = ln(family_income)
reghdfe lnfamily_income treat_post_2year $cv, absorb(行政区域代码 时间 ) 
est store r1
reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep( treat_post_2year) addfe("City=YES" "Year=YES" "Controls=YES")

// 2.心理机制
cd "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析1\数据中转1"
import excel "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析1\数据中转1\subsample (cesd10 satlife sleep).xlsx", firstrow clear

sum2docx cesd10 satlife if sleep>6 using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

reghdfe cesd10 treat_post_1year $cv, absorb( 行政区域代码 时间 ) // 心理健康,越大越差 0-30
est store r1
reghdfe satlife treat_post_1year $cv, absorb(行政区域代码 时间 ) //生活满意度
est store r2
reg2docx r1 r2 using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep( treat_post_1year) addfe("City=YES" "Year=YES" "Controls=YES")

cd "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析1\数据中转1"
import excel "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析1\数据中转1\subsample (sleep).xlsx", firstrow clear
sum2docx sleep using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

reghdfe sleep treat_post_1year $cv if sleep>6, absorb(行政区域代码 时间 )
est store r1
reg2docx r1  using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep( treat_post_1year) addfe("City=YES" "Year=YES" "Controls=YES")

cd "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析1\数据中转1"
import excel "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析1\数据中转1\subsample (memeory executive).xlsx", firstrow clear
sum2docx memeory executive using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

reghdfe memeory treat_post_1year $cv, absorb(行政区域代码 时间 )
est store r1
reghdfe executive treat_post_1year $cv, absorb(行政区域代码 时间 )
est store r2
reg2docx r1 r2 using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep( treat_post_1year) addfe("City=YES" "Year=YES" "Controls=YES")

pselect3 sleep treat_post_1year $cv , absorb(行政区域代码 时间 ) cmd(reghdfe) neg(treat_post_1year) s(0.01)

//心理压力
cd "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析1\数据中转1"
import excel "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析1\数据中转1\subsample subsample (bl_crp pulse systo diasto).xlsx", firstrow clear
sum2docx bl_crp pulse systo diasto using 描述性统计.docx, replace stats(N mean(%9.3f) sd min(%9.3f)  max(%9.3f))

reghdfe bl_crp treat_post_1year $cv, absorb( 时间 )
est store r1
reghdfe pulse treat_post_1year $cv, absorb( 时间 )
est store r2
reghdfe systo treat_post_1year $cv, absorb( 时间 )
est store r3
reghdfe diasto treat_post_1year $cv, absorb( 时间 )
est store r4
reg2docx r1 r2 r3 r4 using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep( treat_post_1year) addfe("City=NO" "Year=YES" "Controls=YES")

egen total_social = rowtotal(social1 social2 social3 social4 social5 social6 social7 social8 social9 social10 social11)

egen total_act = rowtotal(act_1 act_2 act_3 act_4 act_5 act_6 act_7 act_8)

reghdfe total_social treat_post_1year $cv, absorb(行政区域代码 时间 )
pselect3 total_act treat_post_1year $cv, absorb(行政区域代码 时间 ) cmd(reghdfe) s(0.01) neg(treat_post_1year)

reghdfe total_act treat_post_1year $cv, absorb(行政区域代码 时间 )

reghdfe systo treat×post2 $cv, absorb(行政区域代码 时间 )
reghdfe diasto treat×post2 $cv, absorb(行政区域代码 时间 )

reghdfe happiness treat×post2 $cv, absorb(行政区域代码 时间 ) 
reghdfe life_satisfaction treat×post2 $cv, absorb(行政区域代码 时间) 

// 3.社会机制

cd "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析\数据中转1"
import excel "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析\最终\subsample_性别压力.xlsx", firstrow clear

* 生成新的二元变量
gen pressure_binary = .
replace pressure_binary = 1 if gender_pressure == 1  // 男性压力更大
replace pressure_binary = 0 if gender_pressure == 2  // 女性压力更大

* 使用二元变量进行回归
reghdfe pressure_binary treat_post_2year $cv, absorb(行政区域代码 时间) cluster(行政区域代码)
* 稳健性检验：使用logit模型
est store r1
logit pressure_binary treat_post_2year $cv  i.行政区域代码 i.时间
est store r2
reg2docx r1 r2 using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep( treat_post_2year) addfe("City=YES" "Year=YES" "Controls=YES")


* 边际效应分析
margins, dydx(treat_post_2year) atmeans
reghdfe gender_pressure treat_post_2year $cv if 18<adult_age<65, absorb(行政区域代码 时间 ) 

**# 异质性分析
cd "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析\数据中转1"
import excel "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析\数据中转1\subsample (孩子).xlsx" ,firstrow clear
// 分年龄
gen divorced = (marriage == 2)

reghdfe divorced treat_post_2year $cv if adult_age<35, absorb(行政区域代码 时间)
est store r1
reghdfe divorced treat_post_2year $cv if adult_age >= 35, absorb(行政区域代码 时间)
est store r2

//有无孩子
cd "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析\数据中转1"
import excel "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析\数据中转1\subsample (孩子).xlsx" ,firstrow clear
generate child_dummy = cond(missing(child_age), 0, child_age > 0)
reghdfe divorced treat_post_2year $cv if child_dummy==0, absorb(行政区域代码 时间)
est store r3
reghdfe divorced treat_post_2year $cv if child_dummy==1, absorb(行政区域代码 时间)
est store r4
reg2docx r1 r2 r3 r4 using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep( treat_post_2year) addfe("City=YES" "Year=YES" "Controls=YES")
//灾难异质性
cd "C:\Users\ZhangX\Desktop\生态保护\数据1\进一步分析\数据中转1"
import excel "C:\Users\ZhangX\Desktop\生态保护\数据1\异质性\汇总_with_codes_sorted.xlsx" ,firstrow clear
duplicates list 行政区域代码 时间
duplicates drop 行政区域代码 时间,force
xtset 行政区域代码 时间

reghdfe ln离婚率 treat_post_2year_Meteorological $cv, absorb(行政区域代码 时间 ) cluster(行政区域代码)
est store r1
reghdfe ln离婚率 treat_post_2year_Hydrological $cv, absorb(行政区域代码 时间 ) cluster(行政区域代码)
est store r2
reghdfe ln离婚率 treat_post_2year_Geophysical $cv, absorb(行政区域代码 时间 ) cluster(行政区域代码)
est store r3
reghdfe ln离婚率 treat_post_2year_Climatological $cv, absorb(行政区域代码 时间 ) cluster(行政区域代码)
est store r4
reghdfe ln离婚率 treat_post_2year_Biological $cv, absorb(行政区域代码 时间 ) cluster(行政区域代码) 
est store r5
reg2docx r1 r2 r3 r4 r5 using 稳健性检验.docx, replace scalars(N r2(%9.3f)) b(%9.4f) t(%7.2f) keep( treat_post_2year_Meteorological treat_post_2year_Hydrological treat_post_2year_Geophysical treat_post_2year_Climatological treat_post_2year_Biological) addfe("City=YES" "Year=YES" "Controls=YES")

