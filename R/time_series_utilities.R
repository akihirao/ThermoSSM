#' srr standards: time-series conversion utilities
#'
#' @srrstats {G2.4} Type conversion is explicit and localized to input
#' preprocessing or output construction. The package generally validates
#' expected input classes instead of silently coercing arbitrary user inputs.
#' Explicit conversions are used where they preserve the intended statistical
#' representation, such as constructing time indices, stripping optional
#' `units` attributes, converting `ts` values to numeric vectors for
#' calculations or plotting, and converting numeric JMA area IDs to character
#' endpoint identifiers.
#'
#' @srrstats {G2.4a} Integer-like conversions use `as.integer()` explicitly.
#' Examples include construction of year-month indices from `Date`, `Year`,
#' and `Month` fields, rounding and checking integer seasonal frequencies,
#' and using integer seasonal cycle positions to index climatological means.
#'
#' @srrstats {G2.4b} Continuous numeric conversions use `as.numeric()`
#' explicitly. Examples include converting time-series values to numeric
#' vectors for anomaly, climatology, cross-validation metric, and plotting
#' calculations, converting `units` inputs to numeric values with a warning,
#' and extracting numeric values from model summaries and prediction
#' intervals.
#'
#' @srrstats {G2.4c} Character conversions use `as.character()` where an
#' existing object must be represented as character data. Numeric JMA
#' `sea_area_id` values are explicitly converted with `as.character()` before
#' URL construction, and package version values are converted with
#' `as.character()` for the user-agent string. `paste()` and `paste0()` are
#' used only to build messages, labels, names, file names, and URLs, not as
#' substitutes for type conversion.
#'
#' @srrstats {G2.4d} Factor conversion is explicit where categorical seasonal
#' grouping is needed internally. `compute_monthly_climatology()` constructs
#' `factor(stats::cycle(temp_ts), levels = seq_len(freq_int))` so that all
#' seasonal periods are represented in a controlled order, including periods
#' whose values may be entirely missing.
#'
#' @srrstats {G2.6} One-dimensional inputs are pre-processed through shared
#' validation and coercion paths. Temperature-like analytical inputs must
#' inherit from base R `ts` and are checked with
#' `.tempssm_check_univariate_ts()`, which rejects multivariate `ts` objects
#' while preserving valid univariate time-series attributes. Numeric
#' one-dimensional inputs used in forecast accuracy calculations are checked
#' for compatible lengths and converted with `as.numeric()` before arithmetic.
#' Optional `units` one-dimensional `ts` inputs are stripped to numeric values
#' with an explicit warning while preserving `start`, `frequency`, and
#' dimensions. Unit tests cover univariate, multivariate, non-`ts`, numeric,
#' and `units` inputs.
#'
#' @srrstats {G2.7} The core modelling API uses base R `ts` objects because
#' the implemented state-space and cross-validation routines require regular
#' time-series attributes. Standard tabular and domain-specific input forms
#' are accepted through explicit conversion helpers before modelling:
#' `convert_monthly_df_to_ts()` accepts `data.frame` inputs and compatible
#' subclasses such as `tibble`; `read_monthly_temp_ts()` accepts CSV files and
#' converts them through the same data-frame pathway; `get_jma_sst_zoo()`
#' returns daily JMA SST data as a `zoo` object; and
#' `daily_zoo_to_monthly_ts()` converts daily `zoo` data to monthly `ts`
#' objects. The package therefore supports base tabular, CSV, and
#' domain-specific indexed time-series inputs while keeping analytical
#' routines on a single regular `ts` representation.
#'
#' @srrstats {G2.9} Diagnostic messages are issued when preprocessing loses or
#' adds information. Optional `units` attributes are stripped only with an
#' explicit warning that the values have been converted to numeric values.
#' Unnamed exogenous `ts` inputs are accepted only in workflows where default
#' names are explicitly allowed, and a warning is issued before names such as
#' `var1`, `var2`, ... are added. Monthly data-frame and CSV conversion warns
#' when input rows are sorted by date, and warns when implicit missing months
#' are inserted as explicit `NA` values. These behaviours are covered by unit
#' tests for `tempssm()` input preparation, tabular conversion, CSV reading,
#' and daily `zoo` aggregation.
#'
#' @srrstats {G2.10} Single-column extraction from tabular inputs avoids
#' relying on class-specific default simplification. Monthly data-frame and
#' CSV conversion use `[[ ]]` to extract `Date` and `Temp` vectors, and row
#' filtering uses `drop = FALSE` to preserve tabular structure. Internal JMA
#' parsing and `zoo` construction similarly use `[[ ]]` for column vectors and
#' `drop = FALSE` when returning subsets. Daily `zoo` aggregation extracts the
#' selected variable with `zoo_obj[, var, drop = FALSE]`. Tests cover base
#' `data.frame`, compatible `tibble`, and `zoo` inputs.
#'
#' @srrstats {G2.11} Data-frame-like inputs are processed column-wise through
#' explicit extraction and validation. Standard `Date` and numeric vector
#' columns are handled without class-dependent assumptions. Temperature value
#' columns with class `units` are accepted in monthly tabular conversion,
#' stripped to numeric values with an explicit warning, and then converted to
#' regular `ts` objects. Unit tests cover `units` temperature columns in both
#' base `data.frame` and compatible `tibble` inputs, confirming that
#' non-standard column attributes are pre-processed rather than causing
#' avoidable errors.
#'
#' @srrstats {G2.12} List columns in tabular temperature inputs are rejected
#' with informative errors rather than being silently simplified. Monthly
#' tabular conversion requires `Temp` to be a numeric vector, or a `units`
#' vector that can be stripped to numeric values with a warning. Because list
#' columns can contain heterogeneous lengths or types, automatic `unlist()`
#' conversion would risk changing the intended observations. Unit tests cover
#' list-valued `Temp` columns in both base `data.frame` and compatible
#' `tibble` inputs.
#'
#' @srrstats {TS1.0} The package uses base R `ts` objects as its explicit
#' time-series class for modelling and related utilities. Core functions such
#' as `tempssm()`, `ts_train_test_split()`, `trim_ts_overlap()`,
#' `split_multi_ts()`, `compute_monthly_climatology()`,
#' `compute_temp_anomaly()`, and `plot_temp_anomaly()` validate that inputs inherit
#' from class `ts` and reject generic non-time-series inputs. Data-frame and
#' CSV inputs are accepted only by dedicated conversion utilities, which return
#' explicit `ts` objects and are not used as generic substitutes for
#' time-series inputs in modelling functions.
#'
#' @srrstats {TS1.1} Function documentation explicitly states the expected
#' input types and classes for time-series data and conversion utilities. Core
#' modelling and time-series functions document base R `ts` inputs, including
#' `temp_data`, `exo_data`, and `multi_ts`. Conversion helpers document
#' non-time-series inputs such as data frames and CSV file paths, and document
#' their return values as explicit monthly `ts` objects. Functions for JMA SST
#' data document `zoo` inputs or outputs where daily indexed data are used,
#' and monthly `ts` outputs where data are aggregated.
#'
#' @srrstats {TS1.5} The package checks strict ordering of time indices before
#' model fitting and cross-validation. The core input path calls
#' `.tempssm_check_ts_order()` from `.tempssm_check_temp_ts()` and
#' `.tempssm_check_exo_ts()` to require strictly increasing `time()` values for
#' accepted `ts` inputs. Conversion helpers also validate calendar order before
#' constructing monthly `ts` objects: data-frame input is sorted by `Date` and
#' duplicate months are rejected, while CSV input must have strictly
#' increasing year-month rows with no duplicate year-month combinations.
#' Missing months are warned about separately because they represent
#' regularity/completeness rather than ordering.
#'
#' @srrstats {TS1.6} Ordering violations are caught during input
#' pre-processing rather than during model fitting. Core `ts` inputs are
#' checked by `.tempssm_check_ts_order()` before they are passed to model
#' construction or cross-validation fold generation. Data-frame conversion
#' catches unordered `Date` values with a warning before sorting, and rejects
#' duplicate monthly indices. CSV conversion rejects duplicate or
#' non-increasing year-month rows before constructing a `ts` object. `zoo`
#' conversion rejects missing or non-increasing indices before monthly
#' aggregation. Unit tests cover these ordering checks in the corresponding
#' pre-processing functions.
#'
#' @srrstats {TS1.7} The package accepts vector inputs carrying class `units`
#' from the `units` package without adding `units` as a hard runtime
#' dependency. Core model input pre-processing detects `units` attached to
#' `ts` objects, converts values to numeric vectors for downstream state-space
#' modelling, and preserves the original `ts` time attributes. Data-frame and
#' `zoo` conversion helpers also strip `units` from value columns before
#' constructing monthly `ts` objects. The conversion emits an explicit warning
#' so users know that unit metadata are not retained in model inputs. Tests for
#' this behaviour are conditional on the optional `units` package.
#'
#' @srrstats {TS2.0} Core modelling functions require regular base R `ts`
#' inputs, where missing observations can only be represented explicitly as
#' `NA` values. Conversion utilities that construct monthly `ts` objects from
#' data-frame, CSV, or daily `zoo` inputs detect implicit missing months before
#' constructing the output. Missing months between the first and last observed
#' month are converted to explicit `NA` values with a diagnostic warning, so
#' irregular input is not silently collapsed into a shorter regular `ts`
#' object. Unit tests cover these conversion paths.
#'
#' @noRd
NULL


