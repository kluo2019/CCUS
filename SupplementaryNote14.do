clear all
global path "C:\phd4\CCUS"
cd "$path"

* ================================================
* BEA Transfer Payments Placebo Test
* Using CAINC30 - Economic Profile by County
* LineCode 130: Per capita personal current transfer receipts
* ================================================

* Import CAINC30
import delimited "$path\data\CAINC30__ALL_AREAS_1969_2024.csv", ///
    clear varnames(1) stringcols(1 2 3 4 5 6 7 8)

* Clean FIPS - remove quotes
replace geofips = subinstr(geofips, `"""', "", .)
replace geofips = trim(geofips)

* Keep only per capita personal current transfer receipts
* LineCode 130
keep if linecode == "130"

* Keep only US counties (state FIPS 01-56, county code not 000)
gen statefips_str = substr(geofips, 1, 2)
destring statefips_str, gen(statefips_num)
keep if statefips_num >= 1 & statefips_num <= 56

gen county3 = substr(geofips, 3, 3)
drop if county3 == "000"
drop statefips_str statefips_num county3

* Keep identifier and year columns 2000-2021 only (v40-v61)
keep geofips geoname v40-v61

* Rename year columns to actual years
rename v40 y2000
rename v41 y2001
rename v42 y2002
rename v43 y2003
rename v44 y2004
rename v45 y2005
rename v46 y2006
rename v47 y2007
rename v48 y2008
rename v49 y2009
rename v50 y2010
rename v51 y2011
rename v52 y2012
rename v53 y2013
rename v54 y2014
rename v55 y2015
rename v56 y2016
rename v57 y2017
rename v58 y2018
rename v59 y2019
rename v60 y2020
rename v61 y2021

* Destring year values (may contain "(NA)" or "(D)" for missing)
forval yr = 2000/2021 {
    replace y`yr' = "" if y`yr' == "(NA)" | y`yr' == "(D)"
    destring y`yr', replace
}

* Reshape from wide to long
reshape long y, i(geofips geoname) j(year)
rename y transfer_pc

* Clean FIPS to 5 digits for merging
gen fips = geofips
replace fips = substr(fips, 1, 5)

* Check
tab year
summarize transfer_pc

* Log transform
gen ltransfer_pc = log(transfer_pc) if transfer_pc > 0

* Save clean panel
save "$path\data\bea_transfer_panel.dta", replace
display "BEA transfer payments panel built"
display "Observations: " _N

* ================================================
* Merge with CCUS treatment structure
* ================================================

use "$path\data\bea_transfer_panel.dta", clear

* Merge with CCUS county crosswalk
merge m:1 fips using "$path\data\ccus_county.dta", ///
    keep(master match) gen(_merge_ccus)

* Check merge
tab _merge_ccus

* Define treatment and post indicators
gen treated   = (_merge_ccus == 3)
gen post_bea  = 0
replace post_bea = 1 if treated == 1 & year >= operational

* Extract state FIPS for state-year FE
gen statefips = substr(fips, 1, 2)

* Create fixed effects
egen county_fe  = group(fips)
egen state_year = group(statefips year)

* Check treatment group
tab treated
tab post_bea if treated == 1

* ================================================
* DID regression
* ================================================

reghdfe ltransfer_pc post_bea, ///
    absorb(county_fe state_year) ///
    cluster(county_fe)

local coef = _b[post_bea]
local se   = _se[post_bea]
local pval = 2*(1-normal(abs(`coef'/`se')))
local pct  = (exp(`coef')-1)*100

display "====================================="
display "BEA Transfer Payments Placebo Test"
display "Outcome: Log per capita transfer receipts"
display "Coefficient: " `coef'
display "SE: " `se'
display "p-value: " `pval'
display "% change: " `pct' "%"
display "====================================="
if `pval' > 0.05 {
    display "No significant effect -- rules out fiscal confound"
}
else {
    display "Significant effect -- fiscal changes accompanied CCUS"
}

* ================================================
* Event study for transfer payments
* ================================================

gen gap_bea = year - operational if treated == 1
replace gap_bea = -6 if gap_bea < -6 & treated == 1
replace gap_bea =  6 if gap_bea >  6 & treated == 1

forval t = 2/6 {
    gen lag_bea`t'  = (gap_bea == -`t') if treated == 1
    replace lag_bea`t' = 0 if lag_bea`t' == .
}
forval t = 0/6 {
    gen lead_bea`t' = (gap_bea == `t') if treated == 1
    replace lead_bea`t' = 0 if lead_bea`t' == .
}

reghdfe ltransfer_pc ///
    lag_bea6 lag_bea5 lag_bea4 lag_bea3 lag_bea2 ///
    lead_bea0 lead_bea1 lead_bea2 lead_bea3 ///
    lead_bea4 lead_bea5 lead_bea6, ///
    absorb(county_fe state_year) ///
    cluster(county_fe)

* Store event study coefficients
cap drop coef_bea ci_lo_bea ci_hi_bea evtime_bea
gen coef_bea   = .
gen ci_lo_bea  = .
gen ci_hi_bea  = .
gen evtime_bea = .

local vars lag_bea6 lag_bea5 lag_bea4 lag_bea3 lag_bea2 ///
           lead_bea0 lead_bea1 lead_bea2 lead_bea3 ///
           lead_bea4 lead_bea5 lead_bea6
local times -6 -5 -4 -3 -2 0 1 2 3 4 5 6
local n = 1

foreach v of local vars {
    local t : word `n' of `times'
    replace evtime_bea = `t'                      in `n'
    replace coef_bea   = _b[`v']                  in `n'
    replace ci_lo_bea  = _b[`v'] - 1.96*_se[`v'] in `n'
    replace ci_hi_bea  = _b[`v'] + 1.96*_se[`v'] in `n'
    local n = `n' + 1
}

replace evtime_bea = -1 in `n'
replace coef_bea   =  0 in `n'
replace ci_lo_bea  =  0 in `n'
replace ci_hi_bea  =  0 in `n'

gsort evtime_bea

twoway ///
    (rcap ci_lo_bea ci_hi_bea evtime_bea if evtime_bea != ., ///
        lcolor(black) lwidth(thin)) ///
    (scatter coef_bea evtime_bea if evtime_bea != ., ///
        msymbol(Oh) mcolor(black) msize(medium)), ///
    yline(0, lpattern(dot) lcolor(teal)) ///
    xline(-1, lpattern(dash) lcolor(chocolate)) ///
    ytitle("Coefficient (log per capita transfer receipts)", size(small)) ///
    xtitle("Years relative to CCUS operation start", size(small)) ///
    note("Omitted baseline: year -1. Vertical line = CCUS operation start." ///
         "County and state-by-year fixed effects. SEs clustered at county level.", ///
         size(vsmall)) ///
    legend(off) ///
    scheme(s1mono) ///
    xlabel(-6(1)6, labsize(small)) ///
    ylabel(, labsize(small)) ///
    name(bea_eventstudy, replace)
graph export "$path\results\bea_transfer_eventstudy.png", replace

display "====================================="
display "BEA placebo test complete"
display "Event study saved to bea_transfer_eventstudy.png"