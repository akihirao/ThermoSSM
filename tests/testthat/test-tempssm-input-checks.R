# tests/testthat/test-tempssm-input-checks.R

test_that(".tempssm_check_temp_ts accepts valid univariate ts", {
  temp_ts <- ts(rnorm(24), start = c(2000, 1), frequency = 12)

  expect_identical(.tempssm_check_temp_ts(temp_ts), temp_ts)
})


test_that(".tempssm_check_temp_ts accepts arbitrary seasonal frequencies", {
  temp_ts <- ts(rnorm(16), start = c(2000, 1), frequency = 4)

  checked <- .tempssm_check_temp_ts(temp_ts)

  expect_identical(frequency(checked), 4)
  expect_identical(start(checked), c(2000, 1))
})


test_that(".tempssm_check_temp_ts rejects invalid temperature series", {
  expect_error(
    .tempssm_check_temp_ts(1:10),
    "must be a <ts> object"
  )

  expect_error(
    .tempssm_check_temp_ts(ts(rnorm(10), frequency = 1)),
    "frequency > 1"
  )

  expect_error(
    .tempssm_check_temp_ts(ts(rnorm(10), frequency = 4.5)),
    "integer frequency"
  )

  multi_ts <- ts(matrix(rnorm(24), ncol = 2), frequency = 12)

  expect_error(
    .tempssm_check_temp_ts(multi_ts),
    "must be univariate"
  )
})


test_that("tempssm validates scalar argument lengths", {
  temp_ts <- ts(rnorm(24), start = c(2000, 1), frequency = 12)

  expect_error(
    tempssm(temp_ts, ar_order = c(1, 2)),
    "ar_order.*length one"
  )

  expect_error(
    tempssm(temp_ts, use_season = c(TRUE, FALSE)),
    "use_season.*length one"
  )

  expect_error(
    tempssm(temp_ts, maxit = c(100, 200)),
    "maxit.*length one"
  )

  expect_error(
    tempssm(temp_ts, reltol = c(1e-8, 1e-10)),
    "reltol.*length one"
  )

  expect_error(
    tempssm(temp_ts, inits = c(1, 2)),
    "inits.*length"
  )

  expect_error(
    tempssm(temp_ts, na_action = c("inform", "warn")),
    "length"
  )
})


test_that("tempssm validates scalar and vector argument types", {
  temp_ts <- ts(rnorm(24), start = c(2000, 1), frequency = 12)

  expect_error(
    tempssm(temp_ts, ar_order = "1"),
    "ar_order.*numeric"
  )

  expect_error(
    tempssm(temp_ts, use_season = 1),
    "use_season.*logical"
  )

  expect_error(
    tempssm(temp_ts, inits = rep("x", 5)),
    "inits.*numeric"
  )

  expect_error(
    tempssm(temp_ts, maxit = "100"),
    "maxit.*numeric"
  )

  expect_error(
    tempssm(temp_ts, reltol = "1e-8"),
    "reltol.*numeric"
  )
})


test_that("tempssm validates na_action choices strictly", {
  temp_ts <- ts(rnorm(24), start = c(2000, 1), frequency = 12)

  expect_error(
    tempssm(temp_ts, na_action = "drop"),
    "should be one of"
  )

  expect_error(
    tempssm(temp_ts, na_action = "WARN"),
    "should be one of"
  )
})


test_that("tempssm warns for high AR orders", {
  temp_ts <- ts(rnorm(36), start = c(2000, 1), frequency = 12)

  warning_state <- new.env(parent = emptyenv())
  warning_state$messages <- character(0)
  withCallingHandlers(
    tempssm(temp_ts, ar_order = 5, maxit = 1, reltol = 1e-4),
    warning = function(w) {
      warning_state$messages <- c(
        warning_state$messages,
        conditionMessage(w)
      )
      invokeRestart("muffleWarning")
    }
  )

  expect_true(any(grepl(
    "ar_order.*greater than 4",
    warning_state$messages
  )))
})


