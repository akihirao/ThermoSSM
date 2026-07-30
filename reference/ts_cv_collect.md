# Collect time series cross-validation results into a tibble

Combine cross-validation results and evaluation metrics into a tidy
`tibble` with one row per fold.

## Usage

``` r
ts_cv_collect(cv_results, metrics)
```

## Arguments

- cv_results:

  A list of results returned by
  [`ts_cv_run()`](https://akihirao.github.io/tempssm/reference/ts_cv_run.md).

- metrics:

  A list of evaluation metrics returned by
  [`compute_cv_metrics()`](https://akihirao.github.io/tempssm/reference/compute_cv_metrics.md),
  corresponding to `cv_results`.

## Value

A `tibble` where each row represents a cross-validation fold, with
columns `fold`, `converged`, `MAE`, `MASE_naive`, and `MASE_seasonal`.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_yamaguchi)

# 1. create train/test splits
folds <- ts_train_test_split(
  temp_data = sst_yamaguchi,
  initial   = 60,
  horizon   = 12,
  step      = 12
)

# 2. run cross-validation over all folds
cv_results <- ts_cv_run(folds)

# 3. compute metrics for each fold
metrics <- lapply(cv_results, compute_cv_metrics)

# 4. collect results into a tidy tibble
cv_summary <- ts_cv_collect(cv_results, metrics)

cv_summary
} # }
```
