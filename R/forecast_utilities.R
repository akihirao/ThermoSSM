#' Forecast from a fitted tempssm model
#'
#' Produces forecasts after the end of the observed sample from a fitted
#' `tempssm` model. By default, the method returns the forecast for the next
#' single time point.
#'
#' @param object A fitted object of class `"tempssm"` returned by
#'   [tempssm()].
#' @param n.ahead Positive integer giving the forecast horizon. The default is
#'   one time point. For a model with exogenous variables, the horizon is
#'   inferred from `new_exo_data` when `n.ahead` is omitted.
#' @param new_exo_data Optional future exogenous variables as a univariate or
#'   multivariate `ts` object. It is required for a model fitted with
#'   exogenous variables and must continue directly after the fitted response
#'   series, with matching frequency, column names, and column order.
#' @param exo_strategy Character scalar specifying how future exogenous values
#'   are obtained. The default, `"provided"`, requires `new_exo_data` for an
#'   exogenous model. `"last"` enables a one-step persistence forecast by
#'   carrying each exogenous variable's final observed value forward.
#' @param interval Character scalar specifying the interval type. One of
#'   `"none"`, `"confidence"`, or `"prediction"`.
#' @param level Numeric scalar between 0 and 1 specifying the confidence level
#'   used when `interval` is not `"none"`.
#' @param ... Additional arguments passed to the KFAS prediction method via
#'   [stats::predict()].
#'
#' @return For `interval = "none"`, a univariate `ts` object of point
#'   forecasts. When intervals are requested, a multivariate `ts` object with
#'   columns `fit`, `lwr`, and `upr`.
#'
#' @details
#' Forecasts begin at the first regular time point after the end of
#' `object$temp_data`. They account for uncertainty in the estimated
#' state conditional on the fitted model parameters, but not parameter
#' estimation uncertainty.
#'
#' When `interval = "confidence"`, the returned lower and upper bounds describe
#' uncertainty in the predicted mean response. When
#' `interval = "prediction"`, the bounds describe uncertainty in a future
#' observation and therefore also include observation error. Prediction
#' intervals are usually wider than confidence intervals. The interval level is
#' controlled by `level` and defaults to 0.95.
#'
#' For a model fitted with exogenous variables, `new_exo_data` must provide
#' known or assumed future covariate values. Missing or non-finite future
#' values are rejected; the method never assumes zero-valued covariates.
#' As a simplified alternative for one-step forecasting,
#' `exo_strategy = "last"` implements last observation carried forward. This
#' is a persistence assumption, not a forecast model for the covariates.
#' Resulting intervals are conditional on those fixed exogenous values and do
#' not include uncertainty about their future evolution.
#'
#' This method produces forecasts beyond the end of the sample. It does not
#' return in-sample one-step-ahead predictions.
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#' res <- tempssm(sst_niigata)
#'
#' # Forecast the next time point
#' predict(res)
#'
#' # Forecast the next 12 time points with prediction intervals
#' predict(res, n.ahead = 12, interval = "prediction", level = 0.95)
#'
#' # Models with exogenous variables require future covariate values
#' exo <- ts(
#'   matrix(seq_along(sst_niigata), ncol = 1),
#'   start = start(sst_niigata),
#'   frequency = frequency(sst_niigata)
#' )
#' colnames(exo) <- "index"
#' res_exo <- tempssm(sst_niigata, exo_data = exo)
#' exo_next <- ts(
#'   matrix(NROW(exo) + 1, ncol = 1, dimnames = list(NULL, "index")),
#'   start = tsp(exo)[2] + 1 / frequency(exo),
#'   frequency = frequency(exo)
#' )
#' predict(res_exo, new_exo_data = exo_next)
#'
#' # Simplified one-step forecast under a persistence assumption
#' predict(res_exo, exo_strategy = "last")
#' }
#'
#' @method predict tempssm
#' @export
predict.tempssm <- function(object,
                            n.ahead = 1L,
                            new_exo_data = NULL,
                            exo_strategy = c("provided", "last"),
                            interval = c(
                              "none",
                              "confidence",
                              "prediction"
                            ),
                            level = 0.95,
                            ...) {
  exo_strategy <- match.arg(exo_strategy)
  request <- .prepare_tempssm_forecast(
    object = object,
    n.ahead = n.ahead,
    n_ahead_missing = missing(n.ahead),
    new_exo_data = new_exo_data,
    exo_strategy = exo_strategy,
    level = level
  )
  interval <- match.arg(interval)

  .predict_tempssm_backend(
    object = object,
    n.ahead = request$n.ahead,
    new_exo_data = request$new_exo_data,
    interval = interval,
    level = level,
    ...
  )
}


