expect_no_missing_or_undefined <- function(x) {
  if (is.list(x) && !is.data.frame(x)) {
    for (element in x) {
      expect_no_missing_or_undefined(element)
    }
    return(invisible(TRUE))
  }

  if (is.data.frame(x)) {
    for (column in x) {
      expect_no_missing_or_undefined(column)
    }
    return(invisible(TRUE))
  }

  expect_false(anyNA(x))

  if (is.numeric(x)) {
    expect_true(all(is.finite(x)))
  }

  invisible(TRUE)
}


get_ar1_ts_internal <- function(...) {
  getFromNamespace("get_ar1_ts", "tempssm")(...)
}

test_that("model accessors return complete finite values for complete fits", {
  expect_no_missing_or_undefined(get_level_ts(res_tempssm, ci = TRUE))
  expect_no_missing_or_undefined(get_drift_ts(res_tempssm, ci = TRUE))
  expect_no_missing_or_undefined(get_season_ts(res_tempssm, ci = TRUE))
  expect_no_missing_or_undefined(get_ar1_ts_internal(res_tempssm, ci = TRUE))
  expect_no_missing_or_undefined(get_tempssm_residuals(res_tempssm))
  expect_no_missing_or_undefined(get_exo_coef(res_tempssm_exo))
})


test_that("diagnostic and summary outputs are complete when defined", {
  diagnostics <- diagnose_residuals(res_tempssm, JB_test = TRUE)
  summary_obj <- summary(res_tempssm)

  expect_no_missing_or_undefined(diagnostics)
  expect_no_missing_or_undefined(summary_obj$fit)
  expect_no_missing_or_undefined(summary_obj$variances)
  expect_no_missing_or_undefined(summary_obj$coef_ar)
})


test_that("utility outputs from complete inputs have no missing values", {
  complete_ts <- ts(rep(1:12, 4), start = c(2000, 1), frequency = 12)
  complete_df <- data.frame(
    Date = seq.Date(as.Date("2001-01-01"), by = "month", length.out = 6),
    Temp = seq_len(6)
  )
  complete_zoo <- zoo::zoo(
    data.frame(Temp = seq_len(60)),
    order.by = seq.Date(as.Date("2001-01-01"), by = "day", length.out = 60)
  )

  expect_no_missing_or_undefined(compute_monthly_climatology(complete_ts))
  expect_no_missing_or_undefined(compute_temp_anomaly(complete_ts))
  expect_no_missing_or_undefined(convert_monthly_df_to_ts(complete_df))
  expect_no_missing_or_undefined(daily_zoo_to_monthly_ts(complete_zoo))
})


test_that("cross-validation outputs are complete for complete inputs", {
  folds <- ts_train_test_split(
    temp_ts_test,
    initial = 60,
    horizon = 12,
    step = 24
  )

  first_fold <- folds[[1]]
  expect_no_missing_or_undefined(first_fold$train_ts)
  expect_no_missing_or_undefined(first_fold$test_ts)
  expect_no_missing_or_undefined(first_fold$train_index)
  expect_no_missing_or_undefined(first_fold$test_index)
})
