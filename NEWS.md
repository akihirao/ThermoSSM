# tempssm 0.3.2

* Maintenance update for co-author review, with minor refinements to
  documentation, examples, and diagnostic workflows.

# tempssm 0.3.1

* Updated manuals and examples around simulated SST datasets, AR-order
  sensitivity checks, exogenous-variable models, prediction, and tsCV.
* Improved residual diagnostics for time-preserving residual series with
  missing values, including plotting, Ljung-Box-type summaries, and access to
  recursive, response, and Pearson residuals.
* Added and reorganized example datasets and harmonized SST/temperature dataset
  naming.
* Improved component plotting for non-seasonal models and refactored internal
  accessor and diagnostic helpers.

# tempssm 0.3.0

* Added a `marginal` option to select diffuse or marginal likelihood
  consistently during KFAS model fitting, likelihood evaluation, summaries,
  and time-series cross-validation. Marginal likelihood is now the default;
  set `marginal = FALSE` to use diffuse likelihood.
* Stopped computing AIC for `tempssm` objects. `AIC.tempssm()` is retained only
  to prevent automatic AIC calculation through `logLik()`, and `get_aic()` has
  been removed. Log-likelihood values and parameter counts remain available
  through `logLik()`.
* Extended the component accessors to return either smoothed or filtered state
  estimates. Filtered confidence intervals are available, with estimates and
  intervals during the exact diffuse phase reported as `NA`.
* Added `compare_ts_cv()` for validated comparison of collected time-series
  cross-validation results across candidate models.
* Added `predict.tempssm()` for forecasts beyond the sample period, including
  models supplied with explicit future exogenous values. An explicit
  `exo_strategy = "last"` option provides a simplified one-step persistence
  forecast using the final observed exogenous values.
* Classified model-fitting messages by verbosity so routine progress details
  can be controlled with `options(tempssm.verbosity = ...)` or the
  `TEMPSSM_VERBOSITY` environment variable.
* Added a pkgdown site workflow, renamed the introductory vignette to
  `getting-started`, and updated package documentation and links.
* Refactored model fitting, cross-validation, forecasting, plotting, and
  time-series utilities into focused internal helpers, with expanded contract
  and regression tests.
* Changed `autoplot.tempssm()` to return a reusable faceted `ggplot` for one to
  four selected model components, and re-exported the `autoplot()` generic.

# tempssm 0.2.4

* Updated package authorship metadata and related documentation to reflect the
  current contributor and co-author list.
* Added rOpenSci statistical software standards documentation and supporting
  tests for parameter recovery, edge cases, noise susceptibility, and extended
  test workflows.
* Clarified missing-value handling for temperature responses and exogenous
  covariates.

# tempssm 0.2.3.1

* Removed several package dependencies by replacing small helper uses with
  local implementations.
* Replaced patchwork-based `autoplot.tempssm()` composition with an internal
  gtable layout helper.


# tempssm 0.2.2

* Major update of core function tempssm().


# tempssm 0.2.1

* The package was previously named `ThermoSSM` and has been renamed to
  `tempssm`.
* Generalized the seasonal component to support models with or without
  seasonality.
