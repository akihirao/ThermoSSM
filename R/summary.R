#' Validate input for a tempssm summary
#'
#' @param object An object expected to contain fitted \code{tempssm} results.
#'
#' @return Invisibly returns \code{object}.
#'
#' @keywords internal
#' @noRd
.validate_tempssm_summary_input <- function(object) {
  if (!inherits(object, "tempssm")) {
    cli::cli_abort("`object` must be an object of class {.cls tempssm}.")
  }

  invisible(object)
}


#' Count diffuse initial states in a fitted tempssm model
#'
#' @inheritParams summary.tempssm
#'
#' @return Integer scalar giving the number of diffuse initial states.
#'
#' @keywords internal
#' @noRd
.tempssm_summary_diffuse_states <- function(object) {
  if (is.null(object$model) || is.null(object$model$P1inf)) {
    return(NA_integer_)
  }

  as.integer(sum(diag(object$model$P1inf) > 0))
}


#' Check whether fitted parameter estimates are available
#'
#' @inheritParams summary.tempssm
#'
#' @return Logical scalar.
#'
#' @keywords internal
#' @noRd
.tempssm_summary_has_params <- function(object) {
  !is.null(object$fit) &&
    !is.null(object$fit$optim.out) &&
    !is.null(object$fit$optim.out$par)
}


#' Extract convergence status for summary output
#'
#' @inheritParams summary.tempssm
#'
#' @return Logical scalar.
#'
#' @keywords internal
#' @noRd
.tempssm_summary_convergence <- function(object) {
  if (!isTRUE(object$converged)) {
    return(FALSE)
  }

  if (is.null(object$fit) || is.null(object$fit$optim.out) ||
      is.null(object$fit$optim.out$convergence)) {
    return(FALSE)
  }

  object$fit$optim.out$convergence == 0
}


#' Build unavailable parameter estimates for summary output
#'
#' @inheritParams summary.tempssm
#'
#' @return A named list with the same shape as \code{.extract_tempssm_params()}.
#'
#' @keywords internal
#' @noRd
.tempssm_summary_na_params <- function(object) {
  list(
    H = NA_real_,
    Q_trend = NA_real_,
    Q_season = NA_real_,
    Q_ar = NA_real_,
    ARs = rep(NA_real_, object$ar_order)
  )
}


#' Extract parameter estimates for summary output
#'
#' @inheritParams summary.tempssm
#'
#' @return A named list containing fitted or unavailable parameter estimates.
#'
#' @keywords internal
#' @noRd
.tempssm_summary_params <- function(object) {
  if (!.tempssm_summary_has_params(object)) {
    return(.tempssm_summary_na_params(object))
  }

  .extract_tempssm_params(object)
}


#' Summary method for tempssm objects
#'
#' Provides a concise summary of a fitted linear Gaussian
#' state-space model estimated by \code{tempssm()}.
#'
#' @param object An object of class \code{"tempssm"} returned
#' by \code{tempssm()}.
#' @param ... Additional arguments (currently not used).
#' @inheritParams logLik.tempssm
#'
#' @return
#' An object of class \code{"summary.tempssm"}, implemented as a named list
#' with components \code{call}, \code{logLik}, \code{marginal}, \code{k},
#' \code{diffuse_states}, \code{convergence}, \code{variances},
#' \code{coef_ar}, \code{exogenous}, and \code{exogenous_coef}. If the model
#' did not converge or fitted parameters are unavailable, \code{logLik} and
#' unavailable parameter estimates are reported as \code{NA}.
#'
#' @method summary tempssm
#' @importFrom stats logLik
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#'
#' # fit model
#' res <- tempssm(sst_niigata)
#'
#' # compute summary
#' s <- summary(res)
#'
#' s
#'
#' # access components programmatically
#' s$logLik
#' s$k
#' s$diffuse_states
#' s$variances
#' }
#'
#' @export
summary.tempssm <- function(object, ..., marginal = NULL) {
  .validate_tempssm_summary_input(object)

  params <- .tempssm_summary_params(object)
  ll <- .tempssm_logLik_display_info(object, marginal = marginal)
  exo_data <- object$exogenous_data
  exogenous_variable <- if (is.null(exo_data)) NULL else colnames(exo_data)

  res <- list(
    call = object$call,
    logLik = ll$logLik,
    marginal = ll$marginal,
    k = ll$df,
    diffuse_states = .tempssm_summary_diffuse_states(object),
    convergence = .tempssm_summary_convergence(object),
    variances = params[c("H", "Q_trend", "Q_season", "Q_ar")],
    coef_ar = list(
      AR_order = object$ar_order,
      AR_coef = params$ARs
    ),
    exogenous = exogenous_variable,
    exogenous_coef = get_exo_coef(object)
  )

  class(res) <- "summary.tempssm"
  res
}


#' Print method for summary of tempssm objects
#'
#' Prints a human-readable summary of a fitted
#' linear Gaussian state-space model estimated by
#' \code{tempssm()}.
#'
#' This method is automatically called when a
#' \code{summary.tempssm} object is printed.
#'
#' @param x An object of class \code{summary.tempssm}.
#' @param ... Additional arguments (currently not used).
#'
#' @return
#' The input object \code{x}, invisibly. The returned object has class
#' \code{"summary.tempssm"}.
#'
#' @method print summary.tempssm
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#'
#' # fit model and compute summary
#' res <- tempssm(sst_niigata)
#' s <- summary(res)
#'
#' # print summary (explicit)
#' print(s)
#'
#' # equivalent (implicit print)
#' s
#' }
#'
#' @export
print.summary.tempssm <- function(x, ...) {
  cat("tempssm summary\n")
  cat("-----------------\n")

  cat("Call:\n")
  print(x$call)
  cat("\n")

  cat("Model fit:\n")
  likelihood_type <- if (isTRUE(x$marginal)) "marginal" else "diffuse"
  cat("  Likelihood type:", likelihood_type, "\n")
  cat("  Log-likelihood :", round(x$logLik, 2), "\n")
  cat("  k              :", x$k, "\n")
  cat("  Diffuse states :", x$diffuse_states, "\n")
  cat("  Converged      :", x$convergence, "\n\n")

  cat("Variance parameters:\n")
  if (!is.null(x$variances$H)) {
    cat("  Observation (H):", x$variances$H, "\n")
  }
  if (!is.null(x$variances$Q_trend)) {
    cat("  State (Q trend):", x$variances$Q_trend, "\n")
  }
  if (!is.null(x$variances$Q_season)) {
    cat("  State (Q season):", x$variances$Q_season, "\n")
  }
  if (!is.null(x$variances$Q_ar)) {
    cat("  State (Q ar):", x$variances$Q_ar, "\n")
  }
  cat("\n")
  cat("Components of auto-regression:\n")
  cat("  Order of AR:", x$coef_ar$AR_order, "\n")
  for (i in 1:x$coef_ar$AR_order) {
    if (!is.null(x$coef_ar$AR_coef[i])) {
      cat(paste0("  Coefficient of AR", i, ":"), x$coef_ar$AR_coef[i], "\n")
    }
  }

  if (!is.null(x$exogenous_coef)) {
    cat("\n")
    cat("Exogenous variable\t", x$exogenous_coef$Variable, "\n")
    cat("Estimated coefficient\t", x$exogenous_coef$Coefficient, "\n")
    cat("Lower CI\t", x$exogenous_coef$lwr, "\n")
    cat("Upper CI\t", x$exogenous_coef$upr, "\n\n")
  }

  invisible(x)
}
