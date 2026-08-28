clear all
global path "C:\phd4\CCUS"
cd "$path\data\qcew"

tempfile qcew_panel
save `qcew_panel', replace emptyok

local years 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 ///
            2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 ///
            2020 2021

foreach yr of local years {
    display "Processing QCEW year `yr'..."
    
    import delimited "`yr'.annual.singlefile.csv", ///
        clear varnames(1) stringcols(1 2 3 4)
    
    * All filter variables now treated as strings
    * agglvl_code == "70": county-level total
    * own_code == "0": all ownerships
    * industry_code == "10": total all industries
    keep if agglvl_code == "70" & own_code == "0" & industry_code == "10"
    
    * Keep only US counties (exclude Puerto Rico state FIPS 72)
    gen statefips = substr(area_fips, 1, 2)
    keep if statefips != "72" & statefips != "US"
    drop statefips
    
    * Keep relevant variables only
    keep area_fips year annual_avg_emplvl avg_annual_pay annual_avg_estabs
    
    * Destring numeric variables
    destring annual_avg_emplvl avg_annual_pay annual_avg_estabs ///
        year, replace ignore(",")
    
    append using `qcew_panel'
    save `qcew_panel', replace
    
    display "Year `yr' processed: " _N " county observations"
}

* Load complete panel
use `qcew_panel', clear

display "Total observations: " _N
tab year

* Inflation adjust wages to 2021 dollars using BLS CPI-U
gen cpi_factor = .
replace cpi_factor = 1.563 if year == 2000
replace cpi_factor = 1.524 if year == 2001
replace cpi_factor = 1.500 if year == 2002
replace cpi_factor = 1.467 if year == 2003
replace cpi_factor = 1.432 if year == 2004
replace cpi_factor = 1.385 if year == 2005
replace cpi_factor = 1.349 if year == 2006
replace cpi_factor = 1.311 if year == 2007
replace cpi_factor = 1.263 if year == 2008
replace cpi_factor = 1.268 if year == 2009
replace cpi_factor = 1.247 if year == 2010
replace cpi_factor = 1.209 if year == 2011
replace cpi_factor = 1.188 if year == 2012
replace cpi_factor = 1.171 if year == 2013
replace cpi_factor = 1.154 if year == 2014
replace cpi_factor = 1.155 if year == 2015
replace cpi_factor = 1.139 if year == 2016
replace cpi_factor = 1.115 if year == 2017
replace cpi_factor = 1.094 if year == 2018
replace cpi_factor = 1.078 if year == 2019
replace cpi_factor = 1.075 if year == 2020
replace cpi_factor = 1.000 if year == 2021

gen avg_annual_pay_2021 = avg_annual_pay * cpi_factor

* Log transform outcomes
gen lemplvl = log(annual_avg_emplvl) if annual_avg_emplvl > 0
gen lwages   = log(avg_annual_pay_2021) if avg_annual_pay_2021 > 0
gen lestabs  = log(annual_avg_estabs) if annual_avg_estabs > 0

* Rename FIPS for merging
rename area_fips fips

* Save clean panel
save "$path\data\qcew_panel_clean.dta", replace
display "QCEW panel built successfully"
display "Observations: " _N



clear all
global path "C:\phd4\CCUS"
cd "$path"

* Load QCEW panel
use "$path\data\qcew_panel_clean.dta", clear

* Load CCUS county crosswalk
merge m:1 fips using "$path\data\ccus_county.dta", ///
    keep(master match) gen(_merge_ccus)

* Define treatment indicators
gen treated   = (_merge_ccus == 3)
gen post_qcew = 0
replace post_qcew = 1 if treated == 1 & year >= operational

* Extract state FIPS for state-year FE
gen statefips = substr(fips, 1, 2)

* Create fixed effects
egen county_fe  = group(fips)
egen state_year = group(statefips year)

* Check treatment group
tab treated
tab post_qcew if treated == 1

* ------------------------------------------------
* DID regressions
* Drop standalone treated -- absorbed by county FE
* Only include treated*post_qcew interaction
* ------------------------------------------------
eststo clear

* 1. Log total employment
eststo emp: reghdfe lemplvl post_qcew, ///
    absorb(county_fe state_year) ///
    cluster(county_fe)
display "Employment coef on post_qcew: " _b[post_qcew] ///
    " SE: " _se[post_qcew]

* 2. Log average annual wages (2021$)
eststo wage: reghdfe lwages post_qcew, ///
    absorb(county_fe state_year) ///
    cluster(county_fe)
display "Wages coef on post_qcew: " _b[post_qcew] ///
    " SE: " _se[post_qcew]

* 3. Log number of establishments
eststo estab: reghdfe lestabs post_qcew, ///
    absorb(county_fe state_year) ///
    cluster(county_fe)
display "Establishments coef on post_qcew: " _b[post_qcew] ///
    " SE: " _se[post_qcew]

* Export results table
esttab emp wage estab ///
    using "$path\results\qcew_DID_results.rtf", ///
    b se r2 star(* 0.1 ** 0.05 *** 0.01) ///
    replace b(%9.4f) se(%9.4f) ///
    mtitles("Log Employment" "Log Avg Wages" "Log Establishments") ///
    title("Table S13. Employment DID: Effect of CCUS on County Labor Markets") ///
    note("County and state-by-year fixed effects." ///
         "Standard errors clustered at county level." ///
         "post_qcew = 1 for CCUS host counties after facility opening." ///
         "* p<0.1, ** p<0.05, *** p<0.01")
* ------------------------------------------------
* Event study for employment
* ------------------------------------------------
gen gap_qcew = year - operational if treated == 1
replace gap_qcew = -6 if gap_qcew < -6 & treated == 1
replace gap_qcew =  6 if gap_qcew >  6 & treated == 1

* Create event time dummies (omit gap = -1 as baseline)
forval t = 2/6 {
    gen lag_emp`t'  = (gap_qcew == -`t') if treated == 1
    replace lag_emp`t' = 0 if lag_emp`t' == .
}
forval t = 0/6 {
    gen lead_emp`t' = (gap_qcew == `t') if treated == 1
    replace lead_emp`t' = 0 if lead_emp`t' == .
}

