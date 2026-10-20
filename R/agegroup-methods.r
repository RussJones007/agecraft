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
#' @param convert_units which side to convert when `age` and `age_group` units differ.
#'   One of "age_to_group" (default), "group_to_age", or "none".
#'   Groups without units are interpreted in the units of `age`, when present,
#'   without changing their interval boundaries. Unitless ages with explicitly
#'   unit-bearing groups remain an error.
#' @param allow_approx logical; if FALSE (default), block conversions between fine units
#'   (second/minute/hour/day/week) and coarse units (month/year) because they are approximate.
#'
#' @return An ordered factor identifying each age group, ordered by interval.
#'   Nonblank group names supply labels; missing or blank names fall back to
#'   interval labels. Distinct intervals must have unique resulting labels.
#' @keywords internal
#' @export
#'
#' @examples
#' # categorize each age into an age group
#' ages <- c(0L, 82L, 1L, 1L, 93L, 83L, 76L, 57L, 59L, 67L, 0L, 64L, 60L, 0L)
#' groups <- age_cat_iv(age = ages, age_group = age_group_presets$Yr.10)
#' head(groups, 12)
age_cat_iv <- function(age, age_group,
                       multiple = c("error", "first", "last"),
                       convert_units = c("age_to_group", "group_to_age", "none"),
                       allow_approx = FALSE){
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

normalize_age_unit <- function(x) {
  if(is.null(x) || !length(x)) return(NULL)
  x <- tolower(trimws(as.character(x)[1]))
  if(x %in% c("s", "sec", "secs", "second", "seconds")) return("second")
  if(x %in% c("min", "mins", "minute", "minutes")) return("minute")
  if(x %in% c("h", "hr", "hrs", "hour", "hours")) return("hour")
  if(x %in% c("d", "day", "days")) return("day")
  if(x %in% c("wk", "wks", "week", "weeks")) return("week")
  if(x %in% c("mo", "mos", "month", "months")) return("month")
  if(x %in% c("yr", "yrs", "year", "years")) return("year")
  x
}

age_cat_iv_age_unit <- function(age) {
  if(is.age_group(age) || is_age(age)) return(get_unit(age))
  units_attr <- attr(age, "units")
  if(is.null(units_attr)) return(NULL)
  normalize_age_unit(units_attr[["numerator"]] %||% units_attr)
}

age_cat_iv_convert_values <- function(values, from_unit, to_unit) {
  from_unit <- normalize_age_unit(from_unit)
  to_unit <- normalize_age_unit(to_unit)
  if(identical(from_unit, to_unit)) return(as.numeric(values))
  x <- units::set_units(as.numeric(values), from_unit, mode = "standard")
  x <- units::set_units(x, to_unit, mode = "standard")
  as.numeric(x)
}

age_cat_iv_is_approx_conversion <- function(from_unit, to_unit) {
  fine <- c("second", "minute", "hour", "day", "week")
  coarse <- c("month", "year")
  (from_unit %in% fine && to_unit %in% coarse) ||
    (from_unit %in% coarse && to_unit %in% fine)
}

age_cat_iv_align_units <- function(age, age_group,
                                   convert_units = c("age_to_group", "group_to_age", "none"),
                                   allow_approx = FALSE) {
  convert_units <- match.arg(convert_units)
  age_unit <- age_cat_iv_age_unit(age)
  group_unit <- normalize_age_unit(get_unit(age_group))

  if(is.null(age_unit) && is.null(group_unit)) return(list(age = age, age_group = age_group))
  if(is.null(group_unit)) {
    attr(age_group, "unit") <- age_unit
    return(list(age = age, age_group = age_group))
  }
  if(is.null(age_unit) || is.null(group_unit)) {
    stop('Age and age_group units are not compatible: one has units and the other does not')
  }
  if(identical(age_unit, group_unit)) return(list(age = age, age_group = age_group))

  if(convert_units == "none") {
    stop('Age and age_group units are not compatible')
  }

  from_unit <- if(convert_units == "age_to_group") age_unit else group_unit
  to_unit <- if(convert_units == "age_to_group") group_unit else age_unit
  if(age_cat_iv_is_approx_conversion(from_unit, to_unit) && !isTRUE(allow_approx)) {
    stop('Age and age_group unit conversion is approximate (month/year involved). Set allow_approx = TRUE to proceed')
  }

  if(convert_units == "age_to_group") {
    if(is.age_group(age) || inherits(age, "ivs_iv")) {
      age <- ivs::iv(
        start = age_cat_iv_convert_values(ivs::iv_start(age), age_unit, group_unit),
        end = age_cat_iv_convert_values(ivs::iv_end(age), age_unit, group_unit)
      )
    } else if (is_age(age)) {
      age <- as_age(age, unit = group_unit, allow_approx = allow_approx)
    } else {
      if(!is.null(attr(age, "units"))) {
        age <- units::set_units(age, group_unit, mode = "standard")
      }
    }
  } else {
    haystack <- ivs::iv(
      start = age_cat_iv_convert_values(ivs::iv_start(age_group), group_unit, age_unit),
      end = age_cat_iv_convert_values(ivs::iv_end(age_group), group_unit, age_unit)
    )
  }

  list(age = age, age_group = age_group,
       haystack = if (convert_units == "group_to_age") haystack else age_group)
}

# convert iv locate output to an ordered factor aligned to input needle order.
age_match_indices <- function(locations, n_needles, multiple = c("error", "first", "last")) {
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
  idx
}

age_cat_iv_to_factor <- function(locations, age_group, n_needles, multiple = c("error", "first", "last")) {
  idx <- age_match_indices(locations, n_needles, multiple)
  factor(x = idx,
         levels = seq_along(age_group),
         labels = age_group_labels(age_group),
         ordered = TRUE)
}

#' @exportS3Method
age_cat_iv.default <- function(age, age_group,
                               multiple = c("error", "first", "last"),
                               convert_units = c("age_to_group", "group_to_age", "none"),
                               allow_approx = FALSE){
  stop('Argument: "age" must be numeric or an interval/age_group vector')
}

#' @exportS3Method
age_cat_iv.numeric <- function(age, age_group,
                               multiple = c("error", "first", "last"),
                               convert_units = c("age_to_group", "group_to_age", "none"),
                               allow_approx = FALSE){
  age_group <- age_cat_iv_haystack(age_group)
  aligned <- age_cat_iv_align_units(age = age, age_group = age_group,
                                    convert_units = convert_units, allow_approx = allow_approx)
  age <- aligned$age
  age_group <- aligned$age_group
  locations <- ivs::iv_locate_between(
    needles = as.numeric(age),
    haystack = aligned$haystack %||% age_group
  )
  age_cat_iv_to_factor(locations = locations, age_group = age_group, n_needles = length(age), multiple = multiple)
}

#' @exportS3Method
age_cat_iv.integer <- function(age, age_group,
                               multiple = c("error", "first", "last"),
                               convert_units = c("age_to_group", "group_to_age", "none"),
                               allow_approx = FALSE){
  age_cat_iv.numeric(age = as.numeric(age), age_group = age_group, multiple = multiple,
                     convert_units = convert_units, allow_approx = allow_approx)
}

#' @exportS3Method
age_cat_iv.units <- function(age, age_group,
                             multiple = c("error", "first", "last"),
                             convert_units = c("age_to_group", "group_to_age", "none"),
                             allow_approx = FALSE){
  age_group <- age_cat_iv_haystack(age_group)
  aligned <- age_cat_iv_align_units(age = age, age_group = age_group,
                                    convert_units = convert_units, allow_approx = allow_approx)
  age <- aligned$age
  age_group <- aligned$age_group
  locations <- ivs::iv_locate_between(
    needles = as.numeric(age),
    haystack = aligned$haystack %||% age_group
  )
  age_cat_iv_to_factor(locations = locations, age_group = age_group, n_needles = length(age), multiple = multiple)
}

#' @exportS3Method
age_cat_iv.age_group <- function(age, age_group,
                                 multiple = c("error", "first", "last"),
                                 convert_units = c("age_to_group", "group_to_age", "none"),
                                 allow_approx = FALSE){
  age_group <- age_cat_iv_haystack(age_group)
  aligned <- age_cat_iv_align_units(age = age, age_group = age_group,
                                    convert_units = convert_units, allow_approx = allow_approx)
  age <- aligned$age
  age_group <- aligned$age_group
  # Unit conversion may produce fractional matching boundaries. Use bare
  # intervals internally and retain the original group labels.
  haystack <- aligned$haystack %||% age_group
  locations <- ivs::iv_locate_overlaps(
    needles = ivs::iv(ivs::iv_start(age), ivs::iv_end(age)),
    haystack = ivs::iv(ivs::iv_start(haystack), ivs::iv_end(haystack)),
    type = "within"
  )
  age_cat_iv_to_factor(locations = locations, age_group = age_group, n_needles = length(age), multiple = multiple)
}

#' @exportS3Method
age_cat_iv.ivs_iv <- function(age, age_group,
                              multiple = c("error", "first", "last"),
                              convert_units = c("age_to_group", "group_to_age", "none"),
                              allow_approx = FALSE){
  age_cat_iv.age_group(age = age, age_group = age_group, multiple = multiple,
                       convert_units = convert_units, allow_approx = allow_approx)
}

#' @exportS3Method
age_cat_iv.double <- function(age, age_group,
                              multiple = c("error", "first", "last"),
                              convert_units = c("age_to_group", "group_to_age", "none"),
                              allow_approx = FALSE){
  age_cat_iv.numeric(age = age, age_group = age_group, multiple = multiple,
                     convert_units = convert_units, allow_approx = allow_approx)
}

#' @exportS3Method
age_cat_iv.POSIXct <- function(age, age_group,
                               multiple = c("error", "first", "last"),
                               convert_units = c("age_to_group", "group_to_age", "none"),
                               allow_approx = FALSE){
  stop('Argument: "age" as POSIXct is not supported for age_cat_iv()')
}

#' @exportS3Method
age_cat_iv.Date <- function(age, age_group,
                            multiple = c("error", "first", "last"),
                            convert_units = c("age_to_group", "group_to_age", "none"),
                            allow_approx = FALSE){
  stop('Argument: "age" as Date is not supported for age_cat_iv()')
}

# Classification labels are separate from the interval's character rendering.
age_group_labels <- function(x) {
  labels <- as.character(x)
  supplied <- names(x)
  if (!is.null(supplied)) {
    use <- !is.na(supplied) & nzchar(trimws(supplied)) & !is.na(labels)
    labels[use] <- supplied[use]
  }
  # Repeated observations of the same interval can share a label, but different
  # categories must never collapse silently into a single factor level.
  present <- !is.na(labels)
  definitions <- unique(data.frame(start = ivs::iv_start(x)[present],
                                   end = ivs::iv_end(x)[present], label = labels[present]))
  if (anyDuplicated(definitions$label)) {
    stop("Distinct age groups must have unique factor labels", call. = FALSE)
  }
  labels
}
