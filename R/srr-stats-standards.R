#' srr_stats
#'
#' All of the following standards initially have `@srrstatsTODO` tags.
#' These may be moved at any time to any other locations in your code.
#' Once addressed, please modify the tag from `@srrstatsTODO` to `@srrstats`,
#' or `@srrstatsNA`, ensuring that references to every one of the following
#' standards remain somewhere within your code.
#' (These comments may be deleted at any time.)
#'
#' @srrstatsVerbose TRUE
#'
#' @srrstats {G2.15} Calculations that may receive missing values pass
#' explicit missing-value handling options to base summary routines. Forecast
#' accuracy metrics use `mean(..., na.rm = TRUE)` so held-out missing values do
#' not silently propagate through MAE or MASE calculations. Daily-to-monthly
#' aggregation exposes `na.rm` to users and forwards that value to `mean()`.
#' Residual kurtosis computes all moment means with an explicit `na.rm`
#' argument. Missing-value proportions are calculated with `mean(is.na(x))`,
#' where `is.na()` returns a complete logical vector.
#'
#' @srrstats {G3.0} Floating-point values are not compared for exact equality
#' in statistical calculations. Time-series frequencies and time indexes are
#' compared with `all.equal()`, and integer-like numeric controls such as
#' `ar_order`, cross-validation window sizes, worker counts, and plot layout
#' dimensions are checked through `.tempssm_is_integerish()` using a tolerance
#' based on `sqrt(.Machine$double.eps)`. Near-zero MASE scaling factors are
#' treated as invalid with the same tolerance. Exact equality comparisons that
#' remain in package code are limited to integer counts, lengths, convergence
#' codes, logical values, or character choices.
#'
#' @srrstats {G4.0} The only package function that writes local output files
#' is `plot_tempssm_residual_diagnostics(save = TRUE)`. It accepts a
#' `prefix` argument rather than complete file names, parses any supplied file
#' extension with `tools::file_path_sans_ext()`, and then automatically
#' generates the two PNG output paths `*_check.png` and `*_qq.png`. Unit tests
#' verify that prefixes with and without an extension produce correctly
#' suffixed PNG files and do not create double-extension file names.
#'
#' @srrstats {G5.0} Unit tests include the base R `datasets::nottem`
#' monthly temperature series as a standard data set with known properties.
#' Tests verify its `ts` start, end, frequency, length, and initial values,
#' and then exercise `compute_monthly_climatology()` and
#' `ts_train_test_split()` on this standard series. Package examples and other
#' tests also use exported domain data sets such as `sst_niigata`.
#'
#' @srrstats {G5.1} Fixed data sets created for package examples and tests
#' are exported through the package `data/` directory and documented with
#' roxygen data objects. These include `temp_hmo`, `nao`,
#' `pdo`, `soi`, `sst_niigata`, `sst_yamaguchi`, and `temp_MtFuji`.
#' Unit tests verify that all of these data sets can be
#' loaded with `data(..., package = "tempssm")` and are regular monthly `ts`
#' objects. Other test inputs are generated directly within the test suite
#' with fixed seeds, so they are reproducible without hidden package-internal
#' data files.
#'
#' @srrstats {G5.2} Error and warning behaviour is tested throughout the
#' test suite with `expect_error()`, `expect_warning()`, and
#' `expect_message()` checks. Tests cover invalid input classes, invalid
#' scalar argument lengths and types, missing and undefined values,
#' incompatible time-series alignment, unsupported model structures,
#' non-convergence handling, file and URL input failures, and plotting
#' argument validation.
#'
#' @srrstats {G5.2a} Directly coded condition messages in package R code are
#' unique. Component-specific validation messages include the relevant
#' function or component name where the same argument is checked in multiple
#' functions. The test suite includes a static check that literal messages
#' passed directly to `stop()`, `warning()`, `message()`, `cli::cli_abort()`,
#' `cli::cli_warn()`, or `cli::cli_inform()` are not duplicated.
#'
#' @srrstats {G5.2b} Explicit tests use `expect_error()`,
#' `expect_warning()`, and `expect_message()` with expected message patterns
#' for package-defined conditions. A static unit test parses the test suite
#' and verifies that every condition expectation supplies an expected message
#' argument, so newly added condition tests cannot silently omit comparison
#' against expected diagnostic text.
#'
#' @srrstats {G5.3} Functions whose return values are expected to be complete
#' are tested for absence of missing and undefined values. The test suite
#' checks model component accessors, residual diagnostics, summaries,
#' exogenous coefficient extraction, complete-input time-series utilities, and
#' cross-validation split objects with a shared helper that rejects `NA`,
#' `NaN`, `Inf`, and `-Inf`. Functions that intentionally preserve or return
#' `NA` values are tested separately for that behaviour, including explicit
#' missing response observations, implicit missing months, undefined MASE
#' denominators, and non-seasonal `Q_season`.
#'
#' @srrstats {G5.4} Correctness tests compare package calculations against
#' fixed expected results. These tests include hand-computed MAE, MASE, and
#' scaling factors; fixed seasonal anomaly values; monthly data-frame to `ts`
#' conversion; rolling-origin train/test split values; prediction-interval
#' trimming; and known properties of the base R `datasets::nottem` monthly
#' temperature series. The state-space likelihood, filtering, and smoothing
#' algorithms themselves are delegated to `KFAS`; tests for `tempssm()` focus
#' on correct construction, validation, extraction, and post-processing around
#' that backend.
#'
#' @srrstats {G5.4b} Existing state-space likelihood, filtering, smoothing,
#' prediction, and confidence-interval calculations are not reimplemented
#' independently; they are delegated to the established `KFAS` backend. Unit
#' tests explicitly compare `tempssm` wrappers with the underlying `KFAS`
#' objects by checking that `logLik.tempssm()` matches the registered `KFAS`
#' method reached through `stats::logLik(res$model)` for both diffuse and
#' marginal likelihoods. The package intentionally does not compute AIC for
#' `tempssm` objects. Component accessors match `res$kfs$alphahat`, and
#' component confidence intervals match `stats::confint(res$kfs)`.
#' 
#' @srrstats {G5.5} Correctness tests use deterministic inputs or fixed
#' random seeds. Tests in `test-correctness-fixed-values.R` use hand-specified
#' vectors, tables, and time series, and tests in `test-standard-datasets.R`
#' use the fixed base R `datasets::nottem` series. Correctness checks that
#' rely on fitted `tempssm` objects use shared fixtures created in
#' `tests/testthat/setup-tempssm.R`, where `set.seed(123)` is called before
#' generating synthetic temperature and exogenous series.
#'
#' @srrstats {G5.8} Edge condition tests are included across the test suite.
#' Tests cover invalid input classes, unsupported scalar and vector types,
#' invalid argument lengths, missing and undefined values, all-missing helper
#' inputs, invalid or non-increasing time indexes, incompatible `ts`
#' frequencies and time indexes, unsupported multivariate response series,
#' missing fitted model components, and non-converged `tempssm` objects.
#' These tests verify that such edge cases produce explicit errors, warnings,
#' `NULL`, or `NA` values according to the documented behaviour of each
#' function.
#'
#' @srrstats {G5.8a} Zero-length data are covered by unit tests. Monthly
#' data-frame conversion and daily `zoo` aggregation reject zero-length inputs
#' with explicit errors before attempting to construct invalid `ts` objects.
#' Forecast accuracy helpers also test zero-length numeric vectors and return
#' missing accuracy values where no comparison can be made.
#'
#' @srrstats {G5.8b} Unsupported data types are covered by unit tests. Model
#' input checks reject complex `ts` values for both `temp_data` and
#' `exo_data`, and scalar numeric controls reject complex values. Conversion
#' utilities reject character and complex temperature columns in monthly
#' data-frame inputs and daily `zoo` inputs before numerical modelling or
#' aggregation is attempted.
#'
#' @srrstats {G5.8c} All-`NA` and all-identical data are covered by unit
#' tests. Model preprocessing rejects all-`NA` temperature responses because
#' no observed response remains for estimation, and all-`NA` exogenous
#' covariates are rejected because `KFAS` regression terms require complete
#' covariates. Conversion utilities preserve all-`NA` temperature fields as
#' explicit `NA` time-series values. For all-identical training series,
#' MASE scaling is zero and MASE is returned as `NA` because the scaled error
#' denominator is undefined.
#'
#' @srrstats {G5.8d} Data outside the scope of the modelling algorithm are
#' covered by unit tests. The primary response series must be univariate, so
#' multivariate `temp_data` is rejected before model fitting. Exogenous
#' regressors may be multivariate, but the number of exogenous variables must
#' not exceed the number of observations; high-dimensional regression inputs
#' of that form are rejected during model input validation rather than being
#' passed to the `KFAS` backend.
#'
#' @srrstats {TS3.0} Unit tests demonstrate that forecast uncertainty widens
#' with forecast horizon for a fitted temperature state-space model. In
#' `tests/testthat/test-predict_no_exo.R`, the test "prediction intervals widen
#' with forecast horizon" fits `tempssm()` to `sst_niigata`, obtains 24-step
#' ahead prediction intervals from the KFAS backend, and checks that interval
#' widths are non-decreasing and wider at horizon 24 than at horizon 1.
#' 
#' @srrstats {TS3.1} The same test file includes a negative-control test,
#' "prediction interval widening check detects violations", which supplies
#' decreasing and constant synthetic interval-width sequences to the widening
#' check and confirms that they are rejected. This demonstrates that the
#' TS3.0 test condition would detect forecast intervals that fail to widen
#' appropriately with horizon.
#' 
#' @srrstats {TS3.3} The package supports trimming forecast values based on
#' prediction interval width through the exported post-processing function
#' `trim_prediction_intervals()`.
#' 
#' @srrstats {TS3.3a} The package-level documentation and the examples for
#' `trim_prediction_intervals()` document how to obtain KFAS prediction
#' intervals from a fitted `tempssm` model and trim them to a maximum allowed
#' interval width.
#' 
#' @srrstats {TS3.3b} The exported function `trim_prediction_intervals()`
#' implements an explicit post-processing mechanism for trimming forecasts to
#' the longest leading horizon whose prediction interval width `upr - lwr`
#' does not exceed a user-specified threshold.
#' 
#' @srrstats {TS4.0b} The primary modelling return value is a unique S3 class,
#' `tempssm`, with methods for printing, summaries, log-likelihood extraction,
#' and visualization. The `summary()` method returns a `summary.tempssm`
#' object, and tests verify the expected S3 classes of these primary return
#' values.
#' 
#' @srrstats {TS4.2} Exported functions document the type and class of their
#' return values in roxygen `@return` fields. Structured return values also
#' document their named list elements or columns, including `tempssm`,
#' `summary.tempssm`, `logLik`, `ts`, `zoo`, `ggplot`, `tibble`,
#' `data.frame`, and named list outputs used by accessors, diagnostics, and
#' cross-validation helpers. Package-level documentation summarizes these
#' return-value conventions.
#' 
#' @srrstats {TS4.3} Return values that represent time series explicitly
#' include their time scales. Component accessors and time-series utilities
#' return base R `ts` objects with preserved or explicitly constructed
#' `start`, `end`, `frequency`, and `time()` attributes. Daily SST retrieval
#' returns `zoo` objects indexed by `Date`, and daily-to-monthly conversion
#' returns monthly `ts` objects with `frequency = 12`. Unit attributes from
#' optional `units` inputs are intentionally not propagated, as documented
#' under TS4.1 and in package-level documentation.
#' 
#' @srrstats {TS4.5} Forecast values are returned on the same numeric scale as
#' the input temperature series, so no back-transformation is required to make
#' them commensurate with the original non-stationary input data. The package
#' documentation explicitly states this design and documents forecast
#' limitations.
#' 
#' @srrstats {TS4.5c} Package-level documentation states that forecasts are
#' conditional on the selected state-space model structure, estimated
#' parameters, and any supplied future exogenous variables. It also states that
#' forecasts should not be interpreted as physically constrained forecasts
#' beyond the assumptions of the fitted model.
#' 
#' @srrstats {TS4.6} Forecast uncertainty is available through the fitted
#' `KFAS` model returned by `tempssm()`. Package-level documentation shows the
#' use of `stats::predict(res$model, n.ahead = h,
#' interval = "prediction")`, which returns point forecasts and prediction
#' interval bounds.
#' 
#' @srrstats {TS4.6c} Prediction intervals from the `KFAS` backend provide a
#' general indication of forecast error through lower and upper interval
#' bounds. The exported helper `trim_prediction_intervals()` also operates on
#' these interval bounds and documents their expected `fit`, `lwr`, and `upr`
#' structure.
#' 
#' @srrstats {TS4.7} Forecast values and observed values are clearly
#' distinguished in package outputs. Direct forecasts obtained via
#' `stats::predict()` return forecast values alone, while cross-validation
#' results store observed test values and forecasts in separate named list
#' elements.
#' 
#' @srrstats {TS4.7a} Direct forecasting uses `stats::predict()` on the fitted
#' `KFAS` model returned by `tempssm()`, and the returned object contains
#' forecast values and optional interval bounds rather than observed input
#' values.
#' 
#' @srrstats {TS4.7b} Cross-validation results returned by
#' `ts_cv_run_fold()` and `ts_cv_run()` use distinct named list elements:
#' `y_test` for observed held-out values and `y_pred` for model forecasts.
#' The `@return` documentation for `ts_cv_run_fold()` describes these elements.
#' 
#' @srrstats {TS5.5} `plot_temp_dev()` provides a `connect_missing` option
#' controlling how missing values are drawn. The default
#' `connect_missing = FALSE` preserves explicit missing values in the plotting
#' data, so line segments are broken at gaps. Setting
#' `connect_missing = TRUE` removes missing anomaly values before plotting,
#' connecting line segments across gaps. Unit tests cover both behaviours.
#'
#' @noRd
NULL

