# agegroup-coerce.r
#
# Coercion infrastructure for age_group objects.
# This file contains vctrs coercion methods plus as.age_group() constructors and related coercion helpers.

# Coercion keeps age units explicit. Different display symbols use canonical labels.
age_group_common_unit <- function(x, y) {
  x_unit <- normalize_age_unit(get_unit(x))
  y_unit <- normalize_age_unit(get_unit(y))
  if (!identical(x_unit, y_unit)) {
    stop("Cannot combine or cast age groups with incompatible units; convert explicitly first", call. = FALSE)
  }
  x_unit
}

#' @exportS3Method vctrs::vec_ptype
vec_ptype.age_group <- function(x, ...) {
  new_age_group(symbols = get_symbols(x), unit = get_unit(x))
}

#' @exportS3Method vctrs::vec_ptype_finalise
vec_ptype_finalise.age_group <- function(x, ...) {
  new_age_group(symbols = get_symbols(x), unit = get_unit(x))
}

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.age_group.age_group <- function(x, y, ...) {
  unit <- age_group_common_unit(x, y)
  symbols <- if (identical(get_symbols(x), get_symbols(y))) get_symbols(x) else
    list(below = "0-", sep = "-", above = "+")
  new_age_group(symbols = symbols, unit = unit)
}

#' @exportS3Method vctrs::vec_cast
vec_cast.age_group.age_group <- function(x, to, ...) {
  age_group_common_unit(x, to)
  new_age_group(ivs::iv_start(x), ivs::iv_end(x), get_symbols(to), unit = get_unit(to))
}

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.age_group.double <- function(x, y, ...) {
  stop("Convert numeric cut points with as.age_group() before combining", call. = FALSE)
}

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.double.age_group <- function(x, y, ...) {
  vec_ptype2.age_group.double(y, x, ...)
}

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.age_group.ivs_iv <- function(x, y, ...) {
  stop("Arguments must have the same class. Convert bare intervals with as.age_group() before combining or calling ivs::iv_set_intersect()", call. = FALSE)
}

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.ivs_iv.age_group <- function(x, y, ...) {
  vec_ptype2.age_group.ivs_iv(y, x, ...)
}

# Explicit casts to bare intervals discard display and unit metadata.
#' @exportS3Method vctrs::vec_cast
vec_cast.ivs_iv.age_group <- function(x, to, ...) {
  ivs::iv(as.double(ivs::iv_start(x)), as.double(ivs::iv_end(x)))
}

#' @exportS3Method vctrs::vec_cast
vec_cast.age_group.ivs_iv <- function(x, to, ...) {
  new_age_group(ivs::iv_start(x), ivs::iv_end(x), get_symbols(to), unit = get_unit(to))
}

#' @exportS3Method base::as.integer age_group
as.integer.age_group <- function(x, ...){
  ret <- iv_start(x) |> trunc()
  if(is.double(ret)) ret <- as.integer(ret)
  ret
}

