# Compute forecast accuracy metrics for a CV fold

Compute forecast accuracy metrics for a CV fold

## Usage

``` r
compute_cv_metrics(cv_result)
```

## Arguments

- cv_result:

  A single result returned by
  [`ts_cv_run_fold()`](https://akihirao.github.io/tempssm/reference/ts_cv_run_fold.md).

## Value

A named list of numeric accuracy metrics with components `MAE`,
`MASE_naive`, and `MASE_seasonal`.

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

# 2. run cross-validation on a single fold
res <- ts_cv_run_fold(folds[[1]])

# 3. compute evaluation metrics
metrics <- compute_cv_metrics(res)

metrics
} # }
```
