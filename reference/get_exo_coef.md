# Extract coefficients of exogenous variables with confidence intervals

Extracts estimated regression coefficients for exogenous variable(s)
included in a `tempssm` model, together with confidence intervals based
on Kalman smoothing results.

## Usage

``` r
get_exo_coef(res, ci_level = 0.95)
```

## Arguments

- res:

  An object of class `"tempssm"` returned by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

- ci_level:

  Numeric confidence level between 0 and 1 (default: 0.95).

## Value

A `data.frame` with the following columns:

- Variable:

  Name of the exogenous variable

- Coefficient:

  Estimated regression coefficient

- lwr:

  Lower bound of the confidence interval

- upr:

  Upper bound of the confidence interval

Returns `NULL` if the model did not converge or no exogenous variables
are included.

## Details

If the fitted model did not converge or does not include exogenous
variables, the function returns `NULL`.

Exogenous coefficients are represented as static regression states. The
returned estimates and confidence limits are taken from the first
smoothed time point because these states are constant over time.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
data(pdo)
common_data <- ts.intersect(sst_niigata, pdo)
temp_data <- common_data[, "sst_niigata"]
exo_data <- common_data[, "pdo", drop = FALSE]
res <- tempssm(temp_data = temp_data, exo_data = exo_data)
get_exo_coef(res)
} # }
```
