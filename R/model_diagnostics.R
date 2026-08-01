#' Extract standardized recursive residuals
#'
#' @inheritParams get_level_ts
#' @param keep_time Logical scalar; if TRUE, the residuals are returned as a
#'   \code{ts} object with the same start and frequency as the input
#'   temperature series; non-finite residuals are retained as \code{NA}. If
#'   FALSE, only finite residuals are returned as a numeric vector.
#'
#' @return
#' By default, a \code{ts} object preserving the time index of the input
#' temperature series. If \code{keep_time = FALSE}, a numeric vector of finite
#' standardized recursive residuals.
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#' res <- tempssm(sst_niigata)
#'
#' residuals_ts <- get_tempssm_residuals(res)
#' residuals <- get_tempssm_residuals(res, keep_time = FALSE)
#' }
#' @export
get_tempssm_residuals <- function(res, keep_time = TRUE) {
  if (!inherits(res, "tempssm")) {
    cli::cli_abort(
      "`res` must be an object of class {.cls tempssm}."
    )
  }

  .tempssm_check_length_one(keep_time, "keep_time")
  .tempssm_check_logical(keep_time, "keep_time")
  if (!is.logical(keep_time) || is.na(keep_time)) {
    cli::cli_abort("{.arg keep_time} must be a logical scalar.")
  }

  r <- stats::rstandard(res$kfs, type = "recursive")
  if (keep_time) {
    if (length(r) != length(res$temp_data)) {
      cli::cli_abort(
        "Time-preserving residuals require residuals and input data to have ",
        "the same length."
      )
    }

    r[!is.finite(r)] <- NA_real_

    return(
      stats::ts(
        as.numeric(r),
        start = stats::start(res$temp_data),
        frequency = stats::frequency(res$temp_data)
      )
    )
  }

  r[is.finite(r)]
}


#' Compute kurtosis
#'
#' Uses non-excess kurtosis, m4 / m2^2.
#'
#' @inheritParams .check_na_ratio
#' @param na.rm Logical scalar; if TRUE, missing values are removed.
#'
#' @return A numeric scalar.
#' @keywords internal
#' @noRd
.kurtosis <- function(x, na.rm = FALSE) {
  mu <- mean(x, na.rm = na.rm)

  m2 <- mean((x - mu)^2, na.rm = na.rm)
  m4 <- mean((x - mu)^4, na.rm = na.rm)

  m4 / m2^2
}


#' Resolve the Ljung--Box lag for residual diagnostics
#'
#' @inheritParams diagnose_residuals
#' @param n_residuals Integer scalar giving the number of residuals.
#'
#' @return Integer scalar giving the lag used by the Ljung--Box test.
#'
#' @keywords internal
#' @noRd
.resolve_ljung_box_lag <- function(res, lb_lag, n_residuals) {
  if (n_residuals < 2L) {
    cli::cli_abort(
      "At least two finite residuals are required for residual diagnostics."
    )
  }

  max_lag <- n_residuals - 1L
  if (is.null(lb_lag)) {
    default_lag <- as.integer(stats::frequency(res$temp_data))
    return(min(default_lag, max_lag))
  }

  .tempssm_check_length_one(lb_lag, "lb_lag")
  .tempssm_check_numeric(lb_lag, "lb_lag")
  .tempssm_check_no_undefined(lb_lag, "lb_lag")

  if (!.tempssm_is_integerish(lb_lag) || lb_lag < 1L) {
    cli::cli_abort("{.arg lb_lag} must be a positive integer scalar.")
  }

  lb_lag <- as.integer(round(lb_lag))
  if (lb_lag > max_lag) {
    cli::cli_abort(
      "{.arg lb_lag} must be smaller than the number of finite residuals."
    )
  }

  lb_lag
}


#' Inform users about missing residual handling in tabular diagnostics
#'
#' @param residual_ts A \code{ts} object of time-preserving residuals.
#'
#' @return Invisibly returns NULL.
#'
#' @keywords internal
#' @noRd
.inform_missing_residual_diagnostics <- function(residual_ts) {
  n_missing <- sum(is.na(residual_ts))
  if (n_missing == 0L) {
    return(invisible(NULL))
  }

  n <- length(residual_ts)
  pct <- 100 * n_missing / n

  cli::cli_inform(
    c(
      "The residual series includes missing values.",
      "i" = paste0(
        "Series length: {n}; missing residuals: {n_missing} ",
        "({sprintf('%.1f', pct)}%)."
      ),
      "*" = paste0(
        "Ljung-Box statistics are computed from the available finite ",
        "residual sequence."
      )
    )
  )

  invisible(NULL)
}


