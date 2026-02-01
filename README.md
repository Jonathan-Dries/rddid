# rddid: Difference-in-Discontinuities in Stata

`rddid` performs Difference-in-Discontinuities estimation by wrapping the `rdrobust` package. It allows for independent or common bandwidth selection and analytic or bootstrapped standard errors.

## Installation

You can install this package directly from GitHub:

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
| **bw(string)** | Specifies the bandwidth selection strategy. <br>• `common` (Default): Calculates the optimal bandwidth for the Treated group and applies it to the Control group. <br>• `independent`: Calculates separate optimal bandwidths for Treated and Control groups. |
| **h(numlist)** | Manually specify bandwidths. Accepts 1, 2, or 4 numbers. <br>• **1 Number:** `h(5)` — Sets bandwidth 5.0 for both Treated and Control (symmetric). <br>• **2 Numbers:** `h(5 10)` — Treated = 5.0 (symmetric), Control = 10.0 (symmetric). <br>• **4 Numbers:** `h(1 2 3 4)` — Treated (Left=1, Right=2), Control (Left=3, Right=4). |
| **est(string)** | Estimation type: `robust` (default), `conventional`, or `biascorrected`. <br>• `robust`: Bias-corrected point estimates with robust standard errors (Calonico et al., 2014). <br>• `conventional`: Conventional point estimates and standard errors. <br>• `biascorrected`: Bias-corrected point estimates with conventional standard errors. |
| **bootstrap** | Request bootstrapped standard errors. If omitted, analytic standard errors (assuming independence) are calculated. |
| **reps(int)** | Number of bootstrap replications (default is 50). Only used if `bootstrap` is specified. |
| **rdrobust_options** | Any other options (e.g., `vce(hc1)`, `kernel(tri)`, `covs(...)`) are passed directly to the underlying `rdrobust` command. |

## Examples

### 1. Standard Estimation

Uses a common bandwidth (optimized for the treatment group) and analytic standard errors.

```stata
rddid outcome score, group(treated)
```

### 2. Independent Bandwidths

Calculates optimal bandwidths separately for the Treated and Control groups (useful if variances differ significantly).

```stata
rddid outcome score, group(treated) bw(independent)
```

### 3. Manual Bandwidths

**Symmetric (Different by Group):** Treated (5.0), Control (10.0)

```stata
rddid outcome score, group(treated) h(5 10)
```

**Fully Asymmetric:** Treated (Left 1, Right 2), Control (Left 3, Right 4)

```stata
rddid outcome score, group(treated) h(1 2 3 4)
```

### 4. Bootstrapped Standard Errors

Necessary if your groups are not independent (e.g., panel data where the same units are in Pre and Post).

```stata
rddid outcome score, group(treated) bootstrap reps(200)
```

### 5. Customizing the Underlying Estimation

You can pass standard `rdrobust` options. For example, to use HC1 robust standard errors instead of the default NN (Nearest Neighbor):

```stata
rddid outcome score, group(treated) vce(hc1)
```

## Saved Results

The command stores the following in `e()`:

**Scalars:**

| Result | Description |
|--------|-------------|
| `e(N)` | Total sample size |
| `e(N_t)`, `e(N_c)` | Sample sizes for Treated and Control groups |
| `e(tau_t)`, `e(se_t)` | RD estimate and SE for Treated group (analytic only) |
| `e(tau_c)`, `e(se_c)` | RD estimate and SE for Control group (analytic only) |
| `e(h_t_l)`, `e(h_t_r)` | Bandwidths for Treated (Left/Right) |
| `e(h_c_l)`, `e(h_c_r)` | Bandwidths for Control (Left/Right) |

**Matrices:**

| Result | Description |
|--------|-------------|
| `e(b)` | The Difference-in-Discontinuities estimate |
| `e(V)` | The variance matrix |

## Author

**Jonathan Dries**
LUISS Guido Carli University

Email: [jvdries@luiss.it](mailto:jvdries@luiss.it)