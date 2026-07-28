# Monthly mean sea surface temperature off Yamaguchi Prefecture

A monthly mean sea surface temperature time series observed in the
coastal waters off Yamaguchi Prefecture, Japan. The data are provided as
a `ts` object and serve as an example dataset for state-space modeling
of environmental temperature time series.

## Usage

``` r
sst_yamaguchi
```

## Format

A `ts` object with:

- frequency:

  12 (monthly data)

- start:

  January 1982

- end:

  December 2025

## Source

Japan Meteorological Agency (JMA). Data obtained from the JMA website:
<https://www.jma.go.jp/jma/indexe.html>

## Details

The time series represents monthly mean sea surface temperature, in
degrees Celsius, off Yamaguchi Prefecture, Japan. The observation period
spans from January 1982 to December 2025. Missing values, if any, are
encoded as `NA`.

## Examples

``` r
data(sst_yamaguchi)
plot(sst_yamaguchi,
  ylab = "Temperature (deg C)",
  main = "Monthly mean SST off Yamaguchi Prefecture"
)

```
