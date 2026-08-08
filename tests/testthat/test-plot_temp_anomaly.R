# tests/testthat/test-plot_temp_anomaly.R

test_that("plot_temp_anomaly returns a ggplot object", {
  temp_ts <- ts(
    rnorm(36, mean = 10),
    start = c(2000, 1),
    frequency = 12
  )

  p <- plot_temp_anomaly(temp_ts)

  expect_s3_class(p, "ggplot")
  expect_identical(rlang::as_label(p$mapping$x), "time")
  expect_identical(p$labels$title, "Temperature anomalies")
  expect_identical(p$labels$x, "Time (year)")
})


test_that("plot_temp_anomaly supports non-monthly seasonal frequencies", {
  temp_ts <- ts(rnorm(16), frequency = 4)

  p <- plot_temp_anomaly(temp_ts)

  expect_s3_class(p, "ggplot")
})


test_that("plot_temp_anomaly checks input class", {
  expect_error(
    plot_temp_anomaly(1:12),
    "`ts` must be an object of class <ts>."
  )
})


test_that("plot_temp_anomaly rejects multivariate input", {
  temp_ts <- ts(matrix(rnorm(24), ncol = 2), frequency = 12)

  expect_error(
    plot_temp_anomaly(temp_ts),
    "ts.*univariate"
  )
})


test_that("plot_temp_anomaly can break or connect lines across missing values", {
  temp_ts <- ts(
    c(1, 2, NA, 4, 5, 6, 7, 8),
    start = c(2000, 1),
    frequency = 4
  )

  p_broken <- plot_temp_anomaly(temp_ts)
  p_connected <- plot_temp_anomaly(temp_ts, connect_missing = TRUE)

  expect_true(anyNA(p_broken$data$anomaly))
  expect_false(anyNA(p_connected$data$anomaly))
  expect_identical(nrow(p_connected$data), nrow(p_broken$data) - 1L)
})


test_that("plot_temp_anomaly checks connect_missing", {
  temp_ts <- ts(rnorm(16), frequency = 4)

  expect_error(
    plot_temp_anomaly(temp_ts, connect_missing = "yes"),
    "`connect_missing` must be a single logical value"
  )
})
