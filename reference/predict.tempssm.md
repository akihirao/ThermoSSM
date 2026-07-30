# Forecast from a fitted tempssm model

Produces forecasts after the end of the observed sample from a fitted
`tempssm` model. By default, the method returns the forecast for the
next single time point.

## Usage

``` r
# S3 method for class 'tempssm'
predict(
  object,
  n.ahead = 1L,
  new_exo_data = NULL,
  exo_strategy = c("provided", "last"),
  interval = c("none", "confidence", "prediction"),
  level = 0.95,
  ...
)
```

## Arguments

- object:

  A fitted object of class `"tempssm"` returned by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

- n.ahead:

  Positive integer giving the forecast horizon. The default is one time
  point. For a model with exogenous variables, the horizon is inferred
  from `new_exo_data` when `n.ahead` is omitted.

- new_exo_data:

  Optional future exogenous variables as a univariate or multivariate
  `ts` object. It is required for a model fitted with exogenous
  variables and must continue directly after the fitted response series,
  with matching frequency, column names, and column order.

- exo_strategy:

  Character scalar specifying how future exogenous values are obtained.
  The default, `"provided"`, requires `new_exo_data` for an exogenous
  model. `"last"` enables a one-step persistence forecast by carrying
  each exogenous variable's final observed value forward.

- interval:

  Character scalar specifying the interval type. One of `"none"`,
  `"confidence"`, or `"prediction"`.

- level:

  Numeric scalar between 0 and 1 specifying the confidence level used
  when `interval` is not `"none"`.

- ...:

  Additional arguments passed to the KFAS prediction method via
  [`stats::predict()`](https://rdrr.io/r/stats/predict.html).

## Value

For `interval = "none"`, a univariate `ts` object of point forecasts.
When intervals are requested, a multivariate `ts` object with columns
`fit`, `lwr`, and `upr`.

## Details

Forecasts begin at the first regular time point after the end of
`object$temp_data`. They account for uncertainty in the estimated state
conditional on the fitted model parameters, but not parameter estimation
uncertainty.

When `interval = "confidence"`, the returned lower and upper bounds
describe uncertainty in the predicted mean response. When
`interval = "prediction"`, the bounds describe uncertainty in a future
observation and therefore also include observation error. Prediction
intervals are usually wider than confidence intervals. The interval
level is controlled by `level` and defaults to 0.95.

For a model fitted with exogenous variables, `new_exo_data` must provide
known or assumed future covariate values. Missing or non-finite future
values are rejected; the method never assumes zero-valued covariates. As
a simplified alternative for one-step forecasting,
`exo_strategy = "last"` implements last observation carried forward.
This is a persistence assumption, not a forecast model for the
covariates. Resulting intervals are conditional on those fixed exogenous
values and do not include uncertainty about their future evolution.

This method produces forecasts beyond the end of the sample. It does not
return in-sample one-step-ahead predictions.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata)

# Forecast the next time point
predict(res)

# Forecast the next 12 time points with prediction intervals
predict(res, n.ahead = 12, interval = "prediction", level = 0.95)

# Models with exogenous variables require future covariate values
exo <- ts(
  matrix(seq_along(sst_niigata), ncol = 1),
  start = start(sst_niigata),
  frequency = frequency(sst_niigata)
)
colnames(exo) <- "index"
res_exo <- tempssm(sst_niigata, exo_data = exo)
exo_next <- ts(
  matrix(NROW(exo) + 1, ncol = 1, dimnames = list(NULL, "index")),
  start = tsp(exo)[2] + 1 / frequency(exo),
  frequency = frequency(exo)
)
predict(res_exo, new_exo_data = exo_next)

# Simplified one-step forecast under a persistence assumption
predict(res_exo, exo_strategy = "last")
} # }
```
