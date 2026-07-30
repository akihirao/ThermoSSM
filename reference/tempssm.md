# tempssm: State space models for temperature time series

tempssm provides tools for analyzing temperature time series (e.g., air
temperature and sea surface temperature) using linear Gaussian
state-space models.

This function estimates a linear Gaussian state-space model (SSM) for
regular temperature time series using Kalman filtering and smoothing.
The input must be a univariate `ts` object with an integer seasonal
frequency greater than 1.

## Usage

``` r
tempssm(
  temp_data,
  exo_data = NULL,
  ar_order = 1,
  inits = NULL,
  maxit = NULL,
  reltol = NULL,
  use_season = TRUE,
  na_action = c("inform", "warn", "error", "allow"),
  marginal = TRUE
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

- ar_order:

  Integer scalar specifying the order of the autoregressive (AR)
  component in the error structure (e.g., 2 for AR(2), 3 for AR(3)).
  Defaults to 1. Orders from 1 to 4 are intended as the usual working
  range; larger values are allowed but trigger a warning because they
  may lead to unstable estimation.

- inits:

  Optional numeric vector of initial parameter values. If `NULL`,
  default values are used. When supplied, its length must match the
  number of variance and autoregressive parameters implied by `ar_order`
  and `use_season`.

- maxit:

  Optional numeric scalar giving the maximum number of iterations. If
  `NULL`, default value of 5000 is used.

- reltol:

  Optional numeric scalar giving the relative convergence tolerance. If
  `NULL`, default value of 1e-16 is used.

- use_season:

  Logical scalar; should the seasonal component be considered? Defaults
  to `TRUE`.

- na_action:

  Character scalar specifying how explicit missing observations in the
  input temperature series should be handled. Use `"inform"` to issue an
  informational message and proceed, `"warn"` to issue a warning and
  proceed, `"error"` to stop, or `"allow"` to proceed silently. The
  default is `"inform"`. Missing values in `exo_data` are always
  rejected; exogenous covariates must be completed before model fitting.

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

An object of class `"tempssm"`, a named list containing:

- model:

  Fitted `SSModel` object, or `NULL` if fitting raised an error.

- fit:

  Results from `fitSSM`, or `NULL` if fitting raised an error.

- kfs:

  Kalman filtering and smoothing results from `KFS`, or `NULL` if
  fitting raised an error.

- temp_data:

  Temperature time series used for estimation.

- exogenous_data:

  Time series of exogenous variables used for estimation, or `NULL`.

- ar_order:

  Order of the autoregressive component.

- use_season:

  Logical; whether to include a seasonal component.

- marginal:

  Logical; whether marginal likelihood was used during parameter
  estimation.

- call:

  Matched function call.

- converged:

  Logical; whether the second optimization stage converged.

- state_map:

  List describing exogenous and complete state names.

## Details

The package is designed for long-term environmental monitoring data and
focuses on trend extraction, seasonal components, and uncertainty
estimation under a unified state-space modeling framework.

Typical applications include:

- Analysis of long-term air temperature records

- Sea surface temperature trend estimation

- Decomposition into level, trend, and seasonal components

The implementation is based on linear Gaussian state-space models and
makes use of Kalman filtering and smoothing.

Main parts of the implementation were adapted from the supplementary
code provided in Baba et al. (2024), available on GitHub:
https://github.com/logics-of-blue/sea-temperature-trend-jogashima

The observed temperature series is not required to be stationary in
mean. Long-term mean changes are represented by latent level and drift
components, and recurring within-cycle mean variation is represented by
the seasonal component when `use_season = TRUE`. Stationarity
constraints are applied to the autoregressive component, whose
coefficients are transformed with
[`KFAS::artransform()`](https://rdrr.io/pkg/KFAS/man/artransform.html)
during model fitting.

Observation and state disturbances are assumed Gaussian with positive,
time-invariant variances. The model does not currently include
time-varying volatility or automatic stationarity tests for the observed
input series.

Invalid arguments and model inputs raise an error before fitting begins.
Errors raised by the KFAS fitting or filtering backend issue a warning
and return a `"tempssm"` object with `converged = FALSE` and `NULL`
model, fit, and filtering components. Errors in model construction,
state-name assignment, or result construction are propagated rather than
converted to a failed fit. If optimization completes without
convergence, the available fitted components are retained and
`converged` is set to `FALSE`.

## Life Cycle and Development Status

`tempssm` is under active development. The current design focuses on
temperature time series represented as base R `ts` objects with integer
seasonal frequencies greater than 1. The examples and validation
primarily use monthly data, but the core modelling path preserves the
input frequency. This scope is intentional: it keeps model fitting and
cross-validation feasible on typical personal computing environments
used by R users.

The package aims to stabilize this workflow before expanding the
supported data structures. Future versions may consider direct modelling
support for daily or irregular time series, such as `zoo` objects, but
such extensions are not part of the current design goals and would
require careful consideration of computational costs, input validation,
and documentation.

## Statistical Terminology

In this package, a linear Gaussian state-space model refers to a model
in which observed temperature values are represented as noisy
observations of unobserved latent states, with Gaussian observation and
state disturbances. The latent states may include a level component, a
seasonal component, an autoregressive component, and optional exogenous
effects.

The level component represents the slowly varying baseline temperature.
The seasonal component represents recurring within-year variation. The
autoregressive component represents short-term serial dependence not
captured by the level or seasonal components. The AR order is the number
of lagged autoregressive terms included in this component.

Exogenous variables are external time series supplied by the user and
aligned with the temperature series. They are included as regression
effects in the state-space model. Kalman filtering refers to sequential
estimation of the latent state using observations up to each time point,
whereas Kalman smoothing refers to estimation of latent states using the
full observed time series.

Residual diagnostics in this package use standardized recursive
residuals extracted from the fitted state-space model. Time-series
cross-validation refers to rolling-origin evaluation, where models are
fitted on earlier observations and evaluated on later held-out
observations. MAE denotes mean absolute error, and MASE denotes mean
absolute scaled error.

## Stationarity and Moment Assumptions

`tempssm` does not require the observed temperature series itself to be
stationary in mean. Long-term changes in the first-order moment are
treated as part of the latent level and drift components, and recurring
within-cycle mean variation is represented by the seasonal component
when `use_season = TRUE`.

Stationarity restrictions are applied to the autoregressive component,
which represents short-term serial dependence after the level, seasonal,
and optional exogenous components have been accounted for. AR
coefficients are transformed with
[`KFAS::artransform()`](https://rdrr.io/pkg/KFAS/man/artransform.html)
during model fitting so that this component satisfies the stationarity
constraints implied by the selected AR order.

Second-order assumptions are specified through time-invariant Gaussian
disturbance variances for the observation equation and state equations.
These variance parameters are estimated as positive values. The package
does not currently model time-varying volatility or automatically test
for higher-order forms of stationarity in the observed input series.

## Time Index and Calendar Conventions

Core modelling functions use base R `ts` objects. The `frequency`
attribute defines the number of observations per seasonal cycle, and the
core model preserves the input frequency. For example, `frequency = 12`
represents monthly observations, `frequency = 24` represents
twice-monthly observations, `frequency = 36` represents three
observations per month, and `frequency = 4` represents four seasonal
observations per year. The model treats these observations as regularly
spaced periods and does not convert periods to a fixed number of days.

Daily SST data are handled only in conversion utilities using `zoo`
objects indexed by `Date` or `POSIXt`. Daily observations are assigned
to calendar months using
[`zoo::as.yearmon()`](https://rdrr.io/pkg/zoo/man/yearmon.html) before
aggregation to monthly `ts` objects. No assumption that a year has 365
or 365.2422 days is used in this conversion path.

Cross-validation arguments such as `initial`, `horizon`, and `step` are
counts of observations, not calendar durations.

## Forecast Horizons and Error Margins

Forecast uncertainty generally increases with forecast horizon because
future observations depend on accumulated uncertainty in the latent
state dynamics and observation equation. In `tempssm`, forecast
intervals are obtained from the underlying `KFAS` state-space model via
`predict(res, n.ahead = h, interval = "prediction")`. Models with
exogenous variables also require future values in `new_exo_data`. For a
simplified one-step forecast, `exo_strategy = "last"` carries the final
observed exogenous values forward under a persistence assumption. With
`interval = "prediction"`, the returned object includes point forecasts
and prediction interval bounds, conventionally named `fit`, `lwr`, and
`upr`, which provide a direct indication of forecast uncertainty.

Users can trim forecasts to a chosen error margin with
[`trim_prediction_intervals()`](https://akihirao.github.io/tempssm/reference/trim_prediction_intervals.md).
This helper keeps the longest leading forecast horizon for which the
prediction interval width, defined as `upr - lwr`, does not exceed a
user-specified maximum width.

Cross-validation helpers such as
[`ts_cv_run_fold()`](https://akihirao.github.io/tempssm/reference/ts_cv_run_fold.md)
return point forecasts for accuracy scoring. They are intended for
evaluating predictive performance rather than for representing full
forecast uncertainty. Users who need prediction intervals should call
[`predict()`](https://rdrr.io/r/stats/predict.html) on the fitted
`tempssm` object as shown above.

Forecast and observed values are kept distinct in package outputs.
Direct calls to [`predict()`](https://rdrr.io/r/stats/predict.html)
return forecast values only. In time-series cross-validation results,
observed test values are stored in `y_test`, while forecasts are stored
separately in `y_pred`.

## Forecast Scale and Transformations

Forecasts are produced on the same numeric scale as the input
temperature series. The package does not log-transform, standardize,
difference, or otherwise transform the response series before
forecasting, so forecast means and prediction intervals do not require
back-transformation to be comparable with the original input data. For
this reason, `tempssm` does not provide a separate back-transformation
routine for forecast values.

Internal parameter transformations are used only to enforce model
constraints: variance parameters are exponentiated to remain positive,
and AR parameters are transformed with
[`KFAS::artransform()`](https://rdrr.io/pkg/KFAS/man/artransform.html)
to satisfy stationarity constraints. These transformations affect the
fitted dynamics and associated uncertainty estimates through the
state-space model, but they do not change the scale on which forecast
values are returned.

[`trim_prediction_intervals()`](https://akihirao.github.io/tempssm/reference/trim_prediction_intervals.md)
is a post-processing helper. It does not alter forecast means, lower
bounds, or upper bounds; it only removes forecast horizons after the
prediction interval width exceeds the user-specified threshold. The
drift accessor scales the latent slope by the input frequency to report
change per seasonal cycle, but this is a component summary and is not
applied to forecast values.

Forecast limitations follow from the fitted linear Gaussian state-space
model. Forecasts are conditional on the selected model structure,
estimated parameters, and any supplied future exogenous variables. They
should not be interpreted as physically constrained forecasts beyond the
assumptions of the fitted model.

## Return Value Conventions

The primary modelling function, `tempssm()`, returns an object of class
`"tempssm"`. This object is a structured list containing the fitted
`KFAS` model, optimization results, Kalman filtering and smoothing
output, original temperature and exogenous time series, model settings,
convergence status, and state-name metadata. It is intentionally not
converted back to the same class as the input series, because it
represents a fitted statistical model rather than a transformed time
series.

Accessor functions such as
[`get_level_ts()`](https://akihirao.github.io/tempssm/reference/get_level_ts.md),
[`get_drift_ts()`](https://akihirao.github.io/tempssm/reference/get_drift_ts.md),
[`get_season_ts()`](https://akihirao.github.io/tempssm/reference/get_season_ts.md),
and
[`get_ar_ts()`](https://akihirao.github.io/tempssm/reference/get_ar_ts.md)
return `ts` objects that preserve the time scale of the fitted model
through their `start`, `end`, `frequency`, and
[`time()`](https://rdrr.io/r/stats/time.html) attributes. Conversion
utilities that aggregate calendar-daily `zoo` inputs return monthly `ts`
objects with `frequency = 12`, while utilities that retrieve daily SST
data as `zoo` objects preserve the `Date` index. Summary and diagnostic
helpers return documented structured objects such as `summary.tempssm`,
`data.frame`, or `tibble` outputs as appropriate for the information
being represented. Each exported function documents the type and class
of its return value in its `@return` field, including named list
elements or columns where the return value is structured.

## Units in Return Values

Inputs carrying class `units` from the optional `units` package are
accepted by selected pre-processing paths, but their unit attributes are
converted to numeric values with an explicit warning before model
fitting or conversion to `ts`. Unit metadata are therefore not
propagated to fitted `tempssm` objects or derived component series. This
avoids adding `units` as a hard runtime dependency and keeps the
internal state-space calculations numeric.

Users who need formal units in downstream presentation should store the
original units externally and reattach or label them after model
fitting.

## Message control

Package messages are controlled by the global `tempssm.verbosity`
option. The default value, `"inform"`, displays analysis-relevant
information such as the treatment of missing response observations. Use
`"debug"` to additionally display model-fitting progress, including
optimization and Kalman filtering stages. Use `"none"` to suppress both
informational and debug messages. For example:
`options(tempssm.verbosity = "debug")`.

The `TEMPSSM_VERBOSITY` environment variable accepts the same values and
takes precedence over the R option. Warnings and errors, including
non-convergence warnings, are never suppressed by these verbosity
settings. The `na_action` argument independently controls the condition
issued for missing observations in the input temperature series; use
`"allow"` to handle those observations silently.

## References

Helske, J. (2017). KFAS: Exponential family state space models in R.
*Journal of Statistical Software*, 78(10), 1–39.
[doi:10.18637/jss.v078.i10](https://doi.org/10.18637/jss.v078.i10)

Baba, S., Ishii, H., and Yoshiyama, T. (2024). Estimating sea
temperature trends using a linear Gaussian state-space model in
Jogashima, Kanagawa, Japan (in Japanese with an English abstract).
*Bulletin of the Japanese Society of Fisheries Oceanography*, 88(3),
190–199.
[doi:10.34423/jsfo.88.3_190](https://doi.org/10.34423/jsfo.88.3_190)

Supplementary code:
https://github.com/logics-of-blue/sea-temperature-trend-jogashima

## See also

<https://github.com/akihirao/tempssm>

## Author

Akira S. Hirao, Shinya Baba, and Momoko Ichinokawa

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata)
summary(res)
} # }
```
