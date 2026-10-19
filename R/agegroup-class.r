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
get_unit <- purrr::attr_getter("unit")

#' Create an interval age_group
#'
#' Creates validated, right-open age intervals. Finite endpoints must be
#' nonnegative whole numbers; endpoints are stored as doubles so that Inf can
#' represent an open-ended upper age group, such as [85, Inf).
#'
#' @param start,end Nonnegative whole-number endpoints, stored as doubles.
#'   `start` determines the interval count; a scalar `end` is recycled.
#'   Only `end` may be Inf. Missing intervals have both endpoints missing.
#' @param unit Optional age unit, such as year or day.
#' @param symbols is a list of three with symbols for: separator, below, and above
#'
#' @return an age_group object represented as intervals. The attribute "symbols" is set and is used to format the
#' age_group when printed.
#' @keywords internal
new_age_group <- function(start = double(),
                          end = double(),
                          symbols = list(below = "0-", sep = "-", above = "+"),
                          unit = NULL){
  start <- vctrs::vec_cast(start, double())
  end <- vctrs::vec_cast(end, double())
  end <- vctrs::vec_recycle(end, length(start))
  if (!is.list(symbols) || length(symbols) != 3L ||
      !setequal(names(symbols), c("below", "sep", "above")) ||
      !all(vapply(symbols, function(x) is.character(x) && length(x) == 1L && !is.na(x), logical(1)))) {
    stop("`symbols` must contain scalar strings named below, sep, and above", call. = FALSE)
  }
  if (!is.null(unit) && (!is.character(unit) || length(unit) != 1L || is.na(unit) || !nzchar(trimws(unit)))) {
    stop("`unit` must be NULL or a nonempty scalar string", call. = FALSE)
  }
  if (any(xor(is.na(start), is.na(end)))) {
    stop("Missing intervals must have both endpoints missing", call. = FALSE)
  }
  present <- !is.na(start)
  if (any(!is.finite(start[present]) | start[present] < 0) ||
      any(end[present] == -Inf | end[present] < 0)) {
    stop("Age endpoints must be nonnegative; only `end` may be Inf", call. = FALSE)
  }
  finite_end <- end[is.finite(end)]
  if (any(start[present] != trunc(start[present])) || any(finite_end != trunc(finite_end))) {
    stop("Age endpoints must be whole numbers", call. = FALSE)
  }
  if (any(start[present] >= end[present])) {
    stop("Each interval must have start < end", call. = FALSE)
  }
  ivs::new_iv(start, end, class = "age_group", symbols = symbols,
              unit = normalize_age_unit(unit))
}

#' @returns is.age_group returns either TRUE or FALSE
#' @rdname as.age_group
#'
#' @export
is.age_group <- function(x){ inherits(x, "age_group")}

#' @keywords internal
#' @exportS3Method vctrs::vec_ptype_abbr
vec_ptype_abbr.age_group <- function(x, ...){"aGrp"}

#' @keywords internal
#' @exportS3Method vctrs::vec_ptype_full
vec_ptype_full.age_group <- function(x, ...) {
  unit <- get_unit(x)
  if (is.null(unit)) "age_group" else paste0("age_group<", unit, ">")
}

# functions for restoring attributes -------------------------------------------------------------------------------

#' @keywords internal
#' @exportS3Method vctrs::vec_restore
vec_restore.age_group <- function(x, to, ...){
  # restore the age_group object
  ret <- new_age_group(start = field(x, "start"), end = field(x, "end"), symbols = get_symbols(to), unit = get_unit(to))
  return(ret)
}

#' @keywords internal
#' @exportS3Method ivs::iv_restore
iv_restore.age_group <- function(x, to, ...){
  ret <- new_age_group(start = field(x, "start"), end = field(x, "end"), symbols = get_symbols(to), unit = get_unit(to))
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
#' @examples
#' valid_age_group_symbol(c("< 5", "5-9", "10+"))
valid_age_group_symbol <- function(x){
  symbol_regex <- regex("(through|thru|total|to|-|<|>|\\+|all|plus|above|,)", ignore_case = TRUE)
  invalid <- stringr::str_remove_all(x, symbol_regex) |> stringr::str_trim()
  malformed <- !(str_detect(x, symbol_regex) | str_detect(x, "^[:digit:]{1,3}$")) | str_detect(invalid, "[:alpha:]")

  malformed <- is.na(x) | malformed
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
