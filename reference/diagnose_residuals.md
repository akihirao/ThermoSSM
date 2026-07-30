# Residual diagnostics for tempssm models

Compute residual diagnostic statistics for a fitted tempssm model. The
output is returned as a tidy tibble suitable for meta-analysis across
many fitted models.

## Usage

``` r
diagnose_residuals(res, JB_test = FALSE, lb_lag = NULL)
```

## Arguments

- res:

  An object of class `"tempssm"` returned by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

- JB_test:

  Logical scalar; if TRUE, the Jarque–Bera test is included.

- lb_lag:

  Positive integer scalar or `NULL`. Lag used for the Ljung–Box test. If
  `NULL`, the seasonal frequency of the fitted temperature time series
  is used, with automatic truncation for very short residual series.

## Value

A `tibble` with one row containing residual diagnostic statistics,
including Ljung–Box test results and kurtosis. The `lb_lag` column gives
the lag used in the Ljung–Box test. If `JB_test = TRUE`, Jarque–Bera
test statistics are also included.

## Details

The Ljung–Box test and kurtosis are computed from finite standardized
recursive residuals. If the fitted response series contains missing
values or if non-finite residuals occur during filtering, the Ljung–Box
test is a diagnostic summary of the available finite residual sequence
rather than a strict test on the original equally spaced time index. To
inspect residual autocorrelation while preserving the original time
structure, use `get_tempssm_residuals(res)` with
[`plot_tempssm_residuals()`](https://akihirao.github.io/tempssm/reference/plot_tempssm_residuals.md).

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)

# Fit model
res <- tempssm(sst_niigata)

# Residual diagnostics (tibble output)
diag <- diagnose_residuals(res)

diag

# Use a longer Ljung--Box lag if needed.
diagnose_residuals(res, lb_lag = 24)
} # }
```
