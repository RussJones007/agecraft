# agegroup-print.r
#
# Formatting and display helpers for age_group objects.
# This file contains methods used for rendering age_group values as character and factor-like outputs.

# Changes the interval to print out as typical age groups
#' @exportS3Method
format.age_group <- function(x, ...){
  ch <- as.character.age_group(x)
  ch
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
  multi_ages <- (starts != (ends - 1))
  ret[multi_ages] <- paste0(starts[multi_ages], sep, ends[multi_ages] - 1)

  # use a single age when separator is not needed
  ret[!multi_ages] <- starts[!multi_ages]

  # if any of the mutli age groups starts with zero and the '<' below character is present in symbols, then format the
  # group to use the below symbol and the end of the group to show less than that age.
  zero_present <- (iv_start(groups) <= 0 & 0 < iv_end(groups)) & str_detect(below, "^<")
  any(zero_present)
  if(any(zero_present)) ret[zero_present] <- paste0(below, iv_end(groups[zero_present]))
  rm(zero_present)

  # check for using the above character when any group ends with Inf, then use the above symbol
  inf_present <- (iv_end(groups) == Inf)
  if(any(inf_present)) ret[inf_present] <- paste0(iv_start(groups[inf_present]), above)

  # represent all ages as a single label
  all_present <- iv_start(groups) <= 0 & iv_end(groups) == Inf
  if(any(all_present)) ret[all_present] <- all_ages
  ret
}

#' Coerce age_group to character vector
#'
#' Get a character vector from an age_group object.
#'
#' @param x  an age group object
#' @param sep a separator to use for the age groups.  Default is '-'.  Typically this will come from the age_group object.
#'
#' @return  age groups as a character vector.
#' @exportS3Method base::as.character age_group
as.character.age_group <- function(x, ...){
  syms <- get_symbols(x)
  if(!rlang::is_empty(x)) age_group_to_char(x, sep = syms$sep, above = syms$above, below = syms$below) else character(0)
}

#' Coerce age_group to a nominal factor
#'
#' @return a nominal factor of age groups.
#' @exportS3Method generics::as.factor age_group
#' @examples
#'
#' ag <- as.age_group(c(0, 1, 5, 10, 20, 30, 40, 50))
#' ag
#' ag_fac <- as.factor(ag)
#' ag_fac
#'
#' ag_ord <- as.ordred(ag)
#' ag_ord
#'
as.factor.age_group <- function(x, ...){
  cls <- class(x)
  syms <- get_symbols(x)
  x <- sort(x)
  class(x) <- cls
  attr(x, "symbols") <- syms
  x <- as.character.age_group(x)
  fac <- generics::as.factor(x)
  return(fac)
}

#' Coerce age_group to ordered factor
#'
#' @return an ordinal factor of age groups.
#' @exportS3Method generics::as.ordered age_group
as.ordered.age_group <- function(x, ...){
  cls <- class(x)
  syms <- get_symbols(x)
  x <- sort(x)
  class(x) <- cls
  attr(x, "symbols") <- syms
  x <- as.character.age_group(x)
  fac <- generics::as.ordered(x)
  return(fac)
}
