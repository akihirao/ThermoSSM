# Compare time-series cross-validation results across models

Summarize model-level performance from collected time-series
cross-validation results. The function is intended for comparing
multiple candidate `tempssm` model specifications using the same folds.

## Usage

``` r
compare_ts_cv(cv_tables)
```

## Arguments

- cv_tables:

  A named list of
  [`ts_cv_collect()`](https://akihirao.github.io/tempssm/reference/ts_cv_collect.md)
  outputs. Each table must contain the same fold IDs in the same order
  and columns `fold`, `converged`, `MAE`, `MASE_naive`, and
  `MASE_seasonal`. List names are used as model labels.

## Value

A `tibble` with one row per model and columns `model`, `n_folds`,
`converged_n`, `converged_rate`, `mean_MAE`, `mean_MASE_naive`, and
`mean_MASE_seasonal`.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_yamaguchi)

folds <- ts_train_test_split(sst_yamaguchi, initial = 60)
cv_ar1 <- ts_cv_run(folds, ar_order = 1)
cv_ar2 <- ts_cv_run(folds, ar_order = 2)

tab_ar1 <- ts_cv_collect(cv_ar1, lapply(cv_ar1, compute_cv_metrics))
tab_ar2 <- ts_cv_collect(cv_ar2, lapply(cv_ar2, compute_cv_metrics))

compare_ts_cv(list(AR1 = tab_ar1, AR2 = tab_ar2))
} # }
```