#' Prepare a forecast request for a tempssm model
#'
#' @inheritParams predict.tempssm
#' @param n_ahead_missing Logical indicating whether `n.ahead` was omitted.
#'
#' @return A list containing the forecast horizon and future exogenous data.
#'
#' @keywords internal
#' @noRd
.prepare_tempssm_forecast <- function(object,
                                      n.ahead,
                                      n_ahead_missing,
                                      new_exo_data,
                                      exo_strategy,
                                      level) {
  if (!inherits(object, "tempssm")) {
    cli::cli_abort(
      "{.arg object} must be an object of class {.cls tempssm}."
    )
  }

  if (!isTRUE(object$converged) || is.null(object$model)) {
    cli::cli_abort(
      "Forecasting requires a converged {.cls tempssm} model."
    )
  }

  has_exogenous <- !is.null(object$exogenous_data)
  if (!has_exogenous && !identical(exo_strategy, "provided")) {
    cli::cli_abort(
      "{.arg exo_strategy} can only be used with an exogenous model."
    )
  }
  if (identical(exo_strategy, "last") && !is.null(new_exo_data)) {
    cli::cli_abort(
      paste0(
        "{.arg new_exo_data} must be {.code NULL} when ",
        "{.code exo_strategy = \"last\"}."
      )
    )
  }
  if (has_exogenous && identical(exo_strategy, "provided") &&
      is.null(new_exo_data)) {
    cli::cli_abort(
      "{.arg new_exo_data} is required for a model with exogenous variables."
    )
  }
  if (!has_exogenous && !is.null(new_exo_data)) {
    cli::cli_abort(
      paste0(
        "{.arg new_exo_data} must be {.code NULL} because the model ",
        "was fitted without exogenous variables."
      )
    )
  }

  if (has_exogenous && n_ahead_missing) {
    n.ahead <- if (identical(exo_strategy, "last")) {
      1L
    } else {
      NROW(new_exo_data)
    }
  }
  .validate_tempssm_forecast_controls(n.ahead, level)

  if (has_exogenous) {
    if (identical(exo_strategy, "last")) {
      if (n.ahead != 1L) {
        cli::cli_abort(
          "{.code exo_strategy = \"last\"} is limited to one-step forecasts."
        )
      }
      new_exo_data <- .make_last_exogenous_forecast(object)
      .tempssm_cli_inform(c(
        "Using the last observed exogenous value for one-step forecasting.",
        "i" = "This applies a persistence assumption to future covariates."
      ))
    }
    new_exo_data <- .validate_tempssm_future_exogenous(
      object,
      new_exo_data,
      n.ahead
    )
  }

  list(n.ahead = as.integer(n.ahead), new_exo_data = new_exo_data)
}


#' Carry the final exogenous observation forward by one time point
#'
#' @inheritParams predict.tempssm
#'
#' @return A one-row `ts` object with the fitted exogenous column structure.
#'
#' @keywords internal
#' @noRd
.make_last_exogenous_forecast <- function(object) {
  fitted_exogenous <- object$exogenous_data
  last_values <- fitted_exogenous[
    NROW(fitted_exogenous),
    ,
    drop = FALSE
  ]
  frequency <- stats::frequency(fitted_exogenous)
  fitted_time <- as.numeric(stats::time(fitted_exogenous))
  next_time <- fitted_time[length(fitted_time)] + 1 / frequency

  stats::ts(
    as.matrix(last_values),
    start = next_time,
    frequency = frequency
  )
}


