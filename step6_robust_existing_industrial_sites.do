clear all
global path "C:\phd4\CCUS"
cd $path\data
insheet using "fakesites.csv", clear
set more off

rename latitude lat2 
rename longitude lon2
save fakesites, replace

clear all
global path "C:\phd4\CCUS"
cd $path
use "TRANS_DIST_ASMT_all.dta", clear 
set more off

drop controlsitenum controlsite lat2 lon2 km_to_fakeid pairsite nearestccus km2ccus new_treat new_D industry_treat ccus_treat D D1 D2 DDD

* drop remodel after 2000
tab state if yearremodeled > 2000 & yearremodeled != ., missing
drop if yearremodeled > 2000 & yearremodeled != .
* 804,788 observations deleted

geonear transid latitude longitude using "$path\data\fakesites.dta", n(controlsitenum lat2 lon2)

rename nid controlsitenum
merge n:1 controlsitenum using $path\data\fakesites
drop if _merge != 3
drop _merge

rename km_to_nid km_to_fakeid

gen new_treat = 0 if km_to_fakeid <= 4.2
replace new_treat = 1 if dist <= 4.2
gen new_D = new_treat*post
tab2 sitenum new_treat, m

gen industry_treat = 0 if km_to_fakeid <= 30
replace industry_treat = 1 if km_to_fakeid <= 4.2

gen ccus_treat = 0 if dist <= 30
replace ccus_treat = 1 if dist <= 4.2

gen D = ccus_treat * post
gen D1 = ccus_treat * industry_treat
gen D2 = post * industry_treat
gen DDD = industry_treat * post * ccus_treat
tab2 sitenum DDD, missing

save TRANS_DIST_ASMT_all, replace

clear all
global path "C:\phd4\CCUS"
cd $path
use "TRANS_DIST_ASMT_all.dta", clear 
set more off

xtset importparcelid date
egen county_year = group(fips year)
egen month_year = group(month year)

xtreg lhprice new_D new_treat post buildingage i.month i.year i.geofips popdens personincome pm25 est, fe robust cluster(importparcelid) 
eststo, title(year FE)

xtreg lhprice new_D new_treat post buildingage popdens personincome pm25 est i.month_year i.geofips, fe robust cluster(importparcelid) 
eststo, title(county-by-year FE)

esttab using "$path\results\DID_fakesites_distancebin.rtf" , b se r2 star(* 0.05 ** 0.01 *** 0.001) replace b(%9.4f) se(%9.4f) long nogap noomit mtitles drop(*month* *year* *geofips* *month_y*) 

esttab using "$path\results\DID_fakesites_distancebin_detailed.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) starlevels(* 0.05 ** 0.01 *** 0.001) replace drop(*month* *year* *geofips* *month_y*) nogaps line wide r2 noomitted nonumbers noparentheses mtitles

