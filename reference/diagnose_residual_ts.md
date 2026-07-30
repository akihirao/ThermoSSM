# Ljung–Box diagnostics for residual time series

Compute a Ljung–Box residual autocorrelation diagnostic for a residual
vector or residual `ts` object. This function is useful after extracting
time-preserving residuals with
`get_tempssm_residuals(res, keep_time = TRUE)`.

## Usage

``` r
diagnose_residual_ts(r, lb_lag = NULL, frequency = NULL)
```

## Arguments

- r:

  Numeric vector or `ts` object of residuals. Missing values are
  allowed.

- lb_lag:

  Positive integer scalar or `NULL`. Lag used for the Ljung–Box
  diagnostic. If `NULL`, the frequency of `r` is used when `r` is a `ts`
  object; otherwise `frequency` is used.

- frequency:

  Positive numeric scalar or `NULL`. Used to choose the default `lb_lag`
  when `r` is not a `ts` object. If `NULL`, non-`ts` input uses 12.

## Value

A `tibble` with one row containing the Ljung–Box statistic, lag, degrees
of freedom, p-value, kurtosis, and residual missingness counts.

## Details

If `r` contains no missing values, the Ljung–Box statistic is equivalent
to `stats::Box.test(r, type = "Ljung-Box")`. If `r` contains missing
values, the time positions are retained and autocorrelations are
computed from available pairs at each lag. The returned statistic should
then be interpreted as a Ljung–Box-type residual autocorrelation
diagnostic rather than as the exact result of
[`stats::Box.test()`](https://rdrr.io/r/stats/box.test.html) applied to
a complete series.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata)

r <- get_tempssm_residuals(res, keep_time = TRUE)
diagnose_residual_ts(r)
diagnose_residual_ts(r, lb_lag = 24)
} # }
```
