#' srr standards: model input validation
#'
#' @srrstats {G2.0} Public entry points validate input lengths for scalar,
#' vector, and time-series inputs. Scalar arguments such as `ar_order`,
#' `use_season`, `maxit`, `reltol`, cross-validation window parameters,
#' logical controls, diagnostic options, file paths, JMA area identifiers, and
#' aggregation thresholds are required to have length one. Time-series inputs
#' are validated through shared preprocessing routines, including checks that
#' exogenous series have the same number of observations and time index as the
#' response series. Arguments that may be single- or multi-valued, such as
#' `label` or `exo_name`, are checked against the corresponding number of
#' variables.
#'
#' @srrstats {G2.0a} Function documentation explicitly states length
#' expectations for scalar inputs, time-series inputs, and name or label
#' vectors. Examples include scalar documentation for `ar_order`, `use_season`,
#' cross-validation window parameters, plotting and diagnostic controls, and
#' length-one-or-number-of-variables expectations for labels and exogenous
#' variable names.
#'
#' @srrstats {G2.1} Public entry points assert expected input types, including
#' `ts` objects for temperature and exogenous time series, `zoo` objects for
#' daily data aggregation, `tempssm` objects for model summaries, diagnostics,
#' plotting, and log-likelihood extraction, numeric scalars or vectors for
#' model controls and parameter inputs, logical scalars for switches, character
#' scalars or vectors for names, file paths, and JMA area identifiers, and
#' lists for cross-validation folds and results.
#'
#' @srrstats {G2.1a} Function documentation states expected input types for
#' public arguments, including class expectations for time-series objects and
#' scalar or vector type expectations for numeric, logical, and character
#' inputs.
#'
#' @srrstats {G2.2} Public functions distinguish univariate and multivariate
#' time-series inputs. Temperature response series supplied to modelling,
#' cross-validation, climatology, anomaly, and plotting functions are required
#' to be univariate `ts` objects. Exogenous series are explicitly allowed to be
#' univariate or multivariate where appropriate, and helper functions that
#' operate on multivariate `ts` objects document and check those expectations.
#'
#' @srrstats {G2.8} Conversion and standardization are performed at package
#' entry points before data are passed to analytical sub-functions. The
#' modelling and cross-validation APIs call `.tempssm_prepare_model_inputs()`,
#' which validates temperature and exogenous inputs, assigns default exogenous
#' names when explicitly allowed, checks frequency and time-index consistency,
#' applies the requested temperature missing-value policy, rejects missing
#' exogenous covariates, and returns a uniform list with validated base R `ts`
#' objects plus common `frequency` and `n_obs` metadata. Tabular, CSV, and
#' `zoo` conversion helpers similarly return regular `ts` objects before
#' those data are used by modelling or utility functions.
#'
#' @srrstats {G2.13} Missing data are checked during initial preprocessing
#' before analytical routines are called. `tempssm()` and
#' `ts_train_test_split()` both call `.tempssm_prepare_model_inputs()`, which
#' checks explicit missing response values through
#' `.tempssm_handle_missing_ts()` and rejects missing exogenous covariates
#' before model fitting, state-space construction, or rolling splits proceed.
#' Monthly tabular and CSV conversion reject missing date/index fields, insert
#' implicit missing months as explicit `NA` values with a warning, and
#' preserve explicit missing temperatures. Daily `zoo` aggregation validates
#' non-missing date indexes, summarizes missing daily values according to
#' `na.rm` and `na_prop_max`, and warns when many monthly values are missing
#' after aggregation.
#'
#' @srrstats {G2.14} User-facing modelling and cross-validation functions
#' provide explicit options for handling missing temperature observations
#' through the `na_action` argument. The shared preprocessing helper
#' `.tempssm_handle_missing_ts()` implements the temperature-series policy
#' before model fitting or rolling-origin splitting proceeds. Missing
#' exogenous covariates are always rejected because KFAS regression terms
#' require complete covariate values. Conversion utilities also expose
#' missing-value controls where relevant, such as `na.rm` and `na_prop_max` in
#' daily-to-monthly `zoo` aggregation.
#'
#' @srrstats {G2.14a} `na_action = "error"` stops when explicit missing
#' values are detected in temperature `ts` inputs. Missing values in
#' exogenous `ts` inputs always stop preprocessing, regardless of
#' `na_action`.
#'
#' @srrstats {G2.14b} The default `na_action = "inform"` reports and proceeds
#' with explicit `NA` temperature observations because linear Gaussian
#' state-space models can treat them as unobserved responses. `na_action =
#' "warn"` raises the notification to a warning, while `na_action = "allow"`
#' proceeds silently.
#'
#' @srrstats {G2.16} Undefined numeric values are handled separately from
#' explicit missing `NA` observations. Model and cross-validation inputs reject
#' `NaN`, `Inf`, and `-Inf` values during shared preprocessing via
#' `.tempssm_check_no_undefined()`. This preserves the package distinction
#' between missing response observations, which linear Gaussian state-space
#' models can handle, and undefined numeric values, which would make
#' likelihood evaluation and regression covariates ill-defined. Tabular and
#' daily `zoo` conversion helpers apply the same check before constructing
#' regular `ts` objects. Unit tests cover undefined values in temperature,
#' exogenous, data-frame, and `zoo` inputs.
#'
#' @srrstats {TS1.2} The package implements explicit validation routines for
#' acceptable time-series classes. The core modelling path uses
#' `.tempssm_check_temp_ts()` to require a univariate base R `ts` object for
#' temperature data and `.tempssm_check_exo_ts()` to require aligned base R
#' `ts` objects for exogenous variables. Time-series utilities such as
#' `trim_ts_overlap()`, `split_multi_ts()`, `compute_monthly_climatology()`,
#' `compute_temp_anomaly()`, and `plot_temp_dev()` also reject non-`ts`
#' inputs. The core modelling path and seasonal climatology helpers accept
#' integer seasonal frequencies greater than 1, not only monthly
#' `frequency = 12` data. Daily SST conversion routines that operate on
#' irregular daily data explicitly require `zoo` inputs before aggregating them
#' to monthly `ts` objects. These validation paths are covered by unit tests
#' for valid and invalid class inputs.
#'
#' @srrstats {TS1.3} Core model inputs are passed through the single internal
#' pre-processing routine `.tempssm_prepare_model_inputs()`. This routine
#' validates temperature and optional exogenous inputs, standardizes unnamed
#' exogenous variables when allowed by the calling workflow, and returns a
#' uniform list containing validated base R `ts` objects, the common
#' frequency, and the number of observations. The primary model fitting
#' function `tempssm()` and the cross-validation splitter
#' `ts_train_test_split()` both use this routine before passing data to
#' downstream model construction, fitting, or fold-generation code. Conversion
#' helpers for data-frame, CSV, and `zoo` inputs transform those inputs to
#' explicit monthly `ts` objects before they enter the modelling path.
#'
#' @srrstats {TS1.4} The core pre-processing routine preserves the time-based
#' attributes of accepted `ts` inputs. `.tempssm_prepare_model_inputs()`
#' returns validated `ts` objects without converting them to non-time-series
#' containers, and preserves `start`, `end`, `frequency`, and `time()` values
#' for both temperature and exogenous series, including the branch where
#' default exogenous variable names are assigned. Conversion utilities that
#' start from data-frame, CSV, or `zoo` inputs explicitly construct monthly
#' `ts` outputs with defined start times and `frequency = 12` before those
#' objects enter the modelling path. These behaviours are covered by unit
#' tests for the pre-processing and conversion utilities.
#'
#' @srrstats {TS2.1} The main modelling and cross-validation entry points
#' provide a \code{na_action} argument controlling how explicit missing values
#' in the regular temperature `ts` input are handled. The argument is passed
#' through the shared input pre-processing routine
#' `.tempssm_prepare_model_inputs()`, so `tempssm()` and
#' `ts_train_test_split()` use the same missing-data policy. Missing
#' exogenous covariates are not controlled by `na_action`; they are rejected
#' because regression covariates must be complete. Conversion utilities also
#' expose missing-data controls where aggregation is performed, such as
#' `na.rm` and `na_prop_max` in `daily_zoo_to_monthly_ts()`.
#'
#' @srrstats {TS2.1a} Setting `na_action = "error"` in `tempssm()` or
#' `ts_train_test_split()` stops during input pre-processing if explicit
#' missing values are detected in `temp_data`. Missing values in `exo_data`
#' always stop input pre-processing.
#'
#' @srrstats {TS2.1b} The default `na_action = "inform"` issues an informational
#' message and proceeds with explicit `NA` temperature observations. Setting
#' `na_action = "warn"` issues a warning instead, and `na_action = "allow"`
#' proceeds silently. These paths preserve the original regular `ts` object
#' and its explicit missing response values, so results use the same time index
#' rather than an implicitly shortened series.
#'
#' @srrstats {TS2.4} The relevant stationarity requirement in `tempssm` is
#' the stationarity of the autoregressive component. The package implements an
#' internal AR-root check after transforming unconstrained optimization
#' parameters to AR coefficients. The same transformation-and-check helper is
#' used during model fitting and when extracting or summarising fitted AR
#' coefficients. Unit tests cover stationary and non-stationary AR
#' coefficients and confirm that transformed AR parameters are stationary.
#'
#' @srrstats {TS2.4b} AR coefficients are transformed with
#' `KFAS::artransform()` and then checked by evaluating whether the AR
#' polynomial roots lie outside the unit circle within numerical tolerance.
#'
#' @noRd
NULL


