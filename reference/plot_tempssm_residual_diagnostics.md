# Plot residual diagnostics for tempssm models

Plot residual diagnostics for tempssm models

## Usage

``` r
plot_tempssm_residual_diagnostics(res, save = FALSE, prefix = "residuals")
```

## Arguments

- res:

  An object of class `"tempssm"` returned by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

- save:

  Logical scalar; if TRUE, plots are saved.

- prefix:

  Character scalar used as the prefix for file names. Diagnostic
  suffixes and the `.png` extension are added automatically. If `prefix`
  includes a file extension, that extension is removed before output
  names are generated.

## Value

Invisibly returns NULL. Called for its side effects (plots).

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata)

plot_tempssm_residual_diagnostics(res)
} # }
```
