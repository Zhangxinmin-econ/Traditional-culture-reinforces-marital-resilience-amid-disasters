*==============================================================
* 05_deidentify.do  —— 省份/地区脱敏
*
* 原则：
*   1) 回归实际用到的分组变量（county_code / countyid / city）保留变量名，
*      取值替换为随机打乱的匿名编号 —— 分组结构不变，故所有结果逐位不变。
*   2) 6位行政区划码前两位编码省份，因此必须打乱而不能保留原码。
*   3) 地名、省市代码、被访者 ID 等未参与回归的标识字段全部删除。
*   4) 对照表保存在复现包【外部】，不随包提交。
*==============================================================
do "D:/论文文件夹/自然灾害与婚姻/提交_复现包/code/00_config.do"

* 本脚本的输入是【未脱敏】的原始数据，存放在复现包外部。
* 脱敏已执行完毕，包内 data/ 即产物；此脚本记录脱敏方法。
global raw "<LOCAL PRIVATE PATH>"
global f_base   "${raw}/基准回归/最终1.dta"
global f_drama  "${raw}/文化/电视剧.dta"
global f_mech   "${raw}/机制/汇总机制2_merged.dta"
global d_cfps   "${raw}/CFPS"
global d_charls "${raw}/CHARLS"

global deid "${pkg}/data_deid"
global keymap "<LOCAL PRIVATE PATH>"

capture mkdir "${deid}"
capture mkdir "${deid}/基准回归"
capture mkdir "${deid}/文化"
capture mkdir "${deid}/机制"
capture mkdir "${deid}/CFPS"
capture mkdir "${deid}/CHARLS"
capture mkdir "${keymap}"

capture log close _all
log using "${logs}/05_deidentify_results.log", replace text

* 需要删除的标识字段
global drop_county "NAME province_code province_std city_code city_std 地点"
global drop_cfps   "PAC provname cityname countyname norm_prov norm_county"
global drop_charls "province ID"

* 安全网：删除任何仍含行政区划后缀（省/市/县/区/自治区/盟/州）的字符串变量
capture program drop scrub_geo_strings
program define scrub_geo_strings
    quietly ds, has(type string)
    local svars "`r(varlist)'"
    foreach v of local svars {
        quietly count if regexm(`v', "(省|市|县|区|自治州|自治县|盟|地区)$")
        if r(N) > 0 {
            drop `v'
            display as error "SCRUB|删除残留地名字段: `v'"
        }
    }
end

*--------------------------------------------------------------
* 1. 县级面板：county_code 对照表（取三个文件的并集）
*--------------------------------------------------------------
tempfile c1 c2 c3 cw_county
use "${f_base}",  clear
keep county_code
duplicates drop
save `c1'
use "${f_drama}", clear
keep county_code
duplicates drop
save `c2'
use "${f_mech}",  clear
keep county_code
duplicates drop
save `c3'

use `c1', clear
append using `c2'
append using `c3'
duplicates drop
* 随机打乱后重新编号，彻底切断省份前缀信息
set seed <REDACTED>
generate double u_ = runiform()
sort u_ county_code
generate long county_code_deid = 900001 + _n - 1
drop u_
label variable county_code_deid "脱敏县编号（随机打乱，不含省份信息）"
count
display as result "CWCOUNT|county=" r(N)
save "${keymap}/对照表_county_code.dta", replace
keep county_code county_code_deid
save `cw_county'

*--------------------------------------------------------------
* 2. 应用到三个县级文件
*--------------------------------------------------------------
local i = 0
foreach f in "${f_base}" "${f_drama}" "${f_mech}" {
    local ++i
    if `i' == 1  local dest "${deid}/基准回归/最终1.dta"
    if `i' == 2  local dest "${deid}/文化/电视剧.dta"
    if `i' == 3  local dest "${deid}/机制/汇总机制2_merged.dta"

    use "`f'", clear
    local n0 = _N
    merge m:1 county_code using `cw_county', keep(match) nogenerate
    assert _N == `n0'
    drop county_code
    rename county_code_deid county_code
    foreach v of global drop_county {
        capture confirm variable `v'
        if !_rc  drop `v'
    }
    order county_code year
    scrub_geo_strings
    compress
    save "`dest'", replace
    display as result "DEID|`dest'|N=" _N
}

