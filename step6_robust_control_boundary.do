clear all
global path "C:\phd4\CCUS"
cd "$path"

forvalues n = 10(10)50{
use "TRANS_DIST_ASMT_all.dta", clear 

drop if dist>`n'
drop if operational <2000
drop if year < 1990

drop if community10 == 0

replace noofstories = round(noofstories)

* Keep only events which are deed transfers. 
keep if dataclassstndcode == "D" | dataclassstndcode == "H"
* This flag field identifies if the transfer is IntraFamily
drop if intrafamilytransferflag == "Y"

* drop remodel after 2000
tab state if yearremodeled > 2000 & yearremodeled != ., missing
drop if yearremodeled > 2000 & yearremodeled != .

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
eststo, title(`n')

esttab using "DID_`n'km.rtf" , b se r2 star(* 0.05 ** 0.01 *** 0.001) replace b(%9.4f) se(%9.4f) long nogap noomit mtitles drop(*month* *county_y* *year*) 

esttab using "DID_`n'km_detailed.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) starlevels(* 0.05 ** 0.01 *** 0.001) replace drop(*month_y* *county_y*) nogaps line wide r2 noomitted nonumbers noparentheses mtitles
}
