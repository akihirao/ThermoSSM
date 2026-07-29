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

Created by processing content from the Japan Meteorological Agency
(JMA), Past Weather Data Download page:
<https://www.data.jma.go.jp/risk/obsdl/index.php> Values with JMA
quality flags below 8 were treated as `NA`.

## Details

The time series represents monthly mean air temperature, in degrees
Celsius, at the summit of Mt. Fuji. The observation period spans from
July 1932 to June 2026. Missing values in the source data and values
with JMA quality flags below 8, where 8 indicates a normal value with no
quality problem, are encoded as `NA`.

## Examples

``` r
data(temp_MtFuji)
plot(temp_MtFuji,
  ylab = "Temperature (deg C)",
  main = "Monthly mean air temperature at the summit of Mt. Fuji"
)

```
