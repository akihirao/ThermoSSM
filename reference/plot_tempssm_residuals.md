# Plot residuals from tempssm models

Plot residuals from tempssm models

## Usage

``` r
plot_tempssm_residuals(
  r,
  panel = c("all", "series", "acf", "histogram"),
  frequency = NULL,
  lag_max = NULL,
  save = FALSE,
  prefix = "residuals"
)
```

## Arguments

- r:

  Numeric vector of residuals, typically obtained with
  [`get_tempssm_residuals()`](https://akihirao.github.io/tempssm/reference/get_tempssm_residuals.md).

- panel:

  Character scalar specifying which panel to draw. Use `"all"` for the
  default three-panel display, `"series"` for the residual time series,
  `"acf"` for the residual autocorrelation plot, or `"histogram"` for
  the residual frequency distribution.

- frequency:

  Positive numeric scalar or `NULL`. Used to choose the default maximum
  lag in the ACF panel when `lag_max = NULL`. If `NULL`, the frequency
  of `r` is used when `r` is a `ts` object; otherwise 12 is used.

- lag_max:

  Positive integer scalar or `NULL`. Maximum lag displayed in the ACF
  panel. If `NULL`, the default is approximately two seasonal cycles
  plus three additional lags, truncated to the residual series length.
  For monthly residuals this displays up to lag 27.

- save:

  Logical scalar; if TRUE, plots are saved.

- prefix:

  Character scalar used as the prefix for file names. Diagnostic
  suffixes and the `.png` extension are added automatically. If `prefix`
  includes a file extension, that extension is removed before output
  names are generated.

## Value

Invisibly returns NULL when `panel = "all"` or `save = TRUE`. Otherwise,
returns a `ggplot` object for the selected panel.

## Details

Missing residuals are allowed. The residual time-series panel preserves
their positions as gaps and uses the `ts` time axis when `r` is a `ts`
object, including axis tick marks based on that time range. The ACF
panel preserves the time structure and uses available pairs for each
lag, and the histogram and normal curve use finite residuals. When
missing residuals are detected, an informational message reports the
series length and the number and percentage of missing values.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata)

r <- get_tempssm_residuals(res)
plot_tempssm_residuals(r)
plot_tempssm_residuals(r, panel = "acf", frequency = 12)
} # }
```
