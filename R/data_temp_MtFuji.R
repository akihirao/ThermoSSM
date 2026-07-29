#' Monthly mean air temperature at the summit of Mt. Fuji
#'
#' A long-term monthly mean air temperature time series observed at the
#' summit of Mt. Fuji, Japan. The data are provided as a \code{ts} object
#' and can be used as an example dataset for state-space modeling of
#' environmental temperature time series.
#'
#' @format
#' A \code{ts} object with:
#' \describe{
#'   \item{frequency}{12 (monthly data)}
#'   \item{start}{July 1932}
#'   \item{end}{June 2026}
#' }
#'
#' @details
#' The time series represents monthly mean air temperature, in degrees
#' Celsius, at the summit of Mt. Fuji. The observation period spans from
#' July 1932 to June 2026. Missing values in the source data and values with
#' JMA quality flags below 8, where 8 indicates a normal value with no quality
#' problem, are encoded as \code{NA}.
#'
#' @source
#' Created by processing content from the Japan Meteorological Agency (JMA),
#' Past Weather Data Download page:
#' \url{https://www.data.jma.go.jp/risk/obsdl/index.php}
#' Values with JMA quality flags below 8 were treated as \code{NA}.
#'
#' @examples
#' data(temp_MtFuji)
#' plot(temp_MtFuji,
#'   ylab = "Temperature (deg C)",
#'   main = "Monthly mean air temperature at the summit of Mt. Fuji"
#' )
#'
"temp_MtFuji"
