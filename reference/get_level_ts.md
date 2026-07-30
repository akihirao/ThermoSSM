# Extract the level component as a time series

Extract the level component as a time series

## Usage

``` r
get_level_ts(
  res,
  ci = FALSE,
  ci_level = 0.95,
  estimate = c("smoothed", "filtered")
)
```

## Arguments

- res:

  An object of class `"tempssm"` returned by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

- ci:

  Logical; if TRUE, pointwise confidence intervals are returned.

- ci_level:

  Numeric confidence level between 0 and 1 (default: 0.95).

- estimate:

  Character scalar specifying the state estimate to return. Use
  `"smoothed"` (the default) for estimates conditional on all
  observations, or `"filtered"` for estimates conditional on
  observations up to each time point.

## Value

A univariate `ts` object of the selected level estimate (in degrees
Celsius). If `ci = TRUE`, a multivariate `ts` object with columns
`level`, `lwr`, and `upr` is returned. Filtered output has intentional
`NA` values during the diffuse phase.

## Details

Filtered states condition on observations up to each time point, whereas
smoothed states condition on all observations in the fitted series. In
both cases, model parameters are those estimated from the complete input
series; requesting filtered states does not refit the model
sequentially.

For filtered estimates, pointwise confidence intervals are calculated
from the filtered state covariance matrices stored in `res$kfs$Ptt`.
These intervals condition on the fitted model parameters and do not
include parameter-estimation uncertainty.

During exact diffuse initialization, KFAS reports only the non-diffuse
part of the filtered state covariance in `Ptt`, and individual state
components may not yet be sufficiently identified. Therefore filtered
point estimates and confidence bounds through `res$kfs$d` are
intentionally returned as `NA`. The first reported filtered result is at
time `res$kfs$d + 1`. Smoothed estimates are not masked.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata)
level_ts <- get_level_ts(res)
filtered_level <- get_level_ts(res, estimate = "filtered")
filtered_level_ci <- get_level_ts(
  res,
  ci = TRUE,
  estimate = "filtered"
)
} # }
```
