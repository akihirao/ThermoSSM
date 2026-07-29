#' srr standards: package-level documentation
#'
#' @srrstats {G1.0} The package lists primary references in README.md and
#' package-level documentation, including Helske (2017) for KFAS and Baba et
#' al. (2024) for the temperature time-series application that motivated the
#' package.
#'
#' @srrstats {G1.1} The "Prior Art and Scope" section of README.md documents
#' that `tempssm` is not the first implementation of linear Gaussian
#' state-space models, Kalman filtering, or Kalman smoothing in R. These
#' computations are delegated to `KFAS`. The package is a domain-focused
#' workflow layer for temperature time-series analysis, integrating model
#' construction, component extraction, uncertainty summaries, diagnostics,
#' visualization, and time-series cross-validation.
#'
#' @srrstats {G1.2} Package-level documentation includes a "Life Cycle and
#' Development Status" section. It states that `tempssm` is under active
#' development, that the current design intentionally focuses on regular
#' temperature time series represented as base R `ts` objects with integer
#' seasonal frequencies greater than 1, and that possible future direct
#' modelling support for daily or irregular time series such as `zoo` objects
#' is outside the current design goals.
#'
#' @srrstats {G1.3} Package-level documentation includes a "Statistical
#' Terminology" section defining the main statistical terms used by the
#' package, including linear Gaussian state-space model, latent state, level,
#' seasonal and autoregressive components, exogenous variables, Kalman
#' filtering, Kalman smoothing, standardized recursive residuals,
#' rolling-origin time-series cross-validation, MAE, and MASE.
#'
#' @srrstats {G1.4} All exported functions are documented with `roxygen2`
#' comments in source files under `R/`. Internal helper functions are either
#' documented with roxygen comments and marked `@noRd`, or kept as local
#' implementation details. The package `NAMESPACE` and `man/*.Rd` files are
#' generated from roxygen comments, with the roxygen2 version recorded in
#' `DESCRIPTION`.
#'
#' @srrstats {G1.4a} Internal top-level helper functions are documented with
#' standard `roxygen2` comments and marked with `@noRd` to suppress `.Rd`
#' generation. S3 methods and exported functions are documented separately.
#' Local nested functions used only within a parent function are treated as
#' implementation details of that documented parent function.
#'
#' @srrstats {TS1.8} Package-level documentation includes a "Time Index and
#' Calendar Conventions" section. Core modelling functions use base R `ts`
#' objects, where `frequency` defines the number of observations per seasonal
#' cycle and is preserved by the core modelling path. Frequencies such as 4,
#' 12, 24, and 36 are treated as regularly spaced observations within a
#' seasonal cycle and are not converted to fixed numbers of days. Daily `zoo`
#' inputs are indexed by `Date` or `POSIXt` and grouped into calendar months
#' with `zoo::as.yearmon()` before aggregation to monthly `ts` objects.
#' Cross-validation window parameters are documented and used as observation
#' counts rather than calendar durations.
#'
#' @srrstats {TS2.2} Stationarity of relevant moments is documented in the
#' package-level help under "Stationarity and Moment Assumptions". The
#' observed temperature series is not required to be stationary in mean because
#' first-order non-stationarity is represented explicitly through latent level,
#' drift, and seasonal components. Stationarity constraints are instead
#' applied to the autoregressive component that represents residual short-term
#' serial dependence after those components have been accounted for.
#' Second-order assumptions are represented by positive, time-invariant
#' Gaussian disturbance variances in the observation and state equations;
#' time-varying volatility and higher-order stationarity checks are outside
#' the current package scope.
#'
#' @srrstats {TS2.3} Stationarity assumptions and requirements are documented
#' in the package-level help and in the `tempssm()` function help. The observed
#' input series is not required to be stationary in mean; non-stationary mean
#' structure is modelled through level, drift, seasonal, and optional
#' exogenous components. Stationarity is required only for the autoregressive
#' component, and this requirement is enforced by transforming AR coefficients
#' with `KFAS::artransform()` during fitting. The documentation also states
#' the second-order assumption of positive, time-invariant Gaussian disturbance
#' variances and the current absence of automatic stationarity testing for the
#' observed input series.
#'
#' @srrstats {TS3.2} Package-level documentation includes a "Forecast
#' Horizons and Error Margins" section. It explains that forecast uncertainty
#' generally increases with horizon because future observations depend on
#' accumulated latent-state and observation uncertainty. The TS3.0 test uses
#' the `niigata_sst` data to demonstrate this widening, and the TS3.1
#' negative-control test demonstrates that decreasing or constant interval
#' widths would be detected as violations.
#'
#' @srrstats {TS4.0} Package-level documentation includes a "Return Value
#' Conventions" section. It explains that the main modelling function returns
#' a classed `tempssm` object, because the result is a fitted statistical model
#' rather than a transformed time series. Accessor functions return `ts`
#' objects for fitted components, and diagnostic or summary functions return
#' documented structured objects appropriate to their purpose.
#'
#' @srrstats {TS4.4} Package-level documentation includes a "Forecast Scale
#' and Transformations" section. It states that forecast values are returned
#' on the original numeric temperature scale because the response series is not
#' log-transformed, standardized, differenced, or otherwise transformed before
#' forecasting. It also documents that internal transformations of variance
#' and AR parameters affect model dynamics and uncertainty estimates but do
#' not change the scale of returned forecast values. The post-processing
#' helper `trim_prediction_intervals()` is documented as truncating forecast
#' horizons without modifying forecast means or interval bounds.
#'
#' @noRd
NULL