test_that(".tempssm_check_exo_ts accepts aligned named exogenous series", {
  temp_ts <- ts(rnorm(24), start = c(2000, 1), frequency = 12)
  exo_ts <- ts(
    matrix(rnorm(48), ncol = 2),
    start = c(2000, 1),
    frequency = 12
  )
  colnames(exo_ts) <- c("x1", "x2")

  expect_identical(.tempssm_check_exo_ts(temp_ts, exo_ts), exo_ts)
})


test_that(".tempssm_check_exo_ts rejects invalid exogenous series", {
  temp_ts <- ts(rnorm(24), start = c(2000, 1), frequency = 12)

  expect_error(
    .tempssm_check_exo_ts(temp_ts, 1:24),
    "must be a <ts> object"
  )

  exo_bad_freq <- ts(rnorm(8), start = c(2000, 1), frequency = 4)
  exo_bad_freq <- set_ts_name(exo_bad_freq, label = "x", quiet = TRUE)

  expect_error(
    .tempssm_check_exo_ts(temp_ts, exo_bad_freq),
    "Frequency"
  )

  exo_bad_time <- ts(rnorm(24), start = c(2001, 1), frequency = 12)
  exo_bad_time <- set_ts_name(exo_bad_time, label = "x", quiet = TRUE)

  expect_error(
    .tempssm_check_exo_ts(temp_ts, exo_bad_time),
    "Time index"
  )

  exo_no_name <- ts(rnorm(24), start = c(2000, 1), frequency = 12)

  expect_error(
    .tempssm_check_exo_ts(temp_ts, exo_no_name),
    "column name"
  )
})


test_that(".tempssm_prepare_model_inputs validates and standardizes inputs", {
  temp_ts <- ts(rnorm(24), start = c(2000, 1), frequency = 12)
  exo_ts <- ts(rnorm(24), start = c(2000, 1), frequency = 12)

  expect_warning(
    prepared <- .tempssm_prepare_model_inputs(
      temp_data = temp_ts,
      exo_data = exo_ts,
      allow_unnamed_exo = TRUE,
      default_exo_names = TRUE
    ),
    "assigning default names"
  )

  expect_identical(prepared$temp_data, temp_ts)
  expect_s3_class(prepared$exo_data, "ts")
  expect_identical(colnames(prepared$exo_data), "var1")
  expect_identical(prepared$frequency, 12)
  expect_identical(prepared$n_obs, 24L)
  expect_identical(start(prepared$temp_data), start(temp_ts))
  expect_identical(end(prepared$temp_data), end(temp_ts))
  expect_identical(frequency(prepared$temp_data), frequency(temp_ts))
  expect_identical(time(prepared$temp_data), time(temp_ts))
  expect_identical(start(prepared$exo_data), start(exo_ts))
  expect_identical(end(prepared$exo_data), end(exo_ts))
  expect_identical(frequency(prepared$exo_data), frequency(exo_ts))
  expect_identical(time(prepared$exo_data), time(exo_ts))
})


test_that(".tempssm_prepare_model_inputs accepts multivariate exogenous ts", {
  temp_ts <- ts(rnorm(24), start = c(2000, 1), frequency = 12)
  exo_ts <- ts(
    matrix(rnorm(48), ncol = 2),
    start = c(2000, 1),
    frequency = 12
  )
  colnames(exo_ts) <- c("x1", "x2")

  prepared <- .tempssm_prepare_model_inputs(
    temp_data = temp_ts,
    exo_data = exo_ts
  )

  expect_identical(prepared$exo_data, exo_ts)
})


