***************************
*** Set Imputation Runs ***
***************************
local imputations = 10
forvalues filenum = 1/`imputations' {

	***********************************
	*** Import CSV Analysis Dataset ***
	***********************************
	import delimited "./homelessDataCS`filenum'.csv", clear  //

	***************************
	*** Main BiProbit Model ***
	***************************
	
	biprobit (homeless = i.expunge white age_enroll female ps_income local_unemploy ps_employed married) ///
	(expunge = treatment white age_enroll female ps_income local_unemploy ps_employed married)
			
	*********************************************
	*** Extract LATE/Predicted Prob Estimates ***
	*********************************************
	margins, dydx(1.expunge)
	matrix late = r(table)[1..6,2]'

	margins, at(expunge=(0 1))
	matrix probs = r(table)[1..6,.]'

	matrix meffects = late\probs
	svmat double meffects, names(col)

	keep b se pvalue ll ul
	local effectnames late pr_1 pr_2
	gen effect = ""
	local i = 1
	foreach eff of local effectnames {
		replace effect = "`eff'" in `i'
		local ++i
	}
	gen expunge = ""
	replace expunge = "LATE" in 1

	local k = 0

	forvalues e = 0/1 {
		local ++k
		replace expunge = "`e'" in `=`k'+1'
	}

	**************
	*** Export ***
	**************
	order effect expunge b se pvalue ll ul

	export delimited using "./homelessCS_Meffects`filenum'.csv", replace

}
