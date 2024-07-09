clear all
global path "C:\phd4\CCUS\results"
cd "$path"
adopath + "$path\"
import excel coef.xlsx, sheet(covid) firstrow clear
set more off

*gen h95ci= coef +1.96*sd
*gen l95ci= coef -1.96*sd

twoway (rcap h95ci l95ci bin, color(olive) lpattern(solid) lwidth(thick)) ///
(scatter coef bin, msymbol(Oh) mcolor(dkorange) msize(large) mlwidth(thick) ///
connect(ascending) lpattern(shortdash) lcolor(olive)), yline(0, lpattern(shortdash) ///
lcolor(gs10)) ylabel(-2(.5)1, labsize(small)) title("Change in housing prices with CCUS projects nearby excluding pandemic-era", size(small)) subtitle("(with county × year fixed effects and county-level covariates)", size(small)) ytitle("Housing price", size(small)) ///
legend(size(vsmall) order(2 "Point estimates" 1 "95% CI")) ///
xtitle("Distance bin (in km)", size(small)) xscale(range(0.5(1)4.5)) ///
xlabel(1 "(0, 1]" 2 "(1, 2]" 3 "(2, 3]" 4 "(3, 4.2]", labsize(small)) scheme(s1mono) name(covid, replace)

graph save "covid.gph", replace
graph export "C:\phd4\CCUS\results\covid.png", as(png) name("covid") replace

clear all
global path "C:\phd4\CCUS\results"
cd "$path"
adopath + "$path\"
import excel coef.xlsx, sheet(new) firstrow clear
set more off

*gen h95ci= coef +1.96*sd
*gen l95ci= coef -1.96*sd

twoway (rcap h95ci l95ci bin, color(olive) lpattern(solid) lwidth(thick)) ///
(scatter coef bin, msymbol(Oh) mcolor(dkorange) msize(large) mlwidth(thick) ///
connect(ascending) lpattern(shortdash) lcolor(olive)), yline(0, lpattern(shortdash) ///
lcolor(gs10)) ylabel(-2(.5)1, labsize(small)) title("Change in housing prices with CCUS projects nearby", size(small)) subtitle("(with county × year fixed effects and county-level covariates)", size(small)) ytitle("Housing price", size(small)) ///
legend(size(vsmall) order(2 "Point estimates" 1 "95% CI")) ///
xtitle("Distance bin (in km)", size(small)) xscale(range(0.5(1)4.5)) ///
xlabel(1 "(0, 1]" 2 "(1, 2]" 3 "(2, 3]" 4 "(3, 4.2]", labsize(small)) scheme(s1mono) name(main, replace)

graph save "new_main_results.gph", replace
graph export "C:\phd4\CCUS\results\new_main_results.png", as(png) name("main") replace


clear all
global path "C:\phd4\CCUS\results"
cd "$path"
adopath + "$path\"
import excel coef.xlsx, sheet(distancebin) firstrow clear
set more off

*gen h95ci= coef +1.96*sd
*gen l95ci= coef -1.96*sd

twoway (rcap h95ci l95ci bin, color(olive) lpattern(solid) lwidth(thick)) ///
(scatter coef bin, msymbol(Oh) mcolor(dkorange) msize(large) mlwidth(thick) ///
connect(ascending) lpattern(shortdash) lcolor(olive)), yline(0, lpattern(shortdash) ///
lcolor(gs10)) ylabel(-1(1)1, labsize(small)) ytitle("Housing price (in %)", size(medmall)) ///
legend(size(vsmall) order(2 "Point estimates" 1 "95% CI")) ///
xtitle("Distance bin (in km)", size(medmall)) xscale(range(0.95(.2)4.25)) ///
xlabel(1(0.2)4.2, labsize(small)) scheme(s1mono) name(main, replace)

graph save "main_results.gph", replace
graph export "C:\phd4\CCUS\results\main_results.svg", as(svg) name("main") replace

import excel coef.xlsx, sheet(type) firstrow clear
set more off

*gen h95ci= coef +1.96*sd
*gen l95ci= coef -1.96*sd

twoway (rcap h90ci l90ci type, color(olive) lpattern(solid) lwidth(thick)) (scatter coef type, msymbol(Oh) mcolor(dkorange) msize(large) mlwidth(thick)), ///
ytitle("Housing price %", size(medsmall)) yline(0, lpattern(shortdash) lcolor(gs10)) ///
legend(size(vsmall) order(2 "Point estimates" 1 "90% CI")) ///
xtitle("Types of CCUS projects", size(vsmall)) xscale(range(.5(.5)7.5)) xlabel(1 "All CCUS" 2 "Carbon capture" 3 "Carbon storage" 4 "Retrofit CCUS" 5 "New CCUS" 6 "New Capture" 7 "New Storage", labsize(vsmall)) ///
ylabel(, labsize(small)) scheme(s1mono) name(type, replace)
graph save "type_results_90.gph", replace
graph export "C:\phd4\CCUS\results\type_results_90.svg", as(svg) name("type") replace

* cross-sectional results
clear all
global path "C:\phd4\CCUS\results"
cd "$path"
adopath + "$path\"
import excel coef.xlsx, sheet(psm) firstrow clear
set more off

*gen h95ci= coef +1.96*sd
*gen l95ci= coef -1.96*sd

twoway (rcap h90ci l90ci type, color(olive) lpattern(solid) lwidth(thick)) (scatter coef type, msymbol(Oh) mcolor(dkorange) msize(large) mlwidth(thick)), ///
ytitle("Housing price %", size(medsmall)) yline(0, lpattern(shortdash) lcolor(gs10)) ///
legend(size(vsmall) order(2 "Point estimates" 1 "90% CI")) ///
xscale(range(.5(.5)7.5)) xlabel(1 "All CCUS" 2 "Capture" 3 "Storage" 4 "Retrofitted CCUS" 5 "New-built CCUS" 6 "New + Capture" 7 "New + Storage", labsize(vsmall)) ///
ylabel(, labsize(small)) scheme(s1mono) name(psm, replace)
graph save "PSM_results_90.gph", replace
graph export "C:\phd4\CCUS\results\PSM_results_90.svg", as(svg) name("psm") replace
