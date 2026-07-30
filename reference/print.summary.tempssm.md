# Print method for summary of tempssm objects

Prints a human-readable summary of a fitted linear Gaussian state-space
model estimated by
[`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

## Usage

``` r
# S3 method for class 'summary.tempssm'
print(x, ...)
```

## Arguments

- x:

  An object of class `summary.tempssm`.

- ...:

  Additional arguments (currently not used).

## Value

The input object `x`, invisibly. The returned object has class
`"summary.tempssm"`.

## Details

This method is automatically called when a `summary.tempssm` object is
printed.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)

# fit model and compute summary
res <- tempssm(sst_niigata)
s <- summary(res)

# print summary (explicit)
print(s)

# equivalent (implicit print)
s
} # }
```
