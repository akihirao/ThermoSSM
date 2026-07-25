test_that("autoplot_ar1 returns a ggplot object", {
  p1 <- autoplot_ar1(res_tempssm)
  p2 <- autoplot_ar1(res_tempssm, ci = FALSE)

  expect_s3_class(p1, "ggplot")
  expect_s3_class(p2, "ggplot")
})


test_that("autoplot_ar1 hides CI label in title by default", {
  p1 <- autoplot_ar1(res_tempssm)
  p2 <- autoplot_ar1(res_tempssm, show_ci_in_title = TRUE)

  expect_identical(p1$labels$title, "Autoregressive (1) component")
  expect_identical(
    p2$labels$title,
    "Autoregressive (1) component (95% CI)"
  )
})


test_that("autoplot_ar1 uses compact unit label by default", {
  p <- autoplot_ar1(res_tempssm)

  expect_identical(rlang::as_label(p$mapping$x), "time")
  expect_identical(p$labels$x, "Time (year)")
  expect_identical(p$labels$y, expression(Temp. ~ (degree * C)))
})


test_that("autoplot_ar1 combines autoregressive states for higher-order AR models", {
  res_ar2 <- tempssm(temp_ts_test, ar_order = 2)
  p <- autoplot_ar1(res_ar2)

  expect_s3_class(p, "ggplot")
  expect_identical(p$labels$title, "Autoregressive component")
  expect_equal(
    p$data$value,
    rowSums(res_ar2$kfs$alphahat[, c("arima1", "arima2")]),
    tolerance = 1e-8
  )
})


test_that("autoplot_ar1 checks inputs correctly", {
  expect_error(
    autoplot_ar1(NULL),
    "`res` must be an object of class <tempssm>."
  )

  expect_error(
    autoplot_ar1(res_tempssm, ci_level = 1.5),
    "`ci_level` must be a numeric value between 0 and 1."
  )

  expect_error(
    autoplot_ar1(res_tempssm, ci = "yes"),
    "`ci` must be a single logical value"
  )

  expect_error(
    autoplot_ar1(res_tempssm, show_ci_in_title = "yes"),
    "`show_ci_in_title` must be a single logical value"
  )
})