#' tempssm: State space models for temperature time series
#'
#' \pkg{tempssm} provides tools for analyzing temperature time series
#' (e.g., air temperature and sea surface temperature) using
#' linear Gaussian state-space models.
#'
#' The package is designed for long-term environmental monitoring data
#' and focuses on trend extraction, seasonal components, and uncertainty
#' estimation under a unified state-space modeling framework.
#'
#' @details
#' Typical applications include:
#' \itemize{
#'   \item Analysis of long-term air temperature records
#'   \item Sea surface temperature trend estimation
#'   \item Decomposition into level, trend, and seasonal components
#' }
#'
#' The implementation is based on linear Gaussian state-space models
#' and makes use of Kalman filtering and smoothing.
#'
#' Main parts of the implementation were adapted from the supplementary code
#' provided in Baba et al. (2024), available on GitHub:
#' https://github.com/logics-of-blue/sea-temperature-trend-jogashima
#'
#'
#' @section Life Cycle and Development Status:
#' `tempssm` is under active development. The current design focuses on
#' temperature time series represented as base R `ts` objects with integer
#' seasonal frequencies greater than 1. The examples and validation primarily
#' use monthly data, but the core modelling path preserves the input
#' frequency. This scope is intentional: it keeps model fitting and
#' cross-validation feasible on typical personal computing environments used
#' by R users.
#'
#' The package aims to stabilize this workflow before expanding the supported
#' data structures. Future versions may consider direct modelling support for
#' daily or irregular time series, such as `zoo` objects, but such extensions
#' are not part of the current design goals and would require careful
#' consideration of computational costs, input validation, and documentation.
#'
#' @section Statistical Terminology:
#' In this package, a linear Gaussian state-space model refers to a model in
#' which observed temperature values are represented as noisy observations of
#' unobserved latent states, with Gaussian observation and state disturbances.
#' The latent states may include a level component, a seasonal component, an
#' autoregressive component, and optional exogenous effects.
#'
#' The level component represents the slowly varying baseline temperature. The
#' seasonal component represents recurring within-year variation. The
#' autoregressive component represents short-term serial dependence not captured
#' by the level or seasonal components. The AR order is the number of lagged
#' autoregressive terms included in this component.
#'
#' Exogenous variables are external time series supplied by the user and aligned
#' with the temperature series. They are included as regression effects in the
#' state-space model. Kalman filtering refers to sequential estimation of the
#' latent state using observations up to each time point, whereas Kalman
#' smoothing refers to estimation of latent states using the full observed time
#' series.
#'
#' Residual diagnostics in this package use standardized recursive residuals
#' extracted from the fitted state-space model. Time-series cross-validation
#' refers to rolling-origin evaluation, where models are fitted on earlier
#' observations and evaluated on later held-out observations. MAE denotes mean
#' absolute error, and MASE denotes mean absolute scaled error.
#'
#' @section Stationarity and Moment Assumptions:
#' `tempssm` does not require the observed temperature series itself to be
#' stationary in mean. Long-term changes in the first-order moment are treated
#' as part of the latent level and drift components, and recurring within-cycle
#' mean variation is represented by the seasonal component when
#' `use_season = TRUE`.
#'
#' Stationarity restrictions are applied to the autoregressive component, which
#' represents short-term serial dependence after the level, seasonal, and
#' optional exogenous components have been accounted for. AR coefficients are
#' transformed with `KFAS::artransform()` during model fitting so that this
#' component satisfies the stationarity constraints implied by the selected AR
#' order.
#'
#' Second-order assumptions are specified through time-invariant Gaussian
#' disturbance variances for the observation equation and state equations.
#' These variance parameters are estimated as positive values. The package does
#' not currently model time-varying volatility or automatically test for
#' higher-order forms of stationarity in the observed input series.
#'
#' @section Time Index and Calendar Conventions:
#' Core modelling functions use base R `ts` objects. The `frequency` attribute
#' defines the number of observations per seasonal cycle, and the core model
#' preserves the input frequency. For example, `frequency = 12` represents
#' monthly observations, `frequency = 24` represents twice-monthly
#' observations, `frequency = 36` represents three observations per month, and
#' `frequency = 4` represents four seasonal observations per year. The model
#' treats these observations as regularly spaced periods and does not convert
#' periods to a fixed number of days.
#'
#' Daily SST data are handled only in conversion utilities using `zoo` objects
#' indexed by `Date` or `POSIXt`. Daily observations are assigned to calendar
#' months using `zoo::as.yearmon()` before aggregation to monthly `ts` objects.
#' No assumption that a year has 365 or 365.2422 days is used in this
#' conversion path.
#'
#' Cross-validation arguments such as `initial`, `horizon`, and `step` are
#' counts of observations, not calendar durations.
#'
#' @section Forecast Horizons and Error Margins:
#' Forecast uncertainty generally increases with forecast horizon because
#' future observations depend on accumulated uncertainty in the latent state
#' dynamics and observation equation. In `tempssm`, forecast intervals are
#' obtained from the underlying `KFAS` state-space model via
#' `predict(res, n.ahead = h, interval = "prediction")`. Models with
#' exogenous variables also require future values in `new_exo_data`.
#' For a simplified one-step forecast, `exo_strategy = "last"` carries the
#' final observed exogenous values forward under a persistence assumption.
#' With `interval = "prediction"`, the returned object includes point
#' forecasts and prediction interval bounds, conventionally named `fit`,
#' `lwr`, and `upr`, which provide a direct indication of forecast
#' uncertainty.
#'
#' Users can trim forecasts to a chosen error margin with
#' `trim_prediction_intervals()`. This helper keeps the longest leading
#' forecast horizon for which the prediction interval width, defined as
#' `upr - lwr`, does not exceed a user-specified maximum width.
#'
#' Cross-validation helpers such as `ts_cv_run_fold()` return point forecasts
#' for accuracy scoring. They are intended for evaluating predictive
#' performance rather than for representing full forecast uncertainty. Users
#' who need prediction intervals should call `predict()` on the fitted
#' `tempssm` object as shown above.
#'
#' Forecast and observed values are kept distinct in package outputs. Direct
#' calls to `predict()` return forecast values only. In time-series
#' cross-validation results, observed test values are stored in `y_test`, while
#' forecasts are stored separately in `y_pred`.
#'
#' @section Forecast Scale and Transformations:
#' Forecasts are produced on the same numeric scale as the input temperature
#' series. The package does not log-transform, standardize, difference, or
#' otherwise transform the response series before forecasting, so forecast
#' means and prediction intervals do not require back-transformation to be
#' comparable with the original input data. For this reason, `tempssm` does
#' not provide a separate back-transformation routine for forecast values.
#'
#' Internal parameter transformations are used only to enforce model
#' constraints: variance parameters are exponentiated to remain positive, and
#' AR parameters are transformed with `KFAS::artransform()` to satisfy
#' stationarity constraints. These transformations affect the fitted dynamics
#' and associated uncertainty estimates through the state-space model, but they
#' do not change the scale on which forecast values are returned.
#'
#' `trim_prediction_intervals()` is a post-processing helper. It does not alter
#' forecast means, lower bounds, or upper bounds; it only removes forecast
#' horizons after the prediction interval width exceeds the user-specified
#' threshold. The drift accessor scales the latent slope by the input
#' frequency to report change per seasonal cycle, but this is a component
#' summary and is not applied to forecast values.
#'
#' Forecast limitations follow from the fitted linear Gaussian state-space
#' model. Forecasts are conditional on the selected model structure, estimated
#' parameters, and any supplied future exogenous variables. They should not be
#' interpreted as physically constrained forecasts beyond the assumptions of
#' the fitted model.
#'
#' @section Return Value Conventions:
#' The primary modelling function, `tempssm()`, returns an object of class
#' `"tempssm"`. This object is a structured list containing the fitted `KFAS`
#' model, optimization results, Kalman filtering and smoothing output, original
#' temperature and exogenous time series, model settings, convergence status,
#' and state-name metadata. It is intentionally not converted back to the same
#' class as the input series, because it represents a fitted statistical model
#' rather than a transformed time series.
#'
#' Accessor functions such as `get_level_ts()`, `get_drift_ts()`,
#' `get_season_ts()`, and `get_ar_ts()` return `ts` objects that preserve the
#' time scale of the fitted model through their `start`, `end`, `frequency`,
#' and `time()` attributes. Conversion utilities that aggregate calendar-daily
#' `zoo` inputs return monthly `ts` objects with `frequency = 12`, while
#' utilities that retrieve daily SST data as `zoo` objects preserve the
#' `Date` index. Summary and diagnostic helpers return documented structured
#' objects such as `summary.tempssm`, `data.frame`, or `tibble` outputs as
#' appropriate for the information being represented.
#' Each exported function documents the type and class of its return value in
#' its `@return` field, including named list elements or columns where the
#' return value is structured.
#'
#' @section Units in Return Values:
#' Inputs carrying class `units` from the optional `units` package are accepted
#' by selected pre-processing paths, but their unit attributes are converted to
#' numeric values with an explicit warning before model fitting or conversion
#' to `ts`. Unit metadata are therefore not propagated to fitted `tempssm`
#' objects or derived component series. This avoids adding `units` as a hard
#' runtime dependency and keeps the internal state-space calculations numeric.
#'
#' Users who need formal units in downstream presentation should store the
#' original units externally and reattach or label them after model fitting.
#'
#' @author
#' Akira S. Hirao, Shinya Baba, and Momoko Ichinokawa
#'
#' @references
#' Helske, J. (2017). KFAS: Exponential family state space models in R.
#' \emph{Journal of Statistical Software}, 78(10), 1--39.
#' \doi{10.18637/jss.v078.i10}
#'
#' Baba, S., Ishii, H., and Yoshiyama, T. (2024). Estimating sea temperature
#' trends using a linear Gaussian state-space model in Jogashima, Kanagawa,
#' Japan (in Japanese with an English abstract).
#' \emph{Bulletin of the Japanese Society of Fisheries Oceanography},
#' 88(3), 190--199. \doi{10.34423/jsfo.88.3_190}
#'
#' Supplementary code:
#' https://github.com/logics-of-blue/sea-temperature-trend-jogashima
#'
#' @seealso
#' \url{https://github.com/akihirao/tempssm}
#'
#' @name tempssm
#' @aliases tempssm-package
NULL
