# Monthly mean air temperature at the summit of Mt. Fuji

A long-term monthly mean air temperature time series observed at the
summit of Mt. Fuji, Japan. The data are provided as a `ts` object and
can be used as an example dataset for state-space modeling of
environmental temperature time series.

## Usage

``` r
temp_MtFuji
```

## Format

A `ts` object with:

- frequency:

  12 (monthly data)

- start:

  July 1932

- end:

  June 2026

## Source

Japan Meteorological Agency (JMA). Data obtained from the JMA website:
<https://www.jma.go.jp/jma/indexe.html>

## Details

The time series represents monthly mean air temperature, in degrees
Celsius, at the summit of Mt. Fuji. The observation period spans from
July 1932 to June 2026. Missing values are encoded as `NA`. Values with
JMA quality flags below 8, where 8 indicates a normal value with no
quality problem, are treated as `NA`.

## Examples

``` r
data(temp_MtFuji)
plot(temp_MtFuji,
  ylab = "Temperature (deg C)",
  main = "Monthly mean air temperature at the summit of Mt. Fuji"
)

```