*--------------------------------------------------------------
* 3. CFPS：countyid 对照表（四个文件的并集）
*--------------------------------------------------------------
tempfile f1 f2 f3 f4 cw_cfps
local j = 0
foreach f in "35和小孩1" "家庭个人收入subsample" "家庭收入subsample" "性别压力 " {
    local ++j
    use "${d_cfps}/`f'.dta", clear
    keep countyid
    duplicates drop
    save `f`j''
}
use `f1', clear
append using `f2'
append using `f3'
append using `f4'
duplicates drop
set seed <REDACTED>
generate double u_ = runiform()
sort u_ countyid
generate long countyid_deid = 800001 + _n - 1
drop u_
label variable countyid_deid "脱敏CFPS县编号（随机打乱）"
count
display as result "CWCOUNT|cfps_county=" r(N)
save "${keymap}/对照表_cfps_countyid.dta", replace
keep countyid countyid_deid
save `cw_cfps'

foreach f in "35和小孩1" "家庭个人收入subsample" "家庭收入subsample" "性别压力 " {
    use "${d_cfps}/`f'.dta", clear
    local n0 = _N
    merge m:1 countyid using `cw_cfps', keep(match) nogenerate
    assert _N == `n0'
    drop countyid
    rename countyid_deid countyid
    foreach v of global drop_cfps {
        capture confirm variable `v'
        if !_rc  drop `v'
    }
    scrub_geo_strings
    compress
    save "${deid}/CFPS/`f'.dta", replace
    display as result "DEID|CFPS/`f'|N=" _N
}

*--------------------------------------------------------------
* 4. CHARLS：city 字符串 → 匿名数值编号（回归用 absorb(city) 与 cluster(city)）
*    注意：原文件名多数带一个尾随空格（如 "cesd10 .dta"），输出保持同名，
*    以便 03_mechanisms.do 指向 data 或 data_deid 都能直接运行。
*--------------------------------------------------------------
tempfile cw_charls acc
clear
save `acc', emptyok

foreach item in cesd10 satlife hope total_cognition memeory executive sleep bl_crp pulse systo diasto {
    local fname "`item' .dta"
    if "`item'" == "pulse"  local fname "pulse.dta"
    use "${d_charls}/`fname'", clear
    keep city
    duplicates drop
    append using `acc'
    duplicates drop
    save `acc', replace
}
use `acc', clear
drop if missing(city)
set seed <REDACTED>
generate double u_ = runiform()
sort u_ city
generate long city_deid = 700001 + _n - 1
drop u_
label variable city_deid "脱敏地级市编号（随机打乱，不含省份信息）"
count
display as result "CWCOUNT|charls_city=" r(N)
save "${keymap}/对照表_charls_city.dta", replace
keep city city_deid
save `cw_charls'

foreach item in cesd10 satlife hope total_cognition memeory executive sleep bl_crp pulse systo diasto {
    local fname "`item' .dta"
    if "`item'" == "pulse"  local fname "pulse.dta"
    use "${d_charls}/`fname'", clear
    local n0 = _N
    merge m:1 city using `cw_charls', keep(master match) nogenerate
    assert _N == `n0'
    drop city
    rename city_deid city
    foreach v of global drop_charls {
        capture confirm variable `v'
        if !_rc  drop `v'
    }
    scrub_geo_strings
    compress
    save "${deid}/CHARLS/`fname'", replace
    display as result "DEID|CHARLS/`item'|N=" _N
}

display as result "DEID_COMPLETE"
log close


