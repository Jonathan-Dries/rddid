*==============================================================================*
* make_rddid_example.do
* Generates rddid_example.dta — bundled example dataset for the rddid package
*
* Context: Synthetic rural electrification policy study.
*   Two neighboring regions (A and B) each have an internal electrification
*   zone boundary. Region A implemented a rural electrification program inside
*   its zone; Region B did not. DiDC isolates the causal effect of the program
*   by comparing the discontinuity in household welfare at the zone boundary
*   across the two regions.
*
* Data generating process:
*   N = 10,000 observations, 200 village clusters of 50 households each.
*   Clusters 1-100   → Region A (group = 1, treated)
*   Clusters 101-200 → Region B (group = 0, control)
*
*   distance ~ Uniform(-150, 150) km from the electrification zone boundary
*             (negative = outside the zone, positive = inside the zone)
*
*   Outcome model:
*     Region A: income_idx = 5 + 2.0*(distance≥0) + 0.015*distance
*                              - 0.8*female + 0.03*age + u_c + ε
*     Region B: income_idx = 4 + 0.5*(distance≥0) + 0.015*distance
*                              - 0.8*female + 0.03*age + u_c + ε
*
*     where u_c ~ N(0, 0.2) is a cluster-level random effect (ICC ≈ 1.7%)
*           ε   ~ N(0, 1.5) is individual-level noise
*
* True parameters:
*   tau_treated = 2.0   (discontinuity in Region A at zone boundary)
*   tau_control = 0.5   (discontinuity in Region B at zone boundary)
*   True DiDC   = 1.5   (causal effect of the electrification program)
*==============================================================================*

* Output directory — update if the package root moves
local pkg_dir "/Users/jdries/Documents/Research Projects/rddid"

clear
set seed 12345
set obs 10000

* Village cluster identifier (50 households per cluster, 200 clusters total)
gen clusterid = ceil(_n / 50)
label variable clusterid "Village cluster identifier"

* Group assignment at cluster level
* Clusters 1-100   = Region A (treated), clusters 101-200 = Region B (control)
gen group = (clusterid <= 100)
label variable group "Region (1 = Region A / treated, 0 = Region B / control)"
label define group_lbl 0 "Region B (control)" 1 "Region A (treated)"
label values group group_lbl

* Running variable: distance from electrification zone boundary (km)
* Uniform(-150, 150): negative = outside the zone, positive = inside the zone
gen distance = runiform() * 300 - 150
label variable distance "Distance from electrification zone boundary (km)"

* Covariates
gen female = rbinomial(1, 0.5)
label variable female "Female respondent (1 = yes)"

gen age = round(18 + runiform() * 42)
label variable age "Respondent age (years)"

* Cluster-level random effect: one draw per cluster, broadcast to all members
sort clusterid
by clusterid: gen cluster_re = rnormal(0, 0.2) if _n == 1
by clusterid: replace cluster_re = cluster_re[1]

* Individual-level noise
gen epsilon = rnormal(0, 1.5)

* Outcome: household income index
* Region A (group=1): discontinuity tau_treated = 2.0
gen income_idx = 5 + 2.0 * (distance >= 0) + 0.015 * distance ///
    - 0.8 * female + 0.03 * age + cluster_re + epsilon if group == 1

* Region B (group=0): discontinuity tau_control = 0.5
replace income_idx = 4 + 0.5 * (distance >= 0) + 0.015 * distance ///
    - 0.8 * female + 0.03 * age + cluster_re + epsilon if group == 0

label variable income_idx "Household income index"

drop cluster_re epsilon

* Dataset label
label data "rddid example: rural electrification study (N=10000, true DiDC=1.5)"

* Save
save "`pkg_dir'/rddid_example.dta", replace

* Verify: tau_treated ≈ 2.0, tau_control ≈ 0.5, DiDC ≈ 1.5
rddid income_idx distance, group(group) est(conventional) ///
    vce(cluster clusterid) covs(female age)
