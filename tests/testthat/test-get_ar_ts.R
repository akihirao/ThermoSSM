# tests/testthat/test-get_ar_ts.R

test_that("get_ar_ts returns the first AR component", {
  ts_obj <- get_ar_ts(res_tempssm, component = "first")

  check_ts_basic(ts_obj, res_tempssm)
  check_ts_univariate(ts_obj)
})

test_that("get_ar_ts returns CI columns for the first AR component", {
  ts_ci <- get_ar_ts(res_tempssm, component = "first", ci = TRUE)

  check_ts_ci_structure(ts_ci, "ar1")
})

test_that("get_ar_ts first-component CI values match KFAS output", {
  ts_ci <- get_ar_ts(res_tempssm, component = "first", ci = TRUE)

  ci_obj <- stats::confint(res_tempssm$kfs)

  check_ts_ci_values(ts_ci, ci_obj, "arima1")
})


test_that("get_ar_ts supports first, sum, and individual AR components", {
  res_ar2 <- tempssm(temp_ts_test, ar_order = 2)

  first_ts <- get_ar_ts(res_ar2, component = "first")
  sum_ts <- get_ar_ts(res_ar2, component = "sum")
  individual_ts <- get_ar_ts(res_ar2, component = "individual")

  expect_identical(
    as.numeric(first_ts),
    as.numeric(res_ar2$kfs$alphahat[, "arima1"])
  )
  expect_identical(
    as.numeric(sum_ts),
    rowSums(res_ar2$kfs$alphahat[, c("arima1", "arima2")])
  )
  expect_true(all(c("ar1", "ar2") %in% colnames(individual_ts)))
})


test_that("get_ar_ts returns CI columns for individual AR states", {
  res_ar2 <- tempssm(temp_ts_test, ar_order = 2)
  ci_ts <- get_ar_ts(res_ar2, component = "individual", ci = TRUE)

  expect_true(
    all(c("ar1_lwr", "ar1_upr", "ar2_lwr", "ar2_upr") %in% colnames(ci_ts))
  )
})


test_that("get_ar_ts masks filtered sum and individual outputs", {
  res_ar2 <- tempssm(temp_ts_test, ar_order = 2)
  diffuse_idx <- seq_len(res_ar2$kfs$d)

  filtered_sum <- get_ar_ts(
    res_ar2,
    component = "sum",
    estimate = "filtered"
  )
  filtered_individual <- get_ar_ts(
    res_ar2,
    component = "individual",
    estimate = "filtered"
  )

  expect_s3_class(filtered_sum, "ts")
  expect_s3_class(filtered_individual, "ts")
  expect_true(all(is.na(filtered_sum[diffuse_idx])))
  expect_true(all(is.na(filtered_individual[diffuse_idx, ])))
  expect_false(anyNA(filtered_sum[-diffuse_idx]))
})


test_that("get_ar_ts validates filtered AR state availability", {
  bad_res <- res_tempssm
  bad_res$kfs$att <- bad_res$kfs$att[, "level", drop = FALSE]

  expect_error(
    get_ar_ts(bad_res, estimate = "filtered"),
    "Autoregressive component not found"
  )
})


test_that("get_ar_ts validates CI content for AR sums and individuals", {
  testthat::local_mocked_bindings(
    confint = function(...) list(level = matrix(0)),
    .package = "stats"
  )

  expect_error(
    get_ar_ts(res_tempssm, component = "sum", ci = TRUE),
    "Autoregressive component not found in confidence intervals"
  )
  expect_error(
    get_ar_ts(res_tempssm, component = "individual", ci = TRUE),
    "Autoregressive component not found in confidence intervals"
  )
})
