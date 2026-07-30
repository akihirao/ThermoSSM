# Monthly Mean Air Temperature at Hohenpeissenberg Meteorological Observatory

A long-term monthly mean air temperature time series observed at the
Hohenpeissenberg Meteorological Observatory, Germany. The data are
provided as a `ts` object and can be used as an example dataset for
state-space modeling of temperature time series.

## Usage

``` r
temp_hmo
```

## Format

A `ts` object with:

- frequency:

  12 (monthly data)

- start:

  January 1781

- end:

  December 2025

## Source

Global Historical Climatology Network monthly (GHCNm), Version 4. Data
obtained from the NOAA National Centers for Environmental Information
GHCNm product page:
<https://www.ncei.noaa.gov/products/land-based-station/global-historical-climatology-network-monthly>

## Details

The time series represents monthly mean air temperature (in degrees
Celsius) at the Hohenpeissenberg Meteorological Observatory. The
observation period spans from January 1781 to December 2025. Missing
values, if any, are encoded as `NA`.

## Examples

``` r
data(temp_hmo)
plot(temp_hmo)

```