* Event study regression
reghdfe lemplvl ///
    lag_emp6 lag_emp5 lag_emp4 lag_emp3 lag_emp2 ///
    lead_emp0 lead_emp1 lead_emp2 lead_emp3 ///
    lead_emp4 lead_emp5 lead_emp6, ///
    absorb(county_fe state_year) ///
    cluster(county_fe)

* Store coefficients
cap drop coef_emp ci_lo_emp ci_hi_emp evtime_emp
gen coef_emp   = .
gen ci_lo_emp  = .
gen ci_hi_emp  = .
gen evtime_emp = .

local vars lag_emp6 lag_emp5 lag_emp4 lag_emp3 lag_emp2 ///
           lead_emp0 lead_emp1 lead_emp2 lead_emp3 ///
           lead_emp4 lead_emp5 lead_emp6
local times -6 -5 -4 -3 -2 0 1 2 3 4 5 6
local n = 1

foreach v of local vars {
    local t : word `n' of `times'
    replace evtime_emp = `t'                      in `n'
    replace coef_emp   = _b[`v']                  in `n'
    replace ci_lo_emp  = _b[`v'] - 1.96*_se[`v'] in `n'
    replace ci_hi_emp  = _b[`v'] + 1.96*_se[`v'] in `n'
    local n = `n' + 1
}

* Add omitted baseline (gap = -1) = 0
replace evtime_emp = -1 in `n'
replace coef_emp   =  0 in `n'
replace ci_lo_emp  =  0 in `n'
replace ci_hi_emp  =  0 in `n'

gsort evtime_emp

* Event study plot
twoway ///
    (rcap ci_lo_emp ci_hi_emp evtime_emp if evtime_emp != ., ///
        lcolor(black) lwidth(thin)) ///
    (scatter coef_emp evtime_emp if evtime_emp != ., ///
        msymbol(Oh) mcolor(black) msize(medium)), ///
    yline(0, lpattern(dot) lcolor(teal)) ///
    xline(-1, lpattern(dash) lcolor(chocolate)) ///
    ytitle("Coefficient (log county employment)", size(small)) ///
    xtitle("Years relative to CCUS operation start", size(small)) ///
    note("Omitted baseline: year -1. Vertical line = CCUS operation start." ///
         "County and state-by-year fixed effects. SEs clustered at county level.", ///
         size(vsmall)) ///
    legend(off) ///
    scheme(s1mono) ///
    xlabel(-6(1)6, labsize(small)) ///
    ylabel(, labsize(small)) ///
    name(emp_eventstudy, replace)
graph export "$path\results\qcew_employment_eventstudy.png", replace

display "====================================="
display "QCEW Employment DID complete"
display "Results in qcew_DID_results.rtf"
display "Event study in qcew_employment_eventstudy.png"
