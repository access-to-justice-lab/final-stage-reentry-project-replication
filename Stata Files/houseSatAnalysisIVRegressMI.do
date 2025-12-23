***************************
*** Set Imputation Runs ***
***************************
local imputations = 10
forvalues filenum = 1/`imputations' {
	
	***********************************
	*** Import CSV Analysis Dataset ***
	***********************************
	import delimited "./houseSatData`filenum'.csv", clear
	
	*********************
	*** Main IV Model ***
	*********************
	ivreg2 house_sat (i.expunge i.expunge#i.seq = i.treatment i.treatment#i.seq) ///
		white female age_enroll income_lag house_num house_size unemploy_lag ps_employed local_unemploy married dependent i.seq i.year, ///
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
	
	export delimited effect b se pvalue ll ul using "./houseSat_treatment_effectsBP`filenum'.csv", replace

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

	export delimited Expungement Sequence b se pvalue ll ul using "./houseSat_group_probsBP`filenum'.csv", replace
	
	***************************************************
	*** Calculate, Store and Export Model Estimates ***
	***************************************************
	import delimited using "./houseSatData`filenum'.csv", clear  //

	ivreg2 house_sat (i.expunge i.expunge#i.seq = i.treatment i.treatment#i.seq) ///
		white female age_enroll income_lag house_num house_size unemploy_lag ps_employed local_unemploy married dependent i.seq i.year, ///
		cluster(stid)
	
	ereturn display
	
	matrix sub = r(table)'

	svmat double sub, names(col)

	keep b se pvalue ll ul

	gen effect = ""
	replace effect = "Expunge1" in 2
	replace effect = "Sequence2" in 24
	replace effect = "Sequence3" in 25
	replace effect = "Sequence4" in 26
	replace effect = "Sequence5" in 27
	replace effect = "Sequence6" in 28
	replace effect = "ES2" in 10
	replace effect = "ES3" in 11
	replace effect = "ES4" in 12
	replace effect = "ES5" in 13
	replace effect = "ES6" in 14

	order effect b se pvalue ll ul
	
	drop if effect == ""

	export delimited using "./houseSat_ME`filenum'.csv", replace

}