#' Residual diagnostics for tempssm models
#'
#' @description
#' Compute residual diagnostic statistics for a fitted tempssm model.
#' The output is returned as a tidy tibble suitable for meta-analysis
#' across many fitted models.
#'
#' @inheritParams get_level_ts
#' @param JB_test Logical scalar; if TRUE, the Jarque–Bera test is included.
#' @param lb_lag Positive integer scalar or \code{NULL}. Lag used for the
#'   Ljung--Box test. If \code{NULL}, the seasonal frequency of the fitted
#'   temperature time series is used, with automatic truncation for very short
#'   residual series.
#'
#' @return
#' A \code{tibble} with one row containing residual diagnostic statistics,
#' including Ljung--Box test results and kurtosis. The \code{lb_lag} column
#' gives the lag used in the Ljung--Box test. If \code{JB_test = TRUE},
#' Jarque--Bera test statistics are also included.
#'
#' @details
#' The Ljung--Box test and kurtosis are computed from finite standardized
#' recursive residuals. If the fitted response series contains missing values
#' or if non-finite residuals occur during filtering, the Ljung--Box test is a
#' diagnostic summary of the available finite residual sequence rather than a
#' strict test on the original equally spaced time index. To inspect residual
#' autocorrelation while preserving the original time structure, use
#' \code{get_tempssm_residuals(res)} with
#' \code{plot_tempssm_residuals()}.
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#'
#' # Fit model
#' res <- tempssm(sst_niigata)
#'
#' # Residual diagnostics (tibble output)
#' diag <- diagnose_residuals(res)
#'
#' diag
#'
#' # Use a longer Ljung--Box lag if needed.
#' diagnose_residuals(res, lb_lag = 24)
#' }
#' @export
diagnose_residuals <- function(res, JB_test = FALSE, lb_lag = NULL) {
  if (!inherits(res, "tempssm")) {
    cli::cli_abort(
      "`res` must be an object of class {.cls tempssm}."
    )
  }

  .tempssm_check_length_one(JB_test, "JB_test")
  .tempssm_check_logical(JB_test, "JB_test")
  if (!is.logical(JB_test) || is.na(JB_test)) {
    cli::cli_abort("{.arg JB_test} must be a logical scalar.")
  }

  residual_ts <- get_tempssm_residuals(res, keep_time = TRUE)
  .inform_missing_residual_diagnostics(residual_ts)

  r <- get_tempssm_residuals(res, keep_time = FALSE)

  n_ts <- length(r)
  lb_lag <- .resolve_ljung_box_lag(res, lb_lag, n_ts)

  lb <- stats::Box.test(
    r,
    type = "Ljung-Box",
    lag = lb_lag
  )

  kurt <- .kurtosis(r)

  if (JB_test) {
    jb <- tseries::jarque.bera.test(r)

    return(
      tibble::tibble(
        lb_stat    = unname(lb$statistic),
        lb_lag     = unname(lb$parameter),
        lb_pvalue  = lb$p.value,
        kurtosis   = kurt,
        jb_stat    = unname(jb$statistic),
        jb_pvalue  = jb$p.value
      )
    )
  }

  tibble::tibble(
    lb_stat    = unname(lb$statistic),
    lb_lag     = unname(lb$parameter),
    lb_pvalue  = lb$p.value,
    kurtosis   = kurt
  )
}


#' Resolve frequency for residual time-series diagnostics
#'
#' @param r Numeric vector or \code{ts} object of residuals.
#' @param frequency Positive numeric scalar or \code{NULL}.
#'
#' @return Numeric scalar.
#'
#' @keywords internal
#' @noRd
.resolve_residual_ts_frequency <- function(r, frequency) {
  if (is.null(frequency)) {
    if (stats::is.ts(r)) {
      return(stats::frequency(r))
    }

    return(12)
  }

  .tempssm_check_length_one(frequency, "frequency")
  .tempssm_check_numeric(frequency, "frequency")
  .tempssm_check_no_undefined(frequency, "frequency")

  if (!is.finite(frequency) || frequency < 1) {
    cli::cli_abort(
      "{.arg frequency} for residual diagnostics must be a positive numeric."
    )
  }

  frequency
}


