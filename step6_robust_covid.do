clear all
global path "C:\phd4\CCUS"
cd "$path"
use TRANS_DIST_ASMT_full_arm, clear
set more off

* drop pandemic period
drop if date > mdy(3,11,2020)
* (38,758 observations deleted)

xtset importparcelid date
egen zip_year = group(zipcode year)
egen county_year = group(fips year)
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

xtreg lhprice vicinitypost* post buildingage popdens personincome pm25 est i.month_year i.county_year, fe robust cluster(importparcelid) 
eststo, title(covariates)

esttab using "$path\results\DID_1000m_covid_detailed.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) starlevels(* 0.05 ** 0.01 *** 0.001) replace drop(*month_y* *county_y*) nogaps line wide r2 noomitted nonumbers noparentheses mtitles