*==============================================================
* 00_config.do  —— 路径与全局设定
* 自然灾害、传统文化与婚姻稳定性（One Earth / Science Advances 投稿版）
*==============================================================
version 18
clear all
set more off
set varabbrev off
set linesize 255

* 复现包根目录
global pkg  "D:/论文文件夹/自然灾害与婚姻/提交_复现包"
global code "${pkg}/code"
global data "${pkg}/data"
global logs "${pkg}/logs"
global out  "${pkg}/output"

* 数据来源。默认使用复现包内自带的数据（自包含）。
* 如需指向原始位置，把 src 改为 "D:/论文文件夹/自然灾害与婚姻2/stata"
global src   "${pkg}/data"
global f_base   "${src}/基准回归/最终1.dta"
global f_drama  "${src}/文化/电视剧.dta"
global f_mech   "${src}/机制/汇总机制2_merged.dta"
global d_cfps   "${src}/CFPS"
global d_charls "${src}/CHARLS"

* 控制变量（与投稿版一致）
global cv        "industry_ratio log_retail log_beds pm25"
global cv_charls "lnis lntfly fbr lnfbr lnrst"

* 结果打印程序：每行对应表格中的一格
capture program drop post_est
program define post_est
    syntax, Label(string) Coef(name)
    scalar b_  = _b[`coef']
    scalar se_ = _se[`coef']
    if e(df_r) < . {
        scalar p_ = 2 * ttail(e(df_r), abs(b_ / se_))
    }
    else {
        scalar p_ = 2 * (1 - normal(abs(b_ / se_)))
    }
    display as result "RESULT|`label'|b=" %12.6f b_ ///
        "|se=" %12.6f se_ "|p=" %10.6f p_ ///
        "|N=" %12.0f e(N) "|r2=" %10.6f e(r2)
end
