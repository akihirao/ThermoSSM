# Run time series cross-validation over multiple folds

Apply
[`ts_cv_run_fold()`](https://akihirao.github.io/tempssm/reference/ts_cv_run_fold.md)
to multiple train/test splits and collect the results. This function
orchestrates time series cross-validation but does not compute
evaluation metrics.

## Usage

``` r
ts_cv_run(
  folds,
  ar_order = 1,
  use_season = TRUE,
  parallel = FALSE,
  workers = NULL,
  progress = FALSE,
  marginal = TRUE
)
```

## Arguments

- folds:

  A list of fold objects returned by
  [`ts_train_test_split()`](https://akihirao.github.io/tempssm/reference/ts_train_test_split.md).

- ar_order:

  Integer scalar specifying the order of the autoregressive (AR)
  component in the error structure (e.g., 2 for AR(2), 3 for AR(3)).
  Defaults to 1. Orders from 1 to 4 are intended as the usual working
  range; larger values are allowed but trigger a warning because they
  may lead to unstable estimation.

- use_season:

  Logical scalar; should the seasonal component be considered? Defaults
  to `TRUE`.

- parallel:

  Logical scalar; if `TRUE`, folds are evaluated in parallel using the
  future.apply framework. If `FALSE`, folds are processed sequentially.
  Default is `FALSE`.

- workers:

  Integer scalar specifying the number of parallel workers to use when
  `parallel = TRUE`. If `NULL` and `parallel = TRUE`, all available
  cores returned by
  [`availableCores`](https://parallelly.futureverse.org/reference/availableCores.html)
  are used. This argument is ignored for execution when
  `parallel = FALSE`.

- progress:

  Logical scalar; if `TRUE`, a progress bar is displayed during
  execution using the progressr package. If `FALSE`, no progress bar is
  shown. Default is `FALSE`.

- marginal:

  Logical scalar specifying the likelihood used during parameter
  estimation. If `TRUE` (the default), KFAS uses the marginal
  likelihood, which adds the diffuse-initialization correction term. If
  `FALSE`, KFAS uses the diffuse likelihood. The selected setting is
  stored in the fitted object and used by default by
  [`logLik()`](https://rdrr.io/r/stats/logLik.html) and
  [`summary()`](https://rdrr.io/r/base/summary.html) methods. Set
  `marginal = FALSE` to reproduce the likelihood default used by
  versions of tempssm prior to this change.

## Value

A list of named lists. Each element corresponds to one fold and contains
the output of
[`ts_cv_run_fold()`](https://akihirao.github.io/tempssm/reference/ts_cv_run_fold.md).

## Details

The requested future execution plan is used only while folds are
evaluated. The plan that was active before calling this function is
restored on exit, including when fold evaluation raises an error.
Calling `ts_cv_run()` does not require attaching future or future.apply
with [`library()`](https://rdrr.io/r/base/library.html), but these
suggested packages must be installed when `parallel = TRUE`.

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

# 2. run cross-validation across all folds
cv_results <- ts_cv_run(
  folds,
  ar_order = 1,
  use_season = TRUE
)

# Optional parallel execution:
# cv_results <- ts_cv_run(folds, parallel = TRUE, workers = 2)

# inspect first fold result
cv_results[[1]]

# predicted vs observed for first fold
cbind(
  observed = as.numeric(cv_results[[1]]$y_test),
  predicted = as.numeric(cv_results[[1]]$y_pred)
)
} # }
```
