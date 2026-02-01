*! version 1.1.0  Jonathan Dries  01Feb2026
program define rddid, eclass
    version 14.0
    
    syntax varlist(min=2 max=2 numeric) [if] [in], ///
        Group(varname) ///
        [ h(numlist max=2) bw(string) Bootstrap Reps(integer 50) * ]

    marksample touse
    markout `touse' `group'
    
    gettoken y x : varlist
    
    if "`bw'" == "" local bw "common"

    * --- Bandwidth Selection ---
    if "`h'" != "" {
        tokenize `h'
        local h_t `1'
        local h_c `2'
        if "`h_c'" == "" local h_c `h_t'
        di as txt "Using manual bandwidths: Treated=`h_t', Control=`h_c'"
    }
    else {
        di as txt "Calculating optimal bandwidths (`bw')..."
        
        * We pass `options` here so bandwidth selection respects kernel/vce choices
        quietly rdbwselect `y' `x' if `group'==1 & `touse', `options'
        local h_t = e(h_mserd)
        
        if "`bw'" == "common" {
            local h_c = `h_t'
        }
        else if "`bw'" == "independent" {
            quietly rdbwselect `y' `x' if `group'==0 & `touse', `options'
            local h_c = e(h_mserd)
        }
        else {
             di as err "Option bw() must be 'common' or 'independent'"
             exit 198
        }
    }

    * --- Estimation ---
    if "`bootstrap'" != "" {
        di as txt "Bootstrapping `reps' replications..."
        
        * We pass `options` here so users can still set kernel() etc inside the bootstrap
        bootstrap diff=r(diff), reps(`reps') nowarn: ///
            rddid_calc `y' `x' `group' `h_t' `h_c' `touse' `"`options'"'
            
        ereturn scalar h_t = `h_t'
        ereturn scalar h_c = `h_c'
        ereturn local bw_type "`bw'"
        ereturn local vce "bootstrap"
        ereturn local cmd "rddid"
    }
    else {
        * --- Analytic SEs ---
        * Here `options` contains whatever the user typed (e.g., vce(hc1), kernel(uniform))
        * It flows directly to rdrobust.
        
        quietly rdrobust `y' `x' if `group' == 1 & `touse', h(`h_t') `options'
        local b_t = e(tau_cl)
        local se_t = e(se_tau_cl)
        local N_t = e(N)
        
        quietly rdrobust `y' `x' if `group' == 0 & `touse', h(`h_c') `options'
        local b_c = e(tau_cl)
        local se_c = e(se_tau_cl)
        local N_c = e(N)
        
        local diff = `b_t' - `b_c'
        local se_diff = sqrt(`se_t'^2 + `se_c'^2)
        local z = `diff' / `se_diff'
        local p = 2 * (1 - normal(abs(`z')))
        
        di _n as txt "Diff-in-Disc Results"
        di as txt "{hline 46}"
        di as txt "Bandwidth (T / C):   " as res %9.3f `h_t' " / " %9.3f `h_c'
        di as txt "Diff-in-Disc Est:    " as res %9.4f `diff'
        di as txt "Standard Error:      " as res %9.4f `se_diff'
        di as txt "P-value:             " as res %9.4f `p'
        di as txt "{hline 46}"

        tempname b V
        matrix `b' = (`diff')
        matrix `V' = (`se_diff'^2)
        matrix colnames `b' = diff
        matrix colnames `V' = diff
        
        ereturn post `b' `V', esample(`touse')
        ereturn scalar h_t = `h_t'
        ereturn scalar h_c = `h_c'
        ereturn scalar N = `N_t' + `N_c'
        ereturn local cmd "rddid"
    }
end

* --- Helper Program ---
program define rddid_calc, rclass
    args y x group h_t h_c touse opts
    
    * Treated
    capture rdrobust `y' `x' if `group'==1 & `touse', h(`h_t') `opts'
    if _rc != 0 return scalar diff = . 
    local b_t = e(tau_cl)
    
    * Control
    capture rdrobust `y' `x' if `group'==0 & `touse', h(`h_c') `opts'
    if _rc != 0 return scalar diff = .
    local b_c = e(tau_cl)
    
    return scalar diff = `b_t' - `b_c'
end