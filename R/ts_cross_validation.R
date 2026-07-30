#' Safely fit tempssm model with error handling
#'
#' Internal helper function to fit a \code{tempssm} model while
#' gracefully handling errors. If model fitting fails, a warning
#' is issued and \code{NULL} is returned.
#'
#' @param y_train A named temperature \code{ts} object used for training.
#' @param exo_train Optional \code{ts} object of exogenous variables.
#' @inheritParams tempssm
#' @param fold_id Identifier for the current cross-validation fold.
#'
#' @return A \code{tempssm} object if successful, otherwise \code{NULL}.
#'
#' @keywords internal
#' @noRd
.fit_tempssm_safe <- function(y_train,
                              exo_train,
                              ar_order,
                              use_season,
                              fold_id,
                              marginal) {
  tryCatch(
    tempssm(
      temp_data = y_train,
      exo_data = exo_train,
      ar_order = ar_order,
      use_season = use_season,
      marginal = marginal
    ),
    error = function(e) {
      cli::cli_warn(
        "Model fitting failed in fold {fold_id}: {conditionMessage(e)}"
      )
      NULL
    }
  )
}


#' Handle non-converged tempssm results in CV fold
#'
#' Internal helper to check convergence of a fitted \code{tempssm} model
#' within a cross-validation fold. If the model did not converge or fitting
#' failed, a warning is issued and a standardized result list is returned.
#'
#' @param res A \code{tempssm} object or \code{NULL}.
#' @param fold A fold object containing at least \code{fold}.
#' @param y_train Training time series.
#' @param y_test Test time series.
#'
#' @return If non-converged, a list with \code{converged = FALSE}.
#'   Otherwise, \code{NULL}.
#'
#' @keywords internal
#' @noRd
.handle_non_convergence <- function(res, fold, y_train, y_test) {
  if (is.null(res) || !isTRUE(res$converged)) {
    cli::cli_warn("Model did not converge for fold {fold$fold}")

    model <- if (!is.null(res)) res$model else NULL
    return(.new_ts_cv_fold_result(
      fold_id = fold$fold,
      converged = FALSE,
      y_train = y_train,
      y_test = y_test,
      model = model
    ))
  }
  NULL
}


#' Generate forecasts without exogenous variables
#'
#' Internal helper to produce forecasts from a fitted model when
#' no exogenous variables are present. This function simply calls
#' \code{stats::predict()} with \code{n.ahead}.
#'
#' @param model A fitted model object (typically \code{SSModel} 
#' from \code{tempssm}).
#' @param h Integer; forecast horizon.
#' @param interval Character scalar specifying the interval type.
#' @param level Numeric scalar specifying the interval confidence level.
#' @param ... Additional arguments passed to [stats::predict()].
#'
#' @return An object returned by \code{stats::predict()}.
#'
#' @keywords internal
#' @noRd
.predict_no_exo <- function(model,
                            h,
                            interval = "none",
                            level = 0.95,
                            ...) {
  stats::predict(
    model,
    n.ahead = h,
    interval = interval,
    level = level,
    ...
  )
}


#' Build SSModel for prediction with exogenous variables
#'
#' Internal helper to construct a \code{KFAS::SSModel} object for
#' a future period using estimated parameters. It is shared by direct
#' forecasting and cross-validation with exogenous variables.
#'
#' The function maps a parameter vector (on unconstrained scale)
#' to a fully specified state-space model, applying appropriate
#' transformations:
#' \itemize{
#'   \item Variances are exponentiated to ensure positivity
#'   \item AR coefficients are transformed using \code{artransform()}
#' }
#'
#' The model structure depends on whether a seasonal component is included.
#'
#' @param pars Numeric vector of model parameters.
#' @param exo_mat Matrix of exogenous variables for the test period.
#' @param n_ahead Integer forecast horizon.
#' @param freq Integer; seasonal frequency.
#' @inheritParams tempssm
#'
#' @return A \code{KFAS::SSModel} object.
#'
#' @keywords internal
#' @noRd
.build_newdata_ssm <- function(pars,
                               exo_mat,
                               n_ahead,
                               freq,
                               ar_order,
                               use_season) {
  if (NROW(exo_mat) != n_ahead) {
    cli::cli_abort(
      "`exo_mat` must have `n_ahead` rows."
    )
  }

  y_new <- rep(NA_real_, n_ahead)
  
  ## ---- Parameter indexing ------------------------------------------
  param_idx_list <- .get_param_index(ar_order = ar_order,
                                     use_season = use_season)
  
  ar_idx <- param_idx_list$ar
  var_idx <- param_idx_list$var
  H_idx <- param_idx_list$H
  
  ## ---- Transform parameters -------------------------------------------
  trans <- .transform_parameters(pars, ar_idx, var_idx, H_idx, use_season)
  
  ## ---- Build model -------
  if (use_season) {

    SSModel(
      H = trans$H,
      y_new ~ exo_mat +
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
  } else {

    SSModel(
      H = trans$H,
      y_new ~ exo_mat +
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
  }
}


#' Prepare model controls for time-series cross-validation
#'
#' @inheritParams tempssm
#'
#' @return A named list containing validated model controls.
#'
#' @keywords internal
#' @noRd
.prepare_ts_cv_model_controls <- function(ar_order,
                                          use_season,
                                          marginal) {
  .validate_ar_order(ar_order)
  .validate_use_season(use_season)
  .validate_marginal(marginal)

  list(
    ar_order = ar_order,
    use_season = use_season,
    marginal = marginal
  )
}


#' Validate the basic structure of a cross-validation fold
#'
#' @param fold A cross-validation fold.
#'
#' @return Invisibly returns \code{fold}.
#'
#' @keywords internal
#' @noRd
.validate_ts_cv_fold_structure <- function(fold) {
  valid <- is.list(fold) &&
    !is.null(fold$fold) &&
    !is.null(fold$train_ts) &&
    !is.null(fold$test_ts)

  if (!valid) {
    cli::cli_abort("`fold` must be valid.")
  }

  invisible(fold)
}


#' Validate a cross-validation fold identifier
#'
#' @param fold_id Fold identifier to validate.
#'
#' @return Invisibly returns \code{fold_id}.
#'
#' @keywords internal
#' @noRd
.validate_ts_cv_fold_id <- function(fold_id) {
  .tempssm_check_length_one(fold_id, "fold$fold")
  .tempssm_check_numeric(fold_id, "fold$fold")

  valid <- !is.na(fold_id) &&
    fold_id >= 1 &&
    .tempssm_is_integerish(fold_id)
  if (!valid) {
    cli::cli_abort("{.arg fold$fold} must be a positive integer.")
  }

  invisible(fold_id)
}


#' Prepare exogenous series in a cross-validation fold
#'
#' @param fold A cross-validation fold.
#' @param y_train Training response series.
#' @param y_test Test response series.
#'
#' @return A named list containing checked training and test exogenous series.
#'
#' @keywords internal
#' @noRd
.prepare_ts_cv_fold_exogenous <- function(fold, y_train, y_test) {
  has_train <- !is.null(fold$exo_train_ts)
  has_test <- !is.null(fold$exo_test_ts)

  if (has_train != has_test) {
    cli::cli_abort(
      "Exogenous fold series must both be supplied or both be {.code NULL}."
    )
  }

  if (!has_train) {
    return(list(train = NULL, test = NULL))
  }

  list(
    train = .tempssm_check_exo_ts(y_train, fold$exo_train_ts),
    test = .tempssm_check_exo_ts(y_test, fold$exo_test_ts)
  )
}


#' Prepare one fold for time-series cross-validation
#'
#' @param fold A cross-validation fold.
#'
#' @return A named list containing validated and named fold inputs.
#'
#' @keywords internal
#' @noRd
.prepare_ts_cv_fold <- function(fold) {
  .validate_ts_cv_fold_structure(fold)
  .validate_ts_cv_fold_id(fold$fold)

  y_train <- fold$train_ts
  y_test <- fold$test_ts
  .tempssm_check_univariate_ts(y_train, "fold$train_ts")
  .tempssm_check_univariate_ts(y_test, "fold$test_ts")

  exogenous <- .prepare_ts_cv_fold_exogenous(fold, y_train, y_test)

  list(
    id = fold$fold,
    y_train = y_train,
    y_test = y_test,
    y_train_named = set_ts_name(y_train, label = "Temp", quiet = TRUE),
    y_test_named = set_ts_name(y_test, label = "Temp", quiet = TRUE),
    exo_train = exogenous$train,
    exo_test = exogenous$test
  )
}


#' Generate predictions for one cross-validation fold
#'
#' @inheritParams get_level_ts
#' @param fold_data Prepared fold data from \code{.prepare_ts_cv_fold()}.
#'
#' @return Predictions for the test period.
#'
#' @keywords internal
#' @noRd
.predict_ts_cv_fold <- function(res, fold_data) {
  .predict_tempssm_backend(
    object = res,
    n.ahead = NROW(fold_data$y_test_named),
    new_exo_data = fold_data$exo_test
  )
}


#' Construct a standardized cross-validation fold result
#'
#' @param fold_id Fold identifier.
#' @param converged Whether model fitting converged.
#' @param y_train Training response series.
#' @param y_test Test response series.
#' @param y_pred Predictions for the test period, or \code{NULL}.
#' @param model Fitted state-space model, or \code{NULL}.
#'
#' @return A standardized cross-validation fold result.
#'
#' @keywords internal
#' @noRd
.new_ts_cv_fold_result <- function(fold_id,
                                   converged,
                                   y_train,
                                   y_test,
                                   y_pred = NULL,
                                   model = NULL) {
  list(
    fold = fold_id,
    converged = converged,
    y_train = y_train,
    y_test = y_test,
    y_pred = y_pred,
    model = model
  )
}


#' Run time series cross-validation for a single fold
#'
#' @description
#' Fits a state space model using \code{tempssm()} on a single
#' training/test split generated by \code{ts_train_test_split()},
#' and produces forecasts for the corresponding test period.
#'
#' This function is primarily used internally by
#' \code{ts_cv_run()} as part of the cross-validation workflow.
#' However, it is also exported for advanced users who wish to
#' inspect or debug model behavior on individual folds.
#'
#' For most use cases, users should call \code{ts_cv_run()}
#' instead of using this function directly.
#'
#' For models without exogenous variables, forecasts are generated using
#' \code{predict(..., n.ahead = h)}. When exogenous variables are
#' present, a new \code{SSModel} object is constructed for the test
#' period using the estimated parameters.
#'
#' \strong{Note:} The current implementation for models with
#' exogenous variables relies on explicit reconstruction of
#' \code{SSModel()}, and may be sensitive to model specification.
#' This part is subject to future improvement.
#'
#' @param fold
#' A single fold object returned by \code{ts_train_test_split()}.
#'
#' @inheritParams tempssm
#'
#' @return
#' A named list with the following components:
#' \describe{
#'   \item{fold}{Integer fold index.}
#'   \item{converged}{Logical scalar indicating whether fitting succeeded.}
#'   \item{y_train}{Training time series of class \code{ts}.}
#'   \item{y_test}{Test time series of class \code{ts}.}
#'   \item{y_pred}{Predicted values for the test period, as returned by
#'   \code{stats::predict()}.}
#'   \item{model}{A fitted state-space model, or \code{NULL} if fitting failed.}
#' }
#'
#' @details
#' When no exogenous variables are supplied, forecasts are obtained
#' directly via \code{predict()} with \code{n.ahead}. In this case,
#' future exogenous effects are implicitly treated as zero.
#'
#' When exogenous variables are present, forecasts depend on the
#' provided test-period covariates. Users should ensure that
#' \code{exo_test_ts} represents realistic or observed future values.
#'
#' @seealso
#' \code{\link{ts_cv_run}} for running cross-validation over all folds.
#'
#' @examples
#' \dontrun{
#' data(sst_yamaguchi)
#'
#' # create folds (no exogenous variables)
#' folds <- ts_train_test_split(
#'   temp_data = sst_yamaguchi,
#'   initial   = 60,
#'   horizon   = 12,
#'   step      = 12
#' )
#'
# run CV on first fold (useful for debugging / inspection)
#' res <- ts_cv_run_fold(folds[[1]])
#'
#' # inspect predictions
#' res$y_pred
#'
#' # compare observed vs predicted
#' cbind(
#'   observed = as.numeric(res$y_test),
#'   predicted = as.numeric(res$y_pred)
#' )
#' }
#'
#' @export
ts_cv_run_fold <- function(fold,
                           ar_order = 1,
                           use_season = TRUE,
                           marginal = TRUE) {
  controls <- .prepare_ts_cv_model_controls(
    ar_order,
    use_season,
    marginal
  )
  fold_data <- .prepare_ts_cv_fold(fold)

  .tempssm_cli_inform("Running CV for fold {fold_data$id}")

  res <- .fit_tempssm_safe(
    y_train = fold_data$y_train_named,
    exo_train = fold_data$exo_train,
    ar_order = controls$ar_order,
    use_season = controls$use_season,
    fold_id = fold_data$id,
    marginal = controls$marginal
  )

  fail <- .handle_non_convergence(
    res,
    fold,
    fold_data$y_train,
    fold_data$y_test
  )
  if (!is.null(fail)) {
    return(fail)
  }

  y_pred <- .predict_ts_cv_fold(res, fold_data)

  .new_ts_cv_fold_result(
    fold_id = fold_data$id,
    converged = TRUE,
    y_train = fold_data$y_train,
    y_test = fold_data$y_test,
    y_pred = y_pred,
    model = res$model
  )
}


#' Validate controls for rolling time-series splits
#'
#' @inheritParams ts_train_test_split
#' @param n_obs Number of observations in the validated temperature series.
#'
#' @return A named list containing validated split controls.
#'
#' @keywords internal
#' @noRd
.prepare_ts_split_controls <- function(initial,
                                       horizon,
                                       step,
                                       fixed_window,
                                       allow_partial,
                                       n_obs) {
  .tempssm_check_length_one(initial, "initial")
  .tempssm_check_length_one(horizon, "horizon")
  .tempssm_check_length_one(step, "step")
  .tempssm_check_numeric(initial, "initial")
  .tempssm_check_numeric(horizon, "horizon")
  .tempssm_check_numeric(step, "step")

  counts <- c(initial, horizon, step)
  valid_counts <- all(c(
    !anyNA(counts),
    all(is.finite(counts)),
    all(.tempssm_is_integerish(counts)),
    all(counts >= 1)
  ))
  if (!valid_counts) {
    cli::cli_abort(
      "`initial`, `horizon`, and `step` must be positive integers."
    )
  }

  .tempssm_check_length_one(fixed_window, "fixed_window")
  .tempssm_check_logical(fixed_window, "fixed_window")
  if (is.na(fixed_window)) {
    cli::cli_abort(
      "{.arg fixed_window} must be a logical scalar."
    )
  }

  .tempssm_check_length_one(allow_partial, "allow_partial")
  .tempssm_check_logical(allow_partial, "allow_partial")
  if (is.na(allow_partial)) {
    cli::cli_abort(
      "{.arg allow_partial} must be a logical scalar."
    )
  }

  if (initial >= n_obs) {
    cli::cli_abort(
      "`initial` must be smaller than the length of the time series."
    )
  }

  list(
    initial = initial,
    horizon = horizon,
    step = step,
    fixed_window = fixed_window,
    allow_partial = allow_partial
  )
}


#' Generate positional bounds for rolling time-series splits
#'
#' This helper computes all train and test boundaries before time-series data
#' are sliced. It assumes that split controls have already been validated.
#'
#' @inheritParams ts_train_test_split
#' @param n_obs Number of observations in the validated temperature series.
#'
#' @return A data frame with numeric columns `train_start`, `train_end`,
#'   `test_start`, and `test_end`.
#'
#' @keywords internal
#' @noRd
.make_rolling_split_bounds <- function(n_obs,
                                       initial,
                                       horizon,
                                       step,
                                       fixed_window,
                                       allow_partial) {
  train_end <- as.numeric(seq.int(initial, n_obs - 1, by = step))

  if (!allow_partial) {
    train_end <- train_end[train_end + horizon <= n_obs]
  }

  if (length(train_end) == 0L) {
    return(data.frame(
      train_start = numeric(),
      train_end = numeric(),
      test_start = numeric(),
      test_end = numeric()
    ))
  }

  train_start <- if (fixed_window) {
    pmax(1, train_end - initial + 1)
  } else {
    rep(1, length(train_end))
  }

  data.frame(
    train_start = train_start,
    train_end = train_end,
    test_start = train_end + 1,
    test_end = pmin(train_end + horizon, n_obs)
  )
}


#' Build one rolling train/test fold
#'
#' @param fold_id Numeric fold identifier.
#' @param train_start Numeric training start position.
#' @param train_end Numeric training end position.
#' @param test_start Numeric test start position.
#' @param test_end Numeric test end position.
#' @inheritParams ts_train_test_split
#'
#' @return A named list representing one rolling split.
#'
#' @keywords internal
#' @noRd
.build_ts_split_fold <- function(fold_id,
                                 temp_data,
                                 exo_data,
                                 train_start,
                                 train_end,
                                 test_start,
                                 test_end) {
  .tempssm_cli_debug(
    paste0(
      "Fold {fold_id}: train[{train_start}:{train_end}], ",
      "test[{test_start}:{test_end}]"
    )
  )

  time_index <- time(temp_data)

  list(
    fold = fold_id,
    train_ts = .ts_slice(temp_data, train_start, train_end),
    test_ts = .ts_slice(temp_data, test_start, test_end),
    exo_train_ts = .ts_slice(exo_data, train_start, train_end),
    exo_test_ts = .ts_slice(exo_data, test_start, test_end),
    train_idx = c(train_start, train_end),
    test_idx = c(test_start, test_end),
    train_range = time_index[c(train_start, train_end)],
    test_range = time_index[c(test_start, test_end)]
  )
}


#' Generate rolling train/test splits for time series
#'
#' @description
#' This function generates training and test splits for time series
#' cross-validation using a rolling-origin (walk-forward) scheme.
#' It is intended for model evaluation, including comparison between
#' simple linear models and state space models.
#'
#' @inheritParams tempssm
#'
#' @param initial
#' Integer scalar giving the initial length of the training set (number of
#' observations).
#' Default is 60.
#'
#' @param horizon
#' Integer scalar giving the forecast horizon for the test set (number of
#' observations).
#' Default is 12.
#'
#' @param step
#' Integer scalar giving the step size between successive folds (number of
#' observations).
#' Default is 12.
#'
#' @param fixed_window
#' Logical scalar; if \code{TRUE}, a fixed-length training window of size
#' \code{initial} is used. If \code{FALSE}, an expanding training window
#' is used. Default is \code{FALSE}.
#'
#' @param allow_partial
#' Logical scalar; if \code{TRUE}, include the final fold even if the remaining
#' test period is shorter than \code{horizon}. Default is \code{FALSE}.
#'
#' @return
#' A list of folds. Each element is a named list containing:
#' \describe{
#'   \item{fold}{Integer fold index.}
#'   \item{train_ts}{Training time series of class \code{ts}.}
#'   \item{test_ts}{Test time series of class \code{ts}.}
#'   \item{exo_train_ts}{Training exogenous \code{ts}, or \code{NULL}.}
#'   \item{exo_test_ts}{Test exogenous \code{ts}, or \code{NULL}.}
#'   \item{train_idx}{Integer vector giving the training index range.}
#'   \item{test_idx}{Integer vector giving the test index range.}
#'   \item{train_range}{Numeric vector giving the training time range.}
#'   \item{test_range}{Numeric vector giving the test time range.}
#' }
#'
#' @examples
#' \dontrun{
#' data(sst_yamaguchi) # monthly SST near Yamaguchi Prefecture
#' data(pdo) # Pacific Decadal Oscillation
#'
#' # synchronize series
#' common_ts <- ts.intersect(sst_yamaguchi, pdo)
#' temp_ts <- common_ts[, "sst_yamaguchi"]
#' pdo_ts <- common_ts[, "pdo"]
#' pdo_ts <- set_ts_name(pdo_ts, label = "PDO") # label
#'
#' folds <- ts_train_test_split(
#'   temp_data = temp_ts,
#'   exo_data  = pdo_ts,
#'   initial   = 60,
#'   horizon   = 12,
#'   step      = 12
#' )
#'
#' # inspect first fold
#' folds[[1]]$train_ts
#' folds[[1]]$test_ts
#' }
#'
#' @importFrom stats window time frequency
#' @export
ts_train_test_split <- function(temp_data,
                                exo_data = NULL,
                                initial = 60,
                                horizon = 12,
                                step = 12,
                                fixed_window = FALSE,
                                allow_partial = FALSE,
                                na_action = c("inform",
                                              "warn",
                                              "error",
                                              "allow")) {
  ## ---- Start message --------------------------------------------------
  .tempssm_cli_inform(
    paste0(
      "Creating rolling train/test data ",
      "(initial={initial}, horizon={horizon}, step={step})"
    )
  )

  ## ---- Input checks ---------------------------------------------------
  model_inputs <- .tempssm_prepare_model_inputs(
    temp_data = temp_data,
    exo_data = exo_data,
    allow_unnamed_exo = TRUE,
    default_exo_names = TRUE,
    na_action = na_action
  )

  temp_data <- model_inputs$temp_data
  exo_data <- model_inputs$exo_data
  freq <- model_inputs$frequency

  n <- model_inputs$n_obs
  controls <- .prepare_ts_split_controls(
    initial = initial,
    horizon = horizon,
    step = step,
    fixed_window = fixed_window,
    allow_partial = allow_partial,
    n_obs = n
  )
  initial <- controls$initial
  horizon <- controls$horizon
  step <- controls$step
  fixed_window <- controls$fixed_window
  allow_partial <- controls$allow_partial

  .tempssm_cli_debug("Series length: {n}, frequency: {freq}")

  ## ---- Exogenous checks ----------------------------------------------
  if (!is.null(exo_data)) {
    .tempssm_cli_debug("Exogenous variables: {NCOL(exo_data)}")
  } else {
    .tempssm_cli_debug("No exogenous variables provided")
  }

  ## ---- Rolling split --------------------------------------------------
  bounds <- .make_rolling_split_bounds(
    n_obs = n,
    initial = initial,
    horizon = horizon,
    step = step,
    fixed_window = fixed_window,
    allow_partial = allow_partial
  )
  folds <- vector("list", nrow(bounds))

  for (idx in seq_len(nrow(bounds))) {
    folds[[idx]] <- .build_ts_split_fold(
      fold_id = as.numeric(idx),
      temp_data = temp_data,
      exo_data = exo_data,
      train_start = bounds$train_start[[idx]],
      train_end = bounds$train_end[[idx]],
      test_start = bounds$test_start[[idx]],
      test_end = bounds$test_end[[idx]]
    )
  }

  ## ---- Completion -----------------------------------------------------
  .tempssm_cli_inform(
    "Created {length(folds)} rolling fold{?s}"
  )

  return(folds)
}


#' Slice a time-series object by positional indices
#'
#' Internal helper to extract a contiguous range from a `ts` object using
#' positional start and end indices.
#'
#' @param x A time-series object of class `ts`, or `NULL`.
#' @param i_start Integer start position.
#' @param i_end Integer end position.
#'
#' @return A sliced `ts` object, or `NULL` if `x` is `NULL`.
#'
#' @keywords internal
#' @noRd
.ts_slice <- function(x, i_start, i_end) {
  if (is.null(x)) {
    return(NULL)
  }

  if (!inherits(x, "ts")) {
    cli::cli_abort("Input must be a {.cls ts} object.")
  }

  .tempssm_check_length_one(i_start, "i_start")
  .tempssm_check_length_one(i_end, "i_end")
  .tempssm_check_numeric(i_start, "i_start")
  .tempssm_check_numeric(i_end, "i_end")

  n <- NROW(x)
  indices <- c(i_start, i_end)
  valid_indices <- all(c(
    !anyNA(indices),
    all(is.finite(indices)),
    all(.tempssm_is_integerish(indices)),
    i_start >= 1,
    i_end <= n,
    i_start <= i_end
  ))

  if (!valid_indices) {
    cli::cli_abort(
      c(
        "Invalid slice indices.",
        "i" = "{.arg i_start}:{.arg i_end} must be a valid in-series range."
      )
    )
  }

  stats::window(
    x,
    start = stats::time(x)[i_start],
    end   = stats::time(x)[i_end]
  )
}


#' Validate a logical cross-validation execution control
#'
#' @param x Value to validate.
#' @param arg_name Argument name used in error messages.
#'
#' @return Invisibly returns \code{x}.
#'
#' @keywords internal
#' @noRd
.validate_ts_cv_logical_control <- function(x, arg_name) {
  .tempssm_check_length_one(x, arg_name)
  .tempssm_check_logical(x, arg_name)

  if (is.na(x)) {
    cli::cli_abort("{.arg {arg_name}} must be a logical scalar.")
  }

  invisible(x)
}


#' Validate the number of cross-validation workers
#'
#' @param workers Number of workers to validate, or \code{NULL}.
#'
#' @return Invisibly returns \code{workers}.
#'
#' @keywords internal
#' @noRd
.validate_ts_cv_workers <- function(workers) {
  if (is.null(workers)) {
    return(invisible(workers))
  }

  .tempssm_check_length_one(workers, "workers")
  .tempssm_check_numeric(workers, "workers")

  valid <- !is.na(workers) &&
    is.finite(workers) &&
    workers >= 1 &&
    .tempssm_is_integerish(workers)
  if (!valid) {
    cli::cli_abort(
      "{.arg workers} must be a positive integer scalar."
    )
  }

  invisible(workers)
}


#' Require packages used for parallel cross-validation
#'
#' @return Invisibly returns \code{TRUE}.
#'
#' @keywords internal
#' @noRd
.require_ts_cv_parallel_packages <- function() {
  missing_packages <- c(
    if (!requireNamespace("future", quietly = TRUE)) "future",
    if (!requireNamespace("future.apply", quietly = TRUE)) "future.apply"
  )

  if (length(missing_packages) > 0L) {
    cli::cli_abort(
      c(
        "Parallel cross-validation requires additional package{?s}.",
        "x" = "Missing package{?s}: {.pkg {missing_packages}}.",
        "i" = "Install missing package(s), or use {.code parallel = FALSE}."
      )
    )
  }

  invisible(TRUE)
}


#' Prepare execution controls for time-series cross-validation
#'
#' @param parallel Whether folds should be evaluated in parallel.
#' @param workers Number of parallel workers, or \code{NULL}.
#' @param progress Whether progress should be reported.
#'
#' @return A named list containing validated execution controls.
#'
#' @keywords internal
#' @noRd
.prepare_ts_cv_run_controls <- function(parallel, workers, progress) {
  .validate_ts_cv_logical_control(parallel, "parallel")
  .validate_ts_cv_logical_control(progress, "progress")

  if (parallel) {
    .require_ts_cv_parallel_packages()

    if (is.null(workers)) {
      workers <- future::availableCores()
    }
  } else if (is.null(workers)) {
    workers <- 1L
  }

  .validate_ts_cv_workers(workers)

  list(
    parallel = parallel,
    workers = workers,
    progress = progress
  )
}


#' Validate folds before cross-validation execution
#'
#' @param folds List of cross-validation folds.
#'
#' @return Invisibly returns \code{folds}.
#'
#' @keywords internal
#' @noRd
.validate_ts_cv_folds <- function(folds) {
  if (!is.list(folds)) {
    cli::cli_abort("`folds` must be a list of fold objects.")
  }

  lapply(folds, .prepare_ts_cv_fold)
  invisible(folds)
}


#' Run one fold with prepared model controls
#'
#' @param fold A cross-validation fold.
#' @param model_controls Validated model controls.
#'
#' @return A result from \code{ts_cv_run_fold()}.
#'
#' @keywords internal
#' @noRd
.run_one_ts_cv_fold <- function(fold, model_controls) {
  ts_cv_run_fold(
    fold = fold,
    ar_order = model_controls$ar_order,
    use_season = model_controls$use_season,
    marginal = model_controls$marginal
  )
}


#' Run folds without progress reporting
#'
#' @inheritParams .validate_ts_cv_folds
#' @param model_controls Validated model controls.
#' @param parallel Whether folds should be evaluated in parallel.
#'
#' @return A list of cross-validation fold results.
#'
#' @keywords internal
#' @noRd
.run_ts_cv_folds_basic <- function(folds, model_controls, parallel) {
  if (!parallel) {
    return(lapply(
      folds,
      .run_one_ts_cv_fold,
      model_controls = model_controls
    ))
  }

  future.apply::future_lapply(
    folds,
    .run_one_ts_cv_fold,
    model_controls = model_controls,
    future.seed = TRUE
  )
}


#' Run folds with progress reporting
#'
#' @inheritParams .run_ts_cv_folds_basic
#'
#' @return A list of cross-validation fold results.
#'
#' @keywords internal
#' @noRd
.run_ts_cv_folds_with_progress <- function(folds, model_controls, parallel) {
  progressr::with_progress({
    progress <- progressr::progressor(along = folds)

    run_one <- function(fold) {
      result <- .run_one_ts_cv_fold(fold, model_controls)
      progress()
      result
    }

    if (!parallel) {
      return(lapply(folds, run_one))
    }

    future.apply::future_lapply(
      folds,
      run_one,
      future.seed = TRUE
    )
  })
}


#' Run folds using the requested progress behavior
#'
#' @inheritParams .run_ts_cv_folds_basic
#' @param progress Whether progress should be reported.
#'
#' @return A list of cross-validation fold results.
#'
#' @keywords internal
#' @noRd
.run_ts_cv_folds <- function(folds, model_controls, progress, parallel) {
  if (length(folds) == 0L) {
    return(list())
  }

  if (!progress) {
    return(.run_ts_cv_folds_basic(folds, model_controls, parallel))
  }

  if (!requireNamespace("progressr", quietly = TRUE)) {
    cli::cli_warn(
      "progressr not installed; running without progress bar"
    )
    return(.run_ts_cv_folds_basic(folds, model_controls, parallel))
  }

  .run_ts_cv_folds_with_progress(folds, model_controls, parallel)
}


#' Evaluate code with a temporary future plan
#'
#' @inheritParams .prepare_ts_cv_run_controls
#' @param code Zero-argument function containing code to evaluate.
#'
#' @return The value returned by \code{code()}.
#'
#' @keywords internal
#' @noRd
.with_ts_cv_plan <- function(parallel, workers, code) {
  if (!parallel) {
    .tempssm_cli_debug("Sequential execution")
    return(code())
  }

  .require_ts_cv_parallel_packages()

  old_plan <- future::plan()
  on.exit(future::plan(old_plan), add = TRUE)

  future::plan(future::multisession, workers = workers)
  .tempssm_cli_debug("Parallel execution with {workers} workers")

  code()
}



#' Run time series cross-validation over multiple folds
#'
#' @description
#' Apply \code{ts_cv_run_fold()} to multiple train/test splits and
#' collect the results. This function orchestrates time series
#' cross-validation but does not compute evaluation metrics.
#'
#' @param folds
#' A list of fold objects returned by \code{ts_train_test_split()}.
#'
#' @inheritParams tempssm
#'
#' @param parallel
#' Logical scalar; if \code{TRUE}, folds are evaluated in parallel using the
#' \pkg{future.apply} framework. If \code{FALSE}, folds are processed
#' sequentially. Default is \code{FALSE}.
#'
#' @param workers
#' Integer scalar specifying the number of parallel workers to use when
#' \code{parallel = TRUE}. If \code{NULL} and \code{parallel = TRUE}, all
#' available cores returned by \code{\link[future]{availableCores}} are used.
#' This argument is ignored for execution when \code{parallel = FALSE}.
#'
#' @param progress
#' Logical scalar; if \code{TRUE}, a progress bar is displayed during execution
#' using the \pkg{progressr} package. If \code{FALSE}, no progress bar
#' is shown. Default is \code{FALSE}.
#'
#' @return
#' A list of named lists. Each element corresponds to one fold and contains
#' the output of \code{ts_cv_run_fold()}.
#'
#' @details
#' The requested \pkg{future} execution plan is used only while folds are
#' evaluated. The plan that was active before calling this function is restored
#' on exit, including when fold evaluation raises an error. Calling
#' \code{ts_cv_run()} does not require attaching \pkg{future} or
#' \pkg{future.apply} with \code{library()}, but these suggested packages must
#' be installed when \code{parallel = TRUE}.
#'
#' @examples
#' \dontrun{
#' data(sst_yamaguchi)
#'
#' # 1. create train/test splits
#' folds <- ts_train_test_split(
#'   temp_data = sst_yamaguchi,
#'   initial   = 60,
#'   horizon   = 12,
#'   step      = 12
#' )
#'
#' # 2. run cross-validation across all folds
#' cv_results <- ts_cv_run(
#'   folds,
#'   ar_order = 1,
#'   use_season = TRUE
#' )
#'
#' # Optional parallel execution:
#' # cv_results <- ts_cv_run(folds, parallel = TRUE, workers = 2)
#'
#' # inspect first fold result
#' cv_results[[1]]
#'
#' # predicted vs observed for first fold
#' cbind(
#'   observed = as.numeric(cv_results[[1]]$y_test),
#'   predicted = as.numeric(cv_results[[1]]$y_pred)
#' )
#' }
#'
#' @export
ts_cv_run <- function(
  folds,
  ar_order = 1,
  use_season = TRUE,
  parallel = FALSE,
  workers = NULL,
  progress = FALSE,
  marginal = TRUE
) {
  model_controls <- .prepare_ts_cv_model_controls(
    ar_order,
    use_season,
    marginal
  )
  run_controls <- .prepare_ts_cv_run_controls(parallel, workers, progress)
  .validate_ts_cv_folds(folds)

  n_folds <- length(folds)
  .tempssm_cli_inform(
    "Running cross-validation on {n_folds} fold{?s}"
  )

  res <- .with_ts_cv_plan(
    run_controls$parallel,
    run_controls$workers,
    function() {
      .run_ts_cv_folds(
        folds,
        model_controls,
        run_controls$progress,
        run_controls$parallel
      )
    }
  )

  .tempssm_cli_inform(
    "Completed cross-validation over {n_folds} fold{?s}"
  )

  res
}


## ---- Assessment Index -------------------------------------------


#' Compute mean absolute error (MAE)
#'
#' @param y_pred Predicted values.
#' @param y_true Observed values.
#'
#' @return Numeric scalar giving MAE.
#'
#' @keywords internal
#' @noRd
.compute_mae <- function(y_pred, y_true) {
  ## ---- fast exit ------------------------------------------------------
  if (is.null(y_pred) || is.null(y_true)) {
    return(NA_real_)
  }

  ## ---- input check ----------------------------------------------------
  if (length(y_pred) != length(y_true)) {
    cli::cli_abort(
      "`y_pred` and `y_true` must have the same length."
    )
  }

  .tempssm_cli_debug(
    "Computing MAE for {length(y_pred)} observation{?s}"
  )

  ## ---- compute --------------------------------------------------------
  mae <- mean(
    abs(as.numeric(y_true) - as.numeric(y_pred)),
    na.rm = TRUE
  )

  .tempssm_cli_debug(
    "MAE computed: {round(mae, 4)}"
  )

  return(mae)
}


#' Compute Mean Absolute Scaled Error (MASE)
#'
#' @description
#' Compute Mean Absolute Scaled Error (MASE) using training data
#' for scaling and test data for evaluation.
#'
#' @param y_pred Predicted values for the test period.
#' @param y_true Observed values for the test period.
#' @param y_train Training time series used for scaling.
#' @param method Scaling method: \code{"naive"} or \code{"seasonal"}.
#'
#' @return Numeric scalar giving MASE, or \code{NA} if unavailable.
#'
#' @references
#' Hyndman, R. J., & Koehler, A. B. (2006).
#' Another look at measures of forecast accuracy.
#' International Journal of Forecasting, 22(4), 679–688.
#'
#' @keywords internal
#' @noRd
.compute_mase <- function(y_pred,
                          y_true,
                          y_train,
                          method = c("naive", "seasonal")) {
  method <- match.arg(method)

  ## ---- fast exit ------------------------------------------------------
  if (is.null(y_pred) || is.null(y_true)) {
    return(NA_real_)
  }

  ## ---- input check ----------------------------------------------------
  .tempssm_check_univariate_ts(y_train, "y_train")

  .tempssm_cli_debug(
    "Computing MASE (method = {method})"
  )

  ## ---- MAE ------------------------------------------------------------
  mae <- .compute_mae(y_pred, y_true)

  if (is.na(mae)) {
    return(NA_real_)
  }

  ## ---- scaling factor -------------------------------------------------
  Q <- tryCatch(
    .scale_Q(y_train, method = method),
    error = function(e) {
      .tempssm_cli_debug(
        "Failed to compute scaling factor Q"
      )
      NA_real_
    }
  )

  if (is.na(Q) || abs(Q) <= sqrt(.Machine$double.eps)) {
    .tempssm_cli_debug("Invalid scaling factor (Q is NA or zero)")
    return(NA_real_)
  }

  ## ---- result ---------------------------------------------------------
  mase <- mae / Q

  .tempssm_cli_debug("MASE computed: {round(mase, 4)}")

  return(mase)
}


#' Compute forecast accuracy metrics for a CV fold
#'
#' @param cv_result A single result returned by \code{ts_cv_run_fold()}.
#'
#' @examples
#' \dontrun{
#' data(sst_yamaguchi)
#'
#' # 1. create train/test splits
#' folds <- ts_train_test_split(
#'   temp_data = sst_yamaguchi,
#'   initial   = 60,
#'   horizon   = 12,
#'   step      = 12
#' )
#'
#' # 2. run cross-validation on a single fold
#' res <- ts_cv_run_fold(folds[[1]])
#'
#' # 3. compute evaluation metrics
#' metrics <- compute_cv_metrics(res)
#'
#' metrics
#' }
#'
#' @return
#' A named list of numeric accuracy metrics with components \code{MAE},
#' \code{MASE_naive}, and \code{MASE_seasonal}.
#' @export
compute_cv_metrics <- function(cv_result) {
  if (!isTRUE(cv_result$converged)) {
    return(list(
      MAE = NA_real_,
      MASE_naive = NA_real_,
      MASE_seasonal = NA_real_
    ))
  }

  list(
    MAE = .compute_mae(cv_result$y_pred, cv_result$y_test),
    MASE_naive = .compute_mase(
      cv_result$y_pred,
      cv_result$y_test,
      cv_result$y_train,
      method = "naive"
    ),
    MASE_seasonal = .compute_mase(
      cv_result$y_pred,
      cv_result$y_test,
      cv_result$y_train,
      method = "seasonal"
    )
  )
}


#' Collect time series cross-validation results into a tibble
#'
#' @description
#' Combine cross-validation results and evaluation metrics into
#' a tidy \code{tibble} with one row per fold.
#'
#' @param cv_results
#' A list of results returned by \code{ts_cv_run()}.
#'
#' @param metrics
#' A list of evaluation metrics returned by
#' \code{compute_cv_metrics()}, corresponding to \code{cv_results}.
#'
#' @return
#' A \code{tibble} where each row represents a cross-validation fold, with
#' columns \code{fold}, \code{converged}, \code{MAE}, \code{MASE_naive}, and
#' \code{MASE_seasonal}.
#'
#' @importFrom tibble tibble
#'
#' @examples
#' \dontrun{
#' data(sst_yamaguchi)
#'
#' # 1. create train/test splits
#' folds <- ts_train_test_split(
#'   temp_data = sst_yamaguchi,
#'   initial   = 60,
#'   horizon   = 12,
#'   step      = 12
#' )
#'
#' # 2. run cross-validation over all folds
#' cv_results <- ts_cv_run(folds)
#'
#' # 3. compute metrics for each fold
#' metrics <- lapply(cv_results, compute_cv_metrics)
#'
#' # 4. collect results into a tidy tibble
#' cv_summary <- ts_cv_collect(cv_results, metrics)
#'
#' cv_summary
#' }
#'
#' @export
ts_cv_collect <- function(cv_results, metrics) {
  ## ---- input check ----------------------------------------------------
  if (!is.list(cv_results) || !is.list(metrics)) {
    cli::cli_abort(
      "`cv_results` and `.arg metrics` must both be lists."
    )
  }

  if (length(cv_results) != length(metrics)) {
    cli::cli_abort(
      "`cv_results` and `.arg metrics` must have the same length."
    )
  }

  n <- length(cv_results)

  .tempssm_cli_debug(
    "Collecting cross-validation results for {n} fold{?s}"
  )

  ## ---- build tibble ---------------------------------------------------
  out <- tibble::tibble(
    fold = as.numeric(lapply(cv_results, function(x) x$fold)),
    converged = as.numeric(lapply(cv_results, function(x) x$converged)),
    MAE = as.numeric(lapply(metrics, function(x) x$MAE)),
    MASE_naive = as.numeric(lapply(metrics, function(x) x$MASE_naive)),
    MASE_seasonal = as.numeric(lapply(metrics, function(x) x$MASE_seasonal))
  )

  return(out)
}


#' Validate a named list of collected tsCV results
#'
#' @param cv_tables A named list of \code{ts_cv_collect()} outputs.
#'
#' @return The input list, invisibly.
#'
#' @keywords internal
#' @noRd
.validate_ts_cv_comparison_tables <- function(cv_tables) {
  if (!is.list(cv_tables) || length(cv_tables) < 2L) {
    cli::cli_abort(
      "{.arg cv_tables} must be a named list containing at least two tables."
    )
  }

  table_names <- names(cv_tables)
  valid_names <- !is.null(table_names) &&
    length(table_names) == length(cv_tables) &&
    !anyNA(table_names) &&
    all(nzchar(trimws(table_names)))
  if (!valid_names) {
    cli::cli_abort(
      "Every table in {.arg cv_tables} must have a non-empty name."
    )
  }

  if (anyDuplicated(table_names)) {
    cli::cli_abort("Names in {.arg cv_tables} must be unique.")
  }

  required_cols <- c(
    "fold",
    "converged",
    "MAE",
    "MASE_naive",
    "MASE_seasonal"
  )
  reference_folds <- NULL

  for (i in seq_along(cv_tables)) {
    current <- cv_tables[[i]]
    current_name <- table_names[[i]]

    if (!is.data.frame(current)) {
      cli::cli_abort(
        "Table {.val {current_name}} must be a data frame."
      )
    }

    missing_cols <- setdiff(required_cols, names(current))
    if (length(missing_cols) > 0L) {
      cli::cli_abort(
        c(
          "Table {.val {current_name}} is missing required column{?s}.",
          "x" = "{.field {missing_cols}}"
        )
      )
    }

    current_folds <- current$fold
    if (is.null(reference_folds)) {
      reference_folds <- current_folds
    } else if (!identical(current_folds, reference_folds)) {
      cli::cli_abort(
        c(
          "Table {.val {current_name}} has incompatible folds.",
          "i" = "Use the same fold IDs and order as {.val {table_names[[1L]]}}."
        )
      )
    }
  }

  invisible(cv_tables)
}


#' Mean of numeric values with all-missing protection
#'
#' @inheritParams .check_na_ratio
#'
#' @return Numeric scalar.
#'
#' @keywords internal
#' @noRd
.mean_or_na <- function(x) {
  x <- as.numeric(x)
  if (all(is.na(x))) {
    return(NA_real_)
  }

  mean(x, na.rm = TRUE)
}


#' Compare time-series cross-validation results across models
#'
#' @description
#' Summarize model-level performance from collected time-series
#' cross-validation results. The function is intended for comparing multiple
#' candidate \code{tempssm} model specifications using the same folds.
#'
#' @param cv_tables A named list of \code{ts_cv_collect()} outputs. Each table
#'   must contain the same fold IDs in the same order and columns
#'   \code{fold}, \code{converged}, \code{MAE}, \code{MASE_naive}, and
#'   \code{MASE_seasonal}. List names are used as model labels.
#'
#' @return
#' A \code{tibble} with one row per model and columns \code{model},
#' \code{n_folds}, \code{converged_n}, \code{converged_rate},
#' \code{mean_MAE}, \code{mean_MASE_naive}, and
#' \code{mean_MASE_seasonal}.
#'
#' @examples
#' \dontrun{
#' data(sst_yamaguchi)
#'
#' folds <- ts_train_test_split(sst_yamaguchi, initial = 60)
#' cv_ar1 <- ts_cv_run(folds, ar_order = 1)
#' cv_ar2 <- ts_cv_run(folds, ar_order = 2)
#'
#' tab_ar1 <- ts_cv_collect(cv_ar1, lapply(cv_ar1, compute_cv_metrics))
#' tab_ar2 <- ts_cv_collect(cv_ar2, lapply(cv_ar2, compute_cv_metrics))
#'
#' compare_ts_cv(list(AR1 = tab_ar1, AR2 = tab_ar2))
#' }
#'
#' @export
compare_ts_cv <- function(cv_tables) {
  .validate_ts_cv_comparison_tables(cv_tables)

  rows <- lapply(names(cv_tables), function(model_name) {
    current <- cv_tables[[model_name]]
    converged <- as.logical(current$converged)

    tibble::tibble(
      model = model_name,
      n_folds = nrow(current),
      converged_n = sum(converged, na.rm = TRUE),
      converged_rate = mean(converged, na.rm = TRUE),
      mean_MAE = .mean_or_na(current$MAE),
      mean_MASE_naive = .mean_or_na(current$MASE_naive),
      mean_MASE_seasonal = .mean_or_na(current$MASE_seasonal)
    )
  })

  tibble::as_tibble(do.call(rbind, rows))
}


#' Compute scale coefficient Q for MASE
#'
#' @description
#' Compute the scaling coefficient \eqn{Q} used in the Mean Absolute
#' Scaled Error (MASE). The scaling is based on in-sample naive or
#' seasonal naive differences of the training time series.
#'
#' @details
#' The scale coefficient \eqn{Q} is defined as follows:
#'
#' For the naive method:
#' \deqn{
#' Q = \frac{1}{n-1} \sum_{t=2}^{n} |y_t - y_{t-1}|
#' }
#'
#' For the seasonal method (with period \eqn{m = frequency(train_ts)}):
#' \deqn{
#' Q = \frac{1}{n-m} \sum_{t=m+1}^{n} |y_t - y_{t-m}|
#' }
#'
#' This function is primarily intended for internal use within the
#' \pkg{tempssm} package to support the computation of MASE.
#'
#' @param train_ts A univariate time series object of class \code{ts}.
#' @param method Character string specifying the scaling method.
#'   Must be either \code{"naive"} or \code{"seasonal"}.
#'
#' @return A numeric scalar representing the scale coefficient \eqn{Q}.
#'
#' @references
#' Hyndman, R. J., & Koehler, A. B. (2006).
#' Another look at measures of forecast accuracy.
#' \emph{International Journal of Forecasting}, 22(4), 679–688.
#'
#' @keywords internal
#' @noRd
.scale_Q <- function(train_ts, method = c("naive", "seasonal")) {
  method <- match.arg(method)

  ## ---- input check ----------------------------------------------------
  .tempssm_check_univariate_ts(train_ts, "train_ts")

  y <- as.numeric(train_ts)
  n <- length(y)

  .tempssm_cli_debug(
    "Computing scale Q (method = {method}, n = {n})"
  )

  ## ---- naive scaling --------------------------------------------------
  if (method == "naive") {
    if (n < 2) {
      cli::cli_abort(
        "At least two observations are required for naive scaling."
      )
    }

    Q <- mean(abs(diff(y)), na.rm = TRUE)
  } else { # seasonal

    m <- stats::frequency(train_ts)

    if (m <= 1) {
      cli::cli_abort(
        "Seasonal scaling requires a {.cls ts} object with frequency > 1."
      )
    }

    if (n <= m) {
      cli::cli_abort(
        "Time series is too short for seasonal scaling."
      )
    }

    Q <- mean(abs(y[(m + 1):n] - y[1:(n - m)]), na.rm = TRUE)
  }

  .tempssm_cli_debug("Scale Q computed: {round(Q, 4)}")

  return(Q)
}
