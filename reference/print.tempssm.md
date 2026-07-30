# Print method for tempssm objects

Print method for tempssm objects

## Usage

``` r
# S3 method for class 'tempssm'
print(x, ...)
```

## Arguments

- x:

  An object of class `"tempssm"` returned by
  [`tempssm()`](https://akihirao.github.io/tempssm/reference/tempssm.md).

- ...:

  Additional arguments, currently ignored.

## Value

The input object `x`, invisibly. The returned object has class
`"tempssm"`.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
res <- tempssm(sst_niigata)
print(res)
} # }
```
