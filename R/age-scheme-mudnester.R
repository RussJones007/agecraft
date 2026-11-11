#' Import an optional mudnester age scheme
#'
#' Reads the public `mudnester::age_schemes` dataset without calling private
#' mudnester helpers. The legacy Agecraft registry is unchanged.
#' @param id One exact upstream scheme identifier (without `mudnester_`).
#' @return `import_mudnester_scheme()` returns an ordinary validated
#'   [age_scheme()]. `mudnester_catalogue()` returns a companion data frame with
#'   upstream provenance, `package_version`, `imported_id`, and an `issues`
#'   character-list column. Upstream column types and missing values are retained.
#' @details Numeric breaks, category order and labels are preserved exactly.
#'   Adjacent breaks define right-open intervals. `years` and `days` map to
#'   `year` and `day` without conversion; other units error. Malformed catalogue
#'   schemas, breaks, labels and band counts error rather than being repaired.
#'
#'   Imported IDs start with `mudnester_`. `verified` is always FALSE, organization
#'   and guidance edition (`version`) are unknown (NULL). The package snapshot is
#'   recorded separately in the companion table and scheme notes. `source` and
#'   `reference` use upstream source and source URL, with missing/blank values
#'   represented by NULL in the scheme. Save the companion table alongside a
#'   scheme for reproducibility: it describes the currently installed catalogue,
#'   not a historical lookup for edited or previously imported schemes.
#'
#'   Every import warns that numerical coverage does not establish clinical
#'   applicability or eligibility: catch-all categories can extend outside the
#'   substantive scope and age-only bands can collapse risk-group distinctions.
#'   Additional issues report illustrative definitions, absent source URLs, and
#'   recognized label/boundary discrepancies or approximate neonatal coordinates.
#'   In 0.7.8 these include `covid19_severity_strata`, `unicef_child_bands`, and
#'   `paediatric_developmental`. No labels or coordinates are silently corrected.
#'   These diagnostics are conservative, not an exhaustive guidance audit.
#'   `last_checked`, FALSE `is_illustrative`, and organization-like IDs do not
#'   independently verify guidance. Edit a local copy to create a derivative
#'   using the ordinary scheme replacement/ancestry behavior.
#'
#'   Catalogue definitions: copyright 2026 Nicolas Smoll, Sunshine Coast Hospital
#'   and Health Service; mudnester is MIT licensed. See the installed package's
#'   LICENSE and the upstream repository <https://github.com/nrsmoll/mudnester>.
#' @seealso [age_scheme()], [scheme_groups()], [list_age_schemes()]
#' @examples
#' if (requireNamespace("mudnester", quietly = TRUE)) {
#'   catalogue <- mudnester_catalogue()
#'   s <- suppressWarnings(import_mudnester_scheme("abs_5yr"))
#'   categorize_age(age(c(0, 4.9, 5), unit = "year"), by = s)
#'   catalogue[catalogue$scheme == "abs_5yr", ]
#' }
#' @export
import_mudnester_scheme <- function(id) {
  if (!is.character(id) || length(id) != 1L || is.na(id) || !nzchar(id)) {
    stop("`id` must be one exact mudnester scheme identifier.", call. = FALSE)
  }
  snapshot <- mudnester_snapshot()
  index <- match(id, snapshot$data$scheme)
  if (is.na(index)) {
    stop("Unknown mudnester scheme ID: ", id,
         ". Inspect mudnester_catalogue() for exact identifiers.", call. = FALSE)
  }
  mudnester_convert_row(snapshot$data[index, , drop = FALSE], snapshot$version)
}

#' @rdname import_mudnester_scheme
#' @export
mudnester_catalogue <- function() {
  snapshot <- mudnester_snapshot()
  mudnester_companion(snapshot$data, snapshot$version)
}

mudnester_available <- function() requireNamespace("mudnester", quietly = TRUE)

mudnester_snapshot <- function() {
  if (!mudnester_available()) {
    stop("Install the optional package with install.packages(\"mudnester\") to import its catalogue.",
         call. = FALSE)
  }
  env <- new.env(parent = emptyenv())
  utils::data("age_schemes", package = "mudnester", envir = env)
  if (!exists("age_schemes", envir = env, inherits = FALSE)) {
    stop("Installed mudnester does not provide the public age_schemes dataset.", call. = FALSE)
  }
  data <- get("age_schemes", envir = env, inherits = FALSE)
  mudnester_validate_schema(data)
  list(data = data, version = as.character(utils::packageVersion("mudnester")))
}

mudnester_validate_schema <- function(data) {
  required <- c("scheme", "family", "focus_tags", "source", "source_url",
                "last_checked", "is_illustrative", "breaks", "labels",
                "age_unit", "n_bands")
  fail <- function() stop("Unsupported mudnester catalogue schema; expected public age_schemes columns and types.",
                          call. = FALSE)
  if (!is.data.frame(data) || anyDuplicated(names(data)) ||
      !all(required %in% names(data))) fail()
  for (field in c("scheme", "source", "source_url")) {
    if (!is.character(data[[field]])) fail()
  }
  for (field in c("family", "age_unit")) {
    if (!is.character(data[[field]]) && !is.factor(data[[field]])) fail()
  }
  for (field in c("focus_tags", "breaks", "labels")) {
    if (!is.list(data[[field]])) fail()
  }
  if (!inherits(data$last_checked, "Date") || !is.logical(data$is_illustrative) ||
      !is.numeric(data$n_bands) || anyNA(data$scheme) ||
      any(!nzchar(trimws(data$scheme))) || anyDuplicated(data$scheme) ||
      any(!grepl("^[A-Za-z][A-Za-z0-9_-]*$", data$scheme))) fail()
  invisible(data)
}

