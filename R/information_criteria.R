######################################
#' @keywords internal
#' @noRd
.validate_tempssm_for_logLik <- function(res) {
  ## ---- class check ----------------------------------------------------
  if (!inherits(res, "tempssm")) {
    cli::cli_abort(
      "`res` must be an object of class {.cls tempssm}."
    )
  }

  ## ---- convergence check ----------------------------------------------
  if (!isTRUE(res$converged)) {
    cli::cli_abort(
      "Log-likelihood is not available because the model did not converge."
    )
  }

  ## ---- component check ------------------------------------------------
  if (is.null(res$model) || is.null(res$fit)) {
    cli::cli_abort(
      "Log-likelihood is not available because the fitted model is missing."
    )
  }

  ## ---- debug message --------------------------------------------------
  .tempssm_cli_debug("Validated tempssm object for log-likelihood")

  return(invisible(res))
}


#' Resolve the likelihood setting for a fitted model
#'
#' @inheritParams get_level_ts
#' @inheritParams logLik.tempssm
#'
#' @return A logical scalar.
#'
#' @keywords internal
#' @noRd
.resolve_tempssm_marginal <- function(res, marginal = NULL) {
  if (is.null(marginal)) {
    # Objects created before marginal was stored used KFAS's FALSE default.
    return(isTRUE(res$marginal))
  }

  .validate_marginal(marginal)
  marginal
}


#' Extract log-likelihood metadata from a fitted tempssm object
#'
#' @inheritParams get_level_ts
#'
#' @return A named list containing degrees of freedom and number of
#'   observations.
#'
#' @keywords internal
#' @noRd
.tempssm_logLik_metadata <- function(res) {
  if (is.null(res$fit) || is.null(res$fit$optim.out) ||
      is.null(res$fit$optim.out$par)) {
    return(list(
      df = NA_integer_,
      nobs = length(res$temp_data)
    ))
  }

  df <- length(res$fit$optim.out$par)

  if (!is.null(res$exogenous_data)) {
    df <- df + ncol(res$exogenous_data)
  }

  list(
    df = df,
    nobs = length(res$temp_data)
  )
}


#' Extract log-likelihood information for display methods
#'
#' @inheritParams get_level_ts
#' @inheritParams logLik.tempssm
#'
#' @return A named list containing the log-likelihood, degrees of freedom,
#'   number of observations, and resolved likelihood setting.
#'
#' @keywords internal
#' @noRd
.tempssm_logLik_display_info <- function(res, marginal = NULL) {
  marginal <- .resolve_tempssm_marginal(res, marginal)
  metadata <- .tempssm_logLik_metadata(res)

  if (!isTRUE(res$converged) || is.null(res$model) ||
      is.null(res$fit) || is.null(res$fit$optim.out) ||
      is.null(res$fit$optim.out$par)) {
    return(list(
      logLik = NA_real_,
      df = metadata$df,
      nobs = metadata$nobs,
      marginal = marginal
    ))
  }

  .internal_logLik_tempssm(res, marginal = marginal)
}


######################################
#' Extract log-likelihood components from a fitted model
#'
#' @inheritParams get_level_ts
#' @inheritParams logLik.tempssm
#'
#' @return A named list containing the log-likelihood, degrees of freedom,
#'   number of observations, and resolved likelihood setting.
#'
#' @keywords internal
#' @noRd
.internal_logLik_tempssm <- function(res, marginal = NULL) {
  ## ---- validation ----------------------------------------------------
  .validate_tempssm_for_logLik(res)
  marginal <- .resolve_tempssm_marginal(res, marginal)

  ## ---- logLik extraction ---------------------------------------------
  ll <- tryCatch(
    # stats::logLik() dispatches SSModel objects to KFAS's registered
    # logLik.SSModel method; KFAS does not export the method directly.
    as.numeric(stats::logLik(res$model, marginal = marginal)),
    error = function(e) {
      cli::cli_abort(
        "Failed to extract log-likelihood from the fitted model."
      )
    }
  )

  ## ---- degrees of freedom --------------------------------------------
  metadata <- .tempssm_logLik_metadata(res)

  ## ---- number of observations ----------------------------------------
  nobs <- metadata$nobs

  ## ---- debug message --------------------------------------------------
  .tempssm_cli_debug(
    paste0(
      "Computed logLik components: logLik={round(ll, 3)}, ",
      "df={metadata$df}, nobs={nobs}"
    )
  )

  ## ---- return --------------------------------------------------------
  return(list(
    logLik = ll,
    df     = metadata$df,
    nobs   = nobs,
    marginal = marginal
  ))
}