#' NA_standards
#'
#' Any non-applicable standards can have their tags changed from `@srrstatsTODO`
#' to `@srrstatsNA`, and placed together in this block, along with explanations
#' for why each of these standards have been deemed not applicable.
#' (These comments may also be deleted at any time.)
#'
#' @srrstatsNA {G1.5} The package does not currently make performance claims
#' in associated publications, such as claims of superior speed, accuracy, or
#' predictive performance relative to other software. Although the initial
#' implementation was adapted from supplementary code associated with Baba et
#' al. (2024), `tempssm` does not claim to reproduce all numerical results from
#' that publication. Examples, tests, and vignettes demonstrate package
#' functionality rather than publication-level performance claims.
#'
#' @srrstatsNA {G1.6} The package does not currently make comparative
#' performance claims against alternative implementations in other R packages.
#' `tempssm` uses `KFAS` as its computational backend and is presented as a
#' domain-focused workflow layer for temperature time-series analysis rather
#' than as a faster, more accurate, or otherwise superior alternative to
#' packages such as `KFAS`, `forecast`, `dlm`, `bsts`, or `MARSS`.
#'
#' @srrstatsNA {G5.4a} This package does not introduce a novel statistical
#' estimation method for which no reference implementation exists. Linear
#' Gaussian state-space likelihood evaluation, Kalman filtering, smoothing,
#' and parameter optimization are delegated to the established `KFAS`
#' backend. Correctness tests therefore focus on package-owned calculations
#' and interfaces around that backend, including fixed-value tests for
#' scaling, anomaly calculation, time-series conversion, rolling-origin
#' splitting, and prediction-interval trimming.
#'
#' @srrstatsNA {G5.4c} Stored values from published paper outputs are not used
#' as correctness references because `tempssm` does not claim to reproduce a
#' specific set of published numerical results and does not implement a novel
#' algorithm for which original code is unavailable. The main state-space
#' calculations are delegated to the available `KFAS` implementation; package
#' correctness is instead tested against hand-computed fixed values and direct
#' comparisons with the fitted `KFAS` objects returned by `tempssm()`.
#'
#' @srrstatsNA {G5.11} Extended tests do not require large external data sets
#' or other assets. The current extended test generates all synthetic
#' time-series inputs internally with fixed random seeds and runs entirely
#' within the standard `testthat` workflow when
#' `TEMPSSM_EXTENDED_TESTS=true` is set. Therefore there are no large assets
#' to host, download, cache, or fetch as part of the testing workflow.
#'
#' @srrstatsNA {G5.11a} Extended tests do not download additional data or
#' assets, so there is no download-failure path to handle. The current
#' extended test is skipped unless `TEMPSSM_EXTENDED_TESTS=true` is set and,
#' when enabled, generates all inputs locally from fixed random seeds.
#' Consequently, no external fetch can fail during extended-test execution.
#'
#' @srrstatsNA {G2.4e} The package does not accept factor inputs as a
#' supported user-facing data type. Temperature and exogenous inputs are
#' validated as `ts` objects, tabular date columns are validated as `Date`,
#' and scalar controls are validated as numeric, logical, or character values.
#' Therefore there is no user-facing factor-to-other-type conversion path.
#'
#' @srrstatsNA {G2.5} The package does not expect factor inputs in its
#' user-facing API. Factor objects are created only internally for seasonal
#' grouping in `compute_monthly_climatology()`, with levels set explicitly from
#' the validated integer seasonal frequency. Because users do not supply factor
#' inputs, there is no ordered-versus-unordered factor expectation to document
#' or validate.
#'
#' @srrstatsNA {G2.14c} The package does not provide automatic imputation as a
#' missing-data option. For linear Gaussian state-space models, explicit
#' missing response observations can be handled by the Kalman filtering and
#' smoothing machinery when users choose `na_action = "inform"`, `"warn"`, or
#' `"allow"`.
#' Exogenous covariates are different: KFAS regression terms require complete
#' covariate values, so missing `exo_data` values stop preprocessing. Replacing
#' missing values with imputed values before fitting would add a separate
#' statistical assumption and could change the likelihood, diagnostics, and
#' uncertainty interpretation. Users who require imputation should perform and
#' document that preprocessing step before calling `tempssm()`.
#'
#' @srrstatsNA {TS2.1c} The package does not replace missing time-series
#' observations with imputed values. For the response temperature series,
#' explicit `NA` values are preserved in the regular `ts` object and can be
#' handled by the linear Gaussian state-space model through the `KFAS`
#' backend when users select `na_action = "inform"`, `"warn"`, or `"allow"`.
#' Missing exogenous covariates are rejected because regression covariates
#' must be complete before fitting. Automatic imputation would introduce an
#' additional modelling assumption outside the scope of `tempssm`; users who
#' require imputation should perform that preprocessing before model fitting.
#'
#' @srrstatsNA {G3.1} The package does not compute empirical covariance
#' matrices with `stats::cov()` or any alternative covariance estimator.
#' Variance parameters in `tempssm()` are scalar observation and state
#' disturbance variances estimated through `KFAS::fitSSM()`, and Kalman
#' filtering and smoothing covariance recursions are handled internally by the
#' `KFAS` backend. There is therefore no package-level covariance algorithm
#' for users to choose.
#'
#' @srrstatsNA {G3.1a} Because the package does not expose a covariance
#' estimation method or call `stats::cov()`, there is no arbitrarily specified
#' covariance method to document in examples or vignettes.
#'
#' @srrstatsNA {TS2.4a} The package uses parameter transformations to enforce
#' the relevant stationarity constraint, so routine warnings are not needed for
#' valid user inputs. An internal error is raised only if transformed AR
#' coefficients fail the stationarity check, which should indicate an internal
#' numerical or implementation problem rather than an expected user action.
#'
#' @srrstatsNA {TS2.5} The package does not construct or return
#' auto-covariance matrices whose row and column ordering would need to be
#' linked to the underlying time-series index. Core modelling functions operate
#' on regular `ts` inputs and validate that temperature and exogenous series
#' have matching time indices before fitting, while returned component series
#' preserve the `ts` time attributes of the fitted model.
#'
#' @srrstatsNA {TS2.6} The package does not construct or return
#' auto-covariance matrices, so there are no auto-covariance matrix units to
#' specify. General handling of optional `units` objects in user inputs is
#' documented separately under TS1.7 and tested in the input pre-processing and
#' conversion utilities.
#'
#' @srrstatsNA {TS4.0a} The primary output of `tempssm()` is a fitted model
#' object rather than a transformed version of the input time series, so it is
#' intentionally not returned in the same class as the input `ts` object.
#' Component accessor functions return `ts` objects where the output represents
#' a time series rather than a model object.
#'
#' @srrstatsNA {TS4.1} Unit attributes from optional `units` inputs are
#' intentionally not propagated to return values. As documented under TS1.7
#' and in package-level documentation, such inputs are converted to numeric
#' values with an explicit warning before model fitting or conversion to `ts`.
#' This avoids adding `units` as a hard runtime dependency and keeps the
#' internal state-space calculations numeric. Returned time-series objects
#' preserve time attributes but not unit attributes.
#'
#' @srrstatsNA {TS4.5a} The package does not transform the response series
#' before forecasting, so there is no transformed forecast scale for which a
#' back-transformation routine or option would be required.
#'
#' @srrstatsNA {TS4.5b} The package does not transform the response series
#' before forecasting, so there is no required user workflow for
#' back-transforming forecast values to the original input scale.
#'
#' @srrstatsNA {TS4.6a} The package does not construct a separate forecast
#' distribution object. Forecast uncertainty is exposed through prediction
#' intervals returned by the `KFAS` backend.
#'
#' @srrstatsNA {TS4.6b} The package does not return forecast standard errors
#' directly as a separate second-order moment interface. Forecast uncertainty
#' is instead represented by prediction interval bounds from `predict()` and
#' the `KFAS` backend.
#'
#' @srrstatsNA {TS4.7c} The package does not combine observed and forecast
#' values into a single returned table for forecasting workflows. It instead
#' returns forecasts alone for direct prediction and distinct `y_test` and
#' `y_pred` list elements for cross-validation workflows.
#'
#' @srrstatsNA {TS5.4} The package does not implement frequency-domain
#' visualizations such as spectra, periodograms, or Fourier-domain plots.
#' The `frequency` attribute of `ts` inputs is used to define seasonal
#' periodicity, but no plot uses an angular-frequency abscissa.
#'
#' @srrstatsNA {TS5.6} The package does not currently implement a forecast
#' plotting interface. Direct forecasts are obtained from
#' `predict(res, ..., interval = "prediction")`, which returns
#' point forecasts and lower and upper prediction interval bounds. Component
#' plots show fitted latent states and their confidence intervals, but they
#' are not forecast plots.
#'
#' @srrstatsNA {TS5.7} The package does not currently implement a forecast
#' plotting interface. Direct forecasts are returned by `stats::predict()`,
#' and cross-validation helpers return observed held-out values and forecasts
#' as separate `y_test` and `y_pred` elements. Because no default forecast
#' plot is produced, there is no plot in which model input values and forecast
#' output values could be included by default.
#'
#' @srrstatsNA {TS5.8} The package does not currently implement a forecast
#' plotting interface. Direct forecasts are returned by `stats::predict()`,
#' and cross-validation outputs distinguish observed and forecast values
#' structurally through separate `y_test` and `y_pred` elements. Because no
#' default forecast plot is produced, there is no plotted visual distinction
#' to define between model input values and forecast output values.
#'
#' @noRd
NULL