mudnester_validate_row <- function(row) {
  mudnester_validate_schema(row)
  if (nrow(row) != 1L) stop("Expected one mudnester catalogue row.", call. = FALSE)
  breaks <- row$breaks[[1L]]
  labels <- row$labels[[1L]]
  if (!is.numeric(breaks) || !is.null(dim(breaks)) || length(breaks) < 2L ||
      anyNA(breaks) || any(breaks < 0) ||
      any(!is.finite(utils::head(breaks, -1L))) || any(diff(breaks) <= 0)) {
    stop("mudnester breaks must be nonmissing, nonnegative and strictly increasing; only the final break may be Inf.",
         call. = FALSE)
  }
  if (!is.character(labels) || !is.null(dim(labels)) ||
      length(labels) != length(breaks) - 1L || anyNA(labels) ||
      any(!nzchar(trimws(labels))) || anyDuplicated(labels)) {
    stop("mudnester labels must be unique, nonblank and match the number of intervals.", call. = FALSE)
  }
  if (is.na(row$n_bands) || !is.finite(row$n_bands) || row$n_bands != length(labels)) {
    stop("mudnester n_bands is inconsistent with breaks and labels.", call. = FALSE)
  }
  if (!as.character(row$age_unit) %in% c("years", "days")) {
    stop("Unsupported mudnester age_unit; only years and days are supported.", call. = FALSE)
  }
  if (!is.character(row$focus_tags[[1L]]) || anyNA(row$focus_tags[[1L]])) {
    stop("mudnester focus_tags must contain character vectors without missing tags.", call. = FALSE)
  }
  invisible(row)
}

mudnester_issues <- function(row) {
  issues <- "Numerical completeness does not establish clinical applicability or eligibility; catch-all categories may exceed substantive scope and age-only bands may collapse risk-group distinctions."
  if (isTRUE(row$is_illustrative)) issues <- c(issues, "Upstream definition is illustrative.")
  if (is.na(row$source_url) || !nzchar(trimws(row$source_url))) {
    issues <- c(issues, "Upstream source URL is missing.")
  }
  if (row$scheme == "covid19_severity_strata" &&
      identical(as.numeric(row$breaks[[1L]]), c(0, 18, 30, 40, 50, 60, 70, 80, Inf)) &&
      any(row$labels[[1L]] %in% c("28-39", "38-49", "48-59", "58-69", "68-79"))) {
    issues <- c(issues, "Known COVID-19 labels disagree with numeric boundaries; imported unchanged.")
  }
  if (row$scheme == "unicef_child_bands" &&
      identical(as.numeric(row$breaks[[1L]][1:2]), c(0, 1)) && row$labels[[1L]][1L] == "0-1") {
    issues <- c(issues, "UNICEF label '0-1' describes numeric [0,1); imported unchanged.")
  }
  if (row$scheme == "paediatric_developmental" &&
      as.character(row$age_unit) == "years" && any(abs(row$breaks[[1L]] - 28 / 365.25) < 1e-12)) {
    issues <- c(issues, "Neonatal boundary is approximately 28/365.25 years, not exact elapsed days; imported unchanged.")
  }
  issues
}

mudnester_companion <- function(data, package_version) {
  mudnester_validate_schema(data)
  issues <- lapply(seq_len(nrow(data)), function(i) {
    row <- data[i, , drop = FALSE]
    mudnester_validate_row(row)
    mudnester_issues(row)
  })
  fields <- c("scheme", "family", "focus_tags", "source", "source_url",
              "last_checked", "is_illustrative")
  out <- as.data.frame(data[fields])
  out$package_version <- rep(package_version, nrow(out))
  out$imported_id <- paste0("mudnester_", data$scheme)
  out$issues <- issues
  out
}

mudnester_convert_row <- function(row, package_version, warn = TRUE) {
  mudnester_validate_row(row)
  breaks <- row$breaks[[1L]]
  unit <- c(years = "year", days = "day")[[as.character(row$age_unit)]]
  groups <- age_group(utils::head(breaks, -1L), utils::tail(breaks, -1L), unit = unit)
  names(groups) <- row$labels[[1L]]
  optional <- function(x) if (is.na(x) || !nzchar(trimws(x))) NULL else x
  issues <- mudnester_issues(row)
  scheme <- age_scheme(
    groups, id = paste0("mudnester_", row$scheme), name = row$scheme,
    type = "partition", domain = c(0, Inf),
    complete = breaks[1L] == 0 && utils::tail(breaks, 1L) == Inf,
    source = optional(row$source), reference = optional(row$source_url),
    verified = FALSE,
    notes = paste0("Imported from mudnester package snapshot ", package_version,
                   "; external guidance edition unknown. Catalogue copyright 2026 Nicolas Smoll, Sunshine Coast Hospital and Health Service (MIT). ",
                   paste(issues, collapse = " "))
  )
  if (warn) warning(paste(issues, collapse = " "), call. = FALSE)
  scheme
}
