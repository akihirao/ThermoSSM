# tests/testthat/test-ts_slice.R

test_that("ts_train_test_split returns list of folds", {
  folds <- ts_train_test_split(temp_ts_test)

  expect_type(folds, "list")
  expect_gt(length(folds), 0)

  fold_is_list <- vapply(folds, is.list, logical(1))

  expect_true(all(fold_is_list))
})


test_that("number of folds matches expected", {
  n <- length(temp_ts_test)
  initial <- 60
  horizon <- 12
  step <- 12

  expected <- floor((n - initial) / step)

  folds <- ts_train_test_split(
    temp_ts_test,
    initial = initial,
    horizon = horizon,
    step = step
  )

  expect_length(folds, expected)
})


test_that("each fold has required elements", {
  folds <- ts_train_test_split(temp_ts_test)

  f1 <- folds[[1]]

  expect_named(
    f1,
    c(
      "fold", "train_ts", "test_ts",
      "exo_train_ts", "exo_test_ts",
      "train_idx", "test_idx",
      "train_range", "test_range"
    )
  )
})


test_that("train and test indices are consistent", {
  folds <- ts_train_test_split(temp_ts_test)

  f1 <- folds[[1]]

  t_idx <- f1$train_idx
  s_idx <- f1$test_idx

  expect_gt(t_idx[2], t_idx[1])
  expect_gt(s_idx[2], s_idx[1])

  expect_identical(s_idx[1], t_idx[2] + 1)
})


test_that("train and test lengths match indices", {
  folds <- ts_train_test_split(temp_ts_test)

  f <- folds[[1]]

  expect_length(
    f$train_ts,
    diff(f$train_idx) + 1
  )

  expect_length(
    f$test_ts,
    diff(f$test_idx) + 1
  )
})


test_that("fixed vs expanding window works correctly", {
  f_exp <- ts_train_test_split(temp_ts_test,
    fixed_window = FALSE
  )

  f_fix <- ts_train_test_split(temp_ts_test,
    fixed_window = TRUE
  )

  # expanding
  expect_gt(
    length(f_exp[[2]]$train_ts),
    length(f_exp[[1]]$train_ts)
  )

  # fixed → 一定
  expect_length(
    f_fix[[2]]$train_ts,
    length(f_fix[[1]]$train_ts)
  )
})


test_that("allow_partial changes final fold", {
  f1 <- ts_train_test_split(
    temp_ts_test,
    allow_partial = FALSE
  )

  f2 <- ts_train_test_split(
    temp_ts_test,
    allow_partial = TRUE
  )

  expect_gte(length(f2), length(f1))
})


test_that("ts_train_test_split can error on missing values", {
  temp_ts <- temp_ts_test
  temp_ts[2] <- NA

  expect_error(
    ts_train_test_split(temp_ts, na_action = "error"),
    "The input temperature series includes missing values"
  )
})


test_that("ts_train_test_split rejects missing exogenous values", {
  exo_ts <- exo_ts_test
  exo_ts[2] <- NA

  expect_error(
    ts_train_test_split(
      temp_ts_test,
      exo_data = exo_ts,
      na_action = "allow"
    ),
    "Exogenous covariates must be complete"
  )
})


test_that("ts_train_test_split validates scalar argument lengths", {
  expect_error(
    ts_train_test_split(temp_ts_test, initial = c(24, 36)),
    "initial.*length one"
  )

  expect_error(
    ts_train_test_split(temp_ts_test, horizon = c(6, 12)),
    "horizon.*length one"
  )

  expect_error(
    ts_train_test_split(temp_ts_test, step = c(6, 12)),
    "step.*length one"
  )

  expect_error(
    ts_train_test_split(temp_ts_test, fixed_window = c(TRUE, FALSE)),
    "fixed_window.*length one"
  )

  expect_error(
    ts_train_test_split(temp_ts_test, allow_partial = c(TRUE, FALSE)),
    "allow_partial.*length one"
  )
})


test_that("ts_train_test_split validates scalar argument types", {
  expect_error(
    ts_train_test_split(temp_ts_test, initial = "60"),
    "initial.*numeric"
  )

  expect_error(
    ts_train_test_split(temp_ts_test, horizon = "12"),
    "horizon.*numeric"
  )

  expect_error(
    ts_train_test_split(temp_ts_test, step = "12"),
    "step.*numeric"
  )

  expect_error(
    ts_train_test_split(temp_ts_test, fixed_window = 1),
    "fixed_window.*logical"
  )

  expect_error(
    ts_train_test_split(temp_ts_test, allow_partial = 1),
    "allow_partial.*logical"
  )
})


test_that("ts_train_test_split rejects multivariate temperature series", {
  temp_multi <- ts(matrix(rnorm(240), ncol = 2),
    start = c(2000, 1), frequency = 12
  )

  expect_error(
    ts_train_test_split(temp_multi),
    "temp_data.*univariate"
  )
})


test_that("works with exogenous variables", {
  folds <- ts_train_test_split(
    temp_ts_test,
    exo_data = exo_ts_test
  )

  f1 <- folds[[1]]

  expect_s3_class(f1$exo_train_ts, "ts")
  expect_s3_class(f1$exo_test_ts, "ts")

  expect_length(
    f1$exo_train_ts,
    length(f1$train_ts)
  )
})


test_that("rejects exogenous variables with a different time index", {
  exo_ts <- ts(rnorm(length(temp_ts_test)),
    start = c(2001, 1),
    frequency = frequency(temp_ts_test)
  )
  exo_ts <- set_ts_name(exo_ts, label = "x", quiet = TRUE)

  expect_error(
    ts_train_test_split(
      temp_ts_test,
      exo_data = exo_ts
    ),
    "Time index"
  )
})


test_that("exo_data is NULL when not provided", {
  folds <- ts_train_test_split(temp_ts_test)

  expect_null(folds[[1]]$exo_train_ts)
  expect_null(folds[[1]]$exo_test_ts)
})
