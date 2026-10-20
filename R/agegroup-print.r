# agegroup-print.r
#
# Formatting and display helpers for age_group objects.
# This file contains methods used for rendering age_group values as character and factor-like outputs.

# Changes the interval to print out as typical age groups
#' @exportS3Method
format.age_group <- function(x, ...){
  ch <- as.character.age_group(x)
  unit <- get_unit(x)
  if(!is.null(unit)) ch[!is.na(ch)] <- paste0(ch[!is.na(ch)], " [", unit, "]")
  ch
}

#' @exportS3Method
print.age_group <- function(x, ...){
  out <- format.age_group(x, ...)
  print(out, quote = FALSE)
  invisible(x)
}

# Function from iv age to character age groups ---------------------------------------------------------------
#' Age group into a character vector
#'
#' This is the reverse of as.age_group().  Function arguments determine the format
#' of the decoded character age group. For the encoding scheme see [as.age_group()] details section.
#'
#' @param groups is an iv vector
#' @param sep defaults to " - ", but may be "to", "through", and "thru"
#' @param above defaults to " +" as suffix but may be set to " >"
#' @param below defaults to "0" as in 0-4, can be "< " or "less than" for different way to express the 0 - age group.
#' @param all_ages defaults to "all", but may be set to "total"
#' @keywords internal
#' @export
age_group_to_char <- function(groups, sep = get_symbols(groups)[["sep"]] %||% "-",
                              above = get_symbols(groups)[["above"]] %||% " +",
                              below = get_symbols(groups)[["below"]] %||% "0",
                              all_ages = "All") {
  sep = sep %||% get_symbols(groups)[["sep"]] %||% "-"
  above = above %||% get_symbols(groups)[["above"]] %||% " +"
  below = below %||% get_symbols(groups)[["below"]] %||% "0"
  all_ages = all_ages %||% "All"

  starts <- ivs::iv_start(groups)
  ends <- ivs::iv_end(groups)

  # format the regular character vector with separators for multiple ages covered and single numbers if only one age covered
  ret <- character(length = length(groups)) # ret is the vector to return

  # use a separator for multi-ages is TRUE
  missing <- is.na(starts) | is.na(ends)
  multi_ages <- !missing & (starts != (ends - 1))
  ret[multi_ages] <- paste0(starts[multi_ages], sep, ends[multi_ages] - 1)

  # Fractional bounds use explicit right-open notation, never end minus one.
  fractional <- !missing & (starts != trunc(starts) | (is.finite(ends) & ends != trunc(ends)))
  ret[fractional] <- paste0("[", starts[fractional], ", ", ends[fractional], ")")

  # use a single age when separator is not needed
  single <- !missing & !multi_ages & !fractional
  ret[single] <- starts[single]

  # if any of the mutli age groups starts with zero and the '<' below character is present in symbols, then format the
  # group to use the below symbol and the end of the group to show less than that age.
  zero_present <- !missing & !fractional & (starts <= 0 & 0 < ends) & str_detect(below, "^<")
  if(any(zero_present)) ret[zero_present] <- paste0(below, iv_end(groups[zero_present]))
  rm(zero_present)

  # check for using the above character when any group ends with Inf, then use the above symbol
  inf_present <- !missing & !fractional & (ends == Inf)
  if(any(inf_present)) ret[inf_present] <- paste0(iv_start(groups[inf_present]), above)

  # represent all ages as a single label
  all_present <- !missing & starts <= 0 & ends == Inf
  if(any(all_present)) ret[all_present] <- all_ages
  ret[missing] <- NA_character_
  ret
}

#' Coerce age_group to character vector
#'
#' Get a character vector from an age_group object.
#'
#' @param x  an age group object
#' @param ... Reserved for future extensions; currently ignored.
#'
#' @return  age groups as a character vector.
#' @exportS3Method base::as.character age_group
as.character.age_group <- function(x, ...){
  syms <- get_symbols(x)
  if(!rlang::is_empty(x)) age_group_to_char(x, sep = syms$sep, above = syms$above, below = syms$below) else character(0)
}

#' Coerce age_group to a nominal factor
#'
#' @param x An age_group vector.
#' @param ... Reserved for future extensions; currently ignored.
#' @return A nominal factor using nonblank group names, otherwise interval labels.
#'   Levels follow interval order; distinct intervals require unique labels.
#' @exportS3Method generics::as.factor age_group
#' @examples
#'
#' ag <- as.age_group(c(0, 1, 5, 10, 20, 30, 40, 50))
#' ag
#' ag_fac <- generics::as.factor(ag)
#' ag_fac
#'
#' ag_ord <- generics::as.ordered(ag)
#' ag_ord
#'
as.factor.age_group <- function(x, ...) {
  factor(age_group_labels(x), levels = unique(age_group_labels(sort(x))))
}

#' Coerce age_group to ordered factor
#'
#' @param x An age_group vector.
#' @param ... Reserved for future extensions; currently ignored.
#' @return An ordinal factor using nonblank group names, otherwise interval labels.
#'   Levels follow interval order; distinct intervals require unique labels.
#' @exportS3Method generics::as.ordered age_group
as.ordered.age_group <- function(x, ...) {
  factor(age_group_labels(x), levels = unique(age_group_labels(sort(x))), ordered = TRUE)
}
