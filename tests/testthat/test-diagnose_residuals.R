# tests/testthat/test-diagnose_residuals.R

# JB test is not performed
test_that("diagnose_residuals returns a tibble", {
  diag <- diagnose_residuals(res_tempssm)

  expect_s3_class(diag, "tbl_df")
  expect_identical(nrow(diag), 1L)

  expect_true(
    all(c("lb_stat", "lb_lag", "lb_pvalue", "kurtosis") %in% colnames(diag))
  )
})


test_that("diagnose_residuals informs about missing residual handling", {
  expect_message(
    diag <- diagnose_residuals(res_tempssm),
    "available finite residual sequence"
  )

  expect_s3_class(diag, "tbl_df")
})


test_that("diagnose_residuals uses seasonal frequency as default LB lag", {
  diag <- diagnose_residuals(res_tempssm)

  expect_identical(
    diag$lb_lag,
    as.numeric(stats::frequency(res_tempssm$temp_data))
  )
})


test_that("diagnose_residuals default LB lag follows non-monthly frequency", {
  quarterly_res <- res_tempssm
  quarterly_res$temp_data <- stats::ts(
    as.numeric(res_tempssm$temp_data),
    start = c(2000, 1),
    frequency = 4
  )

  diag <- diagnose_residuals(quarterly_res)

  expect_identical(diag$lb_lag, 4)
})


test_that("default Ljung-Box lag is truncated for short residual series", {
  short_res <- res_tempssm
  short_res$temp_data <- stats::ts(
    seq_len(6),
    start = c(2000, 1),
    frequency = 12
  )

  expect_identical(
    .resolve_ljung_box_lag(short_res, lb_lag = NULL, n_residuals = 6L),
    5L
  )
})


test_that("diagnose_residuals supports explicit Ljung-Box lag", {
  diag <- diagnose_residuals(res_tempssm, lb_lag = 24)

  expect_identical(diag$lb_lag, 24)
})


# JB test is performed
test_that("diagnose_residuals includes Jarque-Bera results when requested", {
  diag <- diagnose_residuals(res_tempssm, JB_test = TRUE)

  expect_s3_class(diag, "tbl_df")
  expect_true(
    all(c("jb_stat", "jb_pvalue") %in% colnames(diag))
  )
})


test_that("diagnose_residuals checks input class", {
  expect_error(
    diagnose_residuals(NULL),
    "`res` must be an object of class <tempssm>."
  )
})


test_that("diagnose_residuals validates scalar argument lengths", {
  expect_error(
    diagnose_residuals(res_tempssm, JB_test = c(TRUE, FALSE)),
    "JB_test.*length one"
  )

  expect_error(
    diagnose_residuals(res_tempssm, lb_lag = c(12, 24)),
    "lb_lag.*length one"
  )
})


test_that("diagnose_residuals validates scalar argument types", {
  expect_error(
    diagnose_residuals(res_tempssm, JB_test = 1),
    "JB_test.*logical"
  )

  expect_error(
    diagnose_residuals(res_tempssm, lb_lag = "12"),
    "lb_lag.*numeric"
  )
})


test_that("diagnose_residuals validates Ljung-Box lag values", {
  expect_error(
    diagnose_residuals(res_tempssm, lb_lag = 0),
    "lb_lag.*positive integer"
  )

  expect_error(
    diagnose_residuals(res_tempssm, lb_lag = 1.5),
    "lb_lag.*positive integer"
  )

  expect_error(
    diagnose_residuals(
      res_tempssm,
      lb_lag = length(get_tempssm_residuals(
        res_tempssm,
        keep_time = FALSE
      ))
    ),
    "lb_lag.*smaller than the number of finite residuals"
  )
})


test_that("diagnose_residual_ts matches Box.test for complete residuals", {
  r <- stats::ts(
    sin(seq_len(60) / 4) + cos(seq_len(60) / 7),
    start = c(2000, 1),
    frequency = 12
  )

  diag <- diagnose_residual_ts(r, lb_lag = 12)
  lb <- stats::Box.test(r, type = "Ljung-Box", lag = 12)

  expect_s3_class(diag, "tbl_df")
  expect_identical(diag$lb_lag, 12L)
  expect_identical(diag$lb_df, 12L)
  expect_identical(diag$n, 60L)
  expect_identical(diag$n_missing, 0L)
  expect_identical(diag$n_finite, 60L)
  expect_equal(diag$lb_stat, unname(lb$statistic), tolerance = 1e-10)
  expect_equal(diag$lb_pvalue, lb$p.value, tolerance = 1e-10)
})


