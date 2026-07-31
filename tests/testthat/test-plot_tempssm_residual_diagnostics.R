# tests/testthat/test-plot_tempssm_residual_diagnostics.R

test_that("plot_tempssm_residual_diagnostics runs without error", {
  expect_message(
    plot_tempssm_residual_diagnostics(res_tempssm, save = FALSE),
    "The residual series includes missing values"
  )
})


test_that("plot_tempssm_model_residuals runs without error", {
  expect_message(
    plot_tempssm_model_residuals(res_tempssm, save = FALSE),
    "The residual series includes missing values"
  )
})


test_that("plot_tempssm_residuals draws all panels by default", {
  r <- get_tempssm_residuals(res_tempssm)

  expect_invisible(
    plot_tempssm_residuals(r, frequency = frequency(res_tempssm$temp_data))
  )
})


test_that("plot_tempssm_residuals returns selected panels", {
  r <- get_tempssm_residuals(res_tempssm)

  expect_s3_class(plot_tempssm_residuals(r, panel = "series"), "ggplot")
  expect_s3_class(plot_tempssm_residuals(r, panel = "acf"), "ggplot")
  expect_s3_class(plot_tempssm_residuals(r, panel = "histogram"), "ggplot")
})


test_that("residual series plot uses ts time axis when available", {
  r <- stats::ts(c(1, NA, 2, 3), start = c(2000, 1), frequency = 12)
  df <- .residual_series_data(r)
  p <- .plot_residual_series(r)
  x_scale <- .residual_series_x_scale(r)

  expect_identical(df$time, as.numeric(stats::time(r)))
  expect_identical(p$labels$x, "Time")
  expect_s3_class(x_scale, "ScaleContinuousPosition")
})


test_that("plot_tempssm_residuals preserves ts time axis after validation", {
  r <- stats::ts(c(1, NA, 2, 3), start = c(2000, 1), frequency = 12)

  expect_message(
    p <- plot_tempssm_residuals(r, panel = "series"),
    "The residual series includes missing values"
  )

  expect_identical(p$data$time, as.numeric(stats::time(r))[-2])
})


test_that("residual series plot uses index for non-ts input", {
  r <- c(1, NA, 2, 3)
  df <- .residual_series_data(r)

  expect_identical(df$time, seq_along(r))
})


test_that("residual time-axis scale reflects the ts range", {
  r <- stats::ts(seq_len(36), start = c(2001, 1), frequency = 12)
  breaks <- .residual_series_x_breaks(r)

  expect_gte(min(breaks), min(as.numeric(stats::time(r))))
  expect_lte(max(breaks), max(as.numeric(stats::time(r))))
})


test_that("residual ACF default lag uses two cycles plus extra lags", {
  r <- get_tempssm_residuals(res_tempssm)

  expect_identical(
    .resolve_residual_plot_lag_max(r, frequency = 12, lag_max = NULL),
    27L
  )
})


test_that("residual ACF data excludes lag zero", {
  r <- get_tempssm_residuals(res_tempssm)
  acf_df <- .residual_acf_data(r, lag_max = 27L)

  expect_false(any(acf_df$lag == 0))
  expect_identical(min(acf_df$lag), 1)
  expect_identical(max(acf_df$lag), 27)
})


test_that("residual ACF can use available pairs with missing values", {
  r <- stats::ts(c(rnorm(15), NA, rnorm(20)), frequency = 12)
  acf_df <- .residual_acf_data(r, lag_max = 27L)

  expect_false(any(acf_df$lag == 0))
  expect_identical(max(acf_df$lag), 27)
})


test_that("residual ACF lag is truncated for short residual series", {
  r <- seq_len(20)

  expect_identical(
    .resolve_residual_plot_lag_max(r, frequency = 12, lag_max = NULL),
    19L
  )
})


test_that("residual histogram uses frequency y-axis label", {
  p <- .plot_residual_histogram(get_tempssm_residuals(res_tempssm))

  expect_s3_class(p, "ggplot")
  expect_identical(p$labels$y, "Frequency")
})


test_that("residual histogram overlays a normal curve", {
  r <- get_tempssm_residuals(res_tempssm)
  normal_df <- .residual_normal_curve_data(r)
  p <- .plot_residual_histogram(r)

  expect_gt(nrow(normal_df), 0)
  expect_named(normal_df, c("x", "y"))
  expect_length(p$layers, 3)
})


test_that("plot_tempssm_residuals validates inputs", {
  r <- get_tempssm_residuals(res_tempssm)

  expect_message(
    plot_tempssm_residuals(c(1, NA, 0, 0.5), panel = "histogram"),
    "The residual series includes missing values"
  )

  expect_error(
    plot_tempssm_residuals(1),
    "at least two residual values"
  )

  expect_error(
    plot_tempssm_residuals(c(1, Inf)),
    "infinite or NaN residual values"
  )

  expect_error(
    plot_tempssm_residuals(c(1, NA)),
    "at least two non-missing values"
  )

  expect_error(
    plot_tempssm_residuals(r, frequency = 0),
    "frequency.*positive numeric"
  )

  expect_error(
    plot_tempssm_residuals(r, lag_max = 0),
    "lag_max.*positive integer"
  )

  expect_error(
    plot_tempssm_residuals(r, panel = "qq"),
    "'arg' should be one of"
  )
})
