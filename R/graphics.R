#' Check common inputs for component autoplot functions
#'
#' @inheritParams .tempssm_check_accessor_input
#' @inheritParams .tempssm_check_accessor_ci
#' @param show_ci_in_title Logical; should the CI level be shown in the title?
#'
#' @return Invisibly returns \code{NULL}.
#' @noRd
.tempssm_check_component_plot_input <- function(res, ci, ci_level,
                                                show_ci_in_title, fun) {
  if (!inherits(res, "tempssm")) {
    cli::cli_abort(
      "`res` must be an object of class {.cls tempssm}."
    )
  }

  if (!is.logical(ci) || length(ci) != 1) {
    cli::cli_abort(
      "`ci` must be a single logical value for {fun}()."
    )
  }

  if (!is.logical(show_ci_in_title) || length(show_ci_in_title) != 1) {
    cli::cli_abort(
      "`show_ci_in_title` must be a single logical value for {fun}()."
    )
  }

  if (ci) {
    if (!is.numeric(ci_level) || length(ci_level) != 1 ||
        ci_level <= 0 || ci_level >= 1) {
      cli::cli_abort(
        "`ci_level` must be a numeric value between 0 and 1: {fun}()."
      )
    }
  }

  invisible(NULL)
}


#' Build a data frame for component plots
#'
#' @param component_ts A multivariate \code{ts} object returned by an accessor.
#' @param value_name Character scalar naming the point estimate column.
#' @inheritParams .tempssm_check_accessor_ci
#'
#' @return A tibble with \code{time}, component, and optional CI columns.
#' @noRd
.tempssm_component_plot_data <- function(component_ts, value_name, ci) {
  component_df <- data.frame(
    time = as.numeric(stats::time(component_ts)),
    value = as.numeric(component_ts[, value_name])
  )

  if (ci) {
    ci_df <- data.frame(
      lwr = as.numeric(component_ts[, "lwr"]),
      upr = as.numeric(component_ts[, "upr"])
    )
    component_df <- cbind(component_df, ci_df)
  }

  tibble::as_tibble(component_df)
}


#' Build a title for a tempssm component plot
#'
#' @param title Character scalar used for the default title.
#' @param ci_title Character scalar used when the CI level is shown.
#' @inheritParams .tempssm_check_component_plot_input
#'
#' @return A character scalar containing the plot title.
#' @noRd
.tempssm_component_plot_title <- function(title, ci_title, ci, ci_level,
                                          show_ci_in_title) {
  if (!ci || !show_ci_in_title) {
    return(title)
  }

  ci_label <- paste0(round(ci_level * 100), "% CI")
  paste0(ci_title, " (", ci_label, ")")
}


#' Add common layers to a tempssm component plot
#'
#' @param plot A \code{ggplot} object.
#' @param plot_title Character scalar containing the plot title.
#' @param ylab Label of the y-axis.
#' @inheritParams .tempssm_check_accessor_ci
#' @param linewidth Optional line width passed to \code{geom_line()}.
#'
#' @return A \code{ggplot} object with common component layers.
#' @noRd
.tempssm_add_component_layers <- function(plot, plot_title, ylab, ci,
                                          linewidth) {
  if (is.null(linewidth)) {
    plot <- plot + ggplot2::geom_line()
  } else {
    plot <- plot + ggplot2::geom_line(linewidth = linewidth)
  }

  plot <- plot +
    ggplot2::labs(
      title = plot_title,
      x = "Time (year)",
      y = ylab
    )

  if (ci) {
    .tempssm_cli_debug("Including confidence intervals in plot")
    plot <- plot +
      ggplot2::geom_ribbon(
        ggplot2::aes(ymin = .data$lwr, ymax = .data$upr),
        alpha = 0.3
      )
  }

  plot
}


#' Choose line width for dense seasonal component plots
#'
#' @inheritParams .tempssm_check_accessor_input
#' @param default Numeric scalar used for short time series.
#' @param threshold Numeric scalar giving the number of seasonal cycles above
#'   which the line width starts to decrease.
#' @param minimum Numeric scalar giving the lower bound for line width.
#'
#' @return A numeric scalar.
#' @noRd
.tempssm_season_linewidth <- function(res, default = 0.5, threshold = 40,
                                      minimum = 0.2) {
  frequency <- stats::frequency(res$temp_data)
  n_cycles <- NROW(res$temp_data) / frequency

  if (!is.finite(n_cycles) || n_cycles <= threshold) {
    return(default)
  }

  max(minimum, default * sqrt(threshold / n_cycles))
}