#' Validate controls for a tempssm forecast
#'
#' @inheritParams predict.tempssm
#'
#' @return Invisibly returns `NULL`.
#'
#' @keywords internal
#' @noRd
.validate_tempssm_forecast_controls <- function(n.ahead, level) {
  valid_horizon <- is.numeric(n.ahead) &&
    length(n.ahead) == 1L &&
    !is.na(n.ahead) &&
    is.finite(n.ahead) &&
    .tempssm_is_integerish(n.ahead) &&
    n.ahead >= 1
  if (!valid_horizon) {
    cli::cli_abort(
      "{.arg n.ahead} must be a single positive integer."
    )
  }

  valid_level <- is.numeric(level) &&
    length(level) == 1L &&
    !is.na(level) &&
    is.finite(level) &&
    level > 0 &&
    level < 1
  if (!valid_level) {
    cli::cli_abort(
      "{.arg level} must be a single finite number between 0 and 1."
    )
  }

  invisible(NULL)
}


#' Validate future exogenous data for forecasting
#'
#' @inheritParams predict.tempssm
#'
#' @return A validated `ts` object of future exogenous values.
#'
#' @keywords internal
#' @noRd
.validate_tempssm_future_exogenous <- function(object,
                                               new_exo_data,
                                               n.ahead) {
  if (!inherits(new_exo_data, "ts")) {
    cli::cli_abort(
      "{.arg new_exo_data} must be a {.cls ts} object."
    )
  }
  if (!is.numeric(new_exo_data)) {
    cli::cli_abort(
      "{.arg new_exo_data} must contain numeric values."
    )
  }
  if (anyNA(new_exo_data) || !all(is.finite(new_exo_data))) {
    cli::cli_abort(
      "{.arg new_exo_data} must not contain missing or non-finite values."
    )
  }
  if (NROW(new_exo_data) != n.ahead) {
    cli::cli_abort(
      "The number of rows in {.arg new_exo_data} must equal {.arg n.ahead}."
    )
  }

  fitted_exogenous <- object$exogenous_data
  if (NCOL(new_exo_data) != NCOL(fitted_exogenous)) {
    cli::cli_abort(
      "{.arg new_exo_data} must have {NCOL(fitted_exogenous)} column{?s}."
    )
  }
  if (!identical(colnames(new_exo_data), colnames(fitted_exogenous))) {
    cli::cli_abort(
      paste0(
        "Column names and order of {.arg new_exo_data} must match ",
        "the fitted exogenous variables."
      )
    )
  }

  fitted_frequency <- stats::frequency(object$temp_data)
  if (!isTRUE(all.equal(
    stats::frequency(new_exo_data),
    fitted_frequency
  ))) {
    cli::cli_abort(
      "Frequency of {.arg new_exo_data} must match the fitted data."
    )
  }

  fitted_time <- as.numeric(stats::time(object$temp_data))
  fitted_end <- fitted_time[length(fitted_time)]
  expected_time <- fitted_end +
    seq_len(n.ahead) / fitted_frequency
  if (!isTRUE(all.equal(
    as.numeric(stats::time(new_exo_data)),
    as.numeric(expected_time)
  ))) {
    cli::cli_abort(
      paste0(
        "{.arg new_exo_data} must begin at the first time point after ",
        "the fitted data and be regularly spaced."
      )
    )
  }

  new_exo_data
}


