# Trim forecast intervals by maximum interval width

Trims forecast or prediction intervals to the longest leading forecast
horizon for which the interval width remains within a user-specified
threshold.

## Usage

``` r
trim_prediction_intervals(pred, max_width)
```

## Arguments

- pred:

  A matrix-like object, data frame, or multivariate `ts` object
  containing prediction interval columns named `"lwr"` and `"upr"`. This
  matches the object returned by
  `stats::predict(..., interval = "prediction")` for the KFAS model used
  by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

- max_width:

  Numeric scalar giving the maximum permitted interval width, calculated
  as `upr - lwr`.

## Value

An object of the same basic class as `pred`, truncated to the longest
leading sequence whose prediction interval width is less than or equal
to `max_width`. If `pred` is a `ts` object and at least one row is
retained, the returned object preserves its time scale. A zero-row
result is returned as a matrix because base R does not support
zero-length `ts` objects.

## Details

Forecast uncertainty in state-space models generally increases with
forecast horizon because future observations depend on accumulated state
and observation uncertainty. This helper provides a simple
post-processing rule: retain forecasts only until their prediction
interval width exceeds a user-defined error margin. It does not modify
forecast means, lower bounds, or upper bounds; it only truncates the
returned forecast horizon.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata, na_action = "allow")
pred <- stats::predict(
  res$model,
  n.ahead = 24,
  interval = "prediction",
  level = 0.95
)

trim_prediction_intervals(pred, max_width = 4)
} # }
```
