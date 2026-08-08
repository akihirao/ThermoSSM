# Plot temperature anomalies

Plots a temperature time series together with its corresponding
temperature anomalies.

The anomalies are computed by subtracting the long-term seasonal mean
for each period in the seasonal cycle from the observed temperature.

## Usage

``` r
plot_temp_anomaly(ts, connect_missing = FALSE)
```

## Arguments

- ts:

  A univariate time series object of class `ts` with an integer
  frequency greater than 1.

- connect_missing:

  Logical; should line segments be connected across missing values? If
  `FALSE`, the default, lines are broken at missing values. If `TRUE`,
  missing observations are omitted before plotting, so line segments
  connect across gaps.

## Value

A `ggplot2` plot object showing the temperature anomaly time series.

## Details

The function first computes the seasonal climatological mean across all
years, and then calculates anomalies as deviations from these seasonal
averages. For monthly data, this is equivalent to subtracting the
long-term mean for each calendar month.

## Examples

``` r
if (FALSE) { # \dontrun{
data(sst_niigata)
p <- plot_temp_anomaly(sst_niigata)
print(p)
} # }
```