test_that(
  "diagnose_residual_ts handles missing residuals with time structure",
  {
  r <- stats::ts(
    sin(seq_len(60) / 4) + cos(seq_len(60) / 7),
    start = c(2000, 1),
    frequency = 12
  )
  r[c(5, 20)] <- NA_real_

  expect_message(
    diag <- diagnose_residual_ts(r),
    "available-pair autocorrelations"
  )

  expect_s3_class(diag, "tbl_df")
  expect_identical(diag$lb_lag, 12L)
  expect_identical(diag$n, 60L)
  expect_identical(diag$n_missing, 2L)
  expect_identical(diag$n_finite, 58L)
  expect_true(is.finite(diag$lb_stat))
  expect_true(is.finite(diag$lb_pvalue))
  }
)


test_that("diagnose_residual_ts follows frequency for default lag", {
  r <- stats::ts(seq_len(20), start = c(2000, 1), frequency = 4)
  diag <- diagnose_residual_ts(r)

  expect_identical(diag$lb_lag, 4L)
})


test_that("diagnose_residual_ts validates inputs", {
  expect_error(
    diagnose_residual_ts(1),
    "at least two residual values"
  )

  expect_error(
    diagnose_residual_ts(c(1, Inf)),
    "infinite or NaN residual values"
  )

  expect_error(
    diagnose_residual_ts(c(1, NA)),
    "at least two finite residual"
  )

  expect_error(
    diagnose_residual_ts(c(1, 2, 3), frequency = 0),
    "frequency.*positive numeric"
  )

  expect_error(
    diagnose_residual_ts(c(1, 2, 3), lb_lag = 0),
    "lb_lag.*positive integer"
  )

  expect_error(
    diagnose_residual_ts(c(1, 2, 3), lb_lag = 3),
    "lb_lag.*smaller than the number of finite residuals"
  )
})


test_that(".kurtosis removes missing values when requested", {
  x <- c(1, 2, NA, 3, 4)

  expect_true(is.na(.kurtosis(x)))
  expect_false(is.na(.kurtosis(x, na.rm = TRUE)))
})


test_that("plot_tempssm_residual_diagnostics can save plots", {
  prefix <- file.path(tempdir(), "tempssm-residuals")
  check_file <- paste0(prefix, "_check.png")
  qq_file <- paste0(prefix, "_qq.png")

  withr::defer(unlink(c(check_file, qq_file)))

  expect_invisible(
    plot_tempssm_residual_diagnostics(res_tempssm, save = TRUE, prefix = prefix)
  )
  expect_true(file.exists(check_file))
  expect_true(file.exists(qq_file))
})


test_that("plot_tempssm_residual_diagnostics normalizes prefix extensions", {
  prefix <- file.path(tempdir(), "tempssm-residuals.png")
  check_file <- file.path(tempdir(), "tempssm-residuals_check.png")
  qq_file <- file.path(tempdir(), "tempssm-residuals_qq.png")
  unexpected_file <- paste0(prefix, "_check.png")

  withr::defer(unlink(c(check_file, qq_file, unexpected_file)))

  expect_invisible(
    plot_tempssm_residual_diagnostics(res_tempssm, save = TRUE, prefix = prefix)
  )
  expect_true(file.exists(check_file))
  expect_true(file.exists(qq_file))
  expect_false(file.exists(unexpected_file))
})


test_that(
  "plot_tempssm_residual_diagnostics validates scalar argument lengths",
  {
  expect_error(
    plot_tempssm_residual_diagnostics(res_tempssm, save = c(TRUE, FALSE)),
    "save.*length one"
  )

  expect_error(
    plot_tempssm_residual_diagnostics(
      res_tempssm,
      prefix = c("a", "b")
    ),
    "prefix.*length one"
  )
  }
)


test_that("plot_tempssm_residual_diagnostics validates scalar argument types", {
  expect_error(
    plot_tempssm_residual_diagnostics(res_tempssm, save = 1),
    "save.*logical"
  )

  expect_error(
    plot_tempssm_residual_diagnostics(res_tempssm, prefix = 1),
    "prefix.*character"
  )
})
