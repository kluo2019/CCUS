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
connect(ascending) lpattern(shortdash) lcolor(olive)) (bar obs bin, yaxis(2) ytitle("Number of Properties", axis(2) size(small)) barwidth(0.3) color(olive%50)) , yline(0, ///
lpattern(shortdash) lcolor(gs10)) ylabel(-2(.5)1, labsize(small) axis(1)) ylabel(0(2500)10000, labsize(small) axis(2)) title("Change in housing prices with CCUS projects nearby", size(small)) subtitle("(with county × year fixed effects and county-level covariates)", size(small)) ytitle("Housing price", size(small)) ///
legend(size(vsmall) order(3 "Number of Properties" 2 "Point estimates" 1 "95% CI")) ///
xtitle("Distance bin (in km)", size(small)) xscale(range(0.5(1)4.5)) ///
xlabel(1 "(0, 1]" 2 "(1, 2]" 3 "(2, 3]" 4 "(3, 4.2]", labsize(small)) scheme(s1mono) name(main, replace)

graph save "new_main_results.gph", replace
graph export "C:\phd4\CCUS\results\new_main_results.png", as(png) name("main") replace

clear all
global path "C:\phd4\CCUS\results"
cd "$path"
adopath + "$path\"
import excel coef.xlsx, sheet(new400) firstrow clear
set more off

*gen h95ci= coef +1.96*sd
*gen l95ci= coef -1.96*sd

twoway (rcap h95ci l95ci bin, color(olive) lpattern(solid) lwidth(thick)) ///
(scatter coef bin, msymbol(Oh) mcolor(dkorange) msize(large) mlwidth(thick) ///
connect(ascending) lpattern(shortdash) lcolor(olive)) (bar obs bin, yaxis(2) ytitle("Number of Properties", axis(2) size(small)) barwidth(0.3) color(olive%50)) , yline(0, ///
lpattern(shortdash) lcolor(gs10)) ylabel(-2(.5)1, labsize(small) axis(1)) ylabel(0(2500)10000, labsize(small) axis(2)) title("Change in housing prices with CCUS projects nearby", size(small)) subtitle("(with county × year fixed effects and county-level covariates)", size(small)) ytitle("Housing price", size(small)) ///
legend(size(vsmall) order(3 "Number of Properties" 2 "Point estimates" 1 "95% CI")) ///
xtitle("Distance bin (in km)", size(small)) xscale(range(0.5(1)4.5)) ///
xlabel(1 "(800, 1200]" 2 "(1200, 1600]" 3 "(1600, 2000]" 4 "(2000, 2400]" 5 "(2400, 2800]" 6 "(2800, 3200]" 7 "(3200, 3600]" 8 "(3600, 4000]", labsize(vsmall)) scheme(s1mono) name(main400, replace)

graph save "main_results400.gph", replace
graph export "C:\phd4\CCUS\results\main_results400.png", as(png) name("main400") replace
