*! version 1.4.1  Jonathan Dries  01Feb2026
* Bootstrap helper for rddid
program define rddid_calc, rclass
    args y x group h_t h_c touse opts est

    capture rdrobust `y' `x' if `group'==1 & `touse', h(`h_t') `opts'
    if _rc != 0 {
        return scalar diff = .
        exit
    }
    if "`est'" == "conventional" {
        local b_t = e(tau_cl)
    }
    else {
        local b_t = e(tau_bc)
    }

    capture rdrobust `y' `x' if `group'==0 & `touse', h(`h_c') `opts'
    if _rc != 0 {
        return scalar diff = .
        exit
    }
    if "`est'" == "conventional" {
        local b_c = e(tau_cl)
    }
    else {
        local b_c = e(tau_bc)
    }

    return scalar diff = `b_t' - `b_c'
end
