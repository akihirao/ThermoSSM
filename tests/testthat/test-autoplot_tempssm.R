test_that("autoplot.tempssm returns ggplot for each component", {
  components <- c("level", "drift", "season", "ar")

  for (component in components) {
    p <- autoplot(
      res_tempssm,
      component = component,
      ci = FALSE
    )

    expect_s3_class(p, "ggplot")
  }
})


test_that("autoplot generic is re-exported", {
  expect_identical(tempssm::autoplot, ggplot2::autoplot)
})


test_that("autoplot.tempssm passes arguments to a component plotter", {
  p <- autoplot(
    res_tempssm,
    component = "level",
    ci = FALSE,
    ylab = "Sea surface temperature"
  )

  expect_identical(p$labels$y, "Sea surface temperature")
})


test_that("autoplot.tempssm returns faceted ggplot for all components", {
  p <- autoplot(res_tempssm, ci = FALSE)

  expect_s3_class(p, "ggplot")
  expect_identical(p$facet$params$nrow, 2L)
  expect_identical(p$facet$params$ncol, 2L)
  expect_identical(
    unique(p$data$component_id),
    c("level", "drift", "season", "ar")
  )
  expect_identical(nlevels(p$data$component), 4L)
})


test_that("autoplot.tempssm selects components in supplied order", {
  p <- autoplot(
    res_tempssm,
    component = c("drift", "level"),
    ci = FALSE
  )

  expect_s3_class(p, "ggplot")
  expect_identical(
    unique(p$data$component_id),
    c("drift", "level")
  )
  expect_identical(p$facet$params$nrow, 1L)
  expect_identical(p$facet$params$ncol, 2L)
})


test_that("faceted component labels include component-specific units", {
  p <- autoplot(res_tempssm, ci = FALSE)
  labels <- levels(p$data$component)

  expect_true(any(grepl("Level component", labels, fixed = TRUE)))
  expect_true(any(grepl("Drift component", labels, fixed = TRUE)))
  expect_true(any(grepl("C/year", labels, fixed = TRUE)))
  expect_true("Autoregressive component (\u00b0C)" %in% labels)
})


test_that("faceted component plots retain adaptive seasonal line width", {
  long_res <- res_tempssm
  long_res$temp_data <- ts(
    rep(0, 600),
    start = start(res_tempssm$temp_data),
    frequency = frequency(res_tempssm$temp_data)
  )

  p <- autoplot(long_res, ci = FALSE)
  season_line_width <- unique(
    p$data$line_width[p$data$component_id == "season"]
  )
  level_line_width <- unique(
    p$data$line_width[p$data$component_id == "level"]
  )

  expect_lt(season_line_width, 0.5)
  expect_identical(level_line_width, 1.2)
})


test_that("default AR panel sums all states for higher-order models", {
  res_ar2 <- tempssm(temp_ts_test, ar_order = 2)
  p <- autoplot(res_ar2, ci = FALSE)
  ar_data <- p$data[p$data$component_id == "ar", ]

  expect_equal(
    ar_data$value,
    rowSums(res_ar2$kfs$alphahat[, c("arima1", "arima2")]),
    tolerance = 1e-8
  )
  expect_true(all(grepl(
    "Autoregressive component",
    as.character(ar_data$component),
    fixed = TRUE
  )))
})


test_that("autoplot.tempssm output accepts ggplot additions", {
  p <- autoplot(res_tempssm, ci = FALSE)
  modified <- p + ggplot2::theme_bw()

  expect_s3_class(modified, "ggplot")
  expect_silent(ggplot2::ggplot_build(modified))
})


test_that("plot.tempssm returns the faceted ggplot invisibly", {
  p <- plot(res_tempssm, component = "level", ci = FALSE)
  combined <- plot(res_tempssm, ci = FALSE)

  expect_s3_class(p, "ggplot")
  expect_identical(p$labels$title, "Level component")
  expect_s3_class(combined, "ggplot")
  expect_identical(nlevels(combined$data$component), 4L)
})


test_that("plot_tempssm_components returns the same component ggplot", {
  p <- plot_tempssm_components(res_tempssm, component = "level", ci = FALSE)
  combined <- plot_tempssm_components(res_tempssm, ci = FALSE)

  expect_s3_class(p, "ggplot")
  expect_identical(p$labels$title, "Level component")
  expect_s3_class(combined, "ggplot")
  expect_identical(nlevels(combined$data$component), 4L)
})


test_that("autoplot.tempssm accepts a manual facet layout", {
  p <- autoplot(res_tempssm, ci = FALSE, nrow = 4, ncol = 1)

  expect_s3_class(p, "ggplot")
  expect_identical(p$facet$params$nrow, 4L)
  expect_identical(p$facet$params$ncol, 1L)
})


test_that("autoplot.tempssm validates selected components", {
  expect_error(
    autoplot(res_tempssm, component = character()),
    "one to four unique component names"
  )
  expect_error(
    autoplot(res_tempssm, component = c("level", "level")),
    "one to four unique component names"
  )
  expect_error(
    autoplot(res_tempssm, component = "unknown"),
    "one to four unique component names"
  )
  expect_error(
    autoplot(res_tempssm, component = "ar1"),
    "one to four unique component names"
  )
})


test_that("autoplot.tempssm propagates plot input checks", {
  expect_error(
    autoplot(res_tempssm, component = "level", ci = "yes"),
    "`ci` must be a single logical value"
  )

  expect_error(
    autoplot(res_tempssm, component = "level", ci_level = 1.5),
    "`ci_level` must be a numeric value between 0 and 1."
  )

  expect_error(
    autoplot(res_tempssm, nrow = 0),
    "nrow.*positive integer or NULL"
  )

  expect_error(
    autoplot(res_tempssm, ncol = 1.5),
    "ncol.*positive integer or NULL"
  )

  expect_error(
    autoplot(res_tempssm, nrow = 1, ncol = 1),
    "accommodate all selected components"
  )
})
