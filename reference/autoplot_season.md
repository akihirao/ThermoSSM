# Plot the estimated seasonal component from a tempssm model

Create a ggplot2 visualization of the estimated drift component obtained
from a state space model fitted by
[`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).
A pointwise confidence interval is shown as a shaded ribbon.

## Usage

``` r
autoplot_season(
  res,
  ci = TRUE,
  ci_level = 0.95,
  ylab = expression(Temp. ~ (degree * C)),
  show_ci_in_title = FALSE
)
```

## Arguments

- res:

  An object of class `"tempssm"` returned by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

- ci:

  Logical; if TRUE, pointwise confidence intervals are returned.

- ci_level:

  Numeric confidence level between 0 and 1 (default: 0.95).

- ylab:

  Label of y-axis. The default is a plotmath expression showing
  temperature in degrees Celsius.

- show_ci_in_title:

  Logical; should the confidence level be shown in the plot title when
  `ci = TRUE`? The default is `FALSE`.

## Value

A `ggplot` object, allowing further customization by adding standard
ggplot2 layers.

## Details

The confidence interval is computed using
[`stats::confint()`](https://rdrr.io/r/stats/confint.html) applied to
the Kalman filter and smoother results stored in `res$kfs`. The shaded
ribbon represents pointwise confidence intervals for the level state.

## See also

[`tempssm`](https://akihirao.github.io/tempssm/reference/tempssm.md),
[`confint`](https://rdrr.io/r/stats/confint.html)

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata)

# Default 95% confidence interval
autoplot_season(res)

# Custom confidence level
autoplot_season(res, ci_level = 0.9)
} # }
```
