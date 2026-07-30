# Log-likelihood method for tempssm objects (S3 method)

Log-likelihood method for tempssm objects (S3 method)

## Usage

``` r
# S3 method for class 'tempssm'
logLik(object, ..., marginal = NULL)
```

## Arguments

- object:

  An object of class `"tempssm"`, typically returned by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

- ...:

  Additional arguments passed to the generic
  [`logLik()`](https://rdrr.io/r/stats/logLik.html) function. These are
  currently ignored.

- marginal:

  Logical scalar or `NULL`. If `NULL`, use the likelihood setting stored
  when the model was fitted. Set to `TRUE` or `FALSE` to evaluate the
  fitted parameters with the marginal or diffuse likelihood,
  respectively. An explicit value does not refit the model.

## Value

An object of class `"logLik"` containing the numeric log-likelihood,
with `df` and `nobs` attributes.

## Details

The implementation calls the public
[`stats::logLik()`](https://rdrr.io/r/stats/logLik.html) generic on the
fitted `SSModel` object. S3 dispatch then invokes KFAS's registered
`logLik.SSModel` method; that method is not exported for direct use. The
`marginal` argument is passed to the KFAS method.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)

# fit model
res <- tempssm(sst_niigata)

# extract log-likelihood
ll <- logLik(res)
marginal_ll <- logLik(res, marginal = TRUE)

ll

# access attributes
attr(ll, "df") # number of parameters
attr(ll, "nobs") # number of observations
} # }
```