test_that(".tempssm_prepare_model_inputs handles missing values by policy", {
  temp_ts <- ts(c(1, NA, 3, 4), start = c(2000, 1), frequency = 4)
  withr::local_envvar(TEMPSSM_VERBOSITY = "")
  withr::local_options(list(tempssm.verbosity = "inform"))

  expect_message(
    prepared_inform <- .tempssm_prepare_model_inputs(temp_ts),
    "The input temperature series includes missing values"
  )
  expect_message(
    .tempssm_prepare_model_inputs(temp_ts),
    "Series length: 4; missing values: 1 \\(25.0%\\)"
  )
  expect_message(
    .tempssm_prepare_model_inputs(temp_ts),
    "This is supported"
  )
  expect_true(anyNA(prepared_inform$temp_data))

  expect_warning(
    prepared_warn <- .tempssm_prepare_model_inputs(
      temp_ts,
      na_action = "warn"
    ),
    "unobserved responses"
  )
  expect_true(anyNA(prepared_warn$temp_data))

  expect_error(
    .tempssm_prepare_model_inputs(temp_ts, na_action = "error"),
    "The input temperature series includes missing values"
  )

  expect_silent(
    prepared_allow <- .tempssm_prepare_model_inputs(
      temp_ts,
      na_action = "allow"
    )
  )
  expect_true(anyNA(prepared_allow$temp_data))
})


test_that(
  ".tempssm_prepare_model_inputs rejects undefined temperature values",
  {
  temp_nan <- ts(c(1, NaN, 3, 4), start = c(2000, 1), frequency = 4)
  temp_inf <- ts(c(1, Inf, 3, 4), start = c(2000, 1), frequency = 4)

  expect_error(
    .tempssm_prepare_model_inputs(temp_nan, na_action = "allow"),
    "NaN"
  )

  expect_error(
    .tempssm_prepare_model_inputs(temp_inf, na_action = "allow"),
    "Inf"
  )
  }
)


test_that(".tempssm_prepare_model_inputs rejects missing exogenous values", {
  temp_ts <- ts(rnorm(4), start = c(2000, 1), frequency = 4)
  exo_ts <- ts(c(1, NA, 3, 4), start = c(2000, 1), frequency = 4)
  exo_ts <- set_ts_name(exo_ts, label = "x", quiet = TRUE)

  expect_error(
    .tempssm_prepare_model_inputs(
      temp_data = temp_ts,
      exo_data = exo_ts
    ),
    "Exogenous covariates must be complete"
  )

  expect_error(
    .tempssm_prepare_model_inputs(
      temp_data = temp_ts,
      exo_data = exo_ts,
      na_action = "allow"
    ),
    "Exogenous covariates must be complete"
  )
})


test_that(".tempssm_prepare_model_inputs rejects undefined exogenous values", {
  temp_ts <- ts(rnorm(4), start = c(2000, 1), frequency = 4)
  exo_ts <- ts(c(1, Inf, 3, 4), start = c(2000, 1), frequency = 4)
  exo_ts <- set_ts_name(exo_ts, label = "x", quiet = TRUE)

  expect_error(
    .tempssm_prepare_model_inputs(
      temp_data = temp_ts,
      exo_data = exo_ts
    ),
    "Inf"
  )
})


test_that(".tempssm_prepare_model_inputs rejects misaligned exogenous ts", {
  temp_ts <- ts(rnorm(24), start = c(2000, 1), frequency = 12)
  exo_ts <- ts(rnorm(24), start = c(2001, 1), frequency = 12)
  exo_ts <- set_ts_name(exo_ts, label = "x", quiet = TRUE)

  expect_error(
    .tempssm_prepare_model_inputs(
      temp_data = temp_ts,
      exo_data = exo_ts
    ),
    "Time index"
  )
})


test_that(".tempssm_prepare_model_inputs accepts units ts input", {
  skip_if_not_installed("units")

  temp_units <- units::set_units(seq_len(24), "K")
  temp_ts <- ts(as.numeric(temp_units),
    start = c(2000, 1),
    frequency = 12
  )
  class(temp_ts) <- c("units", class(temp_ts))
  attr(temp_ts, "units") <- attr(temp_units, "units")

  expect_warning(
    prepared <- .tempssm_prepare_model_inputs(temp_ts),
    "converted to numeric"
  )

  expect_s3_class(prepared$temp_data, "ts")
  expect_false(inherits(prepared$temp_data, "units"))
  expect_identical(as.numeric(prepared$temp_data), as.numeric(temp_units))
  expect_identical(start(prepared$temp_data), c(2000, 1))
  expect_identical(frequency(prepared$temp_data), 12)
})
