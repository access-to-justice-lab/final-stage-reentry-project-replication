***************************
*** Set Imputation Runs ***
***************************
local imputations = 10
forvalues filenum = 1/`imputations' {
	
	***********************************
	*** Import CSV Analysis Dataset ***
	***********************************
	import delimited "./movedUtyData`filenum'.csv", clear
	drop if seq == 1
		 
	*************************************
	*** Main Linear Probability Model ***
	*************************************
	ivreg2 moved_uty (i.expunge i.expunge#seq = i.treatment i.treatment#seq) ///
	white female age_enroll income_lag house_sat unemploy_lag local_unemploy ps_employed married dependent i.seq i.year, ///
		cluster(stid)

	*******************************************
	*** Calculate and Export LATE Estimates ***
	*******************************************
	* Overall LATE
	margins if seq>1, dydx(1.expunge)
	matrix late = r(table)'

	* Time-varying LATEs
	margins, dydx(1.expunge) at(seq=(2 3 4 5 6))

	matrix tetable = r(table)'
	matrix te = (late\tetable)
	svmat te, names(col)
	
	drop if se == .
	
	gen effect = .
	replace effect = 0 in 1
	replace effect = 2 in 2
	replace effect = 3 in 3
	replace effect = 4 in 4
	replace effect = 5 in 5
	replace effect = 6 in 6
	
	order effect b se pvalue ll ul
	
	export delimited effect b se pvalue ll ul using "./movedUty_treatment_effectsLPM`filenum'.csv", replace

	drop effect b se z pvalue ll ul df crit eform

	****************************************************
	*** Calculate and Export Predicted Probabilities ***
	****************************************************

	margins if seq>1, at(expunge=(0 1) seq=(2 3 4 5 6)) atmeans

	matrix ptable = r(table)'
	svmat ptable, names(col)

	keep b se pvalue ll ul
	gen Expungement = cond(_n<=5,0,1)
	gen Sequence = mod(_n-1,5)+1

	order Expungement Sequence b se pvalue ll ul

	export delimited Expungement Sequence b se pvalue ll ul using "./movedUty_group_probsLPM`filenum'.csv", replace
	
	***************************************************
	*** Calculate, Store and Export Model Estimates ***
	***************************************************
	import delimited using "./movedUtyData`filenum'.csv", clear  //
	drop if seq==1

	ivreg2 moved_uty (i.expunge i.expunge#seq = i.treatment i.treatment#seq) ///
	white female age_enroll income_lag house_sat unemploy_lag local_unemploy ps_employed married dependent i.seq i.year, ///
		cluster(stid)
		
	ereturn display
				
	matrix sub = r(table)'

	svmat double sub, names(col)

	keep b se pvalue ll ul

	gen effect = ""
	replace effect = "Expunge1" in 2
	replace effect = "Sequence3" in 4
	replace effect = "Sequence4" in 5
	replace effect = "Sequence5" in 6
	replace effect = "Sequence6" in 7
	replace effect = "ES3" in 14
	replace effect = "ES4" in 15
	replace effect = "ES5" in 16
	replace effect = "ES6" in 17

	order effect b se pvalue ll ul
	
	drop if effect == ""

	export delimited using "./movedUty_MELPM`filenum'.csv", replace

}