#' Prepare an optional finite numeric control
#'
#' @param x A numeric scalar or \code{NULL}.
#' @inheritParams .tempssm_check_length_one
#' @param default Numeric scalar used when \code{x} is \code{NULL}.
#'
#' @return A finite numeric scalar.
#'
#' @keywords internal
#' @noRd
.prepare_tempssm_numeric_control <- function(x, arg_name, default) {
  if (is.null(x)) {
    return(default)
  }

  .tempssm_check_length_one(x, arg_name)
  .tempssm_check_numeric(x, arg_name)

  if (is.na(x) || !is.finite(x)) {
    cli::cli_abort(
      "{.arg {arg_name}} must be a finite numeric scalar."
    )
  }

  x
}


#' Validate and prepare controls for \code{tempssm()}
#'
#' This helper validates scalar model and optimization controls, supplies
#' defaults for optional optimization controls, and warns about unusually high
#' autoregressive orders.
#'
#' @inheritParams tempssm
#'
#' @return A named list containing validated \code{ar_order},
#'   \code{use_season}, \code{maxit}, \code{reltol}, and \code{na_action}.
#'
#' @keywords internal
#' @noRd
.prepare_tempssm_controls <- function(ar_order,
                                      use_season,
                                      marginal,
                                      maxit,
                                      reltol,
                                      na_action) {
  .validate_ar_order(ar_order)
  .validate_use_season(use_season)
  .validate_marginal(marginal)

  na_action <- match.arg(
    na_action,
    c("inform", "warn", "error", "allow")
  )

  maxit <- .prepare_tempssm_numeric_control(maxit, "maxit", 5000)
  reltol <- .prepare_tempssm_numeric_control(reltol, "reltol", 1e-16)

  if (ar_order > 4) {
    cli::cli_warn(
      "An {.arg ar_order} greater than 4 may lead to unstable estimation."
    )
  }

  list(
    ar_order = ar_order,
    use_season = use_season,
    marginal = marginal,
    maxit = maxit,
    reltol = reltol,
    na_action = na_action
  )
}


#' Compute expected length of the initial parameter vector
#'
#' The initial parameter vector contains trend, optional seasonal,
#' autoregressive, AR variance, and observation variance parameters.
#'
#' @inheritParams tempssm
#'
#' @return Integer scalar giving the expected number of initial values.
#'
#' @keywords internal
#' @noRd
.tempssm_inits_length <- function(ar_order, use_season) {
  as.integer(ar_order + if (use_season) 4L else 3L)
}


#' Generate default initial parameter values for \code{tempssm()}
#'
#' The returned vector follows the optimization parameter order:
#' trend variance, optional seasonal variance, AR coefficients, AR variance,
#' and observation variance.
#'
#' @inheritParams tempssm
#'
#' @return Numeric vector of default initial parameter values.
#'
#' @keywords internal
#' @noRd
.default_tempssm_inits <- function(ar_order, use_season) {
  ar_order <- as.integer(ar_order)
  ar_inits <- c(0.5, rep(0, ar_order - 1L))

  if (use_season) {
    c(
      -13, # trend
      -7, # seasonal
      ar_inits,
      -0.3, # AR variance
      -5 # observation variance
    )
  } else {
    c(
      -13, # trend
      ar_inits,
      -0.3, # AR variance
      -5 # observation variance
    )
  }
}


#' Prepare initial parameter values for \code{tempssm()}
#'
#' This helper supplies default initial values when \code{inits = NULL} and
#' validates user-supplied initial values against the model structure implied
#' by \code{ar_order} and \code{use_season}.
#'
#' @inheritParams tempssm
#'
#' @return Numeric vector of initial parameter values.
#'
#' @keywords internal
#' @noRd
.prepare_tempssm_inits <- function(inits, ar_order, use_season) {
  expected_len <- .tempssm_inits_length(ar_order, use_season)

  if (is.null(inits)) {
    .tempssm_cli_debug("Using default initial parameter values")
    inits <- .default_tempssm_inits(ar_order, use_season)
  }

  .tempssm_check_numeric(inits, "inits")

  if (length(inits) != expected_len) {
    cli::cli_abort(
      "{.arg inits} must be a numeric vector of length {expected_len}."
    )
  }

  inits
}


#' Prepare exogenous inputs for KFAS model construction
#'
#' This helper converts validated exogenous time-series data to the matrix used
#' by the KFAS model constructors and preserves its column names for state
#' mapping.
#'
#' @inheritParams tempssm
#'
#' @return A named list containing \code{exo_names} and \code{exo_matrix}.
#'
#' @keywords internal
#' @noRd
.prepare_tempssm_exogenous <- function(exo_data) {
  if (is.null(exo_data)) {
    .tempssm_cli_debug("No exogenous variables used")
    return(list(exo_names = NULL, exo_matrix = NULL))
  }

  .tempssm_cli_debug("Including exogenous variables in the model")

  exo_names <- colnames(exo_data)
  exo_matrix <- as.matrix(exo_data)

  .tempssm_cli_debug(
    "Exogenous variables: {paste(exo_names, collapse = ', ')}"
  )

  list(exo_names = exo_names, exo_matrix = exo_matrix)
}


#' Construct state names for a fitted tempssm model
#'
#' State names follow the KFAS model component order used by
#' \code{.define_build_model()} and \code{.define_update_func()}.
#'
#' @param exo_names Optional character vector of exogenous state names.
#' @param freq Integer seasonal frequency.
#' @param n_states Integer number of columns in the smoothed state matrix.
#' @inheritParams tempssm
#'
#' @return Character vector of state names.
#'
#' @keywords internal
#' @noRd
.make_tempssm_state_names <- function(exo_names,
                                      freq,
                                      use_season,
                                      ar_order,
                                      n_states) {
  seasonal_names <- if (use_season) {
    paste0("sea_dummy", seq_len(freq - 1))
  } else {
    character(0)
  }

  state_names <- c(
    exo_names,
    "level",
    "slope",
    seasonal_names,
    paste0("arima", seq_len(ar_order))
  )

  if (length(state_names) != n_states) {
    cli::cli_abort(
      paste0(
        "Internal state-name mapping produced {length(state_names)} names, ",
        "but the KFAS state matrix has {n_states} columns."
      )
    )
  }

  state_names
}


#' Construct a tempssm result object
#'
#' @inheritParams .make_tempssm_state_names
#' @param model A fitted KFAS model or \code{NULL}.
#' @param fit A KFAS fitting result or \code{NULL}.
#' @param kfs A KFAS filtering and smoothing result or \code{NULL}.
#' @param temp_data Validated temperature time series.
#' @param exogenous_data Validated exogenous time series or \code{NULL}.
#' @param model_call Matched call to \code{tempssm()}.
#' @param converged Logical scalar indicating optimization convergence.
#' @param state_names Character vector of all state names.
#' @inheritParams tempssm
#'
#' @return An object of class \code{"tempssm"}.
#'
#' @keywords internal
#' @noRd
.new_tempssm_result <- function(model,
                                fit,
                                kfs,
                                temp_data,
                                exogenous_data,
                                ar_order,
                                use_season,
                                marginal,
                                model_call,
                                converged,
                                exo_names,
                                state_names) {
  if (!is.null(kfs)) {
    colnames(kfs$alphahat) <- state_names
    if (!is.null(kfs$att)) {
      colnames(kfs$att) <- state_names
    }
  }

  out <- list(
    model = model,
    fit = fit,
    kfs = kfs,
    temp_data = temp_data,
    exogenous_data = exogenous_data,
    ar_order = ar_order,
    use_season = use_season,
    marginal = marginal,
    call = model_call,
    converged = converged,
    state_map = list(
      exogenous = exo_names,
      all = state_names
    )
  )

  class(out) <- "tempssm"
  out
}


#' Fit a prepared tempssm model with KFAS
#'
#' This helper performs the two-stage optimization used by \code{tempssm()},
#' then runs Kalman filtering and smoothing on the second-stage fitted model.
#'
#' @param build_ssm A prepared \code{KFAS::SSModel} object.
#' @param updatefn Parameter update function passed to \code{KFAS::fitSSM()}.
#' @inheritParams tempssm
#'
#' @return A named list containing the second-stage \code{fit} and the
#'   filtering and smoothing result \code{kfs}.
#'
#' @keywords internal
#' @noRd
.fit_tempssm_kfas <- function(build_ssm,
                              updatefn,
                              inits,
                              marginal,
                              maxit,
                              reltol) {
  control <- list(maxit = maxit, reltol = reltol)

  .tempssm_cli_debug("Optimizing model parameters (stage 1)")
  fit_stage1 <- fitSSM(
    build_ssm,
    inits = inits,
    updatefn = updatefn,
    marginal = marginal,
    method = "Nelder-Mead",
    control = control
  )

  .tempssm_cli_debug("Refining optimization (stage 2)")
  fit_stage2 <- fitSSM(
    build_ssm,
    inits = fit_stage1$optim.out$par,
    updatefn = updatefn,
    marginal = marginal,
    method = "BFGS",
    control = control
  )

  .tempssm_cli_debug("Running Kalman filtering and smoothing")
  kfs <- KFS(
    fit_stage2$model,
    filtering = c("state", "mean"),
    smoothing = c("state", "mean", "disturbance")
  )

  list(fit = fit_stage2, kfs = kfs)
}


#' Base function for fitting a linear Gaussian state-space model to temperature
#' time series
#'
#' This function estimates a linear Gaussian state-space model (SSM)
#' for regular temperature time series using Kalman filtering and smoothing.
#' The input must be a univariate \code{ts} object with an integer seasonal
#' frequency greater than 1.
#'
#' @details
#' The observed temperature series is not required to be stationary in mean.
#' Long-term mean changes are represented by latent level and drift
#' components, and recurring within-cycle mean variation is represented by the
#' seasonal component when \code{use_season = TRUE}. Stationarity constraints
#' are applied to the autoregressive component, whose coefficients are
#' transformed with \code{KFAS::artransform()} during model fitting.
#'
#' Observation and state disturbances are assumed Gaussian with positive,
#' time-invariant variances. The model does not currently include
#' time-varying volatility or automatic stationarity tests for the observed
#' input series.
#'
#' Invalid arguments and model inputs raise an error before fitting begins.
#' Errors raised by the KFAS fitting or filtering backend issue a warning and
#' return a \code{"tempssm"} object with \code{converged = FALSE} and
#' \code{NULL} model, fit, and filtering components. Errors in model
#' construction, state-name assignment, or result construction are propagated
#' rather than converted to a failed fit. If optimization completes without
#' convergence, the available fitted components are retained and
#' \code{converged} is set to \code{FALSE}.
#'
#' @param temp_data A temperature time series of class \code{ts}.
#'   The \code{ts} object must be univariate.
#'   The series can have any integer frequency of 2 or higher.
#'   For example, a frequency of 12 represents a monthly \code{ts} object.
#'
#' @param exo_data A data set of exogenous variable(s) of class \code{ts}.
#'   The series may have any integer frequency of 2 or higher,
#'   but it must be the same as that of \code{temp_data}. It must also have
#'   the same number of observations and the same time index as
#'   \code{temp_data}. The default is \code{NULL} when fitting a model without
#'   exogenous variables.
#'
#' @param ar_order Integer scalar specifying the order of the autoregressive
#' (AR)
#' component in the error structure (e.g., 2 for AR(2), 3 for AR(3)).
#' Defaults to 1. Orders from 1 to 4 are intended as the usual working range;
#' larger values are allowed but trigger a warning because they may lead to
#' unstable estimation.
#'
#' @param use_season Logical scalar; should the seasonal component be
#' considered? Defaults to \code{TRUE}.
#'
#' @param marginal Logical scalar specifying the likelihood used during
#'   parameter estimation. If \code{TRUE} (the default), KFAS uses the
#'   marginal likelihood, which adds the diffuse-initialization correction
#'   term. If \code{FALSE}, KFAS uses the diffuse likelihood. The selected
#'   setting is stored in the fitted object and used by default by
#'   \code{logLik()} and \code{summary()} methods. Set \code{marginal = FALSE}
#'   to reproduce the likelihood default used by versions of \pkg{tempssm}
#'   prior to this change.
#'
#' @param inits Optional numeric vector of initial parameter values.
#'  If \code{NULL}, default values are used. When supplied, its length must
#'  match the number of variance and autoregressive parameters implied by
#'  \code{ar_order} and \code{use_season}.
#'
#' @param maxit Optional numeric scalar giving the maximum number of
#' iterations.
#'  If \code{NULL}, default value of 5000 is used.
#'
#' @param reltol Optional numeric scalar giving the relative convergence
#' tolerance.
#'  If \code{NULL}, default value of 1e-16 is used.
#'
#' @param na_action Character scalar specifying how explicit missing
#'   observations in the input temperature series should be handled. Use
#'   \code{"inform"} to issue an informational message and proceed,
#'   \code{"warn"} to issue a warning and proceed, \code{"error"} to stop, or
#'   \code{"allow"} to proceed silently. The default is \code{"inform"}.
#'   Missing values in \code{exo_data} are always rejected; exogenous
#'   covariates must be completed before model fitting.
#'
#' @section Message control:
#' Package messages are controlled by the global
#' \code{tempssm.verbosity} option. The default value, \code{"inform"}, displays
#' analysis-relevant information such as the treatment of missing response
#' observations. Use \code{"debug"} to additionally display model-fitting
#' progress, including optimization and Kalman filtering stages. Use
#' \code{"none"} to suppress both informational and debug messages. For example:
#' \code{options(tempssm.verbosity = "debug")}.
#'
#' The \code{TEMPSSM_VERBOSITY} environment variable accepts the same values
#' and takes precedence over the R option. Warnings and errors, including
#' non-convergence warnings, are never suppressed by these verbosity settings.
#' The \code{na_action} argument independently controls the condition issued
#' for missing observations in the input temperature series; use
#' \code{"allow"} to handle those observations silently.
#'
#' @return An object of class \code{"tempssm"}, a named list containing:
#' \describe{
#'   \item{model}{Fitted \code{SSModel} object, or \code{NULL} if fitting
#'   raised an error.}
#'   \item{fit}{Results from \code{fitSSM}, or \code{NULL} if fitting raised an
#'   error.}
#'   \item{kfs}{Kalman filtering and smoothing results from \code{KFS}, or
#'   \code{NULL} if fitting raised an error.}
#'   \item{temp_data}{Temperature time series used for estimation.}
#'   \item{exogenous_data}{Time series of exogenous variables used for
#'   estimation, or \code{NULL}.}
#'   \item{ar_order}{Order of the autoregressive component.}
#'   \item{use_season}{Logical; whether to include a seasonal component.}
#'   \item{marginal}{Logical; whether marginal likelihood was used during
#'   parameter estimation.}
#'   \item{call}{Matched function call.}
#'   \item{converged}{Logical; whether the second optimization stage
#'   converged.}
#'   \item{state_map}{List describing exogenous and complete state names.}
#' }
#'
#' @import KFAS
#' @export
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#' res <- tempssm(sst_niigata)
#' summary(res)
#' }
tempssm <- function(temp_data,
                    exo_data = NULL,
                    ar_order = 1,
                    inits = NULL,
                    maxit = NULL,
                    reltol = NULL,
                    use_season = TRUE,
                    na_action = c("inform", "warn", "error", "allow"),
                    marginal = TRUE) {
  model_call <- match.call()

  if (missing(na_action)) {
    na_action <- "inform"
  }
  controls <- .prepare_tempssm_controls(
    ar_order = ar_order,
    use_season = use_season,
    marginal = marginal,
    maxit = maxit,
    reltol = reltol,
    na_action = na_action
  )
  ar_order <- controls$ar_order
  use_season <- controls$use_season
  marginal <- controls$marginal
  maxit <- controls$maxit
  reltol <- controls$reltol
  na_action <- controls$na_action

  ## ---- Default initial values --------------------------------------
  inits <- .prepare_tempssm_inits(
    inits = inits,
    ar_order = ar_order,
    use_season = use_season
  )

  ## ---- Input checks ---------------------------------------------------
  model_inputs <- .tempssm_prepare_model_inputs(
    temp_data = temp_data,
    exo_data = exo_data,
    na_action = na_action
  )

  temp_data <- model_inputs$temp_data
  exo_data <- model_inputs$exo_data
  y <- temp_data
  freq <- model_inputs$frequency

  ## ---- Start message ---------------------------------------------------
  .tempssm_cli_debug(
    paste0(
      "Fitting state-space model (",
      "AR order: {ar_order}, ",
      "seasonal: {use_season})"
    )
  )

  .tempssm_cli_debug("Time series frequency: {freq}")

  .tempssm_cli_debug(
    "Optimization settings: maxit={maxit}, reltol={reltol}"
  )

  ## ---- Parameter indexing --------------------------------------------
  param_idx_list <- .get_param_index(
    ar_order = ar_order,
    use_season = use_season
  )

  ar_idx <- param_idx_list$ar
  var_idx <- param_idx_list$var
  H_idx <- param_idx_list$H

  ## ---- Exogenous handling --------------------------------------------
  exogenous <- .prepare_tempssm_exogenous(exo_data)
  exo_name <- exogenous$exo_names
  exo_mat <- exogenous$exo_matrix

  ## ---- Model definition ----------------------------------------------
  build_ssm <- .define_build_model(
    y = y,
    freq = freq,
    use_season = use_season,
    exo_mat = exo_mat,
    ar_order = ar_order
  )

  update_func_common <- .define_update_func(
    y = y,
    freq = freq,
    use_season = use_season,
    exo_mat = exo_mat,
    ar_order = ar_order,
    ar_idx = ar_idx,
    var_idx = var_idx,
    H_idx = H_idx
  )

  ## ---- Optimization and smoothing ------------------------------------
  fitted <- tryCatch(
    .fit_tempssm_kfas(
      build_ssm = build_ssm,
      updatefn = update_func_common,
      inits = inits,
      marginal = marginal,
      maxit = maxit,
      reltol = reltol
    ),
    error = identity
  )

  if (inherits(fitted, "error")) {
    cli::cli_warn(
      "Model fitting failed: {conditionMessage(fitted)}"
    )

    return(.new_tempssm_result(
      model = NULL,
      fit = NULL,
      kfs = NULL,
      temp_data = temp_data,
      exogenous_data = exo_data,
      ar_order = ar_order,
      use_season = use_season,
      marginal = marginal,
      model_call = model_call,
      converged = FALSE,
      exo_names = exo_name,
      state_names = character(0)
    ))
  }

  fit2 <- fitted$fit
  kfs <- fitted$kfs

  ## ---- State names ----------------------------------------------------
  state_names <- .make_tempssm_state_names(
    exo_names = exo_name,
    freq = freq,
    use_season = use_season,
    ar_order = ar_order,
    n_states = ncol(kfs$alphahat)
  )

  ## ---- Output ---------------------------------------------------------
  out <- .new_tempssm_result(
    model = fit2$model,
    fit = fit2,
    kfs = kfs,
    temp_data = temp_data,
    exogenous_data = exo_data,
    ar_order = ar_order,
    use_season = use_season,
    marginal = marginal,
    model_call = model_call,
    converged = fit2$optim.out$convergence == 0,
    exo_names = exo_name,
    state_names = state_names
  )

  ## ---- Completion message --------------------------------------------
  if (out$converged) {
    .tempssm_cli_debug("Model fitting completed successfully")
  } else {
    cli::cli_warn("Model fitting finished but did not converge")
  }

  out
}


#' Internal helper to construct a KFAS state-space model
#'
#' This internal function builds and returns a \code{KFAS::SSModel} object
#' corresponding to the specified model structure. It conditionally includes
#' trend, seasonal, autoregressive, and optional exogenous components,
#' depending on the input arguments.
#'
#' The function is primarily used within \code{tempssm()} to generate the
#' baseline state-space model prior to parameter estimation. Model parameters
#' are left unspecified (set to \code{NA} or zero) and are later updated
#' during optimization via the update function.
#'
#' Four model configurations are supported:
#' \itemize{
#'   \item Trend + Seasonal + AR (no exogenous variables)
#'   \item Trend + AR (no seasonal component)
#'   \item Trend + Seasonal + AR + Exogenous variables
#'   \item Trend + AR + Exogenous variables (no seasonal component)
#' }
#'
#' @param y A numeric vector or univariate \code{ts} object representing
#'   the observed time series.
#' @param freq Integer indicating the seasonal frequency of \code{y}.
#' @inheritParams tempssm
#' @param exo_mat Optional numeric matrix of exogenous regressors.
#'   If provided, each column is treated as a separate covariate.
#'
#' @return A \code{KFAS::SSModel} object with unspecified variance parameters.
#'
#' @details
#' The trend component is modeled as a second-order polynomial trend.
#' The seasonal component (if included) uses a dummy-variable formulation
#' with a sum-to-zero constraint. The autoregressive component is implemented
#' via \code{SSMarima()} with coefficients initialized to zero.
#'
#' @keywords internal
#' @noRd
.define_build_model <- function(y = NULL,
                                freq = freq,
                                use_season,
                                exo_mat,
                                ar_order = 1) {
  if (use_season && is.null(exo_mat)) {
    build_ssm <- KFAS::SSModel(
      y ~
        SSMtrend(
          degree = 2,
          Q = c(list(0), list(NA))
        ) +
        SSMseasonal(
          sea.type = "dummy",
          period = freq,
          Q = NA
        ) +
        SSMarima(
          ar = rep(0, ar_order),
          d = 0,
          Q = NA
        ),
      H = NA
    )
  } else if (!use_season && is.null(exo_mat)) {
    build_ssm <- KFAS::SSModel(
      y ~
        SSMtrend(
          degree = 2,
          Q = c(list(0), list(NA))
        ) +
        SSMarima(
          ar = rep(0, ar_order),
          d = 0,
          Q = NA
        ),
      H = NA
    )
  } else if (use_season && !(is.null(exo_mat))) {
    build_ssm <- KFAS::SSModel(
      H = NA,
      y ~ exo_mat +
        SSMtrend(
          degree = 2,
          Q = c(list(0), list(NA))
        ) +
        SSMseasonal(
          sea.type = "dummy",
          period = freq,
          Q = NA
        ) +
        SSMarima(
          ar = rep(0, ar_order),
          d = 0,
          Q = NA
        )
    )
  } else if (!use_season && !(is.null(exo_mat))) {
    build_ssm <- KFAS::SSModel(
      H = NA,
      y ~ exo_mat +
        SSMtrend(
          degree = 2,
          Q = c(list(0), list(NA))
        ) +
        SSMarima(
          ar = rep(0, ar_order),
          d = 0,
          Q = NA
        )
    )
  }
  return(build_ssm)
}


