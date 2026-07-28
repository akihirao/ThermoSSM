test_that("base R nottem data retain known monthly time-series properties", {
  data("nottem", package = "datasets")

  expect_s3_class(nottem, "ts")
  expect_identical(stats::start(nottem), c(1920, 1))
  expect_identical(stats::end(nottem), c(1939, 12))
  expect_identical(stats::frequency(nottem), 12)
  expect_length(nottem, 240L)
  expect_equal(as.numeric(nottem[1:6]), c(40.6, 40.8, 44.4, 46.7, 54.1, 58.5))
})


test_that("monthly climatology works with the standard nottem data", {
  data("nottem", package = "datasets")

  climatology <- compute_monthly_climatology(nottem)

  expect_s3_class(climatology, "tbl_df")
  expect_identical(nrow(climatology), 12L)
  expect_identical(climatology$Month, 1:12)
  expect_equal(climatology$Temperature[1:3], c(39.695, 39.19, 42.195))
})


test_that("time-series CV splitting works with the standard nottem data", {
  data("nottem", package = "datasets")

  folds <- ts_train_test_split(
    nottem,
    initial = 120,
    horizon = 12,
    step = 24
  )

  expect_length(folds, 5)
  expect_identical(stats::start(folds[[1]]$train_ts), c(1920, 1))
  expect_identical(stats::start(folds[[1]]$test_ts), c(1930, 1))
  expect_length(folds[[1]]$train_ts, 120L)
  expect_length(folds[[1]]$test_ts, 12L)
})


test_that("package data used in examples and tests are exported", {
  package_data <- c(
    "fuji_temp",
    "hmo_temp",
    "nao",
    "niigata_sst",
    "pdo",
    "sst_jogashima",
    "sst_niigata",
    "sst_yamaguchi",
    "soi",
    "temp_MtFuji",
    "yamaguchi_sst"
  )

  for (dataset in package_data) {
    data_env <- new.env(parent = emptyenv())
    utils::data(list = dataset, package = "tempssm", envir = data_env)

    expect_true(exists(dataset, envir = data_env, inherits = FALSE))

    dataset_value <- get(dataset, envir = data_env, inherits = FALSE)
    expect_s3_class(dataset_value, "ts")
    expect_identical(stats::frequency(dataset_value), 12)
    expect_gt(length(dataset_value), 0)
  }
})
