# AIC method for tempssm objects (S3 method)

AIC is intentionally not computed for models fitted by
[`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).
The method is registered to prevent automatic AIC calculation from the
[`logLik()`](https://rdrr.io/r/stats/logLik.html) method.

## Usage

``` r
# S3 method for class 'tempssm'
AIC(object, ..., k = 2, marginal = NULL)
```

## Arguments

- object:

  An object of class `"tempssm"`, typically returned by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

- ...:

  Additional arguments passed to the generic
  [`AIC()`](https://rdrr.io/r/stats/AIC.html) function. These are
  currently ignored.

- k:

  Numeric penalty coefficient accepted for compatibility with
  [`AIC`](https://rdrr.io/r/stats/AIC.html). This argument is ignored.

- marginal:

  Logical scalar or `NULL` accepted for backward compatibility. This
  argument is ignored.

## Value

This function always raises an error.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata)

# AIC is intentionally not computed for tempssm objects.
AIC(res)

# The log-likelihood and parameter count remain available.
ll <- logLik(res)
as.numeric(ll)
attr(ll, "df")
} # }
```