#' Combine autoregressive states into a single plotted component
#'
#' @inheritParams .tempssm_check_component_plot_input
#'
#' @return A univariate or multivariate \code{ts} object.
#' @noRd
.tempssm_extract_ar_component_ts <- function(res, ci = FALSE,
                                             ci_level = 0.95) {
  .tempssm_check_component_plot_input(
    res = res,
    ci = ci,
    ci_level = ci_level,
    show_ci_in_title = FALSE,
    fun = "autoplot_ar"
  )

  ar_states <- paste0("arima", seq_len(res$ar_order))
  if (is.null(res$kfs) || is.null(res$kfs$alphahat)) {
    cli::cli_abort(
      "Autoregressive component not found in the smoothing results."
    )
  }

  state_matrix <- res$kfs$alphahat
  if (!is.matrix(state_matrix)) {
    cli::cli_abort("Autoregressive smoothing results are not available.")
  }

  point <- rowSums(state_matrix[, ar_states, drop = FALSE])

  if (!ci) {
    return(ts(
      point,
      start = start(res$temp_data),
      frequency = frequency(res$temp_data)
    ))
  }

  ci_obj <- stats::confint(res$kfs, level = ci_level)
  if (!all(ar_states %in% names(ci_obj))) {
    cli::cli_abort(
      "Autoregressive component not found in confidence intervals."
    )
  }

  lwr <- rowSums(vapply(ar_states, function(state) {
    ci_obj[[state]][, "lwr"]
  }, numeric(length(point))))
  upr <- rowSums(vapply(ar_states, function(state) {
    ci_obj[[state]][, "upr"]
  }, numeric(length(point))))

  values <- cbind(
    ar1 = point,
    lwr = lwr,
    upr = upr
  )

  ts(
    values,
    start = start(res$temp_data),
    frequency = frequency(res$temp_data)
  )
}


#' Create a ggplot object for one tempssm component
#'
#' @inheritParams .tempssm_check_component_plot_input
#' @inheritParams .tempssm_add_component_layers
#' @param getter Function used to extract the component time series.
#' @inheritParams .tempssm_component_plot_data
#' @inheritParams .tempssm_component_plot_title
#' @param debug_name Character scalar used in debug messages.
#'
#' @return A \code{ggplot} object.
#' @noRd
.tempssm_autoplot_component <- function(res, ci, ci_level, ylab,
                                        show_ci_in_title, fun, getter,
                                        value_name, title, ci_title,
                                        debug_name, linewidth = NULL) {
  .tempssm_check_component_plot_input(
    res = res,
    ci = ci,
    ci_level = ci_level,
    show_ci_in_title = show_ci_in_title,
    fun = fun
  )

  .tempssm_cli_debug(
    "Creating {debug_name} plot (ci={ci}, ci_level={ci_level})"
  )

  component_ts <- getter(res, ci = TRUE, ci_level = ci_level)
  component_tidy <- .tempssm_component_plot_data(
    component_ts = component_ts,
    value_name = value_name,
    ci = ci
  )
  if (!is.null(linewidth)) {
    component_tidy$line_width <- linewidth
  }

  plot_title <- .tempssm_component_plot_title(
    title,
    ci_title,
    ci,
    ci_level,
    show_ci_in_title
  )

  p <- ggplot2::ggplot(
    component_tidy,
    ggplot2::aes(x = .data$time, y = .data$value)
  )

  p <- .tempssm_add_component_layers(
    p,
    plot_title,
    ylab,
    ci,
    linewidth
  )

  .tempssm_cli_debug("{debug_name} plot created successfully")

  p
}