#' Resolve Ljung--Box lag for residual time-series diagnostics
#'
#' @param lb_lag Positive integer scalar or \code{NULL}.
#' @param frequency Positive numeric scalar.
#' @param n_finite Integer scalar giving the number of finite residuals.
#'
#' @return Integer scalar.
#'
#' @keywords internal
#' @noRd
.resolve_residual_ts_ljung_box_lag <- function(lb_lag,
                                               frequency,
                                               n_finite) {
  if (n_finite < 2L) {
    cli::cli_abort(
      "{.arg r} must contain at least two finite residual values."
    )
  }

  max_lag <- n_finite - 1L
  if (is.null(lb_lag)) {
    default_lag <- as.integer(round(frequency))
    return(min(default_lag, max_lag))
  }

  .tempssm_check_length_one(lb_lag, "lb_lag")
  .tempssm_check_numeric(lb_lag, "lb_lag")
  .tempssm_check_no_undefined(lb_lag, "lb_lag")

  if (!.tempssm_is_integerish(lb_lag) || lb_lag < 1L) {
    cli::cli_abort(
      paste0(
        "{.arg lb_lag} for residual time-series diagnostics must be a ",
        "positive integer."
      )
    )
  }

  lb_lag <- as.integer(round(lb_lag))
  if (lb_lag > max_lag) {
    cli::cli_abort(
      "{.arg lb_lag} must be smaller than the number of finite residuals."
    )
  }

  lb_lag
}


#' Inform users about missing residual time-series diagnostics
#'
#' @param r Numeric vector or \code{ts} object of residuals.
#'
#' @return Invisibly returns NULL.
#'
#' @keywords internal
#' @noRd
.inform_missing_residual_ts_diagnostics <- function(r) {
  n_missing <- sum(is.na(r))
  if (n_missing == 0L) {
    return(invisible(NULL))
  }

  n <- length(r)
  pct <- 100 * n_missing / n

  cli::cli_inform(
    c(
      "The residual series includes missing values.",
      "i" = paste0(
        "Series length: {n}; missing residuals: {n_missing} ",
        "({sprintf('%.1f', pct)}%)."
      ),
      "*" = paste0(
        "Ljung-Box statistics use available-pair autocorrelations ",
        "while preserving the time structure."
      )
    )
  )

  invisible(NULL)
}


#' Validate residual time-series diagnostics inputs
#'
#' @param r Numeric vector or \code{ts} object of residuals.
#' @param lb_lag Positive integer scalar or \code{NULL}.
#' @param frequency Positive numeric scalar or \code{NULL}.
#'
#' @return A list of validated inputs.
#'
#' @keywords internal
#' @noRd
.validate_residual_ts_diagnostics_inputs <- function(r,
                                                     lb_lag,
                                                     frequency) {
  .tempssm_check_numeric(r, "r")
  if (length(r) < 2L) {
    cli::cli_abort(
      "{.arg r} must contain at least two residual values for diagnostics."
    )
  }
  if (any(is.infinite(r) | is.nan(r))) {
    cli::cli_abort(
      "{.arg r} must not contain infinite or NaN residual values."
    )
  }

  n_finite <- sum(is.finite(r))
  frequency <- .resolve_residual_ts_frequency(r, frequency)
  lb_lag <- .resolve_residual_ts_ljung_box_lag(
    lb_lag = lb_lag,
    frequency = frequency,
    n_finite = n_finite
  )
  .inform_missing_residual_ts_diagnostics(r)

  list(
    r = r,
    lb_lag = lb_lag,
    frequency = frequency,
    n_finite = n_finite
  )
}


#' Compute Ljung--Box statistics from available-pair residual ACF
#'
#' @param r Numeric vector or \code{ts} object of residuals.
#' @param lb_lag Positive integer scalar.
#' @param n_finite Integer scalar giving the number of finite residuals.
#'
#' @return A named list with Ljung--Box statistics.
#'
#' @keywords internal
#' @noRd
.available_pair_ljung_box <- function(r, lb_lag, n_finite) {
  acf_df <- .residual_acf_data(r, lag_max = lb_lag)
  acf_lag <- as.integer(round(acf_df$lag))
  use_lag <- acf_lag <= lb_lag &
    acf_lag < n_finite &
    is.finite(acf_df$acf)

  if (!any(use_lag)) {
    cli::cli_abort(
      "At least one finite residual autocorrelation is required."
    )
  }

  rho <- acf_df$acf[use_lag]
  lag <- acf_lag[use_lag]
  lb_stat <- n_finite * (n_finite + 2) *
    sum((rho^2) / (n_finite - lag))
  lb_df <- length(rho)
  lb_pvalue <- stats::pchisq(lb_stat, df = lb_df, lower.tail = FALSE)

  list(
    lb_stat = lb_stat,
    lb_df = lb_df,
    lb_pvalue = lb_pvalue
  )
}