#' Age groups class
#'
#' Convert integer, double,  character or factor vectors to a "age_group" vector. The "age_group" class represents
#' age ranges as an numeric interval. The is.age_group() function tests whether a variable is an "age_group" vector.
#'
#' @param x for as.age_group() a character, factor, numeric vector or interval vector [ivs::iv()]. Character based age
#'   groups,  like " <5, 5-10, 11-15", must have two two numbers separated by: "-", "to", "thru", or, "through". If x is
#'   numeric vector, each entry is treated as a cut point with each group abutting the previous group. See details
#'   below. For the is.age_group() function, x is an object to test.
#'
#' @param below,sep,above  are scalar strings of valid symbols for age groups. Valid symbols are:
#'  * below: '<'
#'  * sep:   'through , 'thru', 'to', '-'
#'  * above: '>', '+', 'plus'
#' @param unit optional character string identifying the age unit (e.g. "year", "month", "day").
#'
#' @details
#' Combining age_group vectors preserves their class and unit. Units must match
#' (including the presence or absence of units); convert explicitly beforehand.
#' Differing display symbols fall back to canonical 0-, -, and + symbols.
#' For [ivs::iv_set_intersect()], both arguments must have the same class:
#' mixing an age_group with a bare ivs interval is an error in either order.
#' Convert bare intervals with as.age_group() before intersecting; their units
#' must also match the age groups.
#' Casting to a bare ivs interval explicitly discards age metadata.
#' Finite endpoints must be nonnegative numbers; fractional boundaries
#' are preserved without rounding. Numeric cuts must be strictly increasing,
#' with Inf allowed only at the end. A scalar finite cut creates a one-unit
#' interval. Empty input creates an empty vector. Missing character, factor,
#' and interval observations are preserved; numeric cut points cannot be missing.
#' Existing age groups retain metadata unless explicitly overridden. Changing
#' an existing non-NULL unit requires explicit conversion first.
#'
#' The age_group class is based on numeric intervals, specifically the ivs class. An [introduction to
#' ivs](https://davisvaughan.github.io/ivs/articles/ivs.html) intervals explains what they are, notation, and the math
#' that can be done with them. Regarding notation,age groups are presented as "5-10"  to represent all ages beginning
#' with 5 and ending with 10. However, the underneath encoding is a right open interval in this case
#' `[5, 11)` which means including five and all numbers through 10 but not including 11 which is the typical way ages are
#' interpreted.
#'
#' To convert from a character or factor vector to age_group, the strings must be formatted using specific symbols to
#' show the age ranges. Those symbols are '-', ':', to',  'through', or 'thru'. The exception are single ages that are
#' made into an age group of one year.  The as.age_group() function also recognizes the prefix '<' to create a range of
#' ages from 0 up to but not including the given age. For example '< 5' would be all numbers below 5 but not including
#' 5. The Ages grouped above an age are recognized by the use of suffixes; '+', 'plus', 'above', and '>'.  These mean
#' the age stated plus all ages greater are included in the group. So, '80+' would be 80 and all greater ages. Two
#' special key words in the character vector can be used: 'all' and 'total', which are encoded as `[0, Inf)` and means all
#' ages.
#'
#' A numeric vector will be converted to age groups by using each value as a cut point resulting in age groups with no
#' gaps. For example, a c(0,10,20,60,Inf) vector results in age groups: "0-9" "10-19", "20-59" and "60+".
#'
#' All age groups are encoded as right-open intervals. Examples `"< 5"`, `"0-4"`, `"85+"`, and `"14"` are encoded as
#' `[0, 5)`, `[0, 5)`, `[85, Inf)`, and `[14, 15)` respectively. Note that a single year of `"14"` is an age
#' group of one year encoded as an interval `[14, 15)` and is interpreted as all values beginning with 14 and
#' up to but not including 15.
#'
#' @return as.age_group() returns an "age_group" vector with attributes of symbols used for the below, sep, and above
#'   characters.
#'
#' @examples
#'
#' # character vector of age groups
#' char_age_groups <- c("0-5", "6-10", "11-20", "20+")
#'
#' ag <- as.age_group(char_age_groups)
#' ag
#' attributes(ag)
#'
#' # numeric vector of age cut points with 80 plus grouped together
#' num_cuts <- c(0,10,20,40,50,60,70,80,Inf)
#' ag_num <- as.age_group(num_cuts, sep = " to ", above = " plus")
#' ag_num
#'
#' @export
as.age_group <- function(x = double(), below = "0-", sep = "-", above = "+", unit = NULL) {
  UseMethod("as.age_group", x)
}

#' @rdname as.age_group
#' @exportS3Method as.age_group factor
as.age_group.factor <- function(x, below = "0-", sep = "-", above = "+", unit = NULL) {
  as.character(x) |>
    as.age_group.character(below = below, sep = sep, above = above, unit = unit)
}

