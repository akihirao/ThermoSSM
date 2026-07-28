# Monthly mean sea surface temperature off Niigata, Japan

Monthly mean sea surface temperature (SST; °C) time series observed at a
fixed coastal station near Niigata City Aquarium, Japan (37-55N, 139-02E
in dd-mm / ddd-mm format). The dataset is provided as a univariate `ts`
object and is intended as an example for state-space analysis of monthly
temperature time series.

## Usage

``` r
sst_niigata
```

## Format

A univariate `ts` object with frequency 12 (monthly data), starting in
January 2002 and ending in December 2023.

## Source

Japan Oceanographic Data Center, Hydrographic and Oceanographic
Department, Japan Coast Guard. Original daily SST data were obtained
from <https://www.jodc.go.jp/jodcweb/JDOSS/index.html> and aggregated
into monthly means.

## Details

The variable name is unified as `Temp` for consistency with other
example datasets in the package. In this dataset, `Temp` represents
monthly mean sea surface temperature (°C). The observation period spans
from January 2002 to December 2023. Missing values, if any, are encoded
as `NA`.

## Examples

``` r
data(sst_niigata)
plot(sst_niigata)

```