#' Forecast through the appropriate tempssm backend
#'
#' @inheritParams predict.tempssm
#'
#' @return An object returned by `stats::predict()`.
#'
#' @keywords internal
#' @noRd
.predict_tempssm_backend <- function(object,
                                     n.ahead,
                                     new_exo_data = NULL,
                                     interval = "none",
                                     level = 0.95,
                                     ...) {
  if (is.null(new_exo_data)) {
    return(.predict_no_exo(
      model = object$model,
      h = n.ahead,
      interval = interval,
      level = level,
      ...
    ))
  }

  .predict_with_exo(
    res = object,
    exo_test = new_exo_data,
    interval = interval,
    level = level,
    ...
  )
}


#' Generate forecasts with exogenous variables
#'
#' @inheritParams get_level_ts
#' @param exo_test Future exogenous data as a `ts` object.
#' @inheritParams predict.tempssm
#'
#' @return An object returned by `stats::predict()`.
#'
#' @keywords internal
#' @noRd
.predict_with_exo <- function(res,
                              exo_test,
                              interval = "none",
                              level = 0.95,
                              ...) {
  if (!inherits(res, "tempssm") ||
      is.null(res$model) ||
      is.null(res$fit$optim.out$par)) {
    cli::cli_abort("{.arg res} must be a fitted {.cls tempssm} object.")
  }

  newdata <- .build_newdata_ssm(
    pars = res$fit$optim.out$par,
    exo_mat = as.matrix(exo_test),
    n_ahead = NROW(exo_test),
    freq = stats::frequency(res$temp_data),
    ar_order = res$ar_order,
    use_season = res$use_season
  )

  stats::predict(
    res$model,
    newdata = newdata,
    interval = interval,
    level = level,
    ...
  )
}


#' Trim forecast intervals by maximum interval width
#'
#' Trims forecast or prediction intervals to the longest leading forecast
#' horizon for which the interval width remains within a user-specified
#' threshold.
#'
#' @param pred A matrix-like object, data frame, or multivariate \code{ts}
#'   object containing prediction interval columns named \code{"lwr"} and
#'   \code{"upr"}. This matches the object returned by
#'   \code{stats::predict(..., interval = "prediction")} for the KFAS model
#'   used by \code{tempssm()}.
#' @param max_width Numeric scalar giving the maximum permitted interval width,
#'   calculated as \code{upr - lwr}.
#'
#' @return An object of the same basic class as \code{pred}, truncated to the
#'   longest leading sequence whose prediction interval width is less than or
#'   equal to \code{max_width}. If \code{pred} is a \code{ts} object and at
#'   least one row is retained, the returned object preserves its time scale.
#'   A zero-row result is returned as a matrix because base R does not support
#'   zero-length \code{ts} objects.
#'
#' @details
#' Forecast uncertainty in state-space models generally increases with forecast
#' horizon because future observations depend on accumulated state and
#' observation uncertainty. This helper provides a simple post-processing rule:
#' retain forecasts only until their prediction interval width exceeds a
#' user-defined error margin. It does not modify forecast means, lower bounds,
#' or upper bounds; it only truncates the returned forecast horizon.
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#' res <- tempssm(sst_niigata, na_action = "allow")
#' pred <- stats::predict(
#'   res$model,
#'   n.ahead = 24,
#'   interval = "prediction",
#'   level = 0.95
#' )
#'
#' trim_prediction_intervals(pred, max_width = 4)
#' }
#'
#' @export
trim_prediction_intervals <- function(pred, max_width) {
  .validate_max_interval_width(max_width)
  interval_width <- .validate_prediction_intervals(pred)
  keep_n <- .prediction_interval_keep_n(interval_width, max_width)

  .slice_prediction_intervals(pred, keep_n)
}


#' Validate the maximum permitted prediction interval width
#'
#' @param max_width Numeric scalar giving the maximum interval width.
#'
#' @return Invisibly returns \code{max_width}.
#'
#' @keywords internal
#' @noRd
.validate_max_interval_width <- function(max_width) {
  valid <- is.numeric(max_width) &&
    length(max_width) == 1L &&
    !is.na(max_width) &&
    is.finite(max_width) &&
    max_width >= 0

  if (!valid) {
    cli::cli_abort(
      "{.arg max_width} must be a single non-negative finite number."
    )
  }

  invisible(max_width)
}


