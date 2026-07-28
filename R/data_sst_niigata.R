#' Monthly mean sea surface temperature off Niigata, Japan
#'
#' Monthly mean sea surface temperature (SST; °C) time series observed at a
#' fixed coastal station near Niigata City Aquarium, Japan (37-55N, 139-02E
#' in dd-mm / ddd-mm format). The dataset is provided as a univariate \code{ts}
#' object and is intended as an example for state-space analysis of monthly
#' temperature time series.
#'
#' @format A univariate \code{ts} object with frequency 12 (monthly data),
#' starting in January 2002 and ending in December 2023.
#'
#' @details
#' The variable name is unified as \code{Temp} for consistency with other
#' example datasets in the package. In this dataset, \code{Temp}
#' represents monthly mean sea surface temperature (°C). The observation period
#' spans from January 2002 to December 2023. Missing values, if any,
#' are encoded as \code{NA}.
#'
#' @source
#' Japan Oceanographic Data Center, Hydrographic and Oceanographic Department,
#' Japan Coast Guard. Original daily SST data were obtained from
#' \url{https://www.jodc.go.jp/jodcweb/JDOSS/index.html} and aggregated into
#' monthly means.
#'
#' @examples
#' data(sst_niigata)
#' plot(sst_niigata)
#'
"sst_niigata"