#' Ljung--Box diagnostics for residual time series
#'
#' @description
#' Compute a Ljung--Box residual autocorrelation diagnostic for a residual
#' vector or residual \code{ts} object. This function is useful after
#' extracting time-preserving residuals with \code{get_tempssm_residuals()}.
#'
#' @param r Numeric vector or \code{ts} object of residuals. Missing values are
#'   allowed.
#' @param lb_lag Positive integer scalar or \code{NULL}. Lag used for the
#'   Ljung--Box diagnostic. If \code{NULL}, the frequency of \code{r} is used
#'   when \code{r} is a \code{ts} object; otherwise \code{frequency} is used.
#' @param frequency Positive numeric scalar or \code{NULL}. Used to choose the
#'   default \code{lb_lag} when \code{r} is not a \code{ts} object. If
#'   \code{NULL}, non-\code{ts} input uses 12.
#'
#' @return
#' A \code{tibble} with one row containing the Ljung--Box statistic, lag,
#' degrees of freedom, p-value, kurtosis, and residual missingness counts.
#'
#' @details
#' If \code{r} contains no missing values, the Ljung--Box statistic is
#' equivalent to \code{stats::Box.test(r, type = "Ljung-Box")}. If \code{r}
#' contains missing values, the time positions are retained and
#' autocorrelations are computed from available pairs at each lag. The returned
#' statistic should then be interpreted as a Ljung--Box-type residual
#' autocorrelation diagnostic rather than as the exact result of
#' \code{stats::Box.test()} applied to a complete series.
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#' res <- tempssm(sst_niigata)
#'
#' r <- get_tempssm_residuals(res)
#' diagnose_residual_ts(r)
#' diagnose_residual_ts(r, lb_lag = 24)
#' }
#' @export
diagnose_residual_ts <- function(r, lb_lag = NULL, frequency = NULL) {
  inputs <- .validate_residual_ts_diagnostics_inputs(
    r = r,
    lb_lag = lb_lag,
    frequency = frequency
  )

  r <- inputs[["r"]]
  lb_lag <- inputs[["lb_lag"]]
  n_finite <- inputs[["n_finite"]]
  lb <- .available_pair_ljung_box(r, lb_lag, n_finite)

  tibble::tibble(
    lb_stat = lb[["lb_stat"]],
    lb_lag = lb_lag,
    lb_df = lb[["lb_df"]],
    lb_pvalue = lb[["lb_pvalue"]],
    kurtosis = .kurtosis(r, na.rm = TRUE),
    n = length(r),
    n_missing = sum(is.na(r)),
    n_finite = n_finite
  )
}


#' Build residual diagnostic plot file paths
#'
#' @param prefix Character scalar used as the path prefix. If a file extension
#'   is supplied, it is removed before diagnostic suffixes are appended.
#'
#' @return A named character vector with file paths for diagnostic plots.
#'
#' @keywords internal
#' @noRd
.residual_diagnostic_paths <- function(prefix) {
  prefix_base <- tools::file_path_sans_ext(prefix)

  c(
    check = paste0(prefix_base, "_check.png"),
    qq = paste0(prefix_base, "_qq.png")
  )
}


#' Validate residual plot output arguments
#'
#' @param save Logical scalar; if TRUE, plots are saved.
#' @param prefix Character scalar used as the path prefix.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @keywords internal
#' @noRd
.validate_residual_plot_output_args <- function(save, prefix) {
  .tempssm_check_length_one(save, "save")
  .tempssm_check_logical(save, "save")
  if (!is.logical(save) || is.na(save)) {
    cli::cli_abort("{.arg save} must be a logical scalar.")
  }

  .tempssm_check_length_one(prefix, "prefix")
  .tempssm_check_character(prefix, "prefix")
  if (!is.character(prefix) || is.na(prefix)) {
    cli::cli_abort("{.arg prefix} must be a character scalar.")
  }

  invisible(NULL)
}