#' Validate and prepare labels for a time-series object
#'
#' @inheritParams set_ts_name
#' @param n_col Integer number of series in \code{ts_in}.
#'
#' @return A character vector with one label per series.
#'
#' @keywords internal
#' @noRd
.prepare_ts_labels <- function(label, n_col) {
  .tempssm_check_character(label, "label")

  if (length(label) != n_col) {
    cli::cli_abort(
      paste0(
        "Length of {.arg label} must equal the number of series ",
        "in {.arg ts_in}."
      )
    )
  }

  label
}


#' Assign variable names to a ts object
#'
#' @description
#' `set_ts_name()` assigns variable (column) names to a time series object
#' of class \code{ts}. The function supports both univariate and multivariate
#' time series and ensures that variable names are handled consistently within
#' the \pkg{tempssm} framework.
#'
#' For univariate series, the input is converted to a single-column \code{ts}
#' object with the specified name. For multivariate series, column names are
#' assigned directly.
#'
#' @param ts_in
#' A time series object of class \code{ts}. May be univariate or multivariate.
#'
#' @param label
#' A character string or character vector specifying variable names.
#' For a univariate series, must be a length-one character string.
#' For a multivariate series, its length must equal the number of columns in
#' \code{ts_in}.
#'
#' @param quiet
#' Logical scalar; if \code{TRUE}, suppresses the informational message.
#'
#' @details
#' This function does not modify the time attributes of the input series
#' (e.g., start time, frequency). It only assigns variable names while 
#' preserving the internal structure required by downstream functions such as
#' \code{tempssm()}.
#'
#' @return
#' A \code{ts} object with assigned variable names and the same time scale as
#' \code{ts_in}, including \code{start}, \code{end}, and \code{frequency}.
#'
#' @seealso
#' \code{\link{trim_ts_overlap}},
#' \code{\link{split_multi_ts}},
#' \code{\link{tempssm}}
#'
#' @examples
#' ## Univariate example
#' ts_uni <- ts(
#'   rnorm(12 * 10),
#'   start = c(2000, 1),
#'   frequency = 12
#' )
#'
#' ts_uni_named <- set_ts_name(ts_uni, label = "temperature")
#'
#' ## Multivariate example
#' ts_multi <- ts(
#'   matrix(rnorm(240), ncol = 3),
#'   start = c(2000, 1),
#'   frequency = 12
#' )
#'
#' ts_multi_named <- set_ts_name(
#'   ts_multi,
#'   label = c("precip", "solar", "wind")
#' )
#'
#' @export
set_ts_name <- function(ts_in, label, quiet = FALSE) {
  ## ---- input check ----------------------------------------------------
  .tempssm_check_class(ts_in, "ts_in", "ts")

  ts_in <- .strip_units_ts(ts_in, arg_name = "ts_in")

  n_col <- NCOL(ts_in)
  label <- .prepare_ts_labels(label, n_col)

  .tempssm_check_length_one(quiet, "quiet")
  .tempssm_check_logical(quiet, "quiet")
  if (is.na(quiet)) {
    cli::cli_abort("`quiet` must be a single logical value.")
  }

  .tempssm_cli_debug("Assigning variable names to {.cls ts} object")

  ## ---- ensure matrix form --------------------------------------------
  x <- if (is.null(dim(ts_in))) {
    .tempssm_cli_debug("Converting univariate series to matrix form")
    matrix(ts_in, ncol = 1)
  } else {
    ts_in
  }

  ## ---- assign names ---------------------------------------------------
  colnames(x) <- label

  ## ---- reconstruct ts -------------------------------------------------
  ts_out <- stats::ts(
    x,
    start = stats::start(ts_in),
    frequency = stats::frequency(ts_in)
  )

  ## ---- inform ---------------------------------------------------------
  if (!quiet) {
    .tempssm_cli_inform(
      "Assigned {length(label)} variable name{?s} to time series"
    )
  }

  return(ts_out)
}


#' Strip units from a vector-like input
#'
#' @param x A vector-like object.
#' @param arg_name Name of the argument or column being converted.
#'
#' @return A numeric vector if \code{x} has class \code{"units"}, otherwise
#'   returns \code{x} unchanged.
#'
#' @keywords internal
#' @noRd
.strip_units_values <- function(x, arg_name) {
  if (!inherits(x, "units")) {
    return(x)
  }

  cli::cli_warn(
    "Units attached to {.arg {arg_name}} are converted to numeric values."
  )

  as.numeric(x)
}


#' Strip units from a \code{ts} object while preserving time attributes
#'
#' @inheritParams .tempssm_check_ts_order
#' @param arg_name Name of the argument being converted.
#'
#' @return A \code{ts} object without units.
#'
#' @keywords internal
#' @noRd
.strip_units_ts <- function(x, arg_name) {
  if (!inherits(x, "units")) {
    return(x)
  }

  values <- .strip_units_values(x, arg_name = arg_name)

  if (!is.null(dim(x))) {
    dim(values) <- dim(x)
    dimnames(values) <- dimnames(x)
  }

  stats::ts(
    values,
    start = stats::start(x),
    frequency = stats::frequency(x)
  )
}


#' Complete a monthly index by inserting explicit missing values
#'
#' @param ym_index Integer year-month index.
#' @param values Numeric values aligned with \code{ym_index}.
#' @param context Description of the input source for warning messages.
#'
#' @return A list containing completed \code{ym_index} and \code{values}.
#'
#' @keywords internal
#' @noRd
.complete_monthly_values <- function(ym_index, values, context) {
  if (length(ym_index) == 0) {
    cli::cli_abort(
      "No observations are available in {context}."
    )
  }

  full_ym_index <- seq.int(min(ym_index), max(ym_index))

  if (length(full_ym_index) != length(ym_index)) {
    cli::cli_warn(
      c(
        "Implicit missing months detected in {context}.",
        "i" = "Explicit {.val NA} values are inserted."
      )
    )
  }

  out <- rep(NA_real_, length(full_ym_index))
  out[match(ym_index, full_ym_index)] <- as.numeric(values)

  list(
    ym_index = full_ym_index,
    values = out
  )
}


#' Construct a monthly time series from a year-month index
#'
#' @inheritParams .complete_monthly_values
#'
#' @return A univariate monthly \code{ts} object.
#'
#' @keywords internal
#' @noRd
.monthly_values_to_ts <- function(ym_index, values, context) {
  completed <- .complete_monthly_values(
    ym_index = ym_index,
    values = values,
    context = context
  )

  start_ym <- completed$ym_index[1]
  start_year <- (start_ym - 1) %/% 12
  start_month <- start_ym - start_year * 12

  .tempssm_cli_debug(
    "Creating ts object starting at {start_year}-{start_month}"
  )

  stats::ts(
    completed$values,
    start = c(start_year, start_month),
    frequency = 12
  )
}


#' Resolve a current time-series argument and its compatibility alias
#'
#' @param current Current argument, which may be missing.
#' @param legacy Compatibility alias, or \code{NULL}.
#' @param current_name Name of the current argument.
#' @param legacy_name Name of the compatibility alias.
#'
#' @return The resolved argument value.
#'
#' @keywords internal
#' @noRd
.resolve_trim_ts_alias <- function(current,
                                   legacy,
                                   current_name,
                                   legacy_name) {
  if (missing(current)) {
    return(legacy)
  }

  if (!is.null(legacy)) {
    cli::cli_abort(
      "Use either {.arg {current_name}} or {.arg {legacy_name}}, not both."
    )
  }

  current
}


#' Validate and prepare names for overlapping time series
#'
#' @inheritParams trim_ts_overlap
#' @param num_exo_variable Number of exogenous variables.
#'
#' @return A named list containing temperature and exogenous variable names.
#'
#' @keywords internal
#' @noRd
.prepare_trim_ts_names <- function(temp_name, exo_name, num_exo_variable) {
  .tempssm_check_length_one(temp_name, "temp_name")
  .tempssm_check_character(temp_name, "temp_name")
  if (anyNA(temp_name)) {
    cli::cli_abort(
      "{.arg temp_name} must be a character scalar."
    )
  }

  if (is.null(exo_name)) {
    cli::cli_warn(
      "`exo_name` not supplied; assigning default names: var1, var2, ..."
    )
    exo_name <- paste0("var", seq_len(num_exo_variable))
  } else {
    .tempssm_check_character(exo_name, "exo_name")
    if (length(exo_name) != num_exo_variable) {
      cli::cli_abort(
        c(
          "Length of {.arg exo_name} must equal ",
          "the number of exogenous variables."
        )
      )
    }
    if (anyNA(exo_name)) {
      cli::cli_abort(
        "{.arg exo_name} must not contain missing values."
      )
    }
  }

  list(
    temp_name = temp_name,
    exo_name = exo_name
  )
}


#' Intersect and split temperature and exogenous time series
#'
#' @inheritParams trim_ts_overlap
#'
#' @return A named list containing overlapping temperature and exogenous
#'   time series.
#'
#' @keywords internal
#' @noRd
.intersect_trim_ts <- function(temp_data, exo_data) {
  same_frequency <- isTRUE(all.equal(
    stats::frequency(temp_data),
    stats::frequency(exo_data)
  ))
  if (!same_frequency) {
    cli::cli_abort(
      "{.arg temp_data} and {.arg exo_data} must have the same frequency."
    )
  }

  overlap <- suppressWarnings(
    stats::ts.intersect(temp_data, exo_data)
  )
  if (is.null(overlap) || NROW(overlap) == 0L) {
    cli::cli_abort(
      c(
        "No overlapping time period found ",
        "between {.arg temp_data} and {.arg exo_data}."
      )
    )
  }

  list(
    temperature = overlap[, 1L, drop = FALSE],
    exogenous = overlap[, -1L, drop = FALSE]
  )
}


#' Construct a labeled overlapping time-series result
#'
#' @param overlap Overlapping series returned by \code{.intersect_trim_ts()}.
#' @inheritParams trim_ts_overlap
#'
#' @return A named list containing labeled temperature and exogenous series.
#'
#' @keywords internal
#' @noRd
.new_trimmed_ts_result <- function(overlap, temp_name, exo_name) {
  temperature <- set_ts_name(
    overlap$temperature,
    label = temp_name
  )
  exogenous <- overlap$exogenous

  if (NCOL(exogenous) == 1L) {
    exogenous <- set_ts_name(exogenous, label = exo_name)
  } else {
    colnames(exogenous) <- exo_name
  }

  list(
    temperature = temperature,
    exogenous = exogenous
  )
}


#' Trim and align temperature and exogenous time series over their shared period
#'
#' @description
#' `trim_ts_overlap()` aligns a temperature time series and one or more 
#' exogenous time series by trimming them to their shared (overlapping) time 
#' period.
#' 
#' The function returns the trimmed series as a named list of `ts` objects,
#' with consistent variable labels applied for downstream modeling in
#' \code{tempssm()}.
#'
#' Univariate `ts` objects are labeled using \code{set_ts_name()} to ensure a
#' consistent handling of variable names within the \pkg{tempssm} framework.
#'
#' @param temp_data
#' A univariate \code{ts} object representing the temperature time series.
#'
#' @param exo_data
#' A multivariate or univariate \code{ts} object of exogenous variables.
#' Each column represents a distinct exogenous covariate.
#'
#' @param temp_name
#' Character scalar giving the variable name for the temperature series.
#' This name is applied using \code{set_ts_name()}.
#'
#' @param exo_name
#' Optional character vector giving variable names for the exogenous variables.
#' Its length must equal the number of exogenous variables when supplied.
#' If \code{NULL}, default names of the form \code{var1}, \code{var2}, \dots
#' are assigned with a warning.
#'
#' @param temp_ts,exo_ts
#' Compatibility aliases for \code{temp_data} and \code{exo_data}.
#' These are accepted to avoid breaking existing calls, but new code should use
#' \code{temp_data} and \code{exo_data}.
#'
#' @details
#' The shared time window is determined using \code{ts.intersect()}, and both
#' temperature and exogenous series are trimmed accordingly.
#' The two inputs must have the same frequency, but that frequency is not fixed;
#' quarterly, monthly, twice-monthly, and other regular \code{ts} frequencies
#' are supported.
#'
#' For univariate series, variable names are assigned via
#' \code{set_ts_name()} rather than \code{colnames()} in order to maintain
#' internal consistency required by \code{tempssm()}.
#'
#' @return
#' A named list with the following elements:
#' \describe{
#'   \item{temperature}{A univariate \code{ts} object of the trimmed 
#'   temperature series.}
#'   \item{exogenous}{A \code{ts} object of the trimmed exogenous variables.}
#' }
#'
#' @seealso
#' [ts.intersect()], [set_ts_name()], \code{\link{tempssm}}
#'
#' @examples
#' temp_data <- ts(rnorm(100), start = c(2000, 1), frequency = 12)
#' exo_data <- ts(matrix(rnorm(200), ncol = 2),
#'   start = c(2001, 1), frequency = 12
#' )
#'
#' trim_ts_overlap(
#'   temp_data,
#'   exo_data,
#'   temp_name = "mean_temp",
#'   exo_name  = c("precip", "solar")
#' )
#'
#' @importFrom stats ts.intersect
#' @export
trim_ts_overlap <- function(
  temp_data,
  exo_data,
  temp_name = "temp",
  exo_name = NULL,
  temp_ts = NULL,
  exo_ts = NULL
) {
  ## ---- backward-compatible aliases -----------------------------------
  temp_data <- .resolve_trim_ts_alias(
    temp_data,
    legacy = temp_ts,
    current_name = "temp_data",
    legacy_name = "temp_ts"
  )
  exo_data <- .resolve_trim_ts_alias(
    exo_data,
    legacy = exo_ts,
    current_name = "exo_data",
    legacy_name = "exo_ts"
  )

  ## ---- basic checks ---------------------------------------------------
  .tempssm_check_univariate_ts(temp_data, "temp_data")
  .tempssm_check_class(exo_data, "exo_data", "ts")

  num_exo_variable <- NCOL(exo_data)

  ## ---- exo name handling ----------------------------------------------
  variable_names <- .prepare_trim_ts_names(
    temp_name = temp_name,
    exo_name = exo_name,
    num_exo_variable = num_exo_variable
  )
  temp_name <- variable_names$temp_name
  exo_name <- variable_names$exo_name

  .tempssm_cli_debug(
    paste0(
      "Trimming time series overlap (temp length={length(temp_data)}, ",
      "exo vars={num_exo_variable})"
    )
  )

  ## ---- overlap --------------------------------------------------------
  overlap <- .intersect_trim_ts(temp_data, exo_data)

  .tempssm_cli_debug("Overlap length: {NROW(overlap$temperature)}")

  ## ---- labels ---------------------------------------------------------
  out <- .new_trimmed_ts_result(
    overlap = overlap,
    temp_name = temp_name,
    exo_name = exo_name
  )

  ## ---- inform ---------------------------------------------------------
  .tempssm_cli_inform(
    "Trimmed series to {NROW(out$temperature)} overlapping observation{?s}"
  )

  return(out)
}


