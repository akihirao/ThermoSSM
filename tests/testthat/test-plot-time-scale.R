test_that("component plot data uses a plain numeric time axis", {
  for (freq in c(4, 12, 24)) {
    component_ts <- ts(
      cbind(
        level = seq_len(freq),
        lwr = seq_len(freq) - 1,
        upr = seq_len(freq) + 1
      ),
      start = c(2000, 1),
      frequency = freq
    )

    plot_data <- .tempssm_component_plot_data(
      component_ts,
      value_name = "level",
      ci = TRUE
    )

    expect_type(plot_data$time, "double")
    expect_false(inherits(plot_data$time, "ts"))
    expect_identical(
      plot_data$time,
      as.numeric(stats::time(component_ts))
    )
  }
})


test_that("component plotters do not emit scale-selection messages", {
  plotters <- list(
    autoplot_level,
    autoplot_drift,
    autoplot_season,
    autoplot_ar
  )

  for (plotter in plotters) {
    expect_no_message(
      component_plot <- plotter(res_tempssm)
    )
    expect_no_message(
      ggplot2::ggplot_build(component_plot)
    )
  }
})


test_that("combined plot interfaces do not emit scale-selection messages", {
  expect_no_message(
    combined_plot <- autoplot(res_tempssm)
  )
  expect_no_message(
    plotted <- plot(res_tempssm)
  )

  expect_s3_class(combined_plot, "ggplot")
  expect_s3_class(plotted, "ggplot")
  expect_no_message(ggplot2::ggplot_build(combined_plot))
})


test_that("temperature anomaly plot uses a numeric time axis silently", {
  expect_no_message(
    anomaly_plot <- plot_temp_dev(temp_ts_test)
  )
  expect_type(anomaly_plot$data$time, "double")
  expect_false(inherits(anomaly_plot$data$time, "ts"))
  expect_no_message(ggplot2::ggplot_build(anomaly_plot))
})
