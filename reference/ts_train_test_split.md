# Generate rolling train/test splits for time series

This function generates training and test splits for time series
cross-validation using a rolling-origin (walk-forward) scheme. It is
intended for model evaluation, including comparison between simple
linear models and state space models.

## Usage

``` r
ts_train_test_split(
  temp_data,
  exo_data = NULL,
  initial = 60,
  horizon = 12,
  step = 12,
  fixed_window = FALSE,
  allow_partial = FALSE,
  na_action = c("inform", "warn", "error", "allow")
)
```

## Arguments

- temp_data:

  A temperature time series of class `ts`. The `ts` object must be
  univariate. The series can have any integer frequency of 2 or higher.
  For example, a frequency of 12 represents a monthly `ts` object.

- exo_data:

  A data set of exogenous variable(s) of class `ts`. The series may have
  any integer frequency of 2 or higher, but it must be the same as that
  of `temp_data`. It must also have the same number of observations and
  the same time index as `temp_data`. The default is `NULL` when fitting
  a model without exogenous variables.

- initial:

  Integer scalar giving the initial length of the training set (number
  of observations). Default is 60.

- horizon:

  Integer scalar giving the forecast horizon for the test set (number of
  observations). Default is 12.

- step:

  Integer scalar giving the step size between successive folds (number
  of observations). Default is 12.

- fixed_window:

  Logical scalar; if `TRUE`, a fixed-length training window of size
  `initial` is used. If `FALSE`, an expanding training window is used.
  Default is `FALSE`.

- allow_partial:

  Logical scalar; if `TRUE`, include the final fold even if the
  remaining test period is shorter than `horizon`. Default is `FALSE`.

- na_action:

  Character scalar specifying how explicit missing observations in the
  input temperature series should be handled. Use `"inform"` to issue an
  informational message and proceed, `"warn"` to issue a warning and
  proceed, `"error"` to stop, or `"allow"` to proceed silently. The
  default is `"inform"`. Missing values in `exo_data` are always
  rejected; exogenous covariates must be completed before model fitting.

## Value

A list of folds. Each element is a named list containing:

- fold:

  Integer fold index.

- train_ts:

  Training time series of class `ts`.

- test_ts:

  Test time series of class `ts`.

- exo_train_ts:

  Training exogenous `ts`, or `NULL`.

- exo_test_ts:

  Test exogenous `ts`, or `NULL`.

- train_idx:

  Integer vector giving the training index range.

- test_idx:

  Integer vector giving the test index range.

- train_range:

  Numeric vector giving the training time range.

- test_range:

  Numeric vector giving the test time range.

## Examples

``` r
if (FALSE) { # \dontrun{
data(yamaguchi_sst) # monthly SST near Yamaguchi Prefecture
data(pdo) # Pacific Decadal Oscillation

# synchronize series
common_ts <- ts.intersect(yamaguchi_sst, pdo)
temp_ts <- common_ts[, "yamaguchi_sst"]
pdo_ts <- common_ts[, "pdo"]
pdo_ts <- set_ts_name(pdo_ts, label = "PDO") # label

folds <- ts_train_test_split(
  temp_data = temp_ts,
  exo_data  = pdo_ts,
  initial   = 60,
  horizon   = 12,
  step      = 12
)

# inspect first fold
folds[[1]]$train_ts
folds[[1]]$test_ts
} # }
```
