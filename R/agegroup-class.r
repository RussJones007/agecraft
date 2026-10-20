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
#' nonnegative numbers; endpoints are stored as doubles so that Inf can
#' represent an open-ended upper age group, such as [85, Inf).
#'
#' @param start,end Nonnegative numeric endpoints, stored as doubles.
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
  labels <- x[[".group_names"]]
  if (!is.null(labels) && any(x[[".group_named"]], na.rm = TRUE)) attr(ret, "group_names") <- labels
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

#' Construct age groups directly from bounds
#'
#' Each interval includes start and excludes end. For example, bounds 1 and 5
#' represent completed ages 1-4. Gaps and overlaps are preserved.
#' @param start,end Nonnegative numeric endpoints. A scalar end is recycled
#'   to the length of start. Only end may be Inf. Missing pairs require two NAs.
#' @param unit Optional time unit, such as "year" or "day".
#' @param below,sep,above Display symbols, as in [as.age_group()].
#' @details
#' Fractional bounds are preserved. Intervals with fractional endpoints display
#' as `[start, end)`; whole-number bounds retain completed-age labels such as 1-4.
#' Assign category labels with `names(x) <- labels`. Classification and factor
#' coercion use nonblank names, falling back to interval labels for missing or
#' blank names. Distinct intervals must have unique resulting factor labels.
#' Names follow observations through slicing, sorting, concatenation and casts;
#' interval set operations discard names because they can create new intervals.
#' Names do not change interval equality or ordering.
#' @return An age_group interval vector.
#' @export
#' @examples
#' age_group(c(1, 10), c(5, Inf), unit = "year")
#' groups <- age_group(c(0, 0.077, 1), c(0.077, 1, 3), unit = "year")
#' names(groups) <- c("Neonate", "Infant", "Toddler")
#' categorize_age(units::set_units(c(0.02, 0.5, 2), "year"), by = groups)
age_group <- function(start = double(), end = double(), unit = NULL,
                      below = "0-", sep = "-", above = "+") {
  new_age_group(start, end, symbols = list(below = below, sep = sep, above = above),
                unit = unit)
}

# Record vectors cannot use the physical names attribute: it identifies fields.
# Expose observation names through names(), and carry them in the slicing proxy.
#' @exportS3Method base::names age_group
names.age_group <- function(x) attr(x, "group_names")

#' @exportS3Method base::`names<-` age_group
`names<-.age_group` <- function(x, value) {
  if (!is.null(value)) {
    value <- as.character(value)
    if (length(value) > length(x)) stop("Too many group names", call. = FALSE)
    length(value) <- length(x)
  }
  attr(x, "group_names") <- value
  x
}

#' @exportS3Method vctrs::vec_proxy
vec_proxy.age_group <- function(x, ...) {
  fields <- unclass(x)
  vctrs::new_data_frame(list(start = fields[["start"]], end = fields[["end"]],
                            .group_names = names(x) %||% rep(NA_character_, length(fields[["start"]])),
                            .group_named = rep(!is.null(names(x)), length(fields[["start"]]))))
}

# Names describe observations, not interval identity or chronological order.
#' @exportS3Method vctrs::vec_proxy_equal
vec_proxy_equal.age_group <- function(x, ...) {
  fields <- unclass(x)
  vctrs::new_data_frame(list(start = fields[["start"]], end = fields[["end"]]))
}

#' @exportS3Method vctrs::vec_proxy_compare
vec_proxy_compare.age_group <- function(x, ...) vec_proxy_equal.age_group(x)
