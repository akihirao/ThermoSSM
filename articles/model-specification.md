# Model specification in tempssm

## Overview

This vignette describes the linear Gaussian state-space model
implemented in `tempssm`. The package is designed for temperature time
series and represents observed variation as a combination of long-term
trend, seasonal variation, autoregressive dependence, and optional
exogenous effects.

The model is estimated with the `KFAS` package as the computational
backend. The main fitting function,
[`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md),
returns both filtering and smoothing estimates. Unless otherwise stated,
summaries, diagnostics, and plots shown by the package are based on
smoothed state estimates.

## State-Space Model

We consider an extended version of the Basic Structural Time Series
Model (BSTSM) to describe temperature time series with explicit
long-term trend, seasonal variability, and autoregressive structure. The
BSTSM is a standard state-space formulation that represents an observed
time series using latent trend, seasonal, and irregular components
(Harvey 1989). Following the temperature time-series application of Baba
et al. (2024), the model used in `tempssm` keeps this interpretable
decomposition and adds autoregressive dependence and optional exogenous
effects. This structure is useful for separating long-term temperature
change, seasonal cycles, and short-term departures.

The observation equation is given by

``` math
y_t = \alpha_t + v_t. \tag{1}
```

Here, $`t`$ denotes the time index, $`y_t`$ is the observed temperature,
$`\alpha_t`$ is the latent state, and $`v_t`$ is the observation error.

The latent state is decomposed as

``` math
\alpha_t = \mu_t + s_t + r_t + E_t. \tag{2}
```

Here, $`\mu_t`$ is the long-term trend component, $`s_t`$ is the
seasonal component, $`r_t`$ is a stationary autoregressive component,
and $`E_t`$ is the contribution of exogenous variables.

## Long-Term Trend

The level component follows a second-order stochastic process:

``` math
\mu_t = 2\mu_{t-1} - \mu_{t-2} + \zeta_t,
\qquad \zeta_t \sim \mathcal{N}(0, \sigma_\zeta^2). \tag{3}
```

Here, $`\zeta_t`$ is the process error of the long-term trend component.
This formulation allows the long-term level and its rate of change to
vary over time.

## Seasonal Component

The seasonal component is modeled with a sum-to-zero constraint:

``` math
s_t = - \sum_{i=t-f+1}^{t-1} s_i + \omega_t,
\qquad \omega_t \sim \mathcal{N}(0, \sigma_\omega^2). \tag{4}
```

Here, $`\omega_t`$ is the process error of the seasonal component and
$`f`$ denotes the seasonal frequency, for example $`f = 12`$ for monthly
data. This formulation makes seasonal effects identifiable and enables
models to be constructed for time series with different temporal
resolutions.

By imposing the sum-to-zero constraint over one complete seasonal cycle,
the seasonal component captures recurring deviations from the underlying
long-term trend without introducing long-term drift. In models without a
seasonal component, the seasonal term $`s_t`$ is set to zero and omitted
from the state equation.

## Autoregressive Component

The autoregressive component follows an $`l`$th-order autoregressive
(AR) process:

``` math
r_t = \phi_1 r_{t-1} + \phi_2 r_{t-2} + \cdots +
\phi_l r_{t-l} + \tau_t,
\qquad \tau_t \sim \mathcal{N}(0, \sigma_\tau^2). \tag{5}
```

Here, $`\tau_t`$ denotes the process error of the autoregressive
component. The process error terms ($`\zeta_t`$, $`\omega_t`$, and
$`\tau_t`$) are assumed to be mutually independent and normally
distributed.

The autoregressive component is mainly intended to absorb remaining
short-term serial dependence after accounting for the long-term trend
and seasonal structure. In applied analyses, low-order AR structures are
often useful as starting points, and higher orders should be considered
together with residual diagnostics and prediction performance.

## Exogenous Component

The exogenous component is defined as

``` math
E_t = \beta_1 x_{1,t} + \beta_2 x_{2,t} + \cdots + \beta_m x_{m,t}. \tag{6}
```

The exogenous term $`E_t`$ represents the influence of external factors.
These may include large-scale climate indices, regional environmental
variables, or other physically motivated predictors relevant to the
observed temperature time series. Each exogenous variable enters the
model linearly through a time-invariant regression coefficient
($`\beta_1, \beta_2, \ldots, \beta_m`$), allowing the magnitude and
direction of its contribution to be estimated jointly with the latent
state components.

For models with exogenous variables, prediction beyond the observed
response period requires future exogenous values or an explicit
assumption about those values.

## Number of Estimated Parameters

When applying the model to observational data, the total number of
parameters to be estimated ($`k`$) depends on the order of the
autoregressive component and the number of exogenous variables included
in the model.

For example, in a model with a second-order autoregressive component and
no exogenous covariates, six parameters are estimated: the observation
error variance, the process error variances associated with the
long-term trend, seasonal, and autoregressive components, and the first-
and second-order autoregressive coefficients ($`\phi_1`$ and
$`\phi_2`$).

In the general case with an $`l`$th-order autoregressive component and
$`m`$ exogenous variables, the total number of parameters is

``` math
k = 4 + l + m.
```

## Parameter Estimation

The core implementation of the parameter estimation procedure is based
on the supplementary code provided by Baba et al. (2024). Parameter
estimation is performed using a two-step optimization strategy
recommended by Helske (2017).

In the first step, model parameters are estimated using the Nelder-Mead
method (Nelder & Mead, 1965) with user-specified initial values. The
resulting estimates are then used as initial values in a second
optimization step based on the BFGS algorithm (Shanno, 1970).

By default,
[`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md)
uses the marginal likelihood implemented in KFAS for parameter
estimation. The diffuse likelihood remains available by explicitly
setting `marginal = FALSE`. The selected likelihood type is stored in
the fitted `tempssm` object and is used consistently by downstream
methods such as [`logLik()`](https://rdrr.io/r/stats/logLik.html) and
[`summary()`](https://rdrr.io/r/base/summary.html).

## References

Baba, S., Ishii, H., and Yoshiyama, T. (2024). Estimating sea
temperature trends using a linear Gaussian state-space model in
Jogashima, Kanagawa, Japan. *Bulletin of the Japanese Society of
Fisheries Oceanography*, 88(3), 190-199. (In Japanese with an English
abstract.) <https://doi.org/10.34423/jsfo.88.3_190>

Baba, S. (2024). Supplementary code and test data for estimating sea
temperature trends using a linear Gaussian state-space model. GitHub
repository:
<https://github.com/logics-of-blue/sea-temperature-trend-jogashima>

Harvey, A. C. (1989). *Forecasting, Structural Time Series Models and
the Kalman Filter*. Cambridge University Press.

Helske, J. (2017). KFAS: Exponential Family State Space Models in R.
*Journal of Statistical Software*, 78(10), 1-39.
<https://doi.org/10.18637/jss.v078.i10>
