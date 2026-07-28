test_that("tempssm logLik method matches the underlying KFAS model", {
  tempssm_loglik <- logLik(res_tempssm)
  kfas_loglik <- stats::logLik(
    res_tempssm$model,
    marginal = res_tempssm$marginal
  )

  expect_identical(as.numeric(tempssm_loglik), as.numeric(kfas_loglik))
  expect_identical(attr(tempssm_loglik, "nobs"), length(res_tempssm$temp_data))
  expect_identical(
    attr(tempssm_loglik, "df"),
    length(res_tempssm$fit$optim.out$par)
  )
})


test_that("tempssm AIC method does not compute information criteria", {
  expect_error(
    AIC(res_tempssm),
    "AIC is not computed"
  )
})


test_that("component accessors match KFAS smoothed states", {
  level_ts <- get_level_ts(res_tempssm, ci = FALSE)
  drift_ts <- get_drift_ts(res_tempssm, ci = FALSE)
  season_ts <- get_season_ts(res_tempssm, ci = FALSE)
  ar1_ts <- get_ar_ts(res_tempssm, component = "first", ci = FALSE)
  kfas_states <- res_tempssm$kfs$alphahat
  freq <- stats::frequency(res_tempssm$temp_data)

  expect_identical(as.numeric(level_ts), as.numeric(kfas_states[, "level"]))
  expect_identical(
    as.numeric(drift_ts),
    as.numeric(kfas_states[, "slope"] * freq)
  )
  expect_identical(
    as.numeric(season_ts),
    as.numeric(kfas_states[, "sea_dummy1"])
  )
  expect_identical(as.numeric(ar1_ts), as.numeric(kfas_states[, "arima1"]))
})


test_that("component accessors match KFAS filtered states", {
  level_ts <- get_level_ts(res_tempssm, estimate = "filtered")
  drift_ts <- get_drift_ts(res_tempssm, estimate = "filtered")
  season_ts <- get_season_ts(res_tempssm, estimate = "filtered")
  ar1_ts <- get_ar_ts(res_tempssm, component = "first", estimate = "filtered")
  kfas_states <- res_tempssm$kfs$att
  freq <- stats::frequency(res_tempssm$temp_data)
  diffuse_end <- res_tempssm$kfs$d
  diffuse_idx <- seq_len(diffuse_end)
  regular_idx <- seq.int(diffuse_end + 1L, NROW(kfas_states))

  expect_true(all(is.na(level_ts[diffuse_idx])))
  expect_true(all(is.na(drift_ts[diffuse_idx])))
  expect_true(all(is.na(season_ts[diffuse_idx])))
  expect_true(all(is.na(ar1_ts[diffuse_idx])))
  expect_identical(
    as.numeric(level_ts[regular_idx]),
    as.numeric(kfas_states[regular_idx, "level"])
  )
  expect_identical(
    as.numeric(drift_ts[regular_idx]),
    as.numeric(kfas_states[regular_idx, "slope"] * freq)
  )
  expect_identical(
    as.numeric(season_ts[regular_idx]),
    as.numeric(kfas_states[regular_idx, "sea_dummy1"])
  )
  expect_identical(
    as.numeric(ar1_ts[regular_idx]),
    as.numeric(kfas_states[regular_idx, "arima1"])
  )
})


test_that("filtered component intervals match KFAS state covariances", {
  level_ci <- get_level_ts(
    res_tempssm,
    ci = TRUE,
    estimate = "filtered"
  )
  drift_ci <- get_drift_ts(
    res_tempssm,
    ci = TRUE,
    estimate = "filtered"
  )
  season_ci <- get_season_ts(
    res_tempssm,
    ci = TRUE,
    estimate = "filtered"
  )
  ar1_ci <- get_ar_ts(
    res_tempssm,
    component = "first",
    ci = TRUE,
    estimate = "filtered"
  )

  filtered <- res_tempssm$kfs$att
  ptt <- res_tempssm$kfs$Ptt
  diffuse_end <- res_tempssm$kfs$d
  diffuse_idx <- seq_len(diffuse_end)
  regular_idx <- seq.int(diffuse_end + 1L, NROW(filtered))
  critical_value <- stats::qnorm(0.975)

  expect_true(all(is.na(level_ci[diffuse_idx, ])))
  expect_true(all(is.na(drift_ci[diffuse_idx, ])))
  expect_true(all(is.na(season_ci[diffuse_idx, ])))
  expect_true(all(is.na(ar1_ci[diffuse_idx, ])))

  expected_bounds <- function(state, scale = 1) {
    state_idx <- match(state, colnames(filtered))
    point <- filtered[regular_idx, state] * scale
    standard_error <- sqrt(ptt[state_idx, state_idx, regular_idx]) * scale
    cbind(
      lwr = point - critical_value * standard_error,
      upr = point + critical_value * standard_error
    )
  }

  expect_identical(
    unname(level_ci[regular_idx, c("lwr", "upr")]),
    unname(expected_bounds("level"))
  )
  expect_identical(
    unname(drift_ci[regular_idx, c("lwr", "upr")]),
    unname(expected_bounds("slope", stats::frequency(res_tempssm$temp_data)))
  )
  expect_identical(
    unname(season_ci[regular_idx, c("lwr", "upr")]),
    unname(expected_bounds("sea_dummy1"))
  )
  expect_identical(
    unname(ar1_ci[regular_idx, c("lwr", "upr")]),
    unname(expected_bounds("arima1"))
  )
})


test_that("component confidence intervals match KFAS confint output", {
  ci_obj <- stats::confint(res_tempssm$kfs, level = 0.95)
  freq <- stats::frequency(res_tempssm$temp_data)

  level_ci <- get_level_ts(res_tempssm, ci = TRUE, ci_level = 0.95)
  drift_ci <- get_drift_ts(res_tempssm, ci = TRUE, ci_level = 0.95)
  season_ci <- get_season_ts(res_tempssm, ci = TRUE, ci_level = 0.95)
  ar1_ci <- get_ar_ts(
    res_tempssm,
    component = "first",
    ci = TRUE,
    ci_level = 0.95
  )

  expect_identical(
    as.numeric(level_ci[, "lwr"]),
    as.numeric(ci_obj$level[, "lwr"])
  )
  expect_identical(
    as.numeric(level_ci[, "upr"]),
    as.numeric(ci_obj$level[, "upr"])
  )
  expect_identical(
    as.numeric(drift_ci[, "lwr"]),
    as.numeric(ci_obj$slope[, "lwr"] * freq)
  )
  expect_identical(
    as.numeric(drift_ci[, "upr"]),
    as.numeric(ci_obj$slope[, "upr"] * freq)
  )
  expect_identical(
    as.numeric(season_ci[, "lwr"]),
    as.numeric(ci_obj$sea_dummy1[, "lwr"])
  )
  expect_identical(
    as.numeric(season_ci[, "upr"]),
    as.numeric(ci_obj$sea_dummy1[, "upr"])
  )
  expect_identical(
    as.numeric(ar1_ci[, "lwr"]),
    as.numeric(ci_obj$arima1[, "lwr"])
  )
  expect_identical(
    as.numeric(ar1_ci[, "upr"]),
    as.numeric(ci_obj$arima1[, "upr"])
  )
})