#' Validate residual plotting inputs
#'
#' @param r Numeric vector of residuals.
#' @param panel Character scalar specifying the requested panel.
#' @param frequency Positive numeric scalar or \code{NULL}.
#' @param lag_max Positive integer scalar or \code{NULL}.
#'
#' @return A list of validated inputs.
#'
#' @keywords internal
#' @noRd
.validate_residual_plot_inputs <- function(r,
                                           panel,
                                           frequency,
                                           lag_max) {
  .tempssm_check_numeric(r, "r")
  if (length(r) < 2L) {
    cli::cli_abort("{.arg r} must contain at least two residual values.")
  }
  if (any(is.infinite(r) | is.nan(r))) {
    cli::cli_abort(
      "{.arg r} must not contain infinite or NaN residual values."
    )
  }
  if (sum(!is.na(r)) < 2L) {
    cli::cli_abort("{.arg r} must contain at least two non-missing values.")
  }

  panel <- match.arg(panel, c("all", "series", "acf", "histogram"))
  frequency <- .resolve_residual_plot_frequency(r, frequency)
  lag_max <- .resolve_residual_plot_lag_max(r, frequency, lag_max)
  .inform_missing_residuals(r)

  list(
    r = r,
    panel = panel,
    frequency = frequency,
    lag_max = lag_max
  )
}


#' Inform users about missing residual handling
#'
#' @inheritParams .validate_residual_plot_inputs
#'
#' @return Invisibly returns NULL.
#'
#' @keywords internal
#' @noRd
.inform_missing_residuals <- function(r) {
  n_missing <- sum(is.na(r))
  if (n_missing == 0L) {
    return(invisible(NULL))
  }

  n <- length(r)
  pct <- 100 * n_missing / n

  cli::cli_inform(
    c(
      "The residual series includes missing values.",
      "i" = paste0(
        "Series length: {n}; missing residuals: {n_missing} ",
        "({sprintf('%.1f', pct)}%)."
      ),
      "*" = paste0(
        "The ACF panel preserves the time structure and uses ",
        "available pairs for each lag."
      ),
      ">" = "The histogram and normal curve use finite residuals."
    )
  )

  invisible(NULL)
}


#' Resolve frequency for residual ACF plots
#'
#' @inheritParams .validate_residual_plot_inputs
#'
#' @return Numeric scalar.
#'
#' @keywords internal
#' @noRd
.resolve_residual_plot_frequency <- function(r, frequency) {
  if (is.null(frequency)) {
    if (stats::is.ts(r)) {
      return(stats::frequency(r))
    }

    return(12)
  }

  .tempssm_check_length_one(frequency, "frequency")
  .tempssm_check_numeric(frequency, "frequency")
  .tempssm_check_no_undefined(frequency, "frequency")

  if (!is.finite(frequency) || frequency < 1) {
    cli::cli_abort("{.arg frequency} must be a positive numeric scalar.")
  }

  frequency
}


#' Resolve maximum ACF lag for residual diagnostic plots
#'
#' @inheritParams .validate_residual_plot_inputs
#'
#' @return Integer scalar.
#'
#' @keywords internal
#' @noRd
.resolve_residual_plot_lag_max <- function(r, frequency, lag_max) {
  n <- length(r)
  max_lag <- n - 1L

  if (is.null(lag_max)) {
    default_lag <- as.integer(ceiling(2 * frequency + 3))
    return(min(default_lag, max_lag))
  }

  .tempssm_check_length_one(lag_max, "lag_max")
  .tempssm_check_numeric(lag_max, "lag_max")
  .tempssm_check_no_undefined(lag_max, "lag_max")

  if (!.tempssm_is_integerish(lag_max) || lag_max < 1L) {
    cli::cli_abort("{.arg lag_max} must be a positive integer scalar.")
  }

  lag_max <- as.integer(round(lag_max))
  if (lag_max > max_lag) {
    cli::cli_abort(
      "{.arg lag_max} must be smaller than the number of residual values."
    )
  }

  lag_max
}


#' Build data for a residual time-series plot
#'
#' @param r Numeric vector of residuals.
#'
#' @return A data frame with time, residual, and segment columns.
#'
#' @keywords internal
#' @noRd
.residual_series_data <- function(r) {
  residual <- as.numeric(r)
  time <- if (stats::is.ts(r)) {
    as.numeric(stats::time(r))
  } else {
    seq_along(r)
  }

  data.frame(
    time = time,
    residual = residual,
    segment = cumsum(is.na(residual)) + 1L
  )
}


#' Build x-axis breaks for residual time-series plots
#'
#' @inheritParams .residual_series_data
#'
#' @return Numeric vector of breaks.
#'
#' @keywords internal
#' @noRd
.residual_series_x_breaks <- function(r) {
  time_range <- range(.residual_series_data(r)$time)
  breaks <- pretty(time_range)
  breaks[breaks >= time_range[1L] & breaks <= time_range[2L]]
}


#' Build x-axis scale for residual time-series plots
#'
#' @inheritParams .residual_series_data
#'
#' @return A ggplot2 scale object.
#'
#' @keywords internal
#' @noRd
.residual_series_x_scale <- function(r) {
  time_range <- range(.residual_series_data(r)$time)
  breaks <- .residual_series_x_breaks(r)

  if (stats::is.ts(r)) {
    labels <- format(breaks, trim = TRUE, scientific = FALSE)
  } else {
    labels <- breaks
  }

  ggplot2::scale_x_continuous(
    breaks = breaks,
    labels = labels,
    limits = time_range
  )
}


#' Build data for a residual ACF plot
#'
#' @inheritParams .residual_series_data
#' @param lag_max Positive integer scalar giving the maximum displayed lag.
#'
#' @return A data frame with lag and acf columns.
#'
#' @keywords internal
#' @noRd
.residual_acf_data <- function(r, lag_max) {
  acf_obj <- stats::acf(
    r,
    lag.max = lag_max,
    plot = FALSE,
    na.action = stats::na.pass
  )
  lag <- as.numeric(acf_obj$lag[, 1L, 1L])
  if (stats::is.ts(r)) {
    lag <- lag * stats::frequency(r)
  }

  acf_df <- data.frame(
    lag = lag,
    acf = as.numeric(acf_obj$acf[, 1L, 1L])
  )

  acf_df[acf_df$lag > 0, , drop = FALSE]
}


#' Plot residual time series
#'
#' @inheritParams .residual_series_data
#'
#' @return A ggplot object.
#'
#' @keywords internal
#' @noRd
.plot_residual_series <- function(r) {
  df <- .residual_series_data(r)
  df_finite <- df[is.finite(df$residual), , drop = FALSE]

  ggplot2::ggplot(df_finite, ggplot2::aes(x = .data[["time"]],
                                          y = .data[["residual"]])) +
    ggplot2::geom_line(
      ggplot2::aes(group = .data[["segment"]]),
      linewidth = 0.3
    ) +
    ggplot2::geom_point(size = 0.5) +
    .residual_series_x_scale(r) +
    ggplot2::labs(title = "Residuals", x = "Time", y = NULL) +
    ggplot2::theme_gray()
}


#' Plot residual autocorrelation
#'
#' @inheritParams .residual_series_data
#' @param lag_max Positive integer scalar giving the maximum displayed lag.
#'
#' @return A ggplot object.
#'
#' @keywords internal
#' @noRd
.plot_residual_acf <- function(r, lag_max) {
  df <- .residual_acf_data(r, lag_max)
  acf_limit <- stats::qnorm(0.975) / sqrt(length(r))

  ggplot2::ggplot(df, ggplot2::aes(x = .data[["lag"]],
                                   y = .data[["acf"]])) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey20") +
    ggplot2::geom_hline(
      yintercept = c(-acf_limit, acf_limit),
      colour = "blue",
      linetype = "dashed"
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(xend = .data[["lag"]], yend = 0),
      linewidth = 0.3
    ) +
    ggplot2::scale_x_continuous(limits = c(1, lag_max)) +
    ggplot2::labs(x = "Lag", y = "ACF") +
    ggplot2::theme_gray()
}


#' Build scaled normal curve for a residual histogram
#'
#' @inheritParams .residual_series_data
#' @param bins Positive integer scalar giving the number of histogram bins.
#'
#' @return A data frame with x and y columns.
#'
#' @keywords internal
#' @noRd
.residual_normal_curve_data <- function(r, bins = 30L) {
  r <- as.numeric(r)
  r <- r[is.finite(r)]
  r_range <- range(r)
  bin_width <- diff(r_range) / bins
  sd_r <- stats::sd(r)

  if (!is.finite(bin_width) || bin_width <= 0 ||
      !is.finite(sd_r) || sd_r <= 0) {
    return(data.frame(x = numeric(), y = numeric()))
  }

  x <- seq(r_range[1L], r_range[2L], length.out = 200L)
  y <- stats::dnorm(x, mean = mean(r), sd = sd_r) * length(r) * bin_width

  data.frame(x = x, y = y)
}


