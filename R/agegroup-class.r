# agegroup-class.r
#
# Class definition and infrastructure for age_group vectors.
# This file contains constructors, validators, and vctrs/ivs class restoration methods.

# age_group utility functions -------------------------------------------------------------------------------
# convenience functions used internally to get attributes under the symbol attribute from age_group objects.
# Used internally, not exported to the package namespace

get_symbols_attr <- attr_getter(attr = "symbols")

get_below <- compose(
  ~pluck(., "below"),
  get_symbols_attr
)

get_separator <- compose(
  ~pluck(., "sep"),
  get_symbols_attr
)

get_above <- compose(
  ~pluck(., "above"),
  get_symbols_attr
)

get_all <- compose(
  ~pluck(., "all"),
  get_symbols_attr
)

# internal convenience function to get the attribute 'symbols' list from an age_group object
get_symbols <- purrr::attr_getter("symbols")

#' Create an interval age_group
#'
#' Creates an vector of age_group with minimal checking.  Other functions call this constructor where proper validation
#' occurs. All ages can be represented as "group" of ages.  For example 4 years old is easily represented as '[4,5)'.
#'
#' @details
#' Double vectors are used.  Integers were originally used as they are smaller and the idea that the ends and starts
#' would always be integer types.  However integer is not consistent with the concept of an interval which encompasses
#' all real numbers beginning with 'start' up to but not including 'end'.  Another very important reason to use use
#' double instead of integer is the 'Inf' is supported in doubles but not integers.  Age groups that include an age and
#' above are encoded as a right open interval using   'Inf'. For  example '85 +' is encoded as an interval like so '[85,
#' Inf)'
#'
#' @param start,end are double vectors of the same length.
#' @param symbols is a list of three with symbols for: separator, below, and above
#'
#' @return an age_group object represented as intervals. The attribute "symbols" is set and is used to format the
#' age_group when printed.
#' @keywords internal
new_age_group <- function(start = NULL,
                          end = NULL,
                          symbols = list(below = "0-", sep = "-", above = "+")){
  if(is.null(start) & is.null(end)) return(ivs::new_iv(start, end, class = "age_group", symbols = symbols) )
  assert_that(is.double(start))
  assert_that(is.double(end))
  assert_that(rlang::is_list(symbols) & (length(symbols) == 3))

  ret <- ivs::new_iv(start, end, class = "age_group", symbols = symbols)

  return(ret)
}

#' @returns is.age_group returns either TRUE or FALSE
#' @rdname as.age_group
#'
#' @export
is.age_group <- function(x){ inherits(x, "age_group")}

#' @keywords internal
#' @export
vec_ptype_abbr.age_group <- function(x, ...){"aGrp"}

#' @keywords internal
#' @export
vec_ptype_full.age_group <- function(x, ...) "age_group"

# functions for restoring attributes -------------------------------------------------------------------------------

#' @keywords internal
#' @exportS3Method vctrs::vec_restore
vec_restore.age_group <- function(x, to, ...){
  # restore the age_group object
  ret <- new_age_group(start = field(x, "start"), end = field(x, "end"), symbols = get_symbols(to))
  return(ret)
}

#' @keywords internal
#' @exportS3Method ivs::iv_restore
iv_restore.age_group <- function(x, to, ...){
  ret <- new_age_group(start = field(x, "start"), end = field(x, "end"), symbols = get_symbols(to))
  return(ret)
}

# internal convenience function to get the "problems" attribute character when checking for valid symbols
get_problems <- purrr::attr_getter("problems")
# internal function to get the locations of invalid entries in character string of age groups.
get_locations <- purrr::attr_getter(("locations"))

#' Check for Valid Symbols
#'
#' For a character vector representing age groups, are all of the non-digit symbols valid for an age_group object.
#' Certain symbols are considered valid for the below, sep, and above symbols
#'
#' @param x a character vector representing age groups, like "< 5", "1-4", "85 +"
#'
#' @return TRUE/FALSE
#' @export
#' @noRd
#' @examples
#' #todo
valid_age_group_symbol <- function(x){
  symbol_regex <- regex("(through|thru|total|to|-|<|>|\\+|all|plus|above|,)", ignore_case = TRUE)
  invalid <- stringr::str_remove_all(x, symbol_regex) |> stringr::str_trim()
  malformed <- !(str_detect(x, symbol_regex) | str_detect(x, "^[:digit:]{1,3}$")) | str_detect(invalid, "[:alpha:]")

  if(any(malformed)){
    prob_ndx <- which(malformed)

    ret <- FALSE
    attr(ret, "problems") <- x[prob_ndx]
    attr(ret, "locations") <- prob_ndx
  } else {
    ret <- TRUE
    attr(ret, "problems") <- NULL
    attr(ret, "locations") <- NULL
  }
  return(ret)
}
