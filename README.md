# tempssm

`tempssm` is an R package for state-space modeling of environmental
temperature time series, including air and water temperature observations. It
provides a practical framework for assessing how long-term trend, seasonal
variation, autoregressive dependence, and optional exogenous effects contribute
to observed temporal variation. The package facilitates the application of
linear Gaussian state-space models estimated by Kalman filtering and smoothing,
using the `KFAS` package as the computational backend (Helske, 2017).

## Key Features

- Fits linear Gaussian state-space models to environmental temperature time
  series.
- Represents temperature dynamics using interpretable latent components:
  long-term trend, seasonal variation, autoregressive dependence, and optional
  exogenous effects.
- Supports arbitrary integer seasonal frequencies, while the current examples
  and validation focus primarily on monthly temperature data.
- Allows the autoregressive order to be specified by the user.
- Provides S3 methods for summaries, diagnostics, accessors, and plots.
- Includes time-series cross-validation tools for model evaluation.

## Input Data Format

Core modeling functions expect input time series to be supplied as R `ts`
objects. The `ts` class is base R's standard format for regularly spaced time
series (see the `stats::ts` documentation:
<https://search.r-project.org/R/refmans/stats/html/ts.html>). Utility
functions are included to help convert common tabular or observational data
into `ts` objects before fitting.

## Prior Art and Scope

`tempssm` provides a domain-focused workflow for analyzing temperature time
series with linear Gaussian state-space models. It brings together model
construction, component extraction, uncertainty summaries, residual
diagnostics, visualization, and time-series cross-validation in a single R
package interface tailored to temperature applications.

The package builds on established statistical methodology, including linear
Gaussian state-space modeling, Kalman filtering, and Kalman smoothing. Model
estimation is handled through the `KFAS` package, which provides a general
framework for state-space models in R.

The initial implementation was adapted from the supplementary code provided by
Baba (2024), accompanying Baba et al. (2024), which analyzed sea temperature
trends using a linear Gaussian state-space model. The supplementary code is
publicly available at:

<https://github.com/logics-of-blue/sea-temperature-trend-jogashima>

Compared with that prior implementation, `tempssm` extends the workflow into a
reusable R package interface with input validation, documented S3 methods,
tests, diagnostics, cross-validation utilities, and examples for broader
temperature time-series analysis.

## Installation

```r
# Install from Github
# install.packages("pak")
pak::pak("akihirao/tempssm")

# Alternative
# install.packages("devtools")
devtools::install_github("akihirao/tempssm")
```

## Documentation

A short tutorial is available in the package vignette:

<https://github.com/akihirao/tempssm/blob/main/vignettes/getting-started.pdf>

The model specification is described separately:

<https://github.com/akihirao/tempssm/blob/main/vignettes/model-specification.pdf>

A comprehensive reference manual (English) is available here:

<https://github.com/akihirao/tempssm/blob/main/tools/manual/tempssm_manual.pdf>

For Japanese users, a detailed manual is also provided:

<https://github.com/akihirao/tempssm/blob/main/tools/manual/tempssm_manual_jp.pdf>


## Basic Usage

### Load the Package and Example Data

This example uses `temp_MtFuji`, a long-term monthly air temperature time
series observed at the summit of Mt. Fuji, Japan. The series contains missing
observations, which `tempssm()` can retain as unobserved responses during
Kalman filtering and smoothing.

```r
library(tempssm)
data(temp_MtFuji)
```

### Fit a State-Space Model

The function `tempssm()` fits a linear Gaussian state-space model to a
temperature time series.

```r
res <- tempssm(temp_MtFuji)
```

The returned object is an S3 object of class `"tempssm"`. Results can be
inspected with standard methods.

```r
summary(res)
plot(res)
```

![Example output from plot(res)](man/figures/myfig.png)

The panels show the estimated model components; gray ribbons indicate
pointwise 95% confidence intervals.

In this example, the estimated level component suggests a gradual long-term
increase in summit temperature. The seasonal component captures the strong
annual cycle, while the autoregressive component represents shorter-term
departures from the trend and seasonal pattern.

For scripted workflows, `plot_tempssm_components()` returns the same component
plot as a `ggplot` object; `ggplot2::autoplot()` is also available.

### Use Your Own Data

Once your data are stored as a `ts` object in the desired temperature unit,
pass it directly to `tempssm()`. For monthly temperature data stored in a CSV
file, prepare columns named `Year`, `Month`, and `Temp`.

```text
Year,Month,Temp
2010,8,13.6
2010,9,6.8
2010,10,NA
2010,11,-1.4
...
```

Use `NA` for missing temperature values, and keep the corresponding `Year` and
`Month` entries. The CSV file should be comma-separated and UTF-8 encoded.

```r
temp_ts <- tempssm::read_monthly_temp_ts("temperature.csv")
res_csv <- tempssm(temp_ts)
```

`read_monthly_temp_ts()` uses base R's `ts()` representation internally. You
can also construct a `ts` object manually if finer control is needed.

## References

Baba, S. (2024). Supplementary code and test data for estimating sea
temperature trends using a linear Gaussian state-space model. GitHub
repository:
<https://github.com/logics-of-blue/sea-temperature-trend-jogashima>

Baba, S., Ishii, H., and Yoshiyama, T. (2024). Estimating sea temperature
trends using a linear Gaussian state-space model in Jogashima, Kanagawa,
Japan. *Bulletin of the Japanese Society of Fisheries Oceanography*, 88(3),
190-199. <https://doi.org/10.34423/jsfo.88.3_190>

Helske, J. (2017). KFAS: Exponential family state space models in R.
*Journal of Statistical Software*, 78(10), 1-39.
<https://doi.org/10.18637/jss.v078.i10>