#' @rdname as.age_group
#' @exportS3Method as.age_group character
as.age_group.character <- function(x, below = "0-", sep = "-", above = "+", unit = NULL) {
  x <- str_trim(x, side = "both") |> str_to_lower()

  grammar <- "^(?:[0-9]+|< *[0-9]+|[0-9]+ *[-] *[0-9]+|[0-9]+ *(?:through|thru|to) *[0-9]+|[0-9]+ *(?:plus|above|>|\\+)|all(?: ages)?|total)$"
  if (any(!is.na(x) & !str_detect(x, grammar))) {
    stop("These age groups in x are malformed: use nonnegative whole numbers and supported symbols", call. = FALSE)
  }
  # check that the correct symbols are present
  valid_syms <- valid_age_group_symbol(x[!is.na(x)])
  if(isFALSE(valid_syms)){
    msg <- paste0('These age groups in x are malformed: "', get_problems(valid_syms), '"')
    stop(msg)
  }
  rm(valid_syms)

  symbols <- list(below = character(),
                  sep = character(),
                  above = character())

  # get the symbols or character strings used in formatting the age group, always choose the first symbol encountered
  get_symbol <- compose(
    ~ if(length(.)) .[1] else NULL,
    stats::na.omit,
    ~ stringr::str_extract(string = x, pattern = .x)
  )

  below_str <- "^(< ?|0 ?-?)"
  symbols$below <- get_symbol(pattern = below_str) %||% below

  separator_str <- " ?(-|to|thru|through) ?"
  symbols$sep <- get_symbol(separator_str) %||% sep

  above_str <- " ?(plus|\\+|>|above)"
  symbols$above <- get_symbol(above_str) %||% above

  # get starts and ends. If special symbols/strings are present then replace them
  starts <- str_extract(x, regex("^(<|\\d{1,7}|all|total)", ignore_case = TRUE)) |>
    str_replace(pattern = regex("(all|total|<|-)", ignore_case = TRUE), replacement = "0") |>
    as.double()
  ends <- str_extract(x, regex("(>|\\d{1,7}|all( ages)?|total|\\+|plus|above)$", ignore_case = TRUE)) |>
    str_replace(pattern = regex("(all( ages)?|total|>|\\+|plus|above)", ignore_case = TRUE), replacement = "Inf") |>
    as.double()

  # check if any NAs exists and throw error with message
  st_ndx <- !is.na(x) & is.na(starts)
  en_ndx <- !is.na(x) & is.na(ends)
  if(any(st_ndx | en_ndx)) {
    ndx <- c(which(st_ndx), which(en_ndx)) |> unique() |> sort()
    err_age_groups <- x[ndx] |> paste(collapse = ", ") |> unique()
    msg <- paste0("Unrecognized groups in x: ", err_age_groups)
    stop(msg)
  }

  inclusive <- !is.na(x) & !str_detect(x, "^<")
  ends[inclusive] <- ends[inclusive] + 1
  ret <- new_age_group(starts, ends, symbols, unit = unit)

  return(ret)
}

# integer vectors cannot include the grouped upper age range as integer cannot include 'Inf'
# this function passes the vector to the as.age_group.double() function.
#' @rdname as.age_group
#' @exportS3Method as.age_group integer
as.age_group.integer <- function(x, below = "0-", sep = "-", above = "+", unit = NULL) {
  x <- as.double(x)
  as.age_group.double(x, below, sep, above, unit = unit)
}

#' @rdname as.age_group
#' @exportS3Method as.age_group double
as.age_group.double <- function(x = double(), below = "0-", sep = "-", above = "+", unit = NULL) {
  if (anyNA(x) || any(x < 0)) {
    stop("Numeric cut points must be nonmissing, nonnegative numbers (or final Inf)", call. = FALSE)
  }
  if (is.unsorted(x, strictly = TRUE)) {
    stop("Numeric cut points must be strictly increasing", call. = FALSE)
  }
  if (length(x) == 1L && is.infinite(x)) {
    stop("Inf requires a finite preceding cut point", call. = FALSE)
  }
  start <- x
  end <- if (length(x)) c(x[-1L], utils::tail(x, 1L) + 1) else double()
  if (length(x) && is.infinite(utils::tail(x, 1L))) {
    start <- utils::head(start, -1L)
    end <- utils::head(end, -1L)
  }

  syms <- list("below" = below, "sep" = sep, "above" = above)

  #check the symbols are valid
  valid_syms <- valid_age_group_symbol(unlist(syms))
  if(isFALSE(valid_syms)){
    msg <- paste0('These age groups in x are malformed: "', get_problems(valid_syms), '"')
    stop(msg)
  }
  rm(valid_syms)

  new_age_group(start = start, end = end, symbols = syms, unit = unit)
}

#' @rdname as.age_group
#' @exportS3Method as.age_group ivs_iv
as.age_group.ivs_iv <- function(x, below = "0-", sep = "-", above = "+", unit = NULL) {
  syms <- list("below" = below, "sep" = sep, "above" = above)
  unit <- unit %||% attr(x, "unit")
  new_age_group(ivs::iv_start(x), ivs::iv_end(x), syms, unit = unit)
}

#' @rdname as.age_group
#' @exportS3Method as.age_group age_group
as.age_group.age_group <- function(x, below = "0-", sep = "-", above = "+", unit = NULL) {
  symbols <- get_symbols(x)
  if (!missing(below)) symbols$below <- below
  if (!missing(sep)) symbols$sep <- sep
  if (!missing(above)) symbols$above <- above
  if (missing(unit)) unit <- get_unit(x)
  if (!identical(normalize_age_unit(unit), get_unit(x)) && !is.null(get_unit(x))) {
    stop("Changing age units requires explicit conversion first", call. = FALSE)
  }
  new_age_group(ivs::iv_start(x), ivs::iv_end(x), symbols, unit)
}
