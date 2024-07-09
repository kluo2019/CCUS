ssc install cem
clear all
global path "C:\phd4\CCUS"
cd "$path"
use TRANS_DIST_ASMT_full_arm, clear
set more off

gen treat =0
replace treat =1 if dist <= 4.2

drop if missing(buildingage) & missing(totalrooms) & missing(totalbedrooms) & missing(buildingarea) & missing(noofstor)

bys fips year: gen n = _N
bys fips year: egen sumtreat = sum(treat)
tab sumtreat
keep if sumtreat > 2

drop treat sumtreat n

egen county_year=group(fips year)
tab county_year

save "$path\data\cem.dta", replace

clear all
global path "C:\phd4\CCUS"
cd "$path\data"
adopath + "$path\"
use cem.dta, clear
set more off

gen matched=.
gen strata=.
gen weights =.

global outcome lhprice
global xlist buildingage totalrooms buildingarea totalbedrooms noofstor

gen treat =0
replace treat =1 if dist <= 4.2

forvalues cy = 1/210{

*-- Run coarsened exact matching
cem $xlist if county_year == `cy', treatment(treat)

replace matched = cem_matched if cem_matched != .
replace weights = cem_weights if cem_weights != .
replace strata = cem_strata if cem_strata != .
drop cem_matched cem_weights cem_strata
}

tab matched,m
keep if matched == 1
* 49,433 obs
save matchedsample.dta, replace

clear all
global path "C:\phd4\CCUS"
cd "$path\data"
adopath + "$path\"
use matchedsample.dta, clear
set more off

egen month_year = group(month year)
gen dist_m = dist * 1000

forval i=1000(1000)4200 {
local j=`i'-1000 
gen byte vicinity_`i'=1 if dist_m <= `i' & dist_m >`j'
replace vicinity_`i'=0 if missing(vicinity_`i')
tab vicinity_`i'
}

forval i=1000(1000)4200 {
gen  vicinitypost`i'=vicinity_`i'*post 
}   

*-- Estimate the DID model using the matched sample and weights
xtset importparcelid date
xtreg lhprice vicinitypost* post buildingage popdens personincome pm25 est i.month_year i.county_year, fe robust cluster(importparcelid) 
eststo, title(county_year FE)

esttab using "$path\results\cemDID.rtf" , b se r2 star(* 0.05 ** 0.01 *** 0.001) replace b(%9.4f) se(%9.4f) long nogap noomit mtitles drop(*month* *county_y*) 

esttab using "$path\results\cemDID_detailed.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) starlevels(* 0.05 ** 0.01 *** 0.001) replace drop(*month* *county_y*) nogaps line wide r2 noomitted nonumbers noparentheses mtitles