#' Plot residual frequency distribution
#'
#' @inheritParams .residual_series_data
#'
#' @return A ggplot object.
#'
#' @keywords internal
#' @noRd
.plot_residual_histogram <- function(r) {
  df <- data.frame(residual = as.numeric(r))
  df <- df[is.finite(df$residual), , drop = FALSE]
  normal_df <- .residual_normal_curve_data(r, bins = 30L)

  ggplot2::ggplot(df, ggplot2::aes(x = .data[["residual"]])) +
    ggplot2::geom_histogram(
      bins = 30,
      fill = "grey35",
      colour = "grey80"
    ) +
    ggplot2::geom_line(
      data = normal_df,
      ggplot2::aes(x = .data[["x"]], y = .data[["y"]]),
      inherit.aes = FALSE,
      colour = "#F46D43",
      linewidth = 0.6
    ) +
    ggplot2::geom_rug(sides = "b") +
    ggplot2::labs(x = "residuals", y = "Frequency") +
    ggplot2::theme_gray()
}


#' Draw residual diagnostic plots
#'
#' @inheritParams .residual_series_data
#' @inheritParams .plot_residual_acf
#'
#' @return Invisibly returns NULL.
#'
#' @keywords internal
#' @noRd
.draw_residual_diagnostic_plots <- function(r, lag_max) {
  gridlayout <- matrix(c(1, 2, 1, 3), nrow = 2)
  plots <- list(
    .plot_residual_series(r),
    .plot_residual_acf(r, lag_max),
    .plot_residual_histogram(r)
  )

  grid::grid.newpage()
  grid::pushViewport(
    grid::viewport(
      layout = grid::grid.layout(
        nrow(gridlayout),
        ncol(gridlayout)
      )
    )
  )
  on.exit(grid::popViewport(), add = TRUE)

  for (i in seq_along(plots)) {
    pos <- as.data.frame(which(gridlayout == i, arr.ind = TRUE))
    print(
      plots[[i]],
      vp = grid::viewport(
        layout.pos.row = pos$row,
        layout.pos.col = pos$col
      )
    )
  }

  invisible(NULL)
}


#' Select a residual diagnostic plot panel
#'
#' @inheritParams .validate_residual_plot_inputs
#' @param lag_max Positive integer scalar giving the maximum displayed lag.
#'
#' @return A ggplot object, or \code{NULL} when \code{panel = "all"}.
#'
#' @keywords internal
#' @noRd
.select_residual_plot_panel <- function(r, panel, lag_max) {
  switch(
    panel,
    all = NULL,
    series = .plot_residual_series(r),
    acf = .plot_residual_acf(r, lag_max),
    histogram = .plot_residual_histogram(r)
  )
}


#' Save residual diagnostic plots
#'
#' @inheritParams .validate_residual_plot_inputs
#' @param plot A ggplot object for a selected panel, or \code{NULL}.
#' @param lag_max Positive integer scalar giving the maximum displayed lag.
#' @param prefix Character scalar used as the path prefix.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @keywords internal
#' @noRd
.save_residual_plot <- function(r, panel, plot, lag_max, prefix) {
  paths <- .residual_diagnostic_paths(prefix)

  grDevices::png(paths[["check"]], 600, 400)
  on.exit(grDevices::dev.off(), add = TRUE)

  if (identical(panel, "all")) {
    .draw_residual_diagnostic_plots(r, lag_max)
  } else {
    print(plot)
  }

  invisible(NULL)
}


