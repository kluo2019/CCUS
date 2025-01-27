* new power generation only
clear all
global path "C:\phd4\CCUS"
cd $path\data
use "site_coor_25.dta", clear
set more off

merge n:1 sitenum using site_info_all
drop if _merge != 3
drop _merge

keep if facilityindustry == "Power Generation"
drop if retrofit == 1
keep sitenum facility_latitude facility_longitude operational

save ccussite, replace

clear all
global path "C:\phd4\CCUS"
cd $path\data
insheet using "fakesites_power_generation_5.csv", clear
set more off

geonear controlsitenum latitude longitude using "$path\data\ccussite.dta", n(sitenum facility_latitude facility_longitude)

merge n:1 sitenum using site_info_all
drop if _merge != 3
drop _merge

keep if facilityindustry == "Power Generation"
drop if retrofit == 1
keep controlsitenum latitude longitude operationalyear

rename controlsitenum sitenum
rename latitude facility_latitude 
rename longitude facility_longitude
rename operationalyear operational

gen whetherccus  = 0

append using ccussite, force
replace whetherccus = 1 if whetherccus == .
save allsites5, replace

clear all
global path "C:\phd4\CCUS"
cd $path
use "TRANS_DIST_ASMT_all.dta", clear 
set more off

keep state yearremodeled transid latitude longitude importparcelid date fips geofips year month lhprice buildingage noofstories totalbedrooms buildingarea popdens personincome fed elecp gas pm25 happening est 

save ddd, replace

clear all
global path "C:\phd4\CCUS"
cd $path
use "ddd.dta", clear 
set more off

* drop remodel after 2000
tab state if yearremodeled > 2000 & yearremodeled != ., missing
drop if yearremodeled > 2000 & yearremodeled != .
* 804,788 observations deleted

geonear transid latitude longitude using "$path\data\allsites5.dta", n(sitenum facility_latitude facility_longitude)

tab nid
sum km_to_nid

rename nid sitenum
rename km_to_nid dist

merge n:1 sitenum using $path\data\allsites5
drop if _merge != 3
drop _merge

drop if dist > 30 

tab sitenum
sum dist

gen treat = 0
replace treat = 1 if dist <= 4.2

gen new_treat = 0 
replace new_treat = 1 if whetherccus == 1

gen post = 0
replace post = 1 if year > operational



gen DD = treat * post * new_treat
gen D1 = treat * post
gen D2 = treat * new_treat
gen D3 = post * new_treat
tab DD, m
tab D1, m
tab D2, m
tab D3, m

xtset importparcelid date
egen county_year = group(fips year)
egen month_year = group(month year)
egen state_year = group(state year)

save DDDdata_singlecontrolsites.dta, replace
**# Bookmark #1
xtreg lhprice DD D1 D2 D3 treat new_treat post buildingage popdens personincome est i.month i.year i.geofips i.state_year, fe robust cluster(importparcelid) 
eststo, title(month, year, county, state-year FE)

xtreg lhprice DD D1 D2 D3 treat new_treat post buildingage popdens personincome est i.month i.geofips i.state_year, fe robust cluster(importparcelid) 
eststo, title(month, county, state-year FE)

xtreg lhprice DD D1 D2 D3 treat new_treat post buildingage popdens personincome est i.month_year i.geofips i.state_year, fe robust cluster(importparcelid) 
eststo, title(month-year, county, state-year FE)

esttab using "$path\results\DDD_power_generation_new5.rtf", b se r2 star(* 0.05 ** 0.01 *** 0.001) replace b(%9.4f) se(%9.4f) long nogap noomit mtitles drop(*month* *year* *geofips* *month_y*) 

esttab using "$path\results\DDD__power_generation_new5_detailed.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) starlevels(* 0.05 ** 0.01 *** 0.001) replace drop(*month* *year* *geofips* *month_y*) nogaps line wide r2 noomitted nonumbers noparentheses mtitles
