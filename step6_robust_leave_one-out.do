clear all
global path "C:\phd4\CCUS"
cd "$path"
use TRANS_DIST_ASMT_full_arm, clear
set more off

xtset importparcelid date
egen zip_year = group(zipcode year)
egen county_year = group(fips year)
egen month_year = group(month year)
gen dist_m = dist * 1000

gen gap = year - operational
gen over5yrs = 0
replace over5yrs = 1 if gap <= -5

* Create bins 0-1km, 1-2km, 2-3km
forval i = 1000(1000)3000 {
    local j = `i' - 1000
    gen byte vicinity_`i' = 1 if dist_m <= `i' & dist_m > `j'
    replace vicinity_`i' = 0 if missing(vicinity_`i')
}

* Create final bin 3-4.2km manually
gen byte vicinity_4200 = 1 if dist_m <= 4200 & dist_m > 3000
replace vicinity_4200 = 0 if missing(vicinity_4200)

* Create interaction terms
foreach i in 1000 2000 3000 4200 {
    gen vicinitypost`i' = vicinity_`i' * post
    gen vicinity_over5yrs`i' = vicinity_`i' * over5yrs
}

* Encode siteid as numeric to avoid string quote issues in loop
rename sitenum siteid
encode siteid, gen(siteid_num)
label list siteid_num

* Save results to permanent file
cap erase "$path\results\loo_results.dta"

postfile handle str10 excluded_site ///
    coef_1000 coef_2000 coef_3000 coef_4200 ///
    se_1000 se_2000 se_3000 se_4200 ///
    avg_premium ///
    using "$path\results\loo_results.dta", replace

* Get number of unique sites
qui tab siteid_num
local nsites = r(r)
display "Total sites to process: `nsites'"

forval s = 1/`nsites' {
    
    * Get the string label for this site number
    local sname : label siteid_num `s'
    display "Running DID excluding site `sname' (code `s')..."
    
    * Check sufficient treated observations remain
    qui count if siteid_num != `s' & dist_m <= 4200 & post == 1
    local ntr = r(N)
    if `ntr' < 50 {
        display "Site `sname': too few treated obs (`ntr'), skipping"
        continue
    }
    
    cap reghdfe lhprice ///
        vicinitypost1000 vicinitypost2000 vicinitypost3000 vicinitypost4200 ///
        vicinity_over5yrs1000 vicinity_over5yrs2000 ///
        vicinity_over5yrs3000 vicinity_over5yrs4200 ///
        post over5yrs buildingage ///
        popdens personincome pm25 est ///
        if siteid_num != `s', ///
        absorb(importparcelid month_year county_year) ///
        cluster(importparcelid)
    
    if _rc != 0 {
        display "Site `sname': regression failed (rc=`_rc'), skipping"
        continue
    }

    local c1 = _b[vicinitypost1000]
    local c2 = _b[vicinitypost2000]
    local c3 = _b[vicinitypost3000]
    local c4 = _b[vicinitypost4200]
    
    local s1 = _se[vicinitypost1000]
    local s2 = _se[vicinitypost2000]
    local s3 = _se[vicinitypost3000]
    local s4 = _se[vicinitypost4200]
    
    local avg = (`c1' + `c2' + `c3' + `c4') / 4
    local avg_pct = (exp(`avg') - 1) * 100
    
    display "  0-1km: `c1' | 1-2km: `c2' | 2-3km: `c3' | 3-4.2km: `c4'"
    display "  Average premium: `avg_pct'%"
    
    post handle ("`sname'") ///
        (`c1') (`c2') (`c3') (`c4') ///
        (`s1') (`s2') (`s3') (`s4') ///
        (`avg_pct')
}

postclose handle

* Load and display results
use "$path\results\loo_results.dta", clear

qui count
if r(N) == 0 {
    display "ERROR: No results saved."
    exit
}

display "====================================="
display "Results saved for `r(N)' iterations"
list excluded_site avg_premium coef_4200 se_4200, clean noobs

* Summary statistics
summarize avg_premium
local min_prem = string(r(min), "%9.2f")
local max_prem = string(r(max), "%9.2f")
display "Average premium range: `min_prem'% to `max_prem'%"
display "(Main result: 3.90%)"

summarize coef_4200
local min_c = string(r(min), "%9.4f")
local max_c = string(r(max), "%9.4f")
display "3-4.2km coefficient range: `min_c' to `max_c'"
display "(Main result: 0.1418 via reghdfe)"

* Count significant iterations
gen tstat_4200 = coef_4200 / se_4200
gen pval_4200 = 2 * (1 - normal(abs(tstat_4200)))
qui count if pval_4200 < 0.05
local nsig = r(N)
local ntot = _N
display "3-4.2km significant (p<0.05) in `nsig' out of `ntot' iterations"

* Coefficient plot
local main_coef = 0.1418
local main_se   = 0.0618
local main_ci_lo = `main_coef' - 1.96 * `main_se'
local main_ci_hi = `main_coef' + 1.96 * `main_se'

gen ci_lo_4200 = coef_4200 - 1.96 * se_4200
gen ci_hi_4200 = coef_4200 + 1.96 * se_4200

* Sort by coefficient magnitude
gsort coef_4200
gen iteration = _n
local ntot = _N

* Create x-axis labels manually from excluded_site
* Build label string for xlabel
local xlabels ""
forval i = 1/`ntot' {
    local sname = excluded_site[`i']
    local xlabels `"`xlabels' `i' "`sname'""'
}

twoway ///
    (rcap ci_lo_4200 ci_hi_4200 iteration, ///
        lcolor(black) lwidth(thin)) ///
    (scatter coef_4200 iteration, ///
        msymbol(Oh) mcolor(black) msize(medium)), ///
    yline(`main_coef', lpattern(dash) lcolor(chocolate) lwidth(medthick)) ///
    yline(`main_ci_lo', lpattern(dot) lcolor(chocolate) lwidth(thin)) ///
    yline(`main_ci_hi', lpattern(dot) lcolor(chocolate) lwidth(thin)) ///
    yline(0, lpattern(dot) lcolor(teal)) ///
    ytitle("3-4.2 km vicinity × post coefficient", size(small)) ///
    xtitle("Excluded CCUS site", size(small)) ///
    note("Dashed line = main result (0.1418); dotted lines = 95% CI", ///
        size(vsmall)) ///
    legend(off) ///
    scheme(s1mono) ///
    xlabel(`xlabels', labsize(vsmall) angle(45)) ///
    ylabel(, labsize(small)) ///
    name(loo_coefplot, replace)
graph export "$path\results\leave_one_out_coefplot.png", replace

display "====================================="
display "Leave-one-out complete"
display "Main result: 3.90% avg premium | 3-4.2km coef = 0.1418 (reghdfe)"
display "LOO avg premium range: `min_prem'% to `max_prem'%"
display "LOO 3-4.2km coef range: `min_c' to `max_c'"
display "LOO 3-4.2km significant in: `nsig' out of `ntot' iterations"


use "$path\results\loo_results.dta", clear

gen tstat_4200 = coef_4200 / se_4200
gen pval_4200 = 2 * (1 - normal(abs(tstat_4200)))
gen stars = ""
replace stars = "*" if pval_4200 < 0.05
replace stars = "**" if pval_4200 < 0.01
replace stars = "***" if pval_4200 < 0.001

* Display clean table with p-values and stars
list excluded_site coef_4200 se_4200 pval_4200 stars, ///
    clean noobs separator(0)
