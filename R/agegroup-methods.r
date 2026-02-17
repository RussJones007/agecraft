# agegroup-methods.r
#
# Core age_group relationship methods.
# This file contains interval-matching APIs that assign ages or age intervals into age groups.

#' Categorize age to age group
#'
#' Uses [ivs::iv] to categorize into interval age groups.
#'
#' @param age_group a integer, or numeric vector that can be represented as age groups. Integer and numeric
#' vectors are internally converted to intervals as an age_group vector.
#' @param age a integer or numeric
#' @param multiple how to handle a single age matching multiple age groups.
#'   One of "error" (default), "first", or "last".
#'
#' @return an ordered factor with where each age is in an age_group.
#' @keywords internal
#' @export
#'
#' @examples
#' # categorize each age into an age group
#' ages <- c(0L, 82L, 1L, 1L, 93L, 83L, 76L, 57L, 59L, 67L, 0L, 64L, 60L, 0L)
#' groups <- age_cat_iv(age = ages, age_group = age.groups$Yr.10)
#' head(groups, 12)
age_cat_iv <- function(age, age_group, multiple = c("error", "first", "last")){
  UseMethod("age_cat_iv")
}

# normalize and validate age_group input. Numeric vectors are treated as cut points.
age_cat_iv_haystack <- function(age_group) {
  if(is.numeric(age_group)) age_group <- as.age_group(age_group)
  if(!is.age_group(age_group)) {
    stop('Argument: "age_group" must be numeric cut points or an age_group vector')
  }
  sort(age_group)
}

age_cat_iv_age_unit <- function(age) {
  if(is.age_group(age)) return(get_unit(age))
  units_attr <- attr(age, "units")
  if(is.null(units_attr)) return(NULL)
  as.character(units_attr[["numerator"]] %||% units_attr)
}

age_cat_iv_validate_units <- function(age, age_group) {
  age_unit <- age_cat_iv_age_unit(age)
  group_unit <- get_unit(age_group)

  if(is.null(age_unit) && is.null(group_unit)) return(invisible(NULL))
  if(is.null(age_unit) || is.null(group_unit)) {
    stop('Age and age_group units are not compatible: one has units and the other does not')
  }
  if(!identical(age_unit, group_unit)) {
    stop('Age and age_group units are not compatible')
  }
  invisible(NULL)
}

# convert iv locate output to an ordered factor aligned to input needle order.
age_cat_iv_to_factor <- function(locations, age_group, n_needles, multiple = c("error", "first", "last")) {
  multiple <- match.arg(multiple)

  if(anyDuplicated(locations$needles)) {
    if(multiple == "error") {
      stop('Age groups passed in the age argument match more than one group in the age_group argument')
    }

    locations <- locations[order(locations$needles, locations$haystack), , drop = FALSE]
    if(multiple == "first") {
      locations <- locations[!duplicated(locations$needles), , drop = FALSE]
    } else {
      locations <- locations[!duplicated(locations$needles, fromLast = TRUE), , drop = FALSE]
    }
  }

  idx <- rep.int(NA_integer_, n_needles)
  idx[locations$needles] <- locations$haystack
  factor(x = idx,
         levels = seq_along(age_group),
         labels = as.character(age_group),
         ordered = TRUE)
}

#' @exportS3Method
age_cat_iv.default <- function(age, age_group, multiple = c("error", "first", "last")){
  stop('Argument: "age" must be numeric or an interval/age_group vector')
}

#' @exportS3Method
age_cat_iv.numeric <- function(age, age_group, multiple = c("error", "first", "last")){
  age_group <- age_cat_iv_haystack(age_group)
  age_cat_iv_validate_units(age = age, age_group = age_group)
  locations <- ivs::iv_locate_between(
    needles = as.numeric(age),
    haystack = age_group
  )
  age_cat_iv_to_factor(locations = locations, age_group = age_group, n_needles = length(age), multiple = multiple)
}

#' @exportS3Method
age_cat_iv.integer <- function(age, age_group, multiple = c("error", "first", "last")){
  age_cat_iv.numeric(age = as.numeric(age), age_group = age_group, multiple = multiple)
}

#' @exportS3Method
age_cat_iv.units <- function(age, age_group, multiple = c("error", "first", "last")){
  age_group <- age_cat_iv_haystack(age_group)
  age_cat_iv_validate_units(age = age, age_group = age_group)
  locations <- ivs::iv_locate_between(
    needles = as.numeric(age),
    haystack = age_group
  )
  age_cat_iv_to_factor(locations = locations, age_group = age_group, n_needles = length(age), multiple = multiple)
}

#' @exportS3Method
age_cat_iv.age_group <- function(age, age_group, multiple = c("error", "first", "last")){
  age_group <- age_cat_iv_haystack(age_group)
  age_cat_iv_validate_units(age = age, age_group = age_group)
  locations <- ivs::iv_locate_overlaps(
    needles = age,
    haystack = age_group,
    type = "within"
  )
  age_cat_iv_to_factor(locations = locations, age_group = age_group, n_needles = length(age), multiple = multiple)
}

#' @exportS3Method
age_cat_iv.ivs_iv <- function(age, age_group, multiple = c("error", "first", "last")){
  age_cat_iv.age_group(age = age, age_group = age_group, multiple = multiple)
}

#' @exportS3Method
age_cat_iv.double <- function(age, age_group, multiple = c("error", "first", "last")){
  age_cat_iv.numeric(age = age, age_group = age_group, multiple = multiple)
}

#' @exportS3Method
age_cat_iv.POSIXct <- function(age, age_group, multiple = c("error", "first", "last")){
  stop('Argument: "age" as POSIXct is not supported for age_cat_iv()')
}

#' @exportS3Method
age_cat_iv.Date <- function(age, age_group, multiple = c("error", "first", "last")){
  stop('Argument: "age" as Date is not supported for age_cat_iv()')
}
