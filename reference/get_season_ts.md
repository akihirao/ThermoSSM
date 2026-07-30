# Extract the seasonal component as a time series

Extract the seasonal component as a time series

## Usage

``` r
get_season_ts(
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

A univariate `ts` object of the selected seasonal estimate (in degrees
Celsius). If `ci = TRUE`, a multivariate `ts` object with columns
`season`, `lwr`, and `upr` is returned. Filtered output has intentional
`NA` values during the diffuse phase.

## Details

The seasonal component represents recurrent intra-year variability
captured by seasonal dummy state components in the state space model.
See
[`get_level_ts`](https://akihirao.github.io/tempssm/reference/get_level_ts.md)
for the distinction between smoothed and filtered estimates and the
handling of the diffuse phase.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata)
season_ts <- get_season_ts(res)
} # }
```
