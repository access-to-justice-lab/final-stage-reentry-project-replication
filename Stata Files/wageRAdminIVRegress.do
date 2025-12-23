***********************************
*** Import CSV Analysis Dataset ***
***********************************
import delimited using "./wageRDataAdmin.csv", clear  // 


*********************
*** Main IV Model ***
*********************
ivreg2 wage_ratio (i.expunge i.expunge#c.seq = i.treatment i.treatment#c.seq) ///
	c.seq white female age_enroll unemploy_lag ps_employed local_unemploy married dependent i.year, ///
	cluster(stid)
	
drop if seq < 0

****************************
*** Generate predictions ***
****************************
preserve

	foreach v in ps_employed local_unemploy married {
        summarize `v' if e(sample), meanonly
        replace `v' = r(mean) if missing(`v')
    }
	
	predict double xb, xb
	predict double se_xb, stdp
	
	gen double xb_ll = xb - 1.96*se_xb
	gen double xb_ul = xb + 1.96*se_xb
	
	gen double xb_trans = ln(1 + exp(xb))
	gen double xb_ll_trans = ln(1 + exp(xb_ll))
	gen double xb_ul_trans = ln(1 + exp(xb_ul))
	
	gen double outcome_hat = pe_wage_avg * xb_trans
	gen double outcome_hat_ll = pe_wage_avg * xb_ll_trans
	gen double outcome_hat_ul = pe_wage_avg * xb_ul_trans
	
	keep stid seq treatment expunge wage_ratio pe_wage_avg outcome_hat outcome_hat_ll outcome_hat_ul

	export delimited using "./wageRAdmin_predictions.csv", replace
	
restore

*********************************************
*** Extract LATE/Predicted Prob Estimates ***
*********************************************
margins, dydx(1.expunge)
matrix late = r(table)[1..6,2]'

margins, dydx(1.expunge) at(seq=(0 1 2 3 4 5 6 7))
matrix pslate = r(table)[1..6,9..16]'

margins if seq>0, at(expunge=(0 1) seq=(1 2 3 4 5 6 7)) atmeans
matrix probs = r(table)[1..6,.]'

matrix lates = late\pslate

matrix meffects = lates\probs
svmat double meffects, names(col)

keep b se pvalue ll ul
local effectnames late ///
late0 late1 late2 late3 late4 late5 late6 late7 ///
pr_1 pr_2 pr_3 pr_4 pr_5 pr_6 pr_7 pr_8 pr_9 pr_10 pr_11 pr_12 pr_13 pr_14
gen effect = ""
local i = 1
foreach eff of local effectnames {
    replace effect = "`eff'" in `i'
    local ++i
}
gen expunge = ""
gen seq = ""
replace expunge = "LATE" in 1
replace seq = "Overall" in 1

local k = 0

forvalues p = 0/7 {
	local ++k
	replace expunge = "LATE" in `=`k'+1'
	replace seq = "`p'" in `=`k'+1'
}

forvalues e = 0/1 {
	forvalues s = 1/7 {
		local ++k
		replace expunge = "`e'" in `=`k'+1'
		replace seq = "`s'" in `=`k'+1'
	}
}

**************
*** Export ***
**************
order effect expunge seq b se pvalue ll ul

export delimited using "./wageRAdmin_Meffects.csv", replace

***************************************************
*** Calculate, Store and Export Model Estimates ***
***************************************************

mat b = e(b)'
mat V = e(V)

local names: colnames e(b)
svmat double b, names(col)

keep y1
drop if y1 == .

rename y1 b
gen se = .
gen pvalue = .
gen ll = .
gen ul = .

forvalues i = 1/`=colsof(V)' {
    replace se = sqrt(V[`i',`i']) in `i'
    replace p  = 2*(1-normal(abs(b/se))) in `i'
    replace ll = b-invnormal(0.975)*se in `i'
    replace ul = b+invnormal(0.975)*se in `i'
}

gen effect = ""
local i = 1
foreach var of local names {
	replace effect = "`var'" in `i'
	local ++i
}


keep b se pvalue ll ul
drop if !inlist(_n, 2, 4, 5)

gen effect = ""
replace effect = "Expunge" in 1
replace effect = "Sequence" in 3
replace effect = "TE" in 2

order effect b se pvalue ll ul

export delimited using "./wageRAdminTE.csv", replace
