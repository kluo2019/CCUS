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

forval i=1000(1000)4200 {
local j=`i'-1000 
gen byte vicinity_`i'=1 if dist_m <= `i' & dist_m >`j'
replace vicinity_`i'=0 if missing(vicinity_`i')
}

forval i=1000(1000)4200 {
gen  vicinitypost`i'=vicinity_`i'*post 
}   

xtreg lhprice vicinitypost* post buildingage i.month i.year popdens personincome pm25 est, fe robust cluster(importparcelid) 
eststo, title(year FE)

xtreg lhprice vicinitypost* post buildingage popdens personincome pm25 est i.month_year i.county_year, fe robust cluster(importparcelid) 
eststo, title(county-by-year FE)

esttab using "$path\results\DID_1000m.rtf" , b se r2 star(* 0.05 ** 0.01 *** 0.001) replace b(%9.4f) se(%9.4f) long nogap noomit mtitles drop(*month* *county_y* *year*) 

esttab using "$path\results\DID_1000m_detailed.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) starlevels(* 0.05 ** 0.01 *** 0.001) replace drop(*month_y* *county_y*) nogaps line wide r2 noomitted nonumbers noparentheses mtitles


* 400m distance bins
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

forval i=400(400)4200 {
local j=`i'-400 
gen byte vicinity_`i'=1 if dist_m <= `i' & dist_m >`j'
replace vicinity_`i'=0 if missing(vicinity_`i')
tab vicinity_`i'
}

gen byte vicinity_4200 =1 if dist_m <= 4200 & dist_m >4000
replace vicinity_4200=0 if missing(vicinity_4200)
tab vicinity_4200

forval i=400(400)4200 {
gen  vicinitypost`i'=vicinity_`i'*post 
}   

gen  vicinitypost4200=vicinity_4200*post 

xtreg lhprice vicinitypost* post buildingage i.month i.year popdens personincome pm25 est, fe robust cluster(importparcelid) 
eststo, title(year FE)

xtreg lhprice vicinitypost* post buildingage popdens personincome pm25 est i.month_year i.county_year, fe robust cluster(importparcelid) 
eststo, title(county-by-year FE)

esttab using "$path\results\DID_400m.rtf" , b se r2 star(* 0.05 ** 0.01 *** 0.001) replace b(%9.4f) se(%9.4f) long nogap noomit mtitles drop(*month* *county_y* *year*) 

esttab using "$path\results\DID_400m_detailed.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) starlevels(* 0.05 ** 0.01 *** 0.001) replace drop(*month_y* *county_y*) nogaps line wide r2 noomitted nonumbers noparentheses mtitles