#' Plot the estimated level component from a tempssm model
#'
#' @importFrom rlang .data
#'
#' @description
#' Create a \pkg{ggplot2} visualization of the estimated level component
#' obtained from a state space model fitted by \code{tempssm()}.
#' A pointwise confidence interval is shown as a shaded ribbon.
#'
#' @inheritParams get_level_ts
#'
#' @param ylab
#' Label of y-axis. The default is a plotmath expression showing temperature
#' in degrees Celsius.
#'
#' @param show_ci_in_title Logical; should the confidence level be shown in
#'   the plot title when \code{ci = TRUE}? The default is \code{FALSE}.
#'
#' @details
#' The confidence interval is computed using
#' \code{stats::confint()} applied to the Kalman filter and smoother
#' results stored in \code{res$kfs}. The shaded ribbon represents
#' pointwise confidence intervals for the level state.
#'
#' @return
#' A \code{ggplot} object, allowing further customization by adding
#' standard \pkg{ggplot2} layers.
#'
#' @seealso
#' \code{\link{tempssm}}, \code{\link[stats]{confint}}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#' res <- tempssm(sst_niigata)
#'
#' # Default 95% confidence interval
#' autoplot_level(res)
#'
#' # Custom confidence level
#' autoplot_level(res, ci_level = 0.9)
#' }
autoplot_level <- function(res,
                           ci = TRUE,
                           ci_level = 0.95,
                           ylab = expression(Temp. ~ (degree * C)),
                           show_ci_in_title = FALSE) {
  .tempssm_autoplot_component(
    res = res,
    ci = ci,
    ci_level = ci_level,
    ylab = ylab,
    show_ci_in_title = show_ci_in_title,
    fun = "autoplot_level",
    getter = get_level_ts,
    value_name = "level",
    title = "Level component",
    ci_title = "Level component",
    debug_name = "level",
    linewidth = 1.2
  )
}


#' Plot the estimated drift (slope) component from a tempssm model
#'
#' @description
#' Create a \pkg{ggplot2} visualization of the estimated drift component
#' obtained from a state space model fitted by \code{tempssm()}.
#' A pointwise confidence interval is shown as a shaded ribbon.
#'
#' @inheritParams get_level_ts
#' @inheritParams autoplot_level
#'
#' @param ylab
#' Label of y-axis. The default is a plotmath expression showing temperature
#' change in degrees Celsius per year.
#'
#' @details
#' The confidence interval is computed using
#' \code{stats::confint()} applied to the Kalman filter and smoother
#' results stored in \code{res$kfs}. The shaded ribbon represents
#' pointwise confidence intervals for the level state.
#'
#' @return
#' A \code{ggplot} object, allowing further customization by adding
#' standard \pkg{ggplot2} layers.
#'
#' @seealso
#' \code{\link{tempssm}}, \code{\link[stats]{confint}}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#' res <- tempssm(sst_niigata)
#'
#' # Default 95% confidence interval
#' autoplot_drift(res)
#'
#' # Custom confidence level
#' autoplot_drift(res, ci_level = 0.9)
#' }
autoplot_drift <- function(res,
                           ci = TRUE,
                           ci_level = 0.95,
                           ylab = expression(Temp. ~ change ~
                                               (degree * C / year)),
                           show_ci_in_title = FALSE) {
  .tempssm_autoplot_component(
    res = res,
    ci = ci,
    ci_level = ci_level,
    ylab = ylab,
    show_ci_in_title = show_ci_in_title,
    fun = "autoplot_drift",
    getter = get_drift_ts,
    value_name = "drift",
    title = "Drift component",
    ci_title = "Drift component",
    debug_name = "drift",
    linewidth = 1.2
  )
}


#' Plot the estimated seasonal component from a tempssm model
#'
#' @description
#' Create a \pkg{ggplot2} visualization of the estimated drift component
#' obtained from a state space model fitted by \code{tempssm()}.
#' A pointwise confidence interval is shown as a shaded ribbon.
#'
#' @inheritParams get_level_ts
#' @inheritParams autoplot_level
#'
#' @param ylab
#' Label of y-axis. The default is a plotmath expression showing temperature
#' in degrees Celsius.
#'
#' @details
#' The confidence interval is computed using
#' \code{stats::confint()} applied to the Kalman filter and smoother
#' results stored in \code{res$kfs}. The shaded ribbon represents
#' pointwise confidence intervals for the level state.
#'
#' @return
#' A \code{ggplot} object, allowing further customization by adding
#' standard \pkg{ggplot2} layers.
#'
#' @seealso
#' \code{\link{tempssm}}, \code{\link[stats]{confint}}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#' res <- tempssm(sst_niigata)
#'
#' # Default 95% confidence interval
#' autoplot_season(res)
#'
#' # Custom confidence level
#' autoplot_season(res, ci_level = 0.9)
#' }
autoplot_season <- function(res,
                            ci = TRUE,
                            ci_level = 0.95,
                            ylab = expression(Temp. ~ (degree * C)),
                            show_ci_in_title = FALSE) {
  .tempssm_autoplot_component(
    res = res,
    ci = ci,
    ci_level = ci_level,
    ylab = ylab,
    show_ci_in_title = show_ci_in_title,
    fun = "autoplot_season",
    getter = get_season_ts,
    value_name = "season",
    title = "Seasonal component",
    ci_title = "Seasonal component",
    debug_name = "season",
    linewidth = .tempssm_season_linewidth(res)
  )
}