#' Internal helper to generate the parameter update function for KFAS
#'
#' This internal function constructs and returns an update function to be used
#' in \code{KFAS::fitSSM()}, which maps an unconstrained parameter vector
#' to a valid state-space model.
#'
#' The returned function takes model parameters on an unconstrained scale
#' and transforms them to enforce constraints such as:
#' \itemize{
#'   \item Variance parameters are exponentiated to ensure positivity
#'   \item Autoregressive coefficients are transformed using
#'         \code{KFAS::artransform()} to ensure stationarity
#' }
#'
#' The structure of the update function depends on whether seasonal and/or
#' exogenous components are included, ensuring consistency with the model
#' defined in \code{.define_build_model()}.
#'
#' @inheritParams .define_build_model
#' @param freq Integer indicating the seasonal frequency.
#' @inheritParams tempssm
#' @param exo_mat Optional matrix of exogenous regressors.
#' @param ar_idx Integer vector indicating positions of AR coefficients
#'   in the parameter vector.
#' @param var_idx Integer indicating the position of the AR process variance.
#' @param H_idx Integer indicating the position of the observation variance.
#'
#' @return A function with signature \code{function(pars, model)} suitable
#'   for use in \code{KFAS::fitSSM()}.
#'
#' @details
#' The returned function rebuilds the full state-space model using the
#' transformed parameters. It ensures that all variance parameters are positive
#' and that the autoregressive process satisfies stationarity constraints.
#'
#' This closure-based design allows efficient reuse of model structure during
#' numerical optimization without reconstructing external inputs.
#'
#' @keywords internal
#' @noRd
.define_update_func <- function(y = NULL,
                                freq = freq,
                                use_season,
                                exo_mat,
                                ar_order = 1,
                                ar_idx,
                                var_idx,
                                H_idx) {
  if (use_season && is.null(exo_mat)) {
    update_func <- function(pars, model) {
      trans <- .transform_parameters(pars, ar_idx, var_idx, H_idx, use_season)
      return(
        KFAS::SSModel(
          y ~
            SSMtrend(
              degree = 2,
              Q = c(list(0), list(trans$trend_var))
            ) +
            SSMseasonal(
              sea.type = "dummy",
              period = freq,
              Q = trans$season_var
            ) +
            SSMarima(
              ar = trans$ar_coefs,
              d = 0,
              Q = trans$ar_var
            ),
          H = trans$H
        )
      )
    }
  } else if (!use_season && is.null(exo_mat)) {
    update_func <- function(pars, model) {
      trans <- .transform_parameters(pars, ar_idx, var_idx, H_idx, use_season)
      return(
        KFAS::SSModel(
          y ~
            SSMtrend(
              degree = 2,
              Q = c(list(0), list(trans$trend_var))
            ) +
            SSMarima(
              ar = trans$ar_coefs,
              d = 0,
              Q = trans$ar_var
            ),
          H = trans$H
        )
      )
    }
  } else if (use_season && !(is.null(exo_mat))) {
    update_func <- function(pars, model) {
      trans <- .transform_parameters(pars, ar_idx, var_idx, H_idx, use_season)
      return(
        KFAS::SSModel(
          H = trans$H,
          y ~ exo_mat +
            SSMtrend(
              degree = 2,
              Q = c(list(0), list(trans$trend_var))
            ) +
            SSMseasonal(
              sea.type = "dummy",
              period = freq,
              Q = trans$season_var
            ) +
            SSMarima(
              ar = trans$ar_coefs,
              d = 0,
              Q = trans$ar_var
            )
        )
      )
    }
  } else if (!use_season && !(is.null(exo_mat))) {
    update_func <- function(pars, model) {
      trans <- .transform_parameters(pars, ar_idx, var_idx, H_idx, use_season)
      return(
        KFAS::SSModel(
          H = trans$H,
          y ~ exo_mat +
            SSMtrend(
              degree = 2,
              Q = c(list(0), list(trans$trend_var))
            ) +
            SSMarima(
              ar = trans$ar_coefs,
              d = 0,
              Q = trans$ar_var
            )
        )
      )
    }
  }
}


#' Check ts object of temperature time series for applying \code{tempssm()}
#'
#' @inheritParams tempssm
#'
#' @return A univariate \code{ts} object.
#'
#' @keywords internal
#' @noRd
.tempssm_check_temp_ts <- function(temp_data) {
  ## ---- type check -----------------------------------------------------
  if (!inherits(temp_data, "ts")) {
    cli::cli_abort(
      "The object {.arg temp_data} must be a {.cls ts} object."
    )
  }

  temp_data <- .strip_units_ts(temp_data, arg_name = "temp_data")
  if (!is.numeric(temp_data)) {
    cli::cli_abort(
      "The object {.arg temp_data} must contain numeric values."
    )
  }
  .tempssm_check_no_undefined(temp_data, "temp_data")

  ## ---- frequency check ------------------------------------------------
  freq <- frequency(temp_data)
  freq_int <- as.integer(round(freq))

  if (freq <= 1 || abs(freq - freq_int) > sqrt(.Machine$double.eps)) {
    cli::cli_abort(
      "The procedure requires a {.cls ts} object with integer frequency > 1."
    )
  }

  ## ---- time order check ----------------------------------------------
  .tempssm_check_ts_order(temp_data, arg_name = "temp_data")

  ## ---- univariate check ----------------------------------------------
  .tempssm_check_univariate_ts(temp_data, "temp_data")

  ## ---- debug message --------------------------------------------------
  .tempssm_cli_debug(
    "Validated temp_data: univariate ts with frequency {freq}"
  )

  return(temp_data)
}


#' Check strict ordering of a \code{ts} time index
#'
#' @inheritParams .tempssm_check_length_one
#' @param x A \code{ts} object.
#'
#' @return Invisibly returns \code{x}.
#'
#' @keywords internal
#' @noRd
.tempssm_check_ts_order <- function(x, arg_name) {
  time_index <- time(x)

  if (length(time_index) > 1 && any(diff(time_index) <= 0)) {
    cli::cli_abort(
      "Time index of {.arg {arg_name}} must be strictly increasing."
    )
  }

  invisible(x)
}


#' Build a message for missing values in the response temperature series
#'
#' @param x A \code{ts} object containing the response temperature series.
#'
#' @return A named character vector for \pkg{cli} condition functions.
#'
#' @keywords internal
#' @noRd
.tempssm_missing_temp_message <- function(x) {
  n_total <- length(as.numeric(x))
  n_missing <- sum(is.na(x))
  pct_missing <- 100 * n_missing / n_total

  msg <- c(
    "The input temperature series includes missing values.",
    paste0(
      "Series length: ", n_total,
      "; missing values: ", n_missing,
      " (", sprintf("%.1f", pct_missing), "%)."
    ),
    paste0(
      "This is supported: missing responses are retained and treated as ",
      "unobserved responses during Kalman filtering and smoothing."
    )
  )
  names(msg) <- c("", "i", "i")
  msg
}


#' Handle explicit missing values in a \code{ts} object
#'
#' @inheritParams .tempssm_check_ts_order
#' @param na_action Missing-value handling policy.
#'
#' @return Invisibly returns \code{x}.
#'
#' @keywords internal
#' @noRd
.tempssm_handle_missing_ts <- function(x, arg_name, na_action) {
  if (!anyNA(x)) {
    return(invisible(x))
  }

  if (all(is.na(x))) {
    cli::cli_abort(
      "{.arg {arg_name}} must contain at least one non-missing value."
    )
  }

  if (identical(na_action, "error")) {
    cli::cli_abort(
      c(
        "The input temperature series includes missing values.",
        "x" = "{.arg na_action} is set to {.val error}.",
        "i" = paste0(
          "Remove or impute missing response values before fitting the ",
          "model, or use another {.arg na_action} policy."
        )
      )
    )
  }

  msg <- .tempssm_missing_temp_message(x)

  if (identical(na_action, "inform")) {
    .tempssm_cli_inform(msg)
  }

  if (identical(na_action, "warn")) {
    cli::cli_warn(msg)
  }

  invisible(x)
}


#' Check ts object of exogenous variable(s) for applying \code{tempssm()}
#'
#' @inheritParams tempssm
#'
#' @return A univariate or multivariate \code{ts} object.
#'
#' @keywords internal
#' @noRd
.tempssm_check_exo_ts <- function(temp_data,
                                  exo_data) {
  ## ---- check temp_data -----------------------------------------------
  temp_data_checked <- .tempssm_check_temp_ts(temp_data)
  temp_freq <- frequency(temp_data_checked)

  ## ---- type check -----------------------------------------------------
  if (!inherits(exo_data, "ts")) {
    cli::cli_abort(
      "The object {.arg exo_data} must be a {.cls ts} object."
    )
  }

  exo_data <- .strip_units_ts(exo_data, arg_name = "exo_data")
  if (!is.numeric(exo_data)) {
    cli::cli_abort(
      "The object {.arg exo_data} must contain numeric values."
    )
  }
  .tempssm_check_no_undefined(exo_data, "exo_data")

  ## ---- frequency check ------------------------------------------------
  exo_freq <- frequency(exo_data)
  if (!isTRUE(all.equal(exo_freq, temp_freq))) {
    cli::cli_abort(
      "Frequency of {.arg exo_data} must match that of {.arg temp_data}."
    )
  }

  ## ---- time order check ----------------------------------------------
  .tempssm_check_ts_order(exo_data, arg_name = "exo_data")

  ## ---- length check ---------------------------------------------------
  if (NROW(exo_data) != NROW(temp_data_checked)) {
    cli::cli_abort(
      "Length of {.arg exo_data} must match that of {.arg temp_data}."
    )
  }

  ## ---- time index check ----------------------------------------------
  if (!isTRUE(all.equal(time(exo_data), time(temp_data_checked)))) {
    cli::cli_abort(
      "Time index of {.arg exo_data} must match that of {.arg temp_data}."
    )
  }

  ## ---- dimensionality check ------------------------------------------
  n_col <- NCOL(exo_data)
  n_obs <- NROW(temp_data_checked)
  if (n_col > n_obs) {
    cli::cli_abort(
      paste0(
        "The number of exogenous variables must not exceed ",
        "the number of observations."
      )
    )
  }

  ## ---- column names check --------------------------------------------
  if (is.null(colnames(exo_data))) {
    cli::cli_abort(
      "The object {.arg exo_data} must have column name(s)."
    )
  }

  ## ---- debug message --------------------------------------------------
  uni_multi <- if (n_col > 1) "multivariate" else "univariate"

  .tempssm_cli_debug(
    paste0(
      "Validated exo_data: {uni_multi} ts with {n_col} variable{?s}, ",
      "frequency {exo_freq}"
      )
   )

  return(exo_data)
}


#' Validate and standardize model time-series inputs
#'
#' @inheritParams tempssm
#' @param allow_unnamed_exo Logical; if \code{TRUE}, unnamed exogenous
#'   variables are allowed after assigning default names.
#' @param default_exo_names Logical; if \code{TRUE}, default names are assigned
#'   to unnamed exogenous variables.
#'
#' @return A named list containing validated \code{temp_data}, validated or
#'   \code{NULL} \code{exo_data}, the common frequency, and the number of
#'   observations.
#'
#' @keywords internal
#' @noRd
.tempssm_prepare_model_inputs <- function(temp_data,
                                          exo_data = NULL,
                                          allow_unnamed_exo = FALSE,
                                          default_exo_names = FALSE,
                                          na_action = c("inform",
                                                        "warn",
                                                        "error",
                                                        "allow")) {
  na_action <- match.arg(na_action)

  temp_data <- .tempssm_check_temp_ts(temp_data)
  .tempssm_handle_missing_ts(
    temp_data,
    arg_name = "temp_data",
    na_action = na_action
  )

  if (!is.null(exo_data) && is.null(colnames(exo_data))) {
    if (!allow_unnamed_exo || !default_exo_names) {
      cli::cli_abort(
        "The object {.arg exo_data} must have column name(s)."
      )
    }

    cli::cli_warn(
      "No column names in {.arg exo_data}; assigning default names."
    )
    exo_data <- tempssm::set_ts_name(
      exo_data,
      label = paste0("var", seq_len(NCOL(exo_data))),
      quiet = TRUE
    )
  }

  if (!is.null(exo_data)) {
    exo_data <- .tempssm_check_exo_ts(
      temp_data = temp_data,
      exo_data = exo_data
    )
    if (anyNA(exo_data)) {
      cli::cli_abort(
        c(
          "Missing values detected in {.arg exo_data}.",
          "i" = paste0(
            "Exogenous covariates must be complete for KFAS regression ",
            "terms."
          ),
          "*" = paste0(
            "Please impute, remove, or otherwise complete missing ",
            "exogenous values before calling {.fn tempssm}."
          )
        )
      )
    }
  }

  list(
    temp_data = temp_data,
    exo_data = exo_data,
    frequency = frequency(temp_data),
    n_obs = length(temp_data)
  )
}
