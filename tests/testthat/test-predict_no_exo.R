# tests/testthat/test-predict_no_exo

.prediction_widths_widen <- function(interval_width,
                                      tol = sqrt(.Machine$double.eps)) {
  min(diff(interval_width)) >= -tol &&
    interval_width[length(interval_width)] > interval_width[1]
}


test_that(".predict_no_exo runs without error", {
  y_train <- window(temp_ts_small, end = c(2002, 12))
  y_train_named <- set_ts_name(y_train, label = "Temp", quiet = TRUE)

  res <- tempssm(y_train_named)

  expect_no_error({
    .predict_no_exo(res$model, h = 12)
  })
})


test_that("prediction length matches h", {
  y_train <- window(temp_ts_small, end = c(2002, 12))
  y_train_named <- set_ts_name(y_train, label = "Temp", quiet = TRUE)

  res <- tempssm(y_train_named)

  h <- 12
  pred <- .predict_no_exo(res$model, h)

  expect_length(pred, h)
})


test_that("prediction output has valid type", {
  y_train <- window(temp_ts_small, end = c(2002, 12))
  y_train_named <- set_ts_name(y_train, label = "Temp", quiet = TRUE)

  res <- tempssm(y_train_named)

  pred <- .predict_no_exo(res$model, h = 6)

  expect_true(
    is.numeric(pred) ||
      inherits(pred, "ts")
  )
})


test_that("different h produces different length", {
  y_train <- window(temp_ts_small, end = c(2002, 12))
  y_train_named <- set_ts_name(y_train, label = "Temp", quiet = TRUE)

  res <- tempssm(y_train_named)

  pred1 <- .predict_no_exo(res$model, h = 3)
  pred2 <- .predict_no_exo(res$model, h = 6)

  expect_length(pred1, 3)
  expect_length(pred2, 6)
})


test_that("works with minimal horizon h = 1", {
  y_train <- window(temp_ts_small, end = c(2002, 12))
  y_train_named <- set_ts_name(y_train, label = "Temp", quiet = TRUE)

  res <- tempssm(y_train_named)

  pred <- .predict_no_exo(res$model, h = 1)

  expect_length(pred, 1)
})


test_that("prediction intervals widen with forecast horizon", {
  data(sst_niigata)

  res <- tempssm(sst_niigata, na_action = "allow")
  pred <- stats::predict(
    res$model,
    n.ahead = 24,
    interval = "prediction",
    level = 0.95
  )

  interval_width <- as.numeric(pred[, "upr"] - pred[, "lwr"])

  expect_true(.prediction_widths_widen(interval_width))
})


test_that("prediction interval widening check detects violations", {
  expect_false(.prediction_widths_widen(c(3, 2, 1)))
  expect_false(.prediction_widths_widen(c(1, 1, 1)))
})