#' Plot residuals from tempssm models
#'
#' @param r Numeric vector of residuals, typically obtained with
#'   \code{get_tempssm_residuals()}.
#' @param panel Character scalar specifying which panel to draw. Use
#'   \code{"all"} for the default three-panel display, \code{"series"} for
#'   the residual time series, \code{"acf"} for the residual autocorrelation
#'   plot, or \code{"histogram"} for the residual frequency distribution.
#' @param frequency Positive numeric scalar or \code{NULL}. Used to choose the
#'   default maximum lag in the ACF panel when \code{lag_max = NULL}. If
#'   \code{NULL}, the frequency of \code{r} is used when \code{r} is a
#'   \code{ts} object; otherwise 12 is used.
#' @param lag_max Positive integer scalar or \code{NULL}. Maximum lag displayed
#'   in the ACF panel. If \code{NULL}, the default is approximately two
#'   seasonal cycles plus three additional lags, truncated to the residual
#'   series length. For monthly residuals this displays up to lag 27.
#' @param save Logical scalar; if TRUE, plots are saved.
#' @param prefix Character scalar used as the prefix for file names.
#'   Diagnostic suffixes and the \code{.png} extension are added
#'   automatically. If \code{prefix} includes a file extension, that extension
#'   is removed before output names are generated.
#'
#' @return
#' Invisibly returns NULL when \code{panel = "all"} or \code{save = TRUE}.
#' Otherwise, returns a \code{ggplot} object for the selected panel.
#'
#' @details
#' Missing residuals are allowed. The residual time-series panel preserves
#' their positions as gaps and uses the \code{ts} time axis when \code{r} is a
#' \code{ts} object, including axis tick marks based on that time range. The
#' ACF panel preserves the time structure and uses available pairs for each
#' lag, and the histogram and normal curve use finite residuals. When missing
#' residuals are detected, an informational message reports the series length
#' and the number and percentage of missing values.
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#' res <- tempssm(sst_niigata)
#'
#' r <- get_tempssm_residuals(res)
#' plot_tempssm_residuals(r)
#' plot_tempssm_residuals(r, panel = "acf", frequency = 12)
#' }
#' @export
plot_tempssm_residuals <- function(r,
                                   panel = c(
                                     "all",
                                     "series",
                                     "acf",
                                     "histogram"
                                   ),
                                   frequency = NULL,
                                   lag_max = NULL,
                                   save = FALSE,
                                   prefix = "residuals") {
  .validate_residual_plot_output_args(save, prefix)

  inputs <- .validate_residual_plot_inputs(r, panel, frequency, lag_max)
  r <- inputs[["r"]]
  panel <- inputs[["panel"]]
  lag_max <- inputs[["lag_max"]]

  plot <- .select_residual_plot_panel(r, panel, lag_max)

  if (save) {
    .save_residual_plot(r, panel, plot, lag_max, prefix)
    return(invisible(NULL))
  }

  if (identical(panel, "all")) {
    .draw_residual_diagnostic_plots(r, lag_max)
    return(invisible(NULL))
  }

  plot
}


#' Plot residuals from a tempssm model
#'
#' @inheritParams get_level_ts
#' @param save Logical scalar; if TRUE, plots are saved.
#' @param prefix Character scalar used as the prefix for file names.
#'   Diagnostic suffixes and the \code{.png} extension are added
#'   automatically. If \code{prefix} includes a file extension, that extension
#'   is removed before output names are generated.
#'
#' @return
#' Invisibly returns NULL. Called for its side effects (plots).
#'
#' @details
#' This is a convenience wrapper for fitted \code{tempssm} objects. It extracts
#' time-preserving standardized recursive residuals internally and then calls
#' \code{plot_tempssm_residuals()}. Use \code{plot_tempssm_residuals()} when
#' residuals have already been extracted with \code{get_tempssm_residuals()}.
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#' res <- tempssm(sst_niigata)
#'
#' plot_tempssm_model_residuals(res)
#' }
#' @export
plot_tempssm_model_residuals <- function(res,
                                         save = FALSE,
                                         prefix = "residuals") {
  r <- get_tempssm_residuals(res, keep_time = TRUE)

  plot_tempssm_residuals(
    r,
    save = save,
    prefix = prefix
  )

  if (save) {
    paths <- .residual_diagnostic_paths(prefix)
    r_finite <- r[is.finite(r)]

    grDevices::png(paths[["qq"]], 600, 400)
    stats::qqnorm(r_finite)
    stats::qqline(r_finite)
    grDevices::dev.off()
  }

  invisible(NULL)
}


#' Plot residual diagnostics for tempssm models
#'
#' @inheritParams plot_tempssm_model_residuals
#'
#' @return
#' Invisibly returns NULL. Called for its side effects (plots).
#'
#' @details
#' This function is retained as a compatibility alias for
#' \code{plot_tempssm_model_residuals()}.
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#' res <- tempssm(sst_niigata)
#'
#' plot_tempssm_residual_diagnostics(res)
#' }
#' @export
plot_tempssm_residual_diagnostics <- function(res,
                                              save = FALSE,
                                              prefix = "residuals") {
  plot_tempssm_model_residuals(
    res = res,
    save = save,
    prefix = prefix
  )
}
