# tests/testthat/test-get_ar1_ts.R

get_ar1_ts_internal <- function(...) {
  getFromNamespace("get_ar1_ts", "tempssm")(...)
}

test_that("get_ar1_ts is not exported", {
  expect_false("get_ar1_ts" %in% getNamespaceExports("tempssm"))
})

test_that("get_ar1_ts basic structure", {
  ts_obj <- get_ar1_ts_internal(res_tempssm)

  check_ts_basic(ts_obj, res_tempssm)
  check_ts_univariate(ts_obj)
})

test_that("get_ar1_ts CI structure", {
  ts_ci <- get_ar1_ts_internal(res_tempssm, ci = TRUE)

  check_ts_ci_structure(ts_ci, "ar1")
})

test_that("get_ar1_ts CI values", {
  ts_ci <- get_ar1_ts_internal(res_tempssm, ci = TRUE)

  ci_obj <- stats::confint(res_tempssm$kfs)

  check_ts_ci_values(ts_ci, ci_obj, "arima1")
})


test_that("get_ar_ts supports first, sum, and individual AR components", {
  res_ar2 <- tempssm(temp_ts_test, ar_order = 2)

  first_ts <- get_ar_ts(res_ar2, component = "first")
  sum_ts <- get_ar_ts(res_ar2, component = "sum")
  individual_ts <- get_ar_ts(res_ar2, component = "individual")

  expect_equal(
    as.numeric(first_ts),
    as.numeric(get_ar1_ts_internal(res_ar2))
  )
  expect_equal(
    as.numeric(sum_ts),
    rowSums(res_ar2$kfs$alphahat[, c("arima1", "arima2")])
  )
  expect_true(all(c("ar1", "ar2") %in% colnames(individual_ts)))
})


test_that("get_ar_ts returns CI columns for individual AR states", {
  res_ar2 <- tempssm(temp_ts_test, ar_order = 2)
  ci_ts <- get_ar_ts(res_ar2, component = "individual", ci = TRUE)

  expect_true(all(c("ar1_lwr", "ar1_upr", "ar2_lwr", "ar2_upr") %in% colnames(ci_ts)))
})
