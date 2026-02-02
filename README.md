# rddid: Difference-in-Discontinuities in Stata

`rddid` performs Difference-in-Discontinuities estimation by wrapping the `rdrobust` package. It allows for independent or common bandwidth selection and analytic or bootstrapped standard errors.

## Installation

**Stable Version**

The latest stable version is available from SSC:
```stata
ssc install rddid, replace
```

**Development Version**

To install the latest development version directly from GitHub:

```stata
net install rddid, from("https://raw.githubusercontent.com/Jonathan-Dries/rddid/main") replace
```

## Syntax

```stata
rddid depvar runvar [if] [in], group(varname) [options]
```

- **depvar**: The outcome variable.
- **runvar**: The running variable (forcing variable).

## Options

| Option | Description |
|--------|-------------|
| **group(varname)** | Required. A binary variable indicating the group. `1` must be the Treated (or Post) group, and `0` must be the Control (or Pre) group. |
| **c(#)** | RD cutoff for the running variable (default 0). |
| **bw(string)** | Specifies the bandwidth selection strategy. <br>• `common` (Default): Calculates the optimal bandwidth for the Treated group and applies it to the Control group. <br>• `independent`: Calculates separate optimal bandwidths for Treated and Control groups. |
| **bwselect(string)** | Bandwidth selector used by `rdbwselect`. Default is `mserd`. Other options: `msetwo`, `cerrd`, `certwo`. Only relevant when `h()` is not specified. |
| **h(numlist)** | Manually specify bandwidths. Accepts 1, 2, or 4 numbers. <br>• **1 Number:** `h(5)` — Sets bandwidth 5.0 for both Treated and Control (symmetric). <br>• **2 Numbers:** `h(5 10)` — Treated = 5.0 (symmetric), Control = 10.0 (symmetric). <br>• **4 Numbers:** `h(1 2 3 4)` — Treated (Left=1, Right=2), Control (Left=3, Right=4). |
| **est(string)** | Estimation type: `robust` (default), `conventional`, or `biascorrected`. <br>• `robust`: Bias-corrected point estimates with robust standard errors (Calonico et al., 2014). <br>• `conventional`: Conventional point estimates and standard errors. <br>• `biascorrected`: Bias-corrected point estimates with conventional standard errors. |
| **bootstrap** | Request bootstrapped standard errors. If omitted, analytic standard errors (assuming independence) are calculated. |
| **reps(int)** | Number of bootstrap replications (default is 50). Only used if `bootstrap` is specified. |
| **seed(int)** | Set random-number seed before bootstrap for reproducibility. |
| **rdrobust_options** | Any other options (e.g., `vce(cluster id)`, `kernel(tri)`, `covs(...)`) are passed directly to the underlying `rdrobust` command. When `bootstrap` is specified and `vce(cluster varname)` is used, the bootstrap resamples whole clusters. |

## Examples

### 1. Standard Estimation

Uses a common bandwidth (optimized for the treatment group) and analytic standard errors.

```stata
rddid outcome score, group(treated)
```

### 2. Non-Zero Cutoff

```stata
rddid outcome score, group(treated) c(50)
```

### 3. Independent Bandwidths

Calculates optimal bandwidths separately for the Treated and Control groups (useful if variances differ significantly).

```stata
rddid outcome score, group(treated) bw(independent)
```

### 4. Manual Bandwidths

**Symmetric (Different by Group):** Treated (5.0), Control (10.0)

```stata
rddid outcome score, group(treated) h(5 10)
```

**Fully Asymmetric:** Treated (Left 1, Right 2), Control (Left 3, Right 4)

```stata
rddid outcome score, group(treated) h(1 2 3 4)
```

### 5. Bootstrapped Standard Errors

Use when your groups are not independent (e.g., panel data where the same units are in Pre and Post).

```stata
rddid outcome score, group(treated) bootstrap reps(200) seed(12345)
```

### 6. Cluster Bootstrap

When your data has cluster structure (e.g., individuals nested in geographic units):

```stata
rddid outcome score, group(treated) bootstrap reps(200) vce(cluster id)
```

### 7. CER-Optimal Bandwidth

```stata
rddid outcome score, group(treated) bwselect(cerrd)
```

### 8. Customizing the Underlying Estimation

You can pass standard `rdrobust` options. For example, to use HC1 robust standard errors instead of the default NN (Nearest Neighbor):

```stata
rddid outcome score, group(treated) vce(hc1)
```

## Postestimation: Plots

After running `rddid`, use `rddidplot` to generate side-by-side RD plots for the Treated and Control groups (requires `rdplot` from the rdrobust package):

```stata
rddid outcome score, group(treated) h(100)
rddidplot
rddidplot, title("RD Plots: Dependent Variable")
rddidplot, cilevel(99)
```

Options: `title()` for a custom title, `cilevel()` for confidence interval level (default 95, set to 0 to disable). See `help rddidplot` for details.

## Saved Results

The command stores the following in `e()`:

**Scalars:**

| Result | Description |
|--------|-------------|
| `e(N)` | Total sample size |
| `e(N_t)`, `e(N_c)` | Sample sizes for Treated and Control groups |
| `e(tau_t)`, `e(tau_c)` | RD estimates for Treated and Control groups |
| `e(se_t)`, `e(se_c)` | Standard errors for Treated and Control groups (analytic only) |
| `e(h_t_l)`, `e(h_t_r)` | Bandwidths for Treated (Left/Right) |
| `e(h_c_l)`, `e(h_c_r)` | Bandwidths for Control (Left/Right) |
| `e(cutoff)` | RD cutoff value |
| `e(bs_reps)` | Bootstrap replications requested (bootstrap only) |
| `e(bs_good)` | Successful bootstrap replications (bootstrap only) |

**Macros:**

| Result | Description |
|--------|-------------|
| `e(cmd)` | `rddid` |
| `e(estimation)` | Estimation type (`robust`, `conventional`, or `biascorrected`) |
| `e(vce)` | `bootstrap` or `analytic` |
| `e(bw_type)` | Bandwidth method (`common` or `independent`) |
| `e(depvar)` | Name of dependent variable |
| `e(runvar)` | Name of running variable |
| `e(group)` | Name of group variable |

**Matrices:**

| Result | Description |
|--------|-------------|
| `e(b)` | The Difference-in-Discontinuities estimate |
| `e(V)` | The variance matrix |
| `e(bs_dist)` | Vector of bootstrap replicate estimates (bootstrap only) |

## Author

**Jonathan Dries**
LUISS Guido Carli University

Email: [jvdries@luiss.it](mailto:jvdries@luiss.it)
