set maxvar 120000
set matsize 11000

clear all
global path "C:/phd4/CCUS"
cd $path/data
use "trans.dta", clear
set more off

* drop outliers of salesprice
egen meanhp=mean(salesprice)
egen sdhp=sd(salesprice)
gen hp1=meanhp-2*sdhp
gen hp2=meanhp+2*sdhp
drop if salesprice >hp2 | salesprice <hp1
drop meanhp sdhp hp1 hp2

merge m:1 year using adjusted
keep if _merge ==3
drop _merge
gen hp = salesprice/cpi*100
gen lhprice = ln(hp)

* 1. properties that have been sold more than once
bys importparcelid: gen n_import = _N
bys importparcelid transid: gen n_trans = _N
keep if n_import > n_trans

* 2. with at least one sale starting after the placement of only one CCUS within 100 km
** 2.1 properties that have only one CCUS within 100 km
*** 2.1.1 obtain coordinates of CCUS facilities
merge m:1 state using site_coor
keep if _merge ==3
drop _merge
drop facility_latitudesite18 facility_longitudesite18 facility_latitudesite25 facility_longitudesite25

*** 2.1.2 convert to desired data pattern--one transid with all sites info
reshape long facility_latitude facility_longitude, i(transid) j(sitenum) string

*** 2.1.3 calculate distance between houses and each CCUS facilities
geodist latitude longitude facility_latitude facility_longitude, gen(dist)
save buffer_all.dta, replace


