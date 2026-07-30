test_that("CV execution controls preserve valid values", {
  controls <- .prepare_ts_cv_run_controls(
    parallel = FALSE,
    workers = 2,
    progress = TRUE
  )

  expect_identical(
    controls,
    list(parallel = FALSE, workers = 2, progress = TRUE)
  )
})


test_that("ts_cv_run defaults to sequential execution", {
  expect_false(formals(ts_cv_run)$parallel)
  expect_null(formals(ts_cv_run)$workers)
})


test_that("CV execution controls resolve default worker counts", {
  expect_identical(
    .prepare_ts_cv_run_controls(FALSE, NULL, FALSE)$workers,
    1L
  )
})


test_that("CV execution controls reject missing logical values", {
  expect_error(
    .prepare_ts_cv_run_controls(NA, 1, FALSE),
    "parallel.*logical scalar"
  )
  expect_error(
    .prepare_ts_cv_run_controls(FALSE, 1, NA),
    "progress.*logical scalar"
  )
})


test_that("CV execution controls reject invalid worker counts", {
  expect_error(
    .prepare_ts_cv_run_controls(FALSE, 0, FALSE),
    "workers.*positive integer"
  )
  expect_error(
    .prepare_ts_cv_run_controls(FALSE, 1.5, FALSE),
    "workers.*positive integer"
  )
  expect_error(
    .prepare_ts_cv_run_controls(FALSE, NA_real_, FALSE),
    "workers.*positive integer"
  )
})
