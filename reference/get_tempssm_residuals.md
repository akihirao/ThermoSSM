# Extract standardized recursive residuals

Extract standardized recursive residuals

## Usage

``` r
get_tempssm_residuals(res)
```

## Arguments

- res:

  An object of class `"tempssm"` returned by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

## Value

A numeric vector of standardized recursive residuals.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata)

residuals <- get_tempssm_residuals(res)
} # }
```
