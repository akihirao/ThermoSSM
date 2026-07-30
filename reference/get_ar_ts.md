# Extract autoregressive components as a time series

Extract autoregressive components as a time series

## Usage

``` r
get_ar_ts(
  res,
  component = c("sum", "first", "individual"),
  ci = FALSE,
  ci_level = 0.95,
  estimate = c("smoothed", "filtered")
)
```

## Arguments

- res:

  An object of class `"tempssm"` returned by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

- component:

  Character scalar specifying which autoregressive component(s) to
  return. The default `"sum"` returns the summed contribution of all
  autoregressive states. Use `"first"` to return the first
  autoregressive state (AR1), or `"individual"` to return all
  autoregressive states as a multivariate `ts` object.

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

A univariate `ts` object of the selected autoregressive estimate (in
degrees Celsius) when `component` is `"sum"` or `"first"`. If
`component = "individual"`, a multivariate `ts` object with columns
`ar1`, `ar2`, and so on is returned. If `ci = TRUE`, the corresponding
confidence interval columns are added. Filtered output has intentional
`NA` values during the diffuse phase.

## Details

The autoregressive component represents short-term autocorrelated
deviations from the level and seasonal structure. For AR models of order
greater than one, `"sum"` is useful for visualizing the combined AR
contribution, while `"individual"` exposes each lag separately. See
[`get_level_ts`](https://akihirao.github.io/tempssm/reference/get_level_ts.md)
for the distinction between smoothed and filtered estimates and the
handling of the diffuse phase.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata)
ar_ts <- get_ar_ts(res)
ar_first <- get_ar_ts(res, component = "first")
ar_individual <- get_ar_ts(res, component = "individual")
} # }
```
