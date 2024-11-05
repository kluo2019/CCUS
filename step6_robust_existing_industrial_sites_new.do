clear all
global path "C:\phd4\CCUS"
cd $path\data
insheet using "fakesites_try3.csv", clear
set more off

rename latitude lat2 
rename longitude lon2
save control_sites_updated, replace

clear all
global path "C:\phd4\CCUS"
cd $path
use "TRANS_DIST_ASMT_all.dta", clear 
set more off

keep state yearremodeled transid latitude longitude dist post sitenum importparcelid date fips geofips year month lhprice buildingage noofstories totalbedrooms buildingarea popdens personincome fed elecp gas pm25 happening est operational
*drop controlsitenum controlsite lat2 lon2 nearestccus km2ccus new_treat new_D

* drop remodel after 2000
tab state if yearremodeled > 2000 & yearremodeled != ., missing
drop if yearremodeled > 2000 & yearremodeled != .
* 804,788 observations deleted

geonear transid latitude longitude using "$path\data\control_sites_updated.dta", n(controlsitenum lat2 lon2)

rename nid controlsitenum
merge n:1 controlsitenum using $path\data\control_sites_updated
drop if _merge != 3
drop _merge

rename km_to_nid km_to_fakeid

gen new_treat = 0 if km_to_fakeid <= 3.2
replace new_treat = 1 if dist <= 4.2
gen new_D = new_treat*post
tab2 sitenum new_treat, m

save TRANS_DIST_ASMT_all_exist_plants_new, replace

clear all
global path "C:\phd4\CCUS"
cd $path
use "TRANS_DIST_ASMT_all_exist_plants_new.dta", clear 
set more off

gen t = year - operational + 6

forvalues i = 1/11{
gen t`i' = 0
}

replace t1 = (t<2)

forvalues i = 2/11{
replace t`i' = (t==`i')
}
gen pre_5 = new_treat * t1
gen pre_4 = new_treat * t2
gen pre_3 = new_treat * t3
gen pre_2 = new_treat * t4
gen current = new_treat * t6
gen post_1 = new_treat * t7
gen post_2 = new_treat * t8
gen post_3 = new_treat * t9
gen post_4 = new_treat * t10
gen post_5 = new_treat * t11

est clear
egen county_year = group(fips year)
egen month_year = group(month year)
egen state_year = group(state year)

reg lhprice pre_* current post_* buildingage popdens personincome est happening i.month_year i.county_year
est store a

coefplot a, baselevels ///
keep(pre_* current post_*) ///
vertical ///转置图形
coeflabels( ///
pre_5 = "<=-5" ///
pre_4 = "-4" ///
pre_3 = "-3" /// 
pre_2 = "-2" ///
current = "0" ///
post_1 = "1" ///
post_2 = "2" ///
post_3 = "3" ///
post_4 = "4" ///
post_5 = "5") ///
yline(0,lcolor(edkblue*0.8)) ///加入y=0这条虚线
ylabel(-0.6(0.2)1.4) ///
xline(5, lwidth(vthin) lpattern(dash) lcolor(teal)) ///
ylabel(,labsize(*0.5)) xlabel(,labsize(*0.5)) ///
ytitle("External impact of CCUS put into operation", size(small)) ///加入Y轴标题,大小small
xtitle("Relative time between housing transaction and CCUS put into operation", size(small)) ///加入X轴标题，大小small 
addplot(line @b @at) ///增加点之间的连线
ciopts(lpattern(dash) recast(rcap) msize(medium)) ///CI为虚线上下封口
msymbol(circle_hollow) ///plot空心格式
scheme(s1mono) name("event_control_sites")

graph save "$path\results\event_fakesites.gph", replace
graph export "C:\phd4\CCUS\results\event_fakesites.png", as(png) name("event_control_sites") replace

clear all
global path "C:\phd4\CCUS"
cd $path
use "TRANS_DIST_ASMT_all_exist_plants_new.dta", clear 
set more off

xtset importparcelid date
egen county_year = group(fips year)
egen month_year = group(month year)
egen state_year = group(state year)

xtreg lhprice new_D new_treat post buildingage popdens personincome est i.month i.year i.geofips i.state_year, fe robust cluster(importparcelid) 
eststo, title(month, year, couty, state-year FE)

xtreg lhprice new_D new_treat post buildingage popdens personincome est i.month i.geofips i.state_year, fe robust cluster(importparcelid) 
eststo, title(month, county, state-year FE)

xtreg lhprice new_D new_treat post buildingage popdens personincome est i.month_year i.geofips i.state_year, fe robust cluster(importparcelid) 
eststo, title(month-year, county, state-year FE)

esttab using "$path\results\DID_fakesites_try3.rtf", b se r2 star(* 0.05 ** 0.01 *** 0.001) replace b(%9.4f) se(%9.4f) long nogap noomit mtitles drop(*month* *year* *geofips* *month_y*) 

esttab using "$path\results\DID_fakesites_try3_detailed.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) starlevels(* 0.05 ** 0.01 *** 0.001) replace drop(*month* *year* *geofips* *month_y*) nogaps line wide r2 noomitted nonumbers noparentheses mtitles

clear all
global path "C:\phd4\CCUS"
cd $path
use "TRANS_DIST_ASMT_all_exist_plants.dta", clear 
set more off

xtset importparcelid date
egen county_year = group(fips year)
egen month_year = group(month year)
egen state_year = group(state year)

xtreg lhprice new_D new_treat post buildingage i.month i.state, fe robust cluster(importparcelid) 
eststo, title(month, state FE)

xtreg lhprice new_D new_treat post buildingage i.month i.year i.state, fe robust cluster(importparcelid) 
eststo, title(month, year, state FE)

xtreg lhprice new_D new_treat post buildingage i.month i.year i.geofips i.state, fe robust cluster(importparcelid) 
eststo, title(month, year, county, state FE)

xtreg lhprice new_D new_treat post buildingage i.month_year i.county i.state, fe robust cluster(importparcelid) 
eststo, title(month-year, county, state FE)

xtreg lhprice new_D new_treat post buildingage i.month i.geofips i.year i.state_year, fe robust cluster(importparcelid) 
eststo, title(month, county, year, state-year FE)

xtreg lhprice new_D new_treat post buildingage i.month i.geofips i.state_year, fe robust cluster(importparcelid) 
eststo, title(month, county, state-year FE)

xtreg lhprice new_D new_treat post buildingage i.month i.state i.year i.county_year, fe robust cluster(importparcelid) 
eststo, title(month, state, year, county-year FE)

esttab using "$path\results\DID_fakesites_state.rtf", b se r2 star(* 0.05 ** 0.01 *** 0.001) replace b(%9.4f) se(%9.4f) long nogap noomit mtitles drop(*month* *year* *geofips* *month_y*) 

esttab using "$path\results\DID_fakesites_state_detailed.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) starlevels(* 0.05 ** 0.01 *** 0.001) replace drop(*month* *year* *geofips* *month_y*) nogaps line wide r2 noomitted nonumbers noparentheses mtitles


