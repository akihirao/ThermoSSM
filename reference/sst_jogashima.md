# Simulated monthly sea surface temperature off Jogashima, Japan

A simulated monthly sea surface temperature (SST; degrees Celsius) time
series for the coastal waters off Jogashima, Miura City, Kanagawa
Prefecture, Japan. The dataset is provided as a univariate `ts` object
and is intended as an example dataset for state-space modeling of
monthly environmental temperature time series.

## Usage

``` r
sst_jogashima
```

## Format

A univariate `ts` object with:

- frequency:

  12 (monthly data)

- start:

  January 1998

- end:

  February 2023

- Temp:

  Simulated monthly sea surface temperature

## Source

Simulated data generated for tempssm based on Baba et al. (2024). The
original study's supplementary code and test data are available at:
<https://github.com/logics-of-blue/sea-temperature-trend-jogashima>

## Details

The variable name is unified as `Temp` for consistency with other
example datasets in the package. In this dataset, `Temp` represents
simulated monthly sea surface temperature in degrees Celsius.

This dataset is not the original observed SST record. It was generated
by simulation based on the state-space model analysis of sea temperature
time series off Jogashima reported by Baba et al. (2024). The simulated
data are included to provide a reproducible example related to the
motivating study while avoiding redistribution of the original
observational dataset. Missing values, if any, are encoded as `NA`.

## References

Baba, S., Ishii, H., and Yoshiyama, T. (2024). Estimating sea
temperature trends using a linear Gaussian state-space model in
Jogashima, Kanagawa, Japan.

Baba, S. (2024). Supplementary code and test data for estimating sea
temperature trends using a linear Gaussian state-space model.
<https://github.com/logics-of-blue/sea-temperature-trend-jogashima>

## Examples

``` r
data(sst_jogashima)
plot(sst_jogashima)

```