#' Plot the estimated autoregressive component from a tempssm model
#'
#' @description
#' Create a \pkg{ggplot2} visualization of the estimated autoregressive
#' component(s) obtained from a state space model fitted by \code{tempssm()}.
#' By default, the summed contribution of all autoregressive states is shown.
#' A pointwise confidence interval is shown as a shaded ribbon.
#'
#' @inheritParams get_level_ts
#' @inheritParams autoplot_level
#'
#' @param ylab
#' Label of y-axis. The default is a plotmath expression showing temperature
#' in degrees Celsius.
#'
#' @details
#' The confidence interval is computed using
#' \code{stats::confint()} applied to the Kalman filter and smoother
#' results stored in \code{res$kfs}. The shaded ribbon represents
#' pointwise confidence intervals for the selected autoregressive component.
#'
#' @return
#' A \code{ggplot} object, allowing further customization by adding
#' standard \pkg{ggplot2} layers.
#'
#' @seealso
#' \code{\link{tempssm}}, \code{\link[stats]{confint}}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#' res <- tempssm(sst_niigata)
#'
#' # Default: show the summed autoregressive component
#' autoplot_ar(res)
#'
#' # Custom confidence level
#' autoplot_ar(res, ci_level = 0.9)
#' }
autoplot_ar <- function(res,
                        ci = TRUE,
                        ci_level = 0.95,
                        ylab = expression(Temp. ~ (degree * C)),
                        show_ci_in_title = FALSE) {
  title <- "Autoregressive component"

  .tempssm_autoplot_component(
    res = res,
    ci = ci,
    ci_level = ci_level,
    ylab = ylab,
    show_ci_in_title = show_ci_in_title,
    fun = "autoplot_ar",
    getter = .tempssm_extract_ar_component_ts,
    value_name = "ar1",
    title = title,
    ci_title = title,
    debug_name = "ar"
  )
}


#' Plot temperature anomalies
#'
#' @description
#' Plots a temperature time series together with its corresponding
#' temperature anomalies.
#'
#' `plot_temp_dev()` is retained for backward compatibility. New code should
#' use `plot_temp_anomaly()`.
#'
#' The anomalies are computed by subtracting the long-term seasonal mean
#' for each period in the seasonal cycle from the observed temperature.
#'
#' @param ts
#' A univariate time series object of class \code{ts} with an integer
#' frequency greater than 1.
#'
#' @param connect_missing
#' Logical; should line segments be connected across missing values?
#' If \code{FALSE}, the default, lines are broken at missing values.
#' If \code{TRUE}, missing observations are omitted before plotting, so line
#' segments connect across gaps.
#'
#' @details
#' The function first computes the seasonal climatological mean across all
#' years, and then calculates anomalies as deviations from these seasonal
#' averages. For monthly data, this is equivalent to subtracting the
#' long-term mean for each calendar month.
#'
#' @return
#' A \code{ggplot2} plot object showing the temperature anomaly time series.
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#' p <- plot_temp_anomaly(sst_niigata)
#' print(p)
#' }
#'
#' @importFrom ggplot2 labs ggtitle
#' @export
plot_temp_anomaly <- function(ts, connect_missing = FALSE) {
  .tempssm_check_univariate_ts(ts, "ts")

  if (!is.logical(connect_missing) || length(connect_missing) != 1) {
    cli::cli_abort("`connect_missing` must be a single logical value.")
  }

  anom <- tempssm::compute_temp_anomaly(ts)
  anom_df <- data.frame(
    time = as.numeric(stats::time(anom)),
    anomaly = as.numeric(anom)
  )

  if (connect_missing) {
    anom_df <- anom_df[!is.na(anom_df$anomaly), , drop = FALSE]
  }

  dev_plot <- ggplot2::ggplot(
    anom_df,
    ggplot2::aes(x = .data$time, y = .data$anomaly)
  ) +
    ggplot2::geom_line() +
    ggplot2::labs(
      y = expression(Temperature ~ (degree * C)),
      x = "Time (year)"
    ) +
    ggplot2::ggtitle("Temperature anomalies")

  return(dev_plot)
}


#' @rdname plot_temp_anomaly
#' @export
plot_temp_dev <- function(ts, connect_missing = FALSE) {
  plot_temp_anomaly(ts = ts, connect_missing = connect_missing)
}