#' Split a multivariate ts object into univariate ts objects
#'
#' @description
#' `split_multi_ts()` splits a multivariate \code{ts} object into a list of
#' univariate \code{ts} objects, one for each variable (column).
#'
#' Each resulting univariate series preserves the original time attributes and
#' is labeled using \code{set_ts_name()} with the corresponding column name.
#' This ensures consistent handling of variable names within the
#' \pkg{tempssm} framework.
#'
#' @param multi_ts
#' A multivariate \code{ts} object.
#' Each column represents a distinct variable.
#'
#' @details
#' The function requires \code{multi_ts} to have valid column names.
#' If a univariate \code{ts} object is supplied, the function stops 
#' with an error.
#'
#' @return
#' A named list of univariate \code{ts} objects.
#' Each list element corresponds to one column of \code{multi_ts}, and the list
#' names are taken from \code{colnames(multi_ts)}.
#'
#' @seealso
#' \code{\link{trim_ts_overlap}},
#' \code{\link{set_ts_name}},
#' \code{\link{tempssm}}
#'
#' @examples
#' multi_ts <- ts(
#'   matrix(rnorm(200), ncol = 2),
#'   start = c(2001, 1),
#'   frequency = 12
#' )
#' colnames(multi_ts) <- c("precip", "solar")
#'
#' split_multi_ts(multi_ts)
#'
#' @export
split_multi_ts <- function(multi_ts) {
  ## ---- input checks ---------------------------------------------------
  if (!inherits(multi_ts, "ts")) {
    cli::cli_abort(
      "`multi_ts` must be an object of class {.cls ts}."
    )
  }

  num_variable <- NCOL(multi_ts)

  if (num_variable == 1) {
    cli::cli_abort(
      "`multi_ts` must be multivariate; a univariate series cannot be split."
    )
  }

  if (is.null(colnames(multi_ts))) {
    cli::cli_abort(
      "`multi_ts` must have column names."
    )
  }

  names_var <- colnames(multi_ts)

  .tempssm_cli_debug(
    "Splitting multivariate ts with {num_variable} variable{?s}"
  )

  ## ---- split ----------------------------------------------------------
  out <- vector("list", num_variable)

  for (i in seq_len(num_variable)) {
    target_name <- names_var[i]

    .tempssm_cli_debug("Processing variable: {target_name}")

    out[[i]] <- set_ts_name(
      multi_ts[, i, drop = FALSE],
      label = target_name
    )
  }

  names(out) <- names_var

  ## ---- inform ---------------------------------------------------------
  .tempssm_cli_inform(
    "Split time series into {num_variable} univariate series"
  )

  return(out)
}


#' Prepare a monthly data frame and its year-month index
#'
#' @inheritParams convert_monthly_df_to_ts
#'
#' @return A list containing the sorted data frame and its integer year-month
#'   index.
#'
#' @keywords internal
#' @noRd
.prepare_monthly_df_index <- function(df) {
  if (!is.data.frame(df)) {
    cli::cli_abort("`df` must be a data frame.")
  }

  required_cols <- c("Date", "Temp")

  if (!all(required_cols %in% names(df))) {
    cli::cli_abort(
      paste0(
        "The data frame must contain columns: ",
        "{paste(required_cols, collapse = ', ')}."
      )
    )
  }

  date_col <- df[["Date"]]

  if (!inherits(date_col, "Date")) {
    cli::cli_abort("The {.col Date} column must be of class {.cls Date}.")
  }

  if (anyNA(date_col)) {
    cli::cli_abort("The {.col Date} column must not contain missing values.")
  }

  .tempssm_cli_debug("Validating input data frame with {nrow(df)} rows")

  if (length(date_col) > 1 && any(diff(date_col) < 0)) {
    cli::cli_warn(
      "Input data are not ordered by {.col Date}; sorting before conversion."
    )
  }

  df <- df[order(date_col), , drop = FALSE]
  date_col <- df[["Date"]]
  ym_index <- as.integer(format(date_col, "%Y")) * 12 +
    as.integer(format(date_col, "%m"))

  if (anyDuplicated(ym_index)) {
    cli::cli_abort("The {.col Date} column must not contain duplicate months.")
  }

  list(
    data = df,
    ym_index = ym_index
  )
}


#' Extract validated temperature values from a monthly data frame
#'
#' @inheritParams convert_monthly_df_to_ts
#'
#' @return A numeric vector containing monthly temperature values.
#'
#' @keywords internal
#' @noRd
.extract_monthly_df_temp_values <- function(df) {
  temp_col <- df[["Temp"]]

  if (is.list(temp_col) && !inherits(temp_col, "units")) {
    cli::cli_abort(
      "The {.col Temp} column must be numeric, not a list column."
    )
  }

  temp_values <- .strip_units_values(temp_col, arg_name = "Temp")

  if (!is.numeric(temp_values)) {
    cli::cli_abort(
      "The {.col Temp} column must be numeric."
    )
  }

  .tempssm_check_no_undefined(temp_values, "Temp")
  temp_values
}


#' Convert a data frame of monthly temperature time series to a \code{ts} object
#'
#' @details
#' This function converts a data frame containing a monthly temperature
#' time series into an R \code{ts} object with a frequency of 12.
#'
#' The input data frame must contain the following columns:
#' \describe{
#'   \item{\code{Date}}{A date column indicating the time index.
#'   If the exact day of the month is not uniquely defined, any arbitrary
#'   day (e.g., the first day of the month) may be used.}
#'   \item{\code{Temp}}{Monthly temperature values. Missing values should be
#'   represented as \code{NA}.}
#' }
#'
#' The function assumes that the input data represent a regularly spaced
#' monthly time series. If missing months are detected in the \code{Date}
#' column, a warning is issued and explicit \code{NA} values are inserted.
#'
#' The expected format is:
#'
#' \preformatted{
#' Date        Temp
#' 2001-01-01  10.4
#' 2001-02-01   8.2
#' 2001-03-01   NA
#' 2001-04-01  13.6
#' ...
#' }
#'
#' @param df A data frame containing monthly temperature data with columns
#'   \code{Date} (class \code{Date}) and \code{Temp} (numeric).
#'
#' @details
#' The output is a regular monthly \code{ts} object. Months are represented as
#' equally spaced observations with \code{frequency = 12}; month lengths are
#' not converted to a fixed number of days.
#'
#' @return A univariate monthly \code{ts} object representing the temperature
#'   time series, with \code{frequency = 12}.
#'
#' @importFrom stats ts
#'
#' @encoding UTF-8
#'
#' @examples
#' ## Create a data frame of monthly temperature data
#' df <- data.frame(
#'   Date = as.Date(c(
#'     "2001-01-01",
#'     "2001-02-01",
#'     "2001-03-01",
#'     "2001-04-01",
#'     "2001-05-01"
#'   )),
#'   Temp = c(10.4, 8.2, NA, 13.6, 16.1)
#' )
#'
#' ## Convert to a monthly ts object
#' temp_ts <- convert_monthly_df_to_ts(df)
#'
#' ## Inspect the result
#' temp_ts
#'
#' @export
convert_monthly_df_to_ts <- function(df) {
  prepared <- .prepare_monthly_df_index(df)
  temp_values <- .extract_monthly_df_temp_values(prepared$data)

  ts_out <- .monthly_values_to_ts(
    ym_index = prepared$ym_index,
    values = temp_values,
    context = "the {.col Date} column"
  )

  ## ---- inform ---------------------------------------------------------
  .tempssm_cli_inform(
    paste0(
      "Converted data frame to monthly time series ",
      "with {length(ts_out)} observation{?s}"
    )
  )

  return(ts_out)
}


