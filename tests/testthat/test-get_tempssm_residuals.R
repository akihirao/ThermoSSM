# tests/testthat/test-get_tempssm_residuals.R

test_that("get_tempssm_residuals returns a numeric vector", {
  r <- get_tempssm_residuals(res_tempssm)

  expect_type(r, "double")
  expect_gt(length(r), 0)
  expect_true(all(is.finite(r)))
})


test_that("get_tempssm_residuals can preserve time structure", {
  r <- get_tempssm_residuals(res_tempssm, keep_time = TRUE)

  expect_s3_class(r, "ts")
  expect_identical(stats::start(r), stats::start(res_tempssm$temp_data))
  expect_identical(stats::frequency(r), stats::frequency(res_tempssm$temp_data))
  expect_identical(length(r), length(res_tempssm$temp_data))
})


test_that("time-preserving residuals retain non-finite values as missing", {
  res_with_nonfinite <- res_tempssm
  res_with_nonfinite$kfs <- res_tempssm$kfs

  r <- stats::rstandard(res_with_nonfinite$kfs, type = "recursive")
  r[1] <- Inf
  mockery::stub(
    get_tempssm_residuals,
    "stats::rstandard",
    r
  )

  r_ts <- get_tempssm_residuals(res_with_nonfinite, keep_time = TRUE)
  r_vec <- get_tempssm_residuals(res_with_nonfinite)

  expect_true(is.na(r_ts[1]))
  expect_false(any(!is.finite(r_vec)))
})


test_that("get_tempssm_residuals checks input class", {
  expect_error(
    get_tempssm_residuals("not a model"),
    "`res` must be an object of class <tempssm>."
  )
})


test_that("get_tempssm_residuals validates keep_time", {
  expect_error(
    get_tempssm_residuals(res_tempssm, keep_time = c(TRUE, FALSE)),
    "keep_time.*length one"
  )

  expect_error(
    get_tempssm_residuals(res_tempssm, keep_time = 1),
    "keep_time.*logical"
  )
})
