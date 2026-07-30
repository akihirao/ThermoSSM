# Plot method for tempssm objects

Default base R plot method for objects fitted by
[`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).
This method delegates to
[`plot_tempssm_components()`](https://akihirao.github.io/tempssm/reference/plot_tempssm_components.md)
so that `plot(res)` displays the same component plots as the explicit
helper.

## Usage

``` r
# S3 method for class 'tempssm'
plot(x, ...)
```

## Arguments

- x:

  An object returned by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

- ...:

  Additional arguments passed to
  [`plot_tempssm_components()`](https://akihirao.github.io/tempssm/reference/plot_tempssm_components.md).

## Value

Invisibly returns the plotted `ggplot` object.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata)
plot(res)
plot(res, component = "level", ci = FALSE)
} # }
```