#' Log-likelihood method for tempssm objects (S3 method)
#'
#' @param object
#' An object of class \code{"tempssm"}, typically returned by
#' \code{tempssm()}.
#'
#' @param ...
#' Additional arguments passed to the generic \code{logLik()} function.
#' These are currently ignored.
#'
#' @param marginal Logical scalar or \code{NULL}. If \code{NULL}, use the
#' likelihood setting stored when the model was fitted. Set to \code{TRUE} or
#' \code{FALSE} to evaluate the fitted parameters with the marginal or diffuse
#' likelihood, respectively. An explicit value does not refit the model.
#'
#' @method logLik tempssm
#'
#' @details
#' The implementation calls the public \code{stats::logLik()} generic on the
#' fitted \code{SSModel} object. S3 dispatch then invokes KFAS's registered
#' \code{logLik.SSModel} method; that method is not exported for direct use.
#' The \code{marginal} argument is passed to the KFAS method.
#'
#' @return
#' An object of class \code{"logLik"} containing the numeric log-likelihood,
#' with \code{df} and \code{nobs} attributes.
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#'
#' # fit model
#' res <- tempssm(sst_niigata)
#'
#' # extract log-likelihood
#' ll <- logLik(res)
#' marginal_ll <- logLik(res, marginal = TRUE)
#'
#' ll
#'
#' # access attributes
#' attr(ll, "df") # number of parameters
#' attr(ll, "nobs") # number of observations
#' }
#'
#' @export
logLik.tempssm <- function(object, ..., marginal = NULL) {
  info <- .internal_logLik_tempssm(object, marginal = marginal)

  structure(
    info$logLik,
    class = "logLik",
    df    = info$df,
    nobs  = info$nobs,
    marginal = info$marginal
  )
}


#' AIC method for tempssm objects (S3 method)
#'
#' @description
#' AIC is intentionally not computed for models fitted by \code{tempssm()}.
#' The method is registered to prevent automatic AIC calculation from the
#' \code{logLik()} method.
#'
#' @param object
#' An object of class \code{"tempssm"}, typically returned by
#' \code{tempssm()}.
#'
#' @param ...
#' Additional arguments passed to the generic \code{AIC()} function.
#' These are currently ignored.
#'
#' @param k
#' Numeric penalty coefficient accepted for compatibility with
#' \code{\link[stats]{AIC}}. This argument is ignored.
#'
#' @param marginal
#' Logical scalar or \code{NULL} accepted for backward compatibility.
#' This argument is ignored.
#'
#' @return
#' This function always raises an error.
#'
#' @examples
#' \dontrun{
#' data(sst_niigata)
#' res <- tempssm(sst_niigata)
#'
#' # AIC is intentionally not computed for tempssm objects.
#' AIC(res)
#'
#' # The log-likelihood and parameter count remain available.
#' ll <- logLik(res)
#' as.numeric(ll)
#' attr(ll, "df")
#' }
#'
#' @method AIC tempssm
#' @export
AIC.tempssm <- function(object, ..., k = 2, marginal = NULL) {
  cli::cli_abort(
    c(
      "AIC is not computed for {.cls tempssm} objects.",
      "Use {.fn logLik} to extract the log-likelihood.",
      "Use {.code attr(logLik(x), \"df\")} for the parameter count.",
      "If needed, compute AIC explicitly under your own assumptions."
    )
  )
}
