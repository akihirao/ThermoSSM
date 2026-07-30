# Summary method for tempssm objects

Provides a concise summary of a fitted linear Gaussian state-space model
estimated by
[`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

## Usage

``` r
# S3 method for class 'tempssm'
summary(object, ..., marginal = NULL)
```

## Arguments

- object:

  An object of class `"tempssm"` returned by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

- ...:

  Additional arguments (currently not used).

- marginal:

  Logical scalar or `NULL`. If `NULL`, use the likelihood setting stored
  when the model was fitted. Set to `TRUE` or `FALSE` to evaluate the
  fitted parameters with the marginal or diffuse likelihood,
  respectively. An explicit value does not refit the model.

## Value

An object of class `"summary.tempssm"`, implemented as a named list with
components `call`, `logLik`, `marginal`, `k`, `diffuse_states`,
`convergence`, `variances`, `coef_ar`, `exogenous`, and
`exogenous_coef`. If the model did not converge or fitted parameters are
unavailable, `logLik` and unavailable parameter estimates are reported
as `NA`.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)

# fit model
res <- tempssm(sst_niigata)

# compute summary
s <- summary(res)

s

# access components programmatically
s$logLik
s$k
s$diffuse_states
s$variances
} # }
```
