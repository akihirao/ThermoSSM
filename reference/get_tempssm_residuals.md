# Extract residuals from a tempssm model

Extract residuals from a tempssm model

## Usage

``` r
get_tempssm_residuals(
  res,
  keep_time = TRUE,
  type = c("recursive", "response", "pearson"),
  standardized = TRUE
)
```

## Arguments

- res:

  An object of class `"tempssm"` returned by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

- keep_time:

  Logical scalar; if TRUE, the residuals are returned as a `ts` object
  with the same start and frequency as the input temperature series;
  non-finite residuals are retained as `NA`. If FALSE, only finite
  residuals are returned as a numeric vector.

- type:

  Character scalar specifying the residual type. The default
  `"recursive"` returns recursive residuals, which are the main
  residuals used for model diagnostics. `"response"` returns
  observation-minus-fitted residuals. `"pearson"` returns Pearson
  residuals.

- standardized:

  Logical scalar. If `TRUE`, standardized residuals are returned for
  residual types supported by
  [`stats::rstandard()`](https://rdrr.io/r/stats/influence.measures.html).
  The default preserves the previous behavior: `type = "recursive"` with
  `standardized = TRUE`. Response residuals are returned on their
  original scale; use `standardized = FALSE` or omit `standardized` when
  `type = "response"`.

## Value

By default, a `ts` object preserving the time index of the input
temperature series. If `keep_time = FALSE`, a numeric vector of finite
residuals of the requested type.

## Details

Recursive residuals are generally preferred for residual autocorrelation
diagnostics in state-space models. Response residuals are often easier
to interpret as observed-minus-fitted differences, while Pearson
residuals provide a variance-scaled response residual. State residuals
are not returned by this function; they have a different interpretation
and may be exposed separately in a future version.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata)

residuals_ts <- get_tempssm_residuals(res)
residuals <- get_tempssm_residuals(res, keep_time = FALSE)
response_residuals <- get_tempssm_residuals(res, type = "response")
} # }
```