#' Read and perform structural validation of a monthly temperature CSV file
#'
#' @inheritParams read_monthly_temp_ts
#'
#' @return A data frame containing the parsed CSV data.
#'
#' @keywords internal
#' @noRd
.read_monthly_temp_csv <- function(csv) {
  if (!is.character(csv) || length(csv) != 1) {
    cli::cli_abort("`csv` must be a file path (character scalar).")
  }

  if (!file.exists(csv)) {
    cli::cli_abort("File does not exist: {csv}")
  }

  .tempssm_cli_debug("Reading CSV file: {csv}")

  raw_data <- tryCatch(
    readr::read_csv(csv, show_col_types = FALSE),
    error = function(e) {
      cli::cli_abort("Failed to read CSV file: {conditionMessage(e)}")
    }
  )

  .tempssm_cli_debug(
    "Columns in input: {paste(names(raw_data), collapse = ', ')}"
  )

  required_cols <- c("Year", "Month", "Temp")

  if (!all(required_cols %in% names(raw_data))) {
    cli::cli_abort(
      paste0(
        "The CSV file must contain columns: ",
        "{paste(required_cols, collapse = ', ')}."
      )
    )
  }

  if (nrow(raw_data) == 0) {
    cli::cli_abort("The input CSV file contains no rows.")
  }

  raw_data
}


#' Validate a CSV year-month index
#'
#' @param raw_data A data frame containing code{Year} and code{Month} columns.
#'
#' @return An integer vector encoding the year and month of each observation.
#'
#' @keywords internal
#' @noRd
.prepare_monthly_csv_index <- function(raw_data) {
  year <- raw_data[["Year"]]
  month <- raw_data[["Month"]]

  if (anyNA(year) || anyNA(month)) {
    cli::cli_abort(
      "{.col Year} and {.col Month} must not contain missing values."
    )
  }

  if (!is.numeric(year) || !is.numeric(month)) {
    cli::cli_abort(
      "The {.col Year} and {.col Month} columns must be numeric."
    )
  }

  .tempssm_check_no_undefined(year, "Year")
  .tempssm_check_no_undefined(month, "Month")

  if (!all(.tempssm_is_integerish(year)) ||
      !all(.tempssm_is_integerish(month))) {
    cli::cli_abort(
      "The {.col Year} and {.col Month} columns must contain whole numbers."
    )
  }

  if (any(month < 1 | month > 12)) {
    cli::cli_abort("Detected invalid month values outside 1-12.")
  }

  ym_index <- as.integer(year) * 12L + as.integer(month)

  if (anyDuplicated(ym_index)) {
    cli::cli_abort(
      "The CSV file must not contain duplicate year-month rows."
    )
  }

  if (length(ym_index) > 1 && any(diff(ym_index) <= 0)) {
    cli::cli_abort(
      "The CSV file must be ordered by strictly increasing year-month values."
    )
  }

  ym_index
}


#' Read and convert a monthly temperature CSV file to a \code{ts} object
#'
#' @details
#' The input CSV file must contain monthly temperature data with
#' three columns: \code{Year}, \code{Month}, and \code{Temp}.
#' The expected format is:
#'
#' \preformatted{
#' Year,Month,Temp
#' 2001,1,10.4
#' 2001,2,8.2
#' 2001,3,NA
#' 2001,4,13.6
#' ...
#' }
#'
#' @param csv A length-one character string giving the path to a UTF-8 CSV file
#'   with columns \code{Year}, \code{Month}, and \code{Temp}.
#'
#' @details
#' The output is a regular monthly \code{ts} object. The \code{Year} and
#' \code{Month} columns define calendar months, which are represented as
#' equally spaced observations with \code{frequency = 12}. Month lengths are
#' not converted to a fixed number of days.
#'
#' @importFrom readr read_csv
#' @importFrom stats ts
#'
#' @encoding UTF-8
#'
#' @return A univariate monthly \code{ts} object representing the temperature
#'   time series, with \code{frequency = 12}.
#'
#' @examples
#' ## Create a temporary CSV file with monthly temperature data
#' tmp_csv <- tempfile(fileext = ".csv")
#'
#' writeLines(
#'   c(
#'     "Year,Month,Temp",
#'     "2001,1,10.4",
#'     "2001,2,8.2",
#'     "2001,3,NA",
#'     "2001,4,13.6",
#'     "2001,5,16.1"
#'   ),
#'   tmp_csv
#' )
#'
#' ## Read the CSV file and convert to a monthly ts object
#' temp_ts <- read_monthly_temp_ts(tmp_csv)
#'
#' ## Inspect the result
#' temp_ts
#'
#' @export
read_monthly_temp_ts <- function(csv) {
  raw_data <- .read_monthly_temp_csv(csv)
  ym_index <- .prepare_monthly_csv_index(raw_data)
  temp_values <- .extract_monthly_df_temp_values(raw_data)

  ts_out <- .monthly_values_to_ts(
    ym_index = ym_index,
    values = temp_values,
    context = "the CSV year-month index"
  )

  ## ---- inform ---------------------------------------------------------
  .tempssm_cli_inform(
    "Loaded monthly temperature series with {length(ts_out)} observation{?s}"
  )

  return(ts_out)
}


#' Validate controls for daily-to-monthly aggregation
#'
#' @inheritParams daily_zoo_to_monthly_ts
#'
#' @return A named list containing validated aggregation controls.
#'
#' @keywords internal
#' @noRd
.prepare_daily_zoo_controls <- function(var, na.rm, na_prop_max) {
  .tempssm_check_length_one(var, "var")
  .tempssm_check_character(var, "var")
  if (is.na(var)) {
    cli::cli_abort("{.arg var} must be a character scalar.")
  }

  .tempssm_check_length_one(na.rm, "na.rm")
  .tempssm_check_logical(na.rm, "na.rm")
  if (is.na(na.rm)) {
    cli::cli_abort("{.arg na.rm} must be a logical scalar.")
  }

  .tempssm_check_length_one(na_prop_max, "na_prop_max")
  .tempssm_check_numeric(na_prop_max, "na_prop_max")
  if (is.na(na_prop_max) ||
      !is.finite(na_prop_max) ||
      na_prop_max < 0 ||
      na_prop_max > 1) {
    cli::cli_abort(
      "`na_prop_max` must be between 0 and 1 for daily_zoo_to_monthly_ts()."
    )
  }

  list(
    var = var,
    na.rm = na.rm,
    na_prop_max = na_prop_max
  )
}


#' Validate and select data for daily-to-monthly aggregation
#'
#' @inheritParams daily_zoo_to_monthly_ts
#'
#' @return A named list containing the selected one-column code{zoo} object,
#'   its time index, and numeric values.
#'
#' @keywords internal
#' @noRd
.prepare_daily_zoo_data <- function(zoo_obj, var) {
  if (!inherits(zoo_obj, "zoo")) {
    cli::cli_abort("Input must be a {.cls zoo} object.")
  }

  if (!var %in% colnames(zoo_obj)) {
    cli::cli_abort(
      "Variable {.val {var}} not found in the zoo object."
    )
  }

  idx <- zoo::index(zoo_obj)
  if (length(idx) == 0) {
    cli::cli_abort(
      "No observations are available in the zoo object."
    )
  }

  if (!inherits(idx, c("Date", "POSIXt"))) {
    cli::cli_abort(
      "Index of the zoo object must be {.cls Date} or {.cls POSIXt}."
    )
  }

  if (anyNA(idx)) {
    cli::cli_abort(
      "Index of the zoo object must not contain missing values."
    )
  }

  if (length(idx) > 1 && any(diff(idx) <= 0)) {
    cli::cli_abort(
      "Index of the zoo object must be strictly increasing."
    )
  }

  selected_zoo <- zoo_obj[, var, drop = FALSE]
  selected_values <- zoo::coredata(selected_zoo)
  if (is.data.frame(selected_values)) {
    selected_values <- selected_values[[1L]]
  } else if (is.matrix(selected_values)) {
    selected_values <- selected_values[, 1L]
  }

  selected_values <- .strip_units_values(selected_values, arg_name = var)
  if (!is.numeric(selected_values)) {
    cli::cli_abort(
      "Variable {.val {var}} in the zoo object must be numeric."
    )
  }

  list(
    selected_zoo = selected_zoo,
    index = idx,
    values = selected_values
  )
}


#' Summarize one month of daily values
#'
#' @param x Numeric values observed within one calendar month.
#' @inheritParams daily_zoo_to_monthly_ts
#'
#' @return A numeric scalar containing the monthly mean or code{NA_real_}.
#'
#' @keywords internal
#' @noRd
.daily_month_mean <- function(x, na.rm, na_prop_max) {
  if (all(is.na(x))) {
    return(NA_real_)
  }

  if (mean(is.na(x)) > na_prop_max) {
    return(NA_real_)
  }

  mean(x, na.rm = na.rm)
}


