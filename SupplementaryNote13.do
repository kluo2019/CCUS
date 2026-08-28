clear all
global path "C:\phd4\CCUS"
cd "$path"
adopath + "$path\"
use "TRANS_DIST_ASMT_without_remodel.dta", clear
set more off

global building buildingage noofstories totalbedrooms building_area  
global demographic personincome popdens 
global control fed elecp gas pm25 happening

xtset importparcelid date
gen treat = 0
replace treat = 1 if dist <= 4.2
gen D = treat * post    
gen never_op = (treat == 0)

gen ry = year - operational

* Drop to ±10 year window
drop if ry > 10 | ry < -10

* Create pre-treatment dummies (omit -1 as baseline)
forvalues k = 10(-1)2 {
    gen pre_`k' = (ry == -`k')
}

* Current period (year 0)
gen current = (ry == 0)

* Post-treatment dummies
forvalues k = 1/10 {
    gen post_`k' = (ry == `k')
}

egen county_year = group(fips year)

* Run IW estimator
eventstudyinteract lhprice pre_* current post_*, ///
    cohort(operational) ///
    control_cohort(never_op) ///
    covariates(est $building $demographic $control) ///
    absorb(i.importparcelid i.county_year) ///
    vce(cluster importparcelid)

* Extract coefficients and SEs
matrix C = e(b_iw)
mata st_matrix("A", sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix list C

* Plot
coefplot matrix(C[1]), se(C[2]) baselevels ///
    vertical ///
    yline(0, lcolor(olive)) ///
    xline(10.5, lwidth(vthin) lpattern(shortdash) lcolor(teal)) ///
    ylabel(-1(0.5)1, labsize(vsmall)) ///
    xlabel(1 "-10" 2 "-9" 3 "-8" 4 "-7" 5 "-6" ///
           6 "-5" 7 "-4" 8 "-3" 9 "-2" 10 "-1" ///
           11 "0" 12 "1" 13 "2" 14 "3" 15 "4" ///
           16 "5" 17 "6" 18 "7" 19 "8" 20 "9" 21 "10", ///
           labsize(vsmall)) ///
    ytitle("Impact of CCUS Projects put into operation", size(small)) ///
    xtitle("Relative Year between housing transaction and CCUS put into operation", ///
        size(small)) ///
    addplot(line @b @at, color(maroon)) ///
    ciopts(recast(rarea) color(gs5%80*.2) lwidth(none)) ///
    msymbol(diamond_hollow) mlcolor(maroon) msize(medium) ///
    scheme(s1mono) ///
    legend(size(vsmall) order(2 "Point Estimate" 1 "95% CI"))
graph save "$path\results\event_extended.gph", replace
graph export "$path\results\event_extended.png", replace

display "Extended event study complete"
display "Check matrix list C for all coefficients and SEs"


clear all
global path "C:\phd4\CCUS"
cd "$path"
use "TRANS_DIST_ASMT_without_remodel.dta", clear
set more off

global building buildingage noofstories totalbedrooms buildingarea  
global demographic personincome popdens 
global control fed elecp gas pm25 happening

xtset importparcelid date
gen treat = 0
replace treat = 1 if dist <= 4.2

gen ry = year - operational
egen county_year = group(fips year)
egen month_year  = group(month year)

* Create stratified post-treatment indicators
* Only for treated properties (within 4.2 km)
gen post_early  = (ry >= 1 & ry <= 3)  & treat == 1
gen post_medium = (ry >= 4 & ry <= 7)  & treat == 1
gen post_long   = (ry >= 8)            & treat == 1

replace post_early  = 0 if missing(post_early)
replace post_medium = 0 if missing(post_medium)
replace post_long   = 0 if missing(post_long)

* Pre-treatment control
gen over5yrs = 0
replace over5yrs = 1 if ry <= -5 & treat == 1

* Check observation counts
display "Early (1-3 yrs) treated obs:"
count if post_early == 1
display "Medium (4-7 yrs) treated obs:"
count if post_medium == 1
display "Long (8+ yrs) treated obs:"
count if post_long == 1

* Stratified DID regression
xtreg lhprice ///
    post_early post_medium post_long over5yrs ///
    buildingage popdens personincome pm25 est ///
    fed elecp gas happening ///
    i.month_year i.county_year, ///
    fe robust cluster(importparcelid)

* Display results
local coef_e = _b[post_early]
local coef_m = _b[post_medium]
local coef_l = _b[post_long]
local se_e   = _se[post_early]
local se_m   = _se[post_medium]
local se_l   = _se[post_long]
local p_e    = 2*(1-normal(abs(`coef_e'/`se_e')))
local p_m    = 2*(1-normal(abs(`coef_m'/`se_m')))
local p_l    = 2*(1-normal(abs(`coef_l'/`se_l')))
local pct_e  = (exp(`coef_e') - 1) * 100
local pct_m  = (exp(`coef_m') - 1) * 100
local pct_l  = (exp(`coef_l') - 1) * 100

display "====================================="
display "Stratified post-treatment results:"
display "Early  (1-3 yrs): coef=" `coef_e' " SE=" `se_e' ///
    " p=" `p_e' " premium=" `pct_e' "%"
display "Medium (4-7 yrs): coef=" `coef_m' " SE=" `se_m' ///
    " p=" `p_m' " premium=" `pct_m' "%"
display "Long   (8+ yrs):  coef=" `coef_l' " SE=" `se_l' ///
    " p=" `p_l' " premium=" `pct_l' "%"

* Export table
eststo clear
eststo strat: xtreg lhprice ///
    post_early post_medium post_long over5yrs ///
    buildingage popdens personincome pm25 est ///
    fed elecp gas happening ///
    i.month_year i.county_year, ///
    fe robust cluster(importparcelid)

esttab strat ///
    using "$path\results\stratified_posttreatment.rtf", ///
    b se r2 star(* 0.1 ** 0.05 *** 0.01) ///
    replace b(%9.4f) se(%9.4f) ///
    keep(post_early post_medium post_long) ///
    mtitles("Stratified Post-Treatment") ///
    title("Table S14. Housing Price Effects by Years Since CCUS Operation") ///
    note("Dependent variable: log housing price (2021 dollars)." ///
         "Individual, county-by-year, month-by-sample fixed effects." ///
         "Robust SEs clustered at household level." ///
         "post_early = years 1-3 post-operation;" ///
         "post_medium = years 4-7 post-operation;" ///
         "post_long = 8+ years post-operation." ///
         "* p<0.1, ** p<0.05, *** p<0.01")

display "====================================="
display "Stratified analysis complete"
display "Results saved to stratified_posttreatment.rtf"