***********************************
*** Import CSV Analysis Dataset ***
***********************************
import delimited "./recDataCSAdmin.csv", clear  //

biprobit (recid = i.expunge white female age_enroll income unemployed_q ps_employed local_unemploy) 	///
			(expunge = treatment white female age_enroll income unemployed_q ps_employed local_unemploy)
			
*********************************************
*** Extract LATE/Predicted Prob Estimates ***
*********************************************
margins, dydx(1.expunge)
matrix late = r(table)[1..6,2]'

margins, at(expunge=(0 1)) atmeans 
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

export delimited using "./recCSAdmin_Meffects.csv", replace