#' Aggregate selected daily zoo data by calendar month
#'
#' @param selected_zoo A validated one-column daily code{zoo} object.
#' @inheritParams daily_zoo_to_monthly_ts
#'
#' @return A one-column monthly code{zoo} object.
#'
#' @keywords internal
#' @noRd
.aggregate_daily_zoo_monthly <- function(selected_zoo,
                                         na.rm,
                                         na_prop_max) {
  monthly_fun <- function(x) {
    .daily_month_mean(
      x,
      na.rm = na.rm,
      na_prop_max = na_prop_max
    )
  }

  zoo_monthly <- stats::aggregate(
    selected_zoo,
    zoo::as.yearmon,
    monthly_fun
  )

  if (NROW(zoo_monthly) == 0) {
    cli::cli_abort(
      "No valid observations available after aggregation."
    )
  }

  zoo_monthly
}


#' Convert monthly zoo data to a regular monthly time series
#'
#' @param zoo_monthly A validated one-column monthly code{zoo} object.
#' @param var Character scalar used as the output column name.
#'
#' @return A one-column monthly code{ts} object.
#'
#' @keywords internal
#' @noRd
.monthly_zoo_to_ts <- function(zoo_monthly, var) {
  monthly_values <- .strip_units_values(
    zoo::coredata(zoo_monthly),
    arg_name = var
  )
  .tempssm_check_no_undefined(monthly_values, var)

  monthly_index <- zoo::index(zoo_monthly)
  ym_index <- as.integer(format(monthly_index, "%Y")) * 12 +
    as.integer(format(monthly_index, "%m"))
  completed <- .complete_monthly_values(
    ym_index = ym_index,
    values = monthly_values,
    context = "the aggregated monthly zoo index"
  )

  start_ym <- completed$ym_index[1]
  start_year <- (start_ym - 1) %/% 12
  start_month <- start_ym - start_year * 12

  .tempssm_cli_debug(
    "Creating monthly ts starting at {start_year}-{start_month}"
  )

  ts_monthly <- stats::ts(
    matrix(completed$values, ncol = 1),
    start = c(start_year, start_month),
    frequency = 12
  )
  colnames(ts_monthly) <- var

  if (mean(is.na(ts_monthly)) > 0.3) {
    cli::cli_warn(
      "More than 30% of aggregated monthly values are missing."
    )
  }

  ts_monthly
}


#' Convert a daily zoo object to a monthly \code{ts} object
#'
#' @param zoo_obj A \code{zoo} object with daily observations. The index must
#'   be of class \code{Date} or \code{POSIXt}, and the object must include a
#'   numeric column named by \code{var}.
#'
#' @param var A character string specifying the name of the variable
#'   to be aggregated (default: \code{"Temp"}).
#'
#' @param na.rm Logical scalar; should missing values be removed before
#'   averaging?
#'
#' @param na_prop_max Numeric scalar giving the maximum allowed proportion of
#'   NA values within a month. If the proportion of missing values exceeds this
#'   threshold, the monthly mean is set to NA. Default is \code{1} (no
#'   additional filtering).
#'
#' @details
#' Daily observations are grouped by calendar month using
#' \code{zoo::as.yearmon()}. The resulting monthly series is represented as a
#' regular base R \code{ts} object with \code{frequency = 12}. Month lengths
#' are not converted to a fixed day count; the calendar index determines month
#' membership. Months with no observations between the first and last
#' observed months are represented explicitly as \code{NA}.
#'
#' The missing-value proportion is calculated from records present within each
#' month. Unobserved calendar days are not counted as missing; incorporating
#' expected daily coverage may be considered in a future version.
#'
#' @return A univariate monthly \code{ts} object with \code{frequency = 12}.
#'
#' @examples
#' \dontrun{
#' sst_zoo <- get_jma_sst_zoo(sea_area_id = 138)
#' sst_ts_monthly <- daily_zoo_to_monthly_ts(sst_zoo)
#' }
#'
#' @importFrom zoo index coredata as.yearmon
#' @importFrom stats ts start aggregate
#'
#' @export
daily_zoo_to_monthly_ts <- function(zoo_obj,
                                    var = "Temp",
                                    na.rm = TRUE,
                                    na_prop_max = 1) {
  ## ---- input check ----------------------------------------------------
  controls <- .prepare_daily_zoo_controls(
    var = var,
    na.rm = na.rm,
    na_prop_max = na_prop_max
  )
  var <- controls$var
  na.rm <- controls$na.rm
  na_prop_max <- controls$na_prop_max

  prepared_data <- .prepare_daily_zoo_data(zoo_obj, var = var)
  selected_zoo <- prepared_data$selected_zoo

  .tempssm_cli_debug(
    "Aggregating daily zoo data to monthly ts (var={var})"
  )

  ## ---- aggregation ----------------------------------------------------
  zoo_monthly <- .aggregate_daily_zoo_monthly(
    selected_zoo = selected_zoo,
    na.rm = na.rm,
    na_prop_max = na_prop_max
  )
  ts_monthly <- .monthly_zoo_to_ts(zoo_monthly, var = var)

  ## ---- inform ---------------------------------------------------------
  .tempssm_cli_inform(
    paste0(
      "Aggregated daily data to monthly series ",
      "with {NROW(ts_monthly)} observation{?s}"
    )
  )

  return(ts_monthly)
}


#' Validate a seasonal time-series frequency
#'
#' @inheritParams compute_monthly_climatology
#'
#' @return An integer scalar giving the validated seasonal frequency.
#'
#' @keywords internal
#' @noRd
.validate_seasonal_ts_frequency <- function(temp_ts) {
  .tempssm_check_univariate_ts(temp_ts, "temp_ts")

  freq <- stats::frequency(temp_ts)
  freq_int <- as.integer(round(freq))

  if (freq <= 1 || abs(freq - freq_int) > sqrt(.Machine$double.eps)) {
    cli::cli_abort(
      "Time series must have an integer frequency greater than 1."
    )
  }

  freq_int
}


#' Compute seasonal climatology (mean seasonal cycle)
#'
#' @param temp_ts Univariate temperature time series of class \code{ts}.
#'   The time series must have an integer frequency greater than 1. For example,
#'   \code{frequency = 12} represents monthly data, \code{frequency = 24}
#'   represents twice-monthly data, and \code{frequency = 4} represents
#'   four seasonal observations per year.
#'
#' @return A tibble with one row per seasonal period containing the
#'   climatological mean temperature. For monthly data, the first column is
#'   named \code{Month} for backward compatibility. For other frequencies,
#'   the first column is named \code{Period}.
#'
#' @importFrom stats cycle
#' @importFrom tibble tibble
#'
#' @encoding UTF-8
#'
#' @examples
#' temp_ts <- ts(
#'   rnorm(12 * 30, mean = 10),
#'   start = c(1981, 1),
#'   frequency = 12
#' )
#'
#' monthly_climatology <- compute_monthly_climatology(temp_ts)
#'
#' @export
compute_monthly_climatology <- function(temp_ts) {
  freq_int <- .validate_seasonal_ts_frequency(temp_ts)

  .tempssm_cli_debug(
    "Computing seasonal climatology for {length(temp_ts)} observations"
  )

  ## ---- compute --------------------------------------------------------
  temp <- as.numeric(temp_ts)
  period <- factor(stats::cycle(temp_ts), levels = seq_len(freq_int))

  seasonal_mean <- tapply(temp, period, mean, na.rm = TRUE)

  ## ---- output ---------------------------------------------------------
  out <- tibble::tibble(
    Period = seq_len(freq_int),
    Temperature = as.numeric(seasonal_mean)
  )

  if (freq_int == 12) {
    names(out)[1] <- "Month"
  }

  .tempssm_cli_debug("Computed climatology for {freq_int} seasonal periods")

  return(out)
}


