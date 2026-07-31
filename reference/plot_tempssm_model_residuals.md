# Plot residuals from a tempssm model

Plot residuals from a tempssm model

## Usage

``` r
plot_tempssm_model_residuals(res, save = FALSE, prefix = "residuals")
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

## Details

This is a convenience wrapper for fitted `tempssm` objects. It extracts
time-preserving standardized recursive residuals internally and then
calls
[`plot_tempssm_residuals()`](https://akihirao.github.io/tempssm/reference/plot_tempssm_residuals.md).
Use
[`plot_tempssm_residuals()`](https://akihirao.github.io/tempssm/reference/plot_tempssm_residuals.md)
when residuals have already been extracted with
[`get_tempssm_residuals()`](https://akihirao.github.io/tempssm/reference/get_tempssm_residuals.md).

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata)

plot_tempssm_model_residuals(res)
} # }
```
