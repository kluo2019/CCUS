set maxvar 120000
set matsize 11000

use "TRANS_DIST_ASMT_all.dta", clear 

drop if dist>30
drop if operational <2000
drop if year < 1990

drop if community10 == 0

replace noofstories = round(noofstories)

* Keep only events which are deed transfers. 
keep if dataclassstndcode == "D" | dataclassstndcode == "H"
* This flag field identifies if the transfer is IntraFamily
drop if intrafamilytransferflag == "Y"

save TRANS_DIST_ASMT_full_remodel.dta, replace

* drop remodel after 2000
tab state if yearremodeled > 2000 & yearremodeled != ., missing
drop if yearremodeled > 2000 & yearremodeled != .

save TRANS_DIST_ASMT_full_arm, replace

bys importparcelid: gen repeatsale = _N
bys importparcelid: egen sumpost = sum(post)
order importparcelid repeatsale sumpost post
keep if repeatsale>1 & (repeatsale > sumpost)

replace geozip = 60002 if transid == 385058335
replace geozip = 60096 if transid == 453920792
replace geozip = 60096 if transid == 528902306
replace geozip = 62522 if transid == 416042855
replace geozip = 62521 if transid == 387687420
replace geozip = 62521 if transid == 378135437
replace geozip = 62521 if transid == 386380271
replace geozip = 62535 if transid == 426955552
replace geozip = 62526 if transid == 386380273
replace geozip = 53140 if transid == 538903672
drop zipcode
gen str5 zipcode = string(geozip,"%05.0f")
save TRANS_DIST_ASMT_without_remodel.dta, replace

* summary statistics
clear all
global path "C:\phd4\CCUS"
cd "$path\data"
set more off
* full sample
use TRANS_DIST_ASMT_full_arm.dta, clear
gen treat = 0 
replace treat = 1 if dist <= 4.2
tabstat yearbuilt noofstories totalroom totalbedroom buildingarea landassessed, by(treat) col(statistics) stat(mean sd min max) format(%9.2f)
tabstat hp, by(state) stat(n mean sd) 
tab treat

* cross-sectional sample
use "matchedsample.dta", clear 
drop treat
gen treat = 0 
replace treat = 1 if dist <= 4.2
tabstat yearbuilt noofstories totalroom totalbedroom buildingarea landassessed, by(treat) col(statistics) stat(mean sd min max) format(%9.2f)
tab treat

* t test
use "matchedsample.dta", clear 
drop treat
gen treat = 0 
replace treat = 1 if dist <= 4.2
keep if treat == 1
keep hp yearbuilt noofstories totalrooms totalbedrooms buildingarea landassessedvalue garage_area
gen sample = 3
save matchedtreat.dta, replace

use "matchedsample.dta", clear 
drop treat
gen treat = 0 
replace treat = 1 if dist <= 4.2
keep if treat == 0
keep hp yearbuilt noofstories totalrooms totalbedrooms buildingarea landassessedvalue garage_area
gen sample = 3
save matchedcontrol.dta, replace

use "TRANS_DIST_ASMT_full_arm.dta", clear 
gen treat = 0 
replace treat = 1 if dist <= 4.2
keep if treat == 1
keep hp yearbuilt noofstories totalrooms totalbedrooms buildingarea landassessedvalue garage_area
gen sample = 2
save repeatedtreat.dta, replace

use "TRANS_DIST_ASMT_full_arm.dta", clear 
gen treat = 0 
replace treat = 1 if dist <= 4.2
keep if treat == 0
keep hp yearbuilt noofstories totalrooms totalbedrooms buildingarea landassessedvalue garage_area
gen sample = 2
save repeatedcontrol.dta, replace

use "repeatedtreat.dta", clear 
set more off

append using matchedtreat

foreach n in yearbuilt noofstories totalrooms totalbedrooms buildingarea landassessedvalue{
ttest `n', by(sample)
}

use "repeatedcontrol.dta", clear 
set more off

append using matchedcontrol

foreach n in yearbuilt noofstories totalrooms totalbedrooms buildingarea landassessedvalue{
ttest `n', by(sample)
}

* percentage difference
clear all
global path "C:\phd4\CCUS"
cd "$path\data"
set more off
use "TRANS_DIST_ASMT_full_arm.dta", clear
gen treat = 0 
replace treat = 1 if dist <= 4.2
tabstat hp yearbuilt noofstories totalroom totalbedroom building_area landassessed garage_area, col(statistics) stat(mean) format(%9.2f)