#' Select a baseline period for temperature anomaly calculation
#'
#' @inheritParams compute_temp_anomaly
#' @param freq_int Integer scalar giving the validated seasonal frequency.
#'
#' @return A univariate \code{ts} object containing the baseline period.
#'
#' @keywords internal
#' @noRd
.select_anomaly_baseline <- function(temp_ts, baseline, freq_int) {
  if (is.null(baseline)) {
    .tempssm_cli_debug("Using full period for climatology")
    return(temp_ts)
  }

  if (!is.numeric(baseline) ||
      is.complex(baseline) ||
      length(baseline) != 2L) {
    cli::cli_abort(
      "{.arg baseline} must be a numeric vector of length 2."
    )
  }

  if (anyNA(baseline)) {
    cli::cli_abort("{.arg baseline} must not contain missing values.")
  }

  if (!all(is.finite(baseline))) {
    cli::cli_abort("{.arg baseline} must contain finite values.")
  }

  if (!all(.tempssm_is_integerish(baseline))) {
    cli::cli_abort("{.arg baseline} must contain whole years.")
  }

  if (baseline[1] > baseline[2]) {
    cli::cli_abort("{.arg baseline} start year must be <= end year.")
  }

  .tempssm_cli_debug(
    "Using baseline period: {baseline[1]}-{baseline[2]}"
  )

  ts_start <- stats::start(temp_ts)[1]
  ts_end <- stats::end(temp_ts)[1]

  if (max(baseline[1], ts_start) > min(baseline[2], ts_end)) {
    cli::cli_abort("No data available in the specified baseline period.")
  }

  ts_base <- stats::window(
    temp_ts,
    start = c(baseline[1], 1),
    end = c(baseline[2], freq_int)
  )

  ts_base
}


#' Compute seasonal temperature anomalies
#'
#' Temperature anomalies are calculated by subtracting a seasonal climatology
#' from each observation. The climatology can be
#' computed either from the full time series or from a user-defined
#' baseline period.
#'
#' @importFrom stats cycle window frequency start
#'
#' @param temp_ts Univariate temperature time series of class \code{ts}.
#'   The time series must have an integer frequency greater than 1. For example,
#'   \code{frequency = 12} represents monthly data, \code{frequency = 24}
#'   represents twice-monthly data, and \code{frequency = 4} represents
#'   four seasonal observations per year.
#'
#' @param baseline Optional numeric vector of length 2 specifying
#'   the reference period for climatology in complete seasonal cycles
#'   (e.g., \code{c(1981, 2010)}). If \code{NULL}, the full period
#'   is used.
#'
#' @details
#' Seasonal climatology is computed using
#' \code{compute_monthly_climatology()}.
#' If \code{baseline} is provided, climatology is estimated using
#' only data within the specified reference period.
#' Missing values are ignored when calculating climatological means.
#'
#' @return A \code{ts} object of seasonal temperature anomalies with the same
#'   \code{start} and \code{frequency} as \code{temp_ts}.
#'
#' @examples
#' temp_ts <- ts(
#'   rnorm(12 * 30, mean = 10),
#'   start = c(1981, 1),
#'   frequency = 12
#' )
#'
#' # Full-period climatology
#' anom_all <- compute_temp_anomaly(temp_ts)
#'
#' # Baseline climatology (1981-2010)
#' anom_base <- compute_temp_anomaly(temp_ts, baseline = c(1981, 2010))
#'
#' @export
compute_temp_anomaly <- function(temp_ts, baseline = NULL) {
  freq_int <- .validate_seasonal_ts_frequency(temp_ts)
  ts_base <- .select_anomaly_baseline(temp_ts, baseline, freq_int)

  ## ---- climatology ----------------------------------------------------
  .tempssm_cli_debug("Computing seasonal climatology")

  clim_tbl <- tempssm::compute_monthly_climatology(ts_base)
  clim_vec <- clim_tbl$Temperature

  clim <- clim_vec[as.integer(stats::cycle(temp_ts))]

  ## ---- anomaly --------------------------------------------------------
  .tempssm_cli_debug("Computing anomalies")

  ts_out <- stats::ts(
    as.numeric(temp_ts) - clim,
    start = stats::start(temp_ts),
    frequency = stats::frequency(temp_ts)
  )

  return(ts_out)
}


#' Get the package user agent string
#'
#' Internal helper returning the user agent used for HTTP requests.
#' If the `tempssm.user_agent` option is set, that value is used;
#' otherwise a package-specific default is returned.
#'
#' @return A length-one character vector.
#'
#' @keywords internal
#' @noRd
.user_agent <- function() {
  getOption(
    "tempssm.user_agent",
    paste0(
      "tempssm/",
      utils::packageVersion("tempssm"),
      " (https://github.com/yourname/tempssm)"
    )
  )
}


#' Parse JMA SST CSV raw data into tidy format
#'
#' Internal helper to parse raw CSV data retrieved from the JMA SST
#' endpoint. The function converts the raw content into a tidy data
#' frame with proper date handling and missing value treatment.
#'
#' @param raw A raw vector containing CSV data.
#'
#' @return A data frame with columns:
#' \describe{
#'   \item{date}{Date object}
#'   \item{Temp}{Numeric temperature (NA for missing values)}
#'   \item{flag}{Original flag column}
#' }
#'
#' @keywords internal
#' @noRd
.parse_jma_csv <- function(raw) {
  sst_raw <- readr::read_csv(
    raw,
    show_col_types = FALSE
  )

  if (nrow(sst_raw) < 2) {
    cli::cli_abort("Retrieved data has unexpected or empty format.")
  }

  ## preserve the existing behavior of dropping the final parsed row.
  sst_tidy <- as.data.frame(sst_raw[-nrow(sst_raw), , drop = FALSE])

  colnames(sst_tidy) <- c(
    "Year", "Month", "Day", "areaNo", "flag", "Temp"
  )

  sst_tidy[["Temp"]] <- as.numeric(sst_tidy[["Temp"]])
  sst_tidy[["date"]] <- as.Date(
    ISOdate(
      year = as.integer(sst_tidy[["Year"]]),
      month = as.integer(sst_tidy[["Month"]]),
      day = as.integer(sst_tidy[["Day"]])
    )
  )
  sst_tidy[["Temp"]][sst_tidy[["Temp"]] <= -999] <- NA_real_

  sst_tidy[, c("date", "Temp", "flag"), drop = FALSE]
}


#' Construct JMA SST endpoint URL
#'
#' Internal helper to generate the HTTP endpoint URL for retrieving
#' JMA sea-surface temperature data based on a sea area ID.
#'
#' @param sea_area_id Character string or numeric JMA sea area ID.
#'
#' @return A character string representing the full URL.
#'
#' @details
#' This function performs only string construction and does not validate
#' the existence or accessibility of the endpoint.
#'
#' @keywords internal
#' @noRd
.build_jma_url <- function(sea_area_id) {
  paste0(
    "https://www.data.jma.go.jp/kaiyou/data/db/kaikyo/series/engan/txt/area",
    sea_area_id,
    ".txt"
  )
}


#' Fetch raw SST data from JMA endpoint
#'
#' Internal helper to perform an HTTP request to the JMA SST endpoint
#' and return the raw response body. This function encapsulates
#' request construction, User-Agent handling, and error management.
#'
#' The returned value is a raw vector intended to be parsed by
#' \code{.parse_jma_csv()}.
#'
#' @param sea_area_id Character string or numeric JMA sea area ID.
#'
#' @return A raw vector containing CSV data retrieved from the endpoint.
#'
#' @details
#' This function is responsible only for data retrieval and does not
#' perform any parsing or validation of the content.
#'
#' @keywords internal
#' @noRd
.fetch_jma_raw <- function(sea_area_id) {
  if (!is.character(sea_area_id)) {
    sea_area_id <- as.character(sea_area_id)
  }

  url <- .build_jma_url(sea_area_id)

  .tempssm_cli_debug("Fetching JMA SST data (area_id={sea_area_id})")

  req <- httr2::request(url)
  req <- httr2::req_user_agent(req, .user_agent())
  req <- httr2::req_error(
    req,
    body = function(resp) {
        paste0(
          "Failed to retrieve SST data for sea_area_id = '",
          sea_area_id,
          "'. HTTP status: ",
          httr2::resp_status(resp)
        )
    }
  )

  resp <- tryCatch(
    httr2::req_perform(req),
    error = function(e) {
      cli::cli_abort(
        "Failed to access JMA SST endpoint: {conditionMessage(e)}"
      )
    }
  )

  .tempssm_cli_debug("HTTP request successful")

  httr2::resp_body_raw(resp)
}


