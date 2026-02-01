*! version 1.2.0  Jonathan Dries  01Feb2026
program define rddid, eclass
    version 14.0
    
    * CHANGE: Increased max h() to 4
    syntax varlist(min=2 max=2 numeric) [if] [in], ///
        Group(varname) ///
        [ h(numlist max=4) bw(string) Bootstrap Reps(integer 50) * ]

    marksample touse
    markout `touse' `group'
    
    gettoken y x : varlist
    
    if "`bw'" == "" local bw "common"

    * --- Bandwidth Selection Logic ---
    local n_h : word count `h'
    
    if `n_h' > 0 {
        * MANUAL BANDWIDTHS
        tokenize `h'
        if `n_h' == 1 {
            * h(5) -> T:5,5  C:5,5
            local h_t "`1'"
            local h_c "`1'"
            di as txt "Using manual symmetric bandwidth: `1' (Common)"
        }
        else if `n_h' == 2 {
            * h(5 10) -> T:5,5  C:10,10
            local h_t "`1'"
            local h_c "`2'"
            di as txt "Using manual symmetric bandwidths: Treated=`1', Control=`2'"
        }
        else if `n_h' == 4 {
            * h(1 2 3 4) -> T:1,2  C:3,4
            local h_t "`1' `2'"
            local h_c "`3' `4'"
            di as txt "Using manual asymmetric bandwidths:"
            di as txt "  Treated: Left=`1', Right=`2'"
            di as txt "  Control: Left=`3', Right=`4'"
        }
        else {
            di as err "Option h() requires 1, 2, or 4 numbers."
            exit 198
        }
    }
    else {
        * AUTOMATIC OPTIMAL BANDWIDTHS
        di as txt "Calculating optimal bandwidths (`bw')..."
        
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
        
        * NOTE: We wrap h_t and h_c in quotes to handle cases like "5 10" safely
        bootstrap diff=r(diff), reps(`reps') nowarn: ///
            rddid_calc `y' `x' `group' "`h_t'" "`h_c'" `touse' `"`options'"'
            
        ereturn local bw_type "`bw'"
        ereturn local vce "bootstrap"
        
        * Helper to post bandwidth scalars (handles 1 or 2 numbers)
        _rddid_post_bw, ht(`h_t') hc(`h_c')
        
        ereturn local cmd "rddid"
    }
    else {
        * --- Analytic SEs ---
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
        di as txt "Treated Bandwidth (L/R): " as res "`h_t'"
        di as txt "Control Bandwidth (L/R): " as res "`h_c'"
        di as txt "{hline 46}"
        di as txt "Diff-in-Disc Est:        " as res %9.4f `diff'
        di as txt "Standard Error:          " as res %9.4f `se_diff'
        di as txt "P-value:                 " as res %9.4f `p'
        di as txt "{hline 46}"

        tempname b V
        matrix `b' = (`diff')
        matrix `V' = (`se_diff'^2)
        matrix colnames `b' = diff
        matrix colnames `V' = diff
        
        ereturn post `b' `V', esample(`touse')
        
        _rddid_post_bw, ht(`h_t') hc(`h_c')
        
        ereturn scalar N = `N_t' + `N_c'
        ereturn local cmd "rddid"
    }
end

* --- Helper: Calculation Program ---
program define rddid_calc, rclass
    args y x group h_t h_c touse opts
    
    capture rdrobust `y' `x' if `group'==1 & `touse', h(`h_t') `opts'
    if _rc != 0 return scalar diff = . 
    local b_t = e(tau_cl)
    
    capture rdrobust `y' `x' if `group'==0 & `touse', h(`h_c') `opts'
    if _rc != 0 return scalar diff = .
    local b_c = e(tau_cl)
    
    return scalar diff = `b_t' - `b_c'
end

* --- Helper: Post Bandwidths to e() ---
program define _rddid_post_bw, eclass
    syntax, ht(string) hc(string)
    
    * Parse Treated
    local n_ht : word count `ht'
    tokenize `ht'
    if `n_ht' == 1 {
        ereturn scalar h_t_l = `1'
        ereturn scalar h_t_r = `1'
    }
    else {
        ereturn scalar h_t_l = `1'
        ereturn scalar h_t_r = `2'
    }

    * Parse Control
    local n_hc : word count `hc'
    tokenize `hc'
    if `n_hc' == 1 {
        ereturn scalar h_c_l = `1'
        ereturn scalar h_c_r = `1'
    }
    else {
        ereturn scalar h_c_l = `1'
        ereturn scalar h_c_r = `2'
    }
end