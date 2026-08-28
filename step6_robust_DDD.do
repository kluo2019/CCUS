clear all
global path "C:\phd4\CCUS"
cd "$path"
set more off

* ================================================
* Step 1: Prepare ALL CCUS sites
* ================================================

use "$path\data\site_coor_25.dta", clear

merge n:1 sitenum using "$path\data\site_info_all"
drop if _merge != 3
drop _merge

keep if inlist(sitenum, "site2", "site4", "site6", "site9", "site11", "site15") | ///
        inlist(sitenum, "site17", "site18", "site20", "site28", "site32", "site37")
		
keep sitenum facility_latitude facility_longitude operational

save "$path\data\ccussite_all_sectors.dta", replace

* ================================================
* Step 2: Prepare power generation control sites
* ================================================

insheet using "$path\data\fakesites_power_generation_5.csv", clear

* Rename to match required variable names
rename latitude lat2
rename longitude lon2
rename ccusyear operational

* Keep required variables
keep controlsitenum lat2 lon2 sitenum operational

gen sector = "PowerGeneration"

save "$path\data\control_power_temp.dta", replace

* ================================================
* Step 3: Prepare natural gas + ethanol control sites
* ================================================

insheet using "$path\data\fakesites_naturalgas_ethanol.csv", clear
keep controlsitenum lat2 lon2 sitenum operational sector

* Convert controlsitenum to string to match power generation format
tostring controlsitenum, replace

save "$path\data\control_ng_ethanol_temp.dta", replace

* ================================================
* Step 4: Combine all control sites
* ================================================

use "$path\data\control_power_temp.dta", clear
append using "$path\data\control_ng_ethanol_temp.dta"

* Check no duplicate controlsitenum
duplicates report controlsitenum
tab sector

save "$path\data\control_sites_all_sectors.dta", replace

* ================================================
* Step 5: Build pooled housing transaction dataset
* ================================================

use "$path\TRANS_DIST_ASMT_all.dta", clear
set more off

keep state yearremodeled transid latitude longitude ///
    importparcelid date fips geofips year month lhprice ///
    buildingage noofstories totalbedrooms buildingarea ///
    popdens personincome fed elecp gas pm25 happening est

* Match to nearest CCUS site across all sectors
geonear transid latitude longitude ///
    using "$path\data\ccussite_all_sectors.dta", ///
    n(sitenum facility_latitude facility_longitude)

rename nid sitenum
rename km_to_nid dist

merge n:1 sitenum using "$path\data\ccussite_all_sectors.dta"
drop if _merge != 3
drop _merge

* Drop remodeled properties after 2000
drop if yearremodeled > 2000 & yearremodeled != .

* Match to nearest control site across all sectors
geonear transid latitude longitude ///
    using "$path\data\control_sites_all_sectors.dta", ///
    n(controlsitenum lat2 lon2)

rename nid controlsitenum
rename km_to_nid km_to_fakeid

merge n:1 controlsitenum using "$path\data\control_sites_all_sectors.dta", ///
    force
drop if _merge != 3
drop _merge

* Keep within 30 km of either CCUS or control site
drop if dist > 30 & km_to_fakeid > 30

* ================================================
* Step 6: Create DDD variables
* ================================================

gen treat = 0
replace treat = 1 if dist <= 4.2 | km_to_fakeid <= 4.2

gen new_treat = 0
replace new_treat = 1 if dist <= km_to_fakeid

gen post = 0
replace post = 1 if year >= operational

gen DD = treat * post * new_treat
gen D1 = treat * post
gen D2 = treat * new_treat
gen D3 = post * new_treat

xtset importparcelid date
egen county_year = group(fips year)
egen month_year  = group(month year)
egen state_year  = group(state year)

* Check sample
display "Total observations: " _N
display "Obs near CCUS (new_treat=1): "
count if new_treat == 1
display "Obs near control (new_treat=0): "
count if new_treat == 0
display "Treated (treat=1, new_treat=1): "
count if treat == 1 & new_treat == 1
display "Control treated (treat=1, new_treat=0): "
count if treat == 1 & new_treat == 0


* ================================================
* Step 7: Pooled DDD regressions -- Alt 1 and Alt 2 only
* ================================================

eststo clear

* Alt 1: property + month + year + county + state-year FE
eststo alt1: reghdfe lhprice DD D1 D2 D3 ///
    buildingage popdens personincome est ///
    fed elecp gas pm25 happening, ///
    absorb(importparcelid month year geofips state_year) ///
    cluster(importparcelid)

* Alt 2: property + month-year + state-year FE
eststo alt2: reghdfe lhprice DD D1 D2 D3 ///
    buildingage popdens personincome est ///
    fed elecp gas pm25 happening, ///
    absorb(importparcelid month_year state_year) ///
    cluster(importparcelid)

* ================================================
* Step 8: Display and export results
* ================================================

foreach var in DD D1 D3 {
    local b = _b[`var']
    local s = _se[`var']
    if `s' > 0 {
        local p = 2*(1-normal(abs(`b'/`s')))
        display "`var': coef=" `b' " SE=" `s' " p=" `p'
    }
    else {
        display "`var': dropped (collinear)"
    }
}

local dd_coef = _b[DD]
local dd_se   = _se[DD]
local pval    = 2*(1-normal(abs(`dd_coef'/`dd_se')))
local pct     = (exp(`dd_coef')-1)*100

display "====================================="
display "Pooled DDD: Power Gen + NatGas + Ethanol"
display "DD coef:  " `dd_coef'
display "DD SE:    " `dd_se'
display "p-value:  " `pval'
display "Premium:  " `pct' "%"
display "====================================="

* Export Alt 1 and Alt 2 only
esttab alt1 alt2 ///
    using "$path\results\DDD_all_sectors.rtf", ///
    b se r2 star(* 0.1 ** 0.05 *** 0.01) ///
    replace b(%9.4f) se(%9.4f) long nogap noomit ///
    mtitles("Alt 1" "Alt 2") ///
    keep(DD D1 D3) ///
    title("Table S6b. Pooled DDD: Power Generation, Natural Gas Processing, and Ethanol") ///
    note("Dependent variable: log housing price (2021 dollars)." ///
         "DD = treat x post x new_treat is the key triple-difference coefficient." ///
         "new_treat = 1 if nearest site has CCUS; 0 if nearest site is non-CCUS control." ///
         "treat = 1 if within 4.2 km. post = 1 if year >= CCUS operational year." ///
         "D2 (treat x new_treat) absorbed by property fixed effects." ///
         "Alt 1: property, month, year, county, state-by-year fixed effects." ///
         "Alt 2: property, month-by-sample, state-by-year fixed effects." ///
         "Robust SEs clustered at household level." ///
         "* p<0.1, ** p<0.05, *** p<0.01")

display "Pooled DDD complete"
display "Results saved to DDD_all_sectors.rtf"
