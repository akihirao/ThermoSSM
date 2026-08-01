# tests/testthat/test-summary.R

# test for summary object
test_that("summary.tempssm returns a valid summary object", {
  s <- summary(res_tempssm)

  expect_s3_class(s, "summary.tempssm")
  expect_type(s, "list")
})


# test for structure
test_that("summary contains expected components", {
  s <- summary(res_tempssm)

  expected_names <- c(
    "call",
    "logLik",
    "marginal",
    "k",
    "diffuse_states",
    "convergence",
    "variances",
    "coef_ar",
    "exogenous",
    "exogenous_coef"
  )

  expect_named(s, expected_names)
})


test_that("summary exposes logLik metadata without AIC", {
  s <- summary(res_tempssm)
  ll <- logLik(res_tempssm)

  expect_identical(s$logLik, as.numeric(ll))
  expect_identical(s$marginal, attr(ll, "marginal"))
  expect_identical(s$k, attr(ll, "df"))
  expect_false("AIC" %in% names(s))
})


test_that("summary reports NA logLik for non-converged models", {
  res <- res_tempssm
  res$converged <- FALSE
  res$fit$optim.out$convergence <- 1

  s <- summary(res)

  expect_identical(s$logLik, NA_real_)
  expect_identical(s$k, length(res$fit$optim.out$par))
  expect_false(s$convergence)
})


test_that("summary can use an explicit diffuse likelihood", {
  s <- summary(res_tempssm, marginal = FALSE)
  ll <- logLik(res_tempssm, marginal = FALSE)

  expect_false(s$marginal)
  expect_identical(s$logLik, as.numeric(ll))
  expect_identical(s$k, attr(ll, "df"))
})


test_that("summary reports the number of diffuse initial states", {
  s <- summary(res_tempssm)

  expect_type(s$diffuse_states, "integer")
  expect_identical(
    s$diffuse_states,
    as.integer(sum(diag(res_tempssm$model$P1inf) > 0))
  )
})


test_that("summary uses the canonical fitted parameter values", {
  s <- summary(res_tempssm)
  params <- get_tempssm_params(res_tempssm)

  expect_identical(
    s$variances,
    params[c("H", "Q_trend", "Q_season", "Q_ar")]
  )
  expect_identical(s$coef_ar$AR_order, res_tempssm$ar_order)
  expect_identical(s$coef_ar$AR_coef, params$ARs)
})


test_that("print.summary.tempssm works and returns object invisibly", {
  s <- summary(res_tempssm)

  expect_no_error(print(s))

  out <- print(s)
  expect_identical(out, s)
})


test_that("print.summary.tempssm outputs expected text", {
  s <- summary(res_tempssm)

  output <- capture.output(print(s))

  expect_true(any(grepl("tempssm summary", output, fixed = TRUE)))
  expect_true(any(grepl("Log-likelihood", output, fixed = TRUE)))
})


test_that("print.summary.tempssm separates exogenous block", {
  s <- summary(res_tempssm_exo)

  output <- capture.output(print(s))
  exo_line <- grep("Exogenous variable", output, fixed = TRUE)

  expect_length(exo_line, 1)
  expect_identical(output[exo_line - 1], "")
})


test_that("summary handles non-seasonal model", {
  data(sst_niigata)

  res <- tempssm(sst_niigata, use_season = FALSE, na_action = "allow")
  s <- summary(res)

  expect_true(is.na(s$variances$Q_season))
})


test_that("summary contains valid AR coefficients", {
  s <- summary(res_tempssm)

  expect_type(s$coef_ar, "list")
  expect_lte(s$coef_ar$AR_order, 1)
  expect_length(s$coef_ar$AR_coef, s$coef_ar$AR_order)
})


test_that("summary handles no exogenous variables", {
  s <- summary(res_tempssm)

  expect_true(is.null(s$exogenous) || is.character(s$exogenous))
})
