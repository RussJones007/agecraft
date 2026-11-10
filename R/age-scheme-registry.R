#' Discover legacy age schemes
#'
#' @param id Exact registry identifier from `list_age_schemes()`.
#' @return `list_age_schemes()` returns a data frame with registry identifiers,
#'   names, legacy preset keys, type, unit, source/version, verification flag,
#'   purpose, and reference. `get_age_scheme()` returns a validated `age_scheme`.
#' @details The eight built-ins preserve the historical cut points of
#'   [age_group_presets]. They use explicit year units; classify unit-bearing
#'   ages, such as `age(x, unit = "year")`, rather than silently treating plain
#'   numbers as years. The original numeric presets and `age.groups` alias are
#'   unchanged. Several source editions are unknown. These definitions are
#'   legacy reporting conventions, not verified current clinical guidance.
#'
#'   Registry IDs are stable and prefixed `legacy_`. `version` records the
#'   package snapshot of the legacy definition, not an authoritative source
#'   edition. See the installed `extdata/age-group-provenance.csv` table for
#'   source uncertainty. Each lookup constructs an independent scheme.
#' @seealso [age_scheme()], [classify_age_scheme()]
#' @examples
#' list_age_schemes()
#' s <- get_age_scheme("legacy_ili")
#' categorize_age(age(c(2, 15, 70), unit = "year"), by = s)
#' @name age_scheme_registry
NULL

#' @rdname age_scheme_registry
#' @export
list_age_schemes <- function() {
  info <- age_scheme_registry_info()
  data.frame(id = info$id, name = info$name, preset = info$definition,
             type = "partition", unit = "year", source = info$source,
             version = info$package_snapshot, verified = FALSE,
             purpose = info$intended_use,
             reference = "agecraft: extdata/age-group-provenance.csv",
             stringsAsFactors = FALSE)
}

#' @rdname age_scheme_registry
#' @export
get_age_scheme <- function(id) {
  info <- age_scheme_registry_info()
  if (!is.character(id) || length(id) != 1L || is.na(id) || !id %in% info$id) {
    stop("Unknown scheme id; use list_age_schemes() for available identifiers", call. = FALSE)
  }
  row <- info[match(id, info$id), , drop = FALSE]
  presets <- new.env(parent = emptyenv())
  utils::data("age_group_presets", package = "agecraft", envir = presets)
  cuts <- presets$age_group_presets[[row$definition]]
  # Adjacent cuts match categorize_age(), including its finite-terminal rule.
  g <- age_group(utils::head(cuts, -1L), utils::tail(cuts, -1L), unit = "year")
  names(g) <- as.character(g)
  age_scheme(g, id = id, name = row$name, type = "partition",
             domain = c(cuts[1], cuts[length(cuts)]), complete = TRUE,
             purpose = row$intended_use, source = row$source,
             reference = "agecraft: extdata/age-group-provenance.csv",
             version = row$package_snapshot, verified = FALSE,
             notes = paste("Legacy definition; external source edition:",
                           row$source_version_date))
}

age_scheme_registry_info <- function() {
  info <- utils::read.csv(system.file("extdata", "age-group-provenance.csv",
                                      package = "agecraft"), stringsAsFactors = FALSE)
  keys <- c("ILI", "IMM", "Yr.5", "Yr.10", "Spec", "Annual", "School", "Covid")
  info <- info[match(keys, info$definition), , drop = FALSE]
  info$id <- c("legacy_ili", "legacy_imm", "legacy_yr_5", "legacy_yr_10",
               "legacy_spec", "legacy_annual", "legacy_school", "legacy_covid")
  info$name <- c("Legacy influenza-like-illness bands", "Legacy immunization bands",
                 "Legacy five-year reporting bands", "Legacy ten-year reporting bands",
                 "Legacy special reporting bands", "Legacy annual-report bands",
                 "Legacy school reporting bands", "Legacy COVID-19 reporting bands")
  info
}
