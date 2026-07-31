# Autoplot method for tempssm objects

Create diagnostic and component plots for a model fitted by
[`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).
By default, all available components are plotted.

## Usage

``` r
# S3 method for class 'tempssm'
autoplot(
  object,
  component = NULL,
  ci = TRUE,
  ci_level = 0.95,
  nrow = NULL,
  ncol = NULL,
  ...
)
```

## Arguments

- object:

  An object returned by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

- component:

  Character vector specifying one to four components to plot. One of
  `"level"`, `"drift"`, `"season"`, or `"ar"`. Values must be unique and
  are displayed in the supplied order. If `NULL` (default), all
  components included in the fitted model are plotted. Non-seasonal
  models omit the seasonal panel by default.

- ci:

  Logical; if TRUE, pointwise confidence intervals are returned.

- ci_level:

  Numeric confidence level between 0 and 1 (default: 0.95).

- nrow, ncol:

  Optional positive integers specifying the facet layout when multiple
  components are plotted. When both are `NULL`, the layout is selected
  automatically; four components use a 2 by 2 layout. These arguments
  are ignored when one component is selected.

- ...:

  Additional arguments passed to the corresponding `autoplot_*()`
  function.

## Value

A `ggplot` object. Multiple components are represented as facets with
free y-axis scales and component-specific units in the facet labels.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata)

# plot all components with 95% confidence interval
autoplot(res)

# plot all components without 95% confidence interval
autoplot(res, ci = FALSE)

# plot all components in one column
autoplot(res, nrow = 4, ncol = 1)

# plot selected components in the supplied order
autoplot(res, component = c("drift", "level"))

# plot one component
autoplot(res, component = "level", ci = FALSE)
} # }
```
