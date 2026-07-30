# Extract standardized recursive residuals

Extract standardized recursive residuals

## Usage

``` r
get_tempssm_residuals(res, keep_time = FALSE)
```

## Arguments

- res:

  An object of class `"tempssm"` returned by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

- keep_time:

  Logical scalar; if FALSE, only finite residuals are returned as a
  numeric vector. If TRUE, the residuals are returned as a `ts` object
  with the same start and frequency as the input temperature series;
  non-finite residuals are retained as `NA`.

## Value

If `keep_time = FALSE`, a numeric vector of finite standardized
recursive residuals. If `keep_time = TRUE`, a `ts` object preserving the
time index of the input temperature series.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata)

residuals <- get_tempssm_residuals(res)
residuals_ts <- get_tempssm_residuals(res, keep_time = TRUE)
} # }
```
