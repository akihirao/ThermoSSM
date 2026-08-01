# tests/testthat/test-get_tempssm_residuals.R

test_that("get_tempssm_residuals returns a time-preserving ts by default", {
  r <- get_tempssm_residuals(res_tempssm)

  expect_s3_class(r, "ts")
  expect_type(r, "double")
  expect_identical(stats::start(r), stats::start(res_tempssm$temp_data))
  expect_identical(stats::frequency(r), stats::frequency(res_tempssm$temp_data))
  expect_length(r, length(res_tempssm$temp_data))
})


test_that("default residuals match standardized recursive KFS residuals", {
  r <- get_tempssm_residuals(res_tempssm)
  expected <- stats::rstandard(res_tempssm$kfs, type = "recursive")
  expected[!is.finite(expected)] <- NA_real_

  expect_identical(as.numeric(r), as.numeric(expected))
})


test_that("get_tempssm_residuals can return finite numeric residuals", {
  r <- get_tempssm_residuals(res_tempssm, keep_time = FALSE)

  expect_type(r, "double")
  expect_gt(length(r), 0)
  expect_true(all(is.finite(r)))
})


test_that("get_tempssm_residuals can return response residuals", {
  r <- get_tempssm_residuals(res_tempssm, type = "response")
  expected <- stats::residuals(res_tempssm$kfs, type = "response")

  expect_s3_class(r, "ts")
  expect_identical(stats::start(r), stats::start(res_tempssm$temp_data))
  expect_identical(stats::frequency(r), stats::frequency(res_tempssm$temp_data))
  expect_identical(as.numeric(r), as.numeric(expected))
})


test_that("get_tempssm_residuals can return pearson residuals", {
  r <- get_tempssm_residuals(res_tempssm, type = "pearson")
  expected <- stats::rstandard(res_tempssm$kfs, type = "pearson")
  expected[!is.finite(expected)] <- NA_real_

  expect_s3_class(r, "ts")
  expect_identical(as.numeric(r), as.numeric(expected))
})


test_that("get_tempssm_residuals supports unstandardized recursive residuals", {
  r <- get_tempssm_residuals(
    res_tempssm,
    type = "recursive",
    standardized = FALSE
  )
  expected <- stats::residuals(res_tempssm$kfs, type = "recursive")
  expected[!is.finite(expected)] <- NA_real_

  expect_s3_class(r, "ts")
  expect_identical(as.numeric(r), as.numeric(expected))
})


test_that("get_tempssm_residuals can preserve time structure", {
  r <- get_tempssm_residuals(res_tempssm, keep_time = TRUE)

  expect_s3_class(r, "ts")
  expect_identical(stats::start(r), stats::start(res_tempssm$temp_data))
  expect_identical(stats::frequency(r), stats::frequency(res_tempssm$temp_data))
  expect_length(r, length(res_tempssm$temp_data))
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
  r_vec <- get_tempssm_residuals(res_with_nonfinite, keep_time = FALSE)

  expect_true(is.na(r_ts[1]))
  expect_true(all(is.finite(r_vec)))
})


test_that("get_tempssm_residuals checks input class", {
  expect_error(
    get_tempssm_residuals("not a model"),
    "`res` must be an object of class <tempssm>."
  )
})


test_that("get_tempssm_residuals validates residual type and standardization", {
  expect_error(
    get_tempssm_residuals(res_tempssm, type = "state"),
    "'arg' should be one of"
  )

  expect_error(
    get_tempssm_residuals(res_tempssm, standardized = c(TRUE, FALSE)),
    "standardized.*length one"
  )

  expect_error(
    get_tempssm_residuals(res_tempssm, standardized = 1),
    "standardized.*logical"
  )

  expect_error(
    get_tempssm_residuals(
      res_tempssm,
      type = "response",
      standardized = TRUE
    ),
    "Standardized response residuals are not available"
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
