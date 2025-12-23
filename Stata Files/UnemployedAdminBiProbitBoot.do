***********************************
*** Import CSV Analysis Dataset ***
***********************************
import delimited using "./unemployedDataAdmin.csv", clear  // 

********************************
*** Define Bootstrap Program ***
********************************
capture program drop mybiprobitmargeff
program define mybiprobitmargeff, rclass

	***************************
	*** Main Biprobit Model ***
	***************************
    biprobit (unemployed = i.expunge##c.seq white female age_enroll unemploy_lag ps_employed local_unemploy dependent i.year) ///
            (expunge = treatment white female age_enroll unemploy_lag ps_employed local_unemploy dependent c.seq i.year),  ///
            vce(cluster stid)
	
	*********************************************
	*** Extract LATE/Predicted Prob Estimates ***
	*********************************************
    margins, dydx(1.expunge)
    return scalar late = r(b)[1,2]
	
	margins, dydx(1.expunge) at(seq=(1 2 3 4 5 6 7))
	matrix m1 = r(b)
	local k1 = colsof(m1)
	forvalues j1 = 8/`k1' {
		local l1 = `j1' - 7
		return scalar late_`l1' = m1[1,`j1']
	}
    
	margins if seq >= 1, at(expunge=(0 1) seq=(1 2 3 4 5 6 7)) atmeans
    matrix m2 = r(b)
    local k2 = colsof(m2)
    forvalues j2 = 1/`k2' {
        return scalar pr_`j2' = m2[1,`j2']
    }

end

*****************************
*** Run Bootstrap Program ***
*****************************
mybiprobitmargeff
return list

bootstrap late=r(late) ///
		  late_1=r(late_1) late_2=r(late_2) late_3=r(late_3) late_4=r(late_4) late_5=r(late_5) late_6=r(late_6) late_y=r(late_7) ///
          pr_1=r(pr_1) pr_2=r(pr_2) pr_3=r(pr_3) pr_4=r(pr_4) pr_5=r(pr_5) pr_6=r(pr_6) pr_7=r(pr_7) ///
		  pr_8=r(pr_8) pr_9=r(pr_9) pr_10=r(pr_10) pr_11=r(pr_11) pr_12=r(pr_12) pr_13=r(pr_13) pr_14=r(pr_14), ///
          cluster(stid) reps(500) nowarn: mybiprobitmargeff

**********************************
*** Collect and Format Outputs ***
**********************************
mat boot = r(table)'
svmat double boot, names(col)

local effectnames late ///
				  late_1 late_2 late_3 late_4 late_5 late_6 late_7 ///
				  pr_1 pr_2 pr_3 pr_4 pr_5 pr_6 pr_7 ///
				  pr_8 pr_9 pr_10 pr_11 pr_12 pr_13 pr_14
gen effect = ""
local i = 1
foreach eff of local effectnames {
    replace effect = "`eff'" in `i'
    local ++i
}

**************************
*** Calculate p-values ***
**************************
keep effect b se ll ul

gen pvalue = 2 * (1 - normal(abs(b/se)))

********************************************
*** Generate Expunge and Sequence Values ***
********************************************
gen expunge = ""
gen seq = ""

replace expunge = "LATE" in 1
replace seq = "Overall" in 1

local k = 0

forvalues p = 1/7 {
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

export delimited using "./unemployedAdmin_bootstrapped_effects.csv", replace

***************************************************
*** Calculate, Store and Export Model Estimates ***
***************************************************
import delimited using "./unemployedDataAdmin.csv", clear  // 

biprobit (unemployed = i.expunge##c.seq white female age_enroll ps_employed local_unemploy dependent i.year) ///
            (expunge = treatment white female age_enroll ps_employed local_unemploy dependent c.seq i.year),  ///
            noconstant vce(cluster stid)
			
matrix sub = r(table)[1..6,2..5]'

svmat double sub, names(col)

keep b se pvalue ll ul
drop in 3

gen effect = ""
replace effect = "Expunge" in 1
replace effect = "Sequence" in 2
replace effect = "TE" in 3

order effect b se pvalue ll ul

export delimited using "./unemployedAdminTE.csv", replace
			