* site info of the second-nearest and third-nearest sites
clear all
global path "C:\phd4\CCUS"
cd "$path"
use sites2nd.dta, clear
set more off

gen sitenum = "site1"
reshape wide lat2nd lon2nd year_2nd, i(sitenum) j(post_operation_2nd_sites) string

save sites2nd_wide.dta, replace

clear all
global path "C:\phd4\CCUS"
cd "$path"
use sites2nd.dta, clear
set more off

keep if post_operation_2nd_sites == "site14" | post_operation_2nd_sites == "site13" | post_operation_2nd_sites == "site28" | post_operation_2nd_sites == "site2" | post_operation_2nd_sites == "site5" | post_operation_2nd_sites == "site4" | post_operation_2nd_sites == "site1" | post_operation_2nd_sites == "site30" 

rename year_2nd year_3rd
rename lat2nd lat3rd
rename lon2nd lon3rd

gen sitenum = "site1"
reshape wide lat3rd lon3rd year_3rd, i(sitenum) j(post_operation_2nd_sites) string

save sites3rd_wide.dta, replace


* What if there are multiple CCUS projects within 60 miles of each other
* There are several CCUS project sites within 60 miles of each other:

*•	site1 and site14 are within 51.24 miles of each other.
*•	site13 and site2 are within 59.60 miles of each other.
*•	site13 and site5 are within 48.16 miles of each other.
*•	site14 and site28 are within 24.60 miles of each other.
*•	site15 and site31 are within 0.75 miles of each other.
*•	site2 and site4 are within 58.79 miles of each other.
*•	site24 and site9 are within 8.93 miles of each other.
*•	site28 and site30 are within 39.50 miles of each other.

* At most, a CCUS has two other CCUS within 60 miles.
* As we assign the closest one to each household, each house may have at most three CCUS nearby.
* We need to generate a variable to indicate the second and the third nearest CCUS sites

* First, find out the second nearest CCUS sites based on distance and generate post_operation_2nd to indicate the transaction happened after the operational year of the second nearest CCUS project.

* keep accounts with only one nearest CCUS sites to append later
clear all
global path "C:\phd4\CCUS"
cd "$path"
use TRANS_DIST_ASMT_full_arm, clear
set more off

merge n:1 sitenum using sites2nd_wide
drop if _merge == 2
drop _merge

keep if year_2nd == .
drop year_2nd* lat2nd* lon2nd* dist2nd post_operation_2nd_sites post_operation_2nd 

save only1site.dta, replace

* get the second nearest CCUS site info
clear all
global path "C:\phd4\CCUS"
cd "$path"
use TRANS_DIST_ASMT_full_arm, clear
set more off

merge n:1 sitenum using sites2nd_wide
drop if _merge == 2
drop _merge

tab statename if year_2nd != .
tab sitenum if year_2nd != .
keep if year_2nd != .
drop year_2nd lat2nd lon2nd dist2nd post_operation_2nd_sites post_operation_2nd 
reshape long year_2nd lat2nd lon2nd, i(transid) j(sites2nd) string

* calculate distance between houses and the second nearest CCUS facilities
geodist latitude longitude lat2nd lon2nd, gen(dist2nd)

* sort by distance; keep the second one
sort transid dist2nd
bys transid: gen n = _n
keep if n == 2 
drop n

* append with those only have one nearest site nearby
append using only1site, force

save multiplesites.dta, replace

* Second, find out the third nearest CCUS sites based on distance and generate post_operation_3rd to indicate the transaction happened after the operational year of the third nearest CCUS project.

* keep those only have two nearest CCUS sites nearby to append later
merge n:1 sitenum using sites3rd_wide
drop if _merge == 2
drop _merge

keep if year_3rd == .
drop year_3rd* lat3rd* lon3rd* post_operation_3rd_sites post_operation_3rd 

save only2sites.dta, replace

* get the third nearest CCUS site info
use multiplesites.dta, clear
merge n:1 sitenum using sites3rd_wide
drop if _merge == 2
drop _merge

tab statename if year_3rd != .
tab sitenum if year_3rd != .
keep if year_3rd != .
drop year_3rd post_operation_3rd_sites post_operation_3rd 
reshape long year_3rd lat3rd lon3rd, i(transid) j(sites3rd) string

* calculate distance between houses and the second nearest CCUS facilities
geodist latitude longitude lat3rd lon3rd, gen(dist3rd)

* sort by distance; keep the third one
sort transid dist3rd
bys transid: gen n = _n
keep if n == 3 
drop n

* append with those only have two CCUS sites nearby
append using only2sites, force

gen post_operation_2nd = 0
replace post_operation_2nd = 1 if year > year_2nd

gen post_operation_3rd = 0
replace post_operation_3rd = 1 if year > year_3rd

gen num_ccus_60mi_new = post + post_operation_2nd + post_operation_3rd

save TRANS_DIST_ASMT_full_arm.dta, replace

* what if there are multiple CCUS projects within 60 miles of each other
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
tab vicinity_`i'
}

forval i=1000(1000)4200 {
gen  vicinitypost`i'=vicinity_`i'*post 
}   


*xtreg lhprice vicinitypost* post buildingage i.month i.year, fe robust cluster(importparcelid) 
*eststo, title(year FE)

xtreg lhprice vicinitypost* post buildingage num_ccus_60mi i.month i.year popdens personincome pm25 est, fe robust cluster(importparcelid) 
eststo, title(year FE)

*xtreg lhprice vicinitypost* post buildingage i.month_year i.county_year, fe robust cluster(importparcelid) 
*eststo, title(county_year FE)

xtreg lhprice vicinitypost* post buildingage num_ccus_60mi popdens personincome pm25 est i.month_year i.county_year, fe robust cluster(importparcelid) 
eststo, title(covariates)

esttab using "$path\results\DID_#CCUS_60mi_new.rtf" , b se r2 star(* 0.05 ** 0.01 *** 0.001) replace b(%9.4f) se(%9.4f) long nogap noomit mtitles drop(*month* *county_y* *year*) 

esttab using "$path\results\DID_#CCUS_60mi_new_detailed.rtf", cells(b(star fmt(4)) p(fmt(3)) se(fmt(4)) ci_l(fmt(4)) ci_u(fmt(4))) starlevels(* 0.05 ** 0.01 *** 0.001) replace drop(*month_y* *county_y*) nogaps line wide r2 noomitted nonumbers noparentheses mtitles