#' Validate prediction intervals and calculate their widths
#'
#' @param pred A matrix-like prediction interval object.
#'
#' @return A numeric vector containing interval widths.
#'
#' @keywords internal
#' @noRd
.validate_prediction_intervals <- function(pred) {
  .validate_prediction_interval_structure(pred)

  lower <- pred[, "lwr"]
  upper <- pred[, "upr"]
  .validate_prediction_interval_types(lower, upper)
  .validate_prediction_interval_finiteness(lower, upper)
  .validate_prediction_interval_order(lower, upper)

  as.numeric(upper - lower)
}


#' Validate the structure of a prediction interval object
#'
#' @param pred A matrix-like prediction interval object.
#'
#' @return Invisibly returns \code{pred}.
#'
#' @keywords internal
#' @noRd
.validate_prediction_interval_structure <- function(pred) {
  if (is.null(dim(pred))) {
    cli::cli_abort("{.arg pred} must be a matrix-like object.")
  }

  pred_names <- colnames(pred)
  if (is.null(pred_names) || !all(c("lwr", "upr") %in% pred_names)) {
    cli::cli_abort(
      "{.arg pred} must contain columns named {.val lwr} and {.val upr}."
    )
  }

  invisible(pred)
}


#' Validate prediction interval column types
#'
#' @param lower Numeric vector of lower interval bounds.
#' @param upper Numeric vector of upper interval bounds.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @keywords internal
#' @noRd
.validate_prediction_interval_types <- function(lower, upper) {
  if (!is.numeric(lower) || !is.numeric(upper)) {
    cli::cli_abort(
      "The {.val lwr} and {.val upr} columns of {.arg pred} must be numeric."
    )
  }

  invisible(NULL)
}


#' Validate that prediction interval bounds are finite
#'
#' @inheritParams .validate_prediction_interval_types
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @keywords internal
#' @noRd
.validate_prediction_interval_finiteness <- function(lower, upper) {
  if (anyNA(lower) || anyNA(upper) ||
      !all(is.finite(lower)) || !all(is.finite(upper))) {
    cli::cli_abort(
      "Columns {.val lwr} and {.val upr} in {.arg pred} must be finite."
    )
  }

  invisible(NULL)
}


#' Validate prediction interval bound ordering
#'
#' @inheritParams .validate_prediction_interval_types
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @keywords internal
#' @noRd
.validate_prediction_interval_order <- function(lower, upper) {
  if (any(lower > upper)) {
    cli::cli_abort(
      "Each {.val lwr} value must be less than or equal to {.val upr}."
    )
  }

  invisible(NULL)
}


#' Find the length of the leading acceptable prediction horizon
#'
#' @param interval_width Numeric vector of prediction interval widths.
#' @inheritParams trim_prediction_intervals
#'
#' @return An integer giving the number of leading rows to retain.
#'
#' @keywords internal
#' @noRd
.prediction_interval_keep_n <- function(interval_width, max_width) {
  first_exceed <- match(TRUE, interval_width > max_width)

  if (is.na(first_exceed)) {
    return(length(interval_width))
  }

  first_exceed - 1L
}


#' Slice a prediction interval object to a leading horizon
#'
#' @inheritParams trim_prediction_intervals
#' @param keep_n Number of leading rows to retain.
#'
#' @return A prediction interval object truncated to \code{keep_n} rows.
#'
#' @keywords internal
#' @noRd
.slice_prediction_intervals <- function(pred, keep_n) {
  if (keep_n == NROW(pred)) {
    return(pred)
  }

  if (inherits(pred, "ts") && keep_n > 0L) {
    return(stats::window(pred, end = stats::time(pred)[keep_n]))
  }

  pred[seq_len(keep_n), , drop = FALSE]
}