#' Check proportion of missing values and issue warning
#'
#' Internal helper to compute the proportion of missing values in a vector
#' and issue a warning if it exceeds a specified threshold.
#'
#' @param x A numeric vector.
#' @param threshold Numeric threshold for the proportion of missing values.
#'   A warning is triggered if \code{mean(is.na(x))} exceeds this value.
#' @param msg Character string; warning message to display.
#'
#' @return Invisibly returns \code{NULL}. This function is called for its
#'   side effect (issuing a warning).
#'
#' @keywords internal
#' @noRd
.check_na_ratio <- function(x, threshold = 0.3, msg) {
  na_ratio <- mean(is.na(x))

  if (na_ratio > threshold) {
    cli::cli_warn(msg)
  }
}


#' Convert tidy SST data to zoo object
#'
#' Internal helper to construct a \code{zoo} time series object from
#' a tidy data frame containing SST observations. The function maps
#' the \code{Temp} column to values and the \code{date} column to the
#' time index.
#'
#' @param sst_tidy A data frame containing at least two columns:
#'   \code{date} (Date) and \code{Temp} (numeric).
#'
#' @return A \code{zoo} object with a single column named \code{Temp}
#'   indexed by \code{date}.
#'
#' @keywords internal
#' @noRd
.build_sst_zoo <- function(sst_tidy) {
  zoo::zoo(
    x = data.frame(Temp = sst_tidy[["Temp"]]),
    order.by = sst_tidy[["date"]]
  )
}


#' Validate a JMA sea area identifier
#'
#' @inheritParams get_jma_sst_zoo
#'
#' @return The validated sea area identifier unchanged.
#'
#' @keywords internal
#' @noRd
.prepare_jma_sea_area_id <- function(sea_area_id) {
  .tempssm_check_length_one(sea_area_id, "sea_area_id")
  if (!(is.character(sea_area_id) || is.numeric(sea_area_id))) {
    cli::cli_abort(
      "{.arg sea_area_id} must be character or numeric."
    )
  }

  sea_area_id
}


#' Validate the monthly missing-value threshold for JMA SST data
#'
#' @inheritParams get_jma_sst_ts
#'
#' @return The validated threshold unchanged.
#'
#' @keywords internal
#' @noRd
.prepare_jma_na_prop_max <- function(na_prop_max) {
  .tempssm_check_length_one(na_prop_max, "na_prop_max")
  .tempssm_check_numeric(na_prop_max, "na_prop_max")

  if (is.na(na_prop_max) ||
      !is.finite(na_prop_max) ||
      na_prop_max < 0 ||
      na_prop_max > 1) {
    cli::cli_abort(
      "`na_prop_max` must be between 0 and 1 for get_jma_sst_ts()."
    )
  }

  na_prop_max
}


#' Retrieve and prepare daily JMA SST data
#'
#' @inheritParams get_jma_sst_zoo
#'
#' @return A one-column code{zoo} object containing daily SST values.
#'
#' @keywords internal
#' @noRd
.retrieve_jma_sst_zoo <- function(sea_area_id) {
  raw <- .fetch_jma_raw(sea_area_id)
  sst_tidy <- .parse_jma_csv(raw)

  .check_na_ratio(
    sst_tidy$Temp,
    msg = "More than 30% of SST values are missing in retrieved data."
  )

  .build_sst_zoo(sst_tidy)
}


#' Retrieve daily mean sea-surface temperature as a zoo object from JMA
#'
#' This function downloads publicly available daily mean
#' sea-surface temperature (SST) data for Japanese coastal waters
#' provided by the Japan Meteorological Agency (JMA),
#' and returns the data as a \code{zoo} object indexed by date.
#'
#' @importFrom readr read_csv
#' @importFrom httr2 request req_user_agent req_error
#' @importFrom httr2 req_perform resp_body_raw resp_status
#'
#' @param sea_area_id
#' Character or numeric scalar giving the JMA sea area ID
#' (numeric values are accepted and internally coerced to character).
#' For example, 138 corresponding to the coastal sea off southern Ibaraki.
#' A list of sea area IDs and their corresponding regions is available at:
#' \url{https://www.data.jma.go.jp/kaiyou/data/db/kaikyo/series/engan/eg_areano.html}
#'
#' @details
#' The function retrieves a text-format dataset from the JMA website,
#' parses daily observations, and constructs a \code{zoo} object
#' with calendar dates as the index.
#' Missing values in the original dataset are represented as \code{NA}.
#'
#' To comply with good API usage practices, HTTP requests sent by this
#' function include a custom \emph{User-Agent} string identifying the
#' \pkg{tempssm} package. Users may override the default User-Agent by
#' setting the \code{"tempssm.user_agent"} option, for example:
#' \code{options(tempssm.user_agent = "my-analysis/1.0")}.
#'
#' @return
#' A \code{zoo} object of daily mean sea-surface temperature with a
#' \code{Date} index and a single numeric column named \code{Temp}.
#'
#' @examples
#' \dontrun{
#' sst_138_zoo <- get_jma_sst_zoo(sea_area_id = 138)
#' head(sst_138_zoo)
#' }
#'
#' @export
get_jma_sst_zoo <- function(sea_area_id) {
  sea_area_id <- .prepare_jma_sea_area_id(sea_area_id)
  out <- .retrieve_jma_sst_zoo(sea_area_id)

  .tempssm_cli_inform(
    paste0(
      "Retrieved SST data with {NROW(out)} ",
      "observation{?s} for area {sea_area_id}"
    )
  )

  out
}


#' Retrieve daily mean sea-surface temperature as a monthly ts object from JMA
#'
#' This function downloads publicly available daily mean
#' sea-surface temperature (SST) data for Japanese coastal waters
#' provided by the Japan Meteorological Agency (JMA),
#' and returns the monthly average data as a \code{ts} object.
#'
#' @importFrom readr read_csv
#' @importFrom httr2 request req_user_agent req_error
#' @importFrom httr2 req_perform resp_body_raw resp_status
#'
#' @inheritParams get_jma_sst_zoo
#'
#' @param na_prop_max Numeric scalar giving the maximum allowed proportion of
#'   NA values within a month. If the proportion of missing values exceeds this
#'   threshold, the monthly mean is set to NA. Default is \code{1} (no
#'   additional filtering).
#'
#' @details
#' The function retrieves a text-format dataset from the JMA website,
#' using the same retrieval and parsing pathway as \code{get_jma_sst_zoo()}.
#' The daily data are then aggregated by
#' \code{daily_zoo_to_monthly_ts()}. Missing values in the original dataset
#' are represented as \code{NA}.
#'
#' To comply with good API usage practices, HTTP requests sent by this
#' function include a custom \emph{User-Agent} string identifying the
#' \pkg{tempssm} package. Users may override the default User-Agent by
#' setting the \code{"tempssm.user_agent"} option, for example:
#' \code{options(tempssm.user_agent = "my-analysis/1.0")}.
#'
#' @return
#' A univariate monthly \code{ts} object of mean sea-surface temperature, with
#' \code{frequency = 12}.
#'
#' @examples
#' \dontrun{
#' sst_138_ts <- get_jma_sst_ts(sea_area_id = 138)
#' head(sst_138_ts)
#' }
#'
#' @export
get_jma_sst_ts <- function(sea_area_id, na_prop_max = 1) {
  sea_area_id <- .prepare_jma_sea_area_id(sea_area_id)
  na_prop_max <- .prepare_jma_na_prop_max(na_prop_max)
  sst_zoo <- .retrieve_jma_sst_zoo(sea_area_id)

  .tempssm_cli_debug("Aggregating daily data to monthly time series")

  monthly_sst_ts <- tempssm::daily_zoo_to_monthly_ts(
    sst_zoo,
    na_prop_max = na_prop_max
  )

  .tempssm_cli_inform(
    paste0(
      "Retrieved and aggregated SST data to {length(monthly_sst_ts)} ",
      "monthly observation{?s} (area {sea_area_id})"
    )
  )

  monthly_sst_ts
}
