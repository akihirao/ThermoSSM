# Plot component estimates for tempssm objects

Explicit helper for plotting estimated components of a model fitted by
[`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).
This function returns the same `ggplot` object as
[`autoplot.tempssm()`](https://akihirao.github.io/tempssm/reference/autoplot.tempssm.md)
and is useful when a descriptive function name is preferred in scripts
or examples.

## Usage

``` r
plot_tempssm_components(
  x,
  component = NULL,
  ci = TRUE,
  ci_level = 0.95,
  nrow = NULL,
  ncol = NULL,
  ...
)
```

## Arguments

- x:

  An object returned by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

- component:

  Character vector specifying one to four components to plot. One of
  `"level"`, `"drift"`, `"season"`, or `"ar"`. Values must be unique and
  are displayed in the supplied order. If `NULL` (default), all four
  components are plotted.

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
data(sst_sim)
res <- tempssm(sst_sim)

# Explicit component-plot helper
plot_tempssm_components(res)

# Select components
plot_tempssm_components(res, component = c("level", "drift"))
} # }
```
