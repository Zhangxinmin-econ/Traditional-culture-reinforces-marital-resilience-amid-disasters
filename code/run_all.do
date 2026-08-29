*==============================================================
* run_all.do  —— 一键复现
*
* 用法（Windows 命令行）：
*   cd  <复现包路径>\logs
*   "<Stata路径>\StataMP-64.exe" -e do "..\code\run_all.do"
*
* 依赖：reghdfe  psmatch2  xtivreg2  ivreg2
* 输出：logs/ 下的 *_results.log
*       其中每一行 RESULT| 对应论文表格中的一格，标签即表号与列号
*==============================================================
version 18
clear all
set more off

global codedir "D:/论文文件夹/自然灾害与婚姻/提交_复现包/code"

do "${codedir}/01_main.do"
do "${codedir}/02_robustness.do"
do "${codedir}/03_mechanisms.do"
