#' Print method for tempssm objects
#'
#' @param x An object of class \code{"tempssm"} returned by \code{tempssm()}.
#' @param ... Additional arguments, currently ignored.
#'
#' @return
#' The input object \code{x}, invisibly. The returned object has class
#' \code{"tempssm"}.
#'
#' @method print tempssm
#' @importFrom stats start end
#' @export
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#' res <- tempssm(sst_niigata)
#' print(res)
#' }
print.tempssm <- function(x, ...) {
  cat("tempssm model fit\n")
  cat("------------------\n")

  # Observed time series
  temp_data <- x$temp_data
  cat("Data:\n")
  cat("  Temperature time series data\n")
  cat("  Length       :", length(temp_data), "\n")
  cat("  Frequency    :", frequency(temp_data), "\n")
  cat(
    "  Start / End  :",
    paste(stats::start(temp_data), collapse = "-"), " / ",
    paste(stats::end(temp_data), collapse = "-"), "\n\n"
  )

  exo_data <- x$exogenous_data
  if (is.null(exo_data)) {
    cat("  Exogenous variables: NULL\n")
    cat("\n\n")
  } else {
    cat("  Exogenous variable(s)\n")
    cat("  No. variables:", length(colnames(exo_data)), "\n")
    cat("  Length       :", length(exo_data), "\n")
    cat("  Frequency    :", frequency(exo_data), "\n")
    cat(
      "  Start / End  :",
      paste(start(exo_data), collapse = "-"), " / ",
      paste(end(exo_data), collapse = "-"), "\n\n"
    )
  }

  # Convergence information
  ll <- .tempssm_logLik_display_info(x)
  likelihood_type <- if (isTRUE(ll$marginal)) {
    "marginal"
  } else {
    "diffuse"
  }
  cat("Optimization:\n")
  cat("  Converged   :", isTRUE(x$converged), "\n")
  cat("  Likelihood  :", likelihood_type, "\n")
  cat("  LogLik      :", round(ll$logLik, 2), "\n\n")

  cat("Use summary() for detailed results.\n")

  invisible(x)
}
