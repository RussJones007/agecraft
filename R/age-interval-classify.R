# age-interval-classify.R
#
# Core age_interval relationship methods.
# Match ages and observed age intervals to reporting categories.

#' Match ages to interval-defined categories
#'
#' Assign each observation to a category defined by age intervals. Numerical
#' ages match the interval containing their value; observed intervals must fit
#' entirely inside a category. Use [categorize_age()] for an interface that
#' also accepts age schemes and retains category definitions in its output.
#'
#' @param intervals An `age_interval` vector or an integer or double vector of
#'   cut points accepted by [as_age_interval()]. Intervals are sorted before
#'   matching. Each includes its lower bound and excludes its upper bound.
#' @param age An integer, numeric, `age`, `units`, or interval vector. A `units`
#'   observation must have a supported simple time unit (second, minute, hour,
#'   day, week, month or year, including supported aliases). The complete unit
#'   expression is checked before conversion or matching: compound, squared,
#'   inverse, dimensionless and non-time quantities are rejected even when empty
#'   or missing. Plain numeric ages can match unitless intervals; explicitly
#'   unit-bearing intervals require unit-bearing observations.
#' @param multiple how to handle a single age matching multiple age intervals.
#'   One of "error" (default), "first", or "last".
#' @param convert_units which side to convert when `age` and `intervals` units differ.
#'   One of "age_to_group" (default), "group_to_age", or "none".
#'   Groups without units are interpreted in the units of `age`, when present,
#'   without changing their interval boundaries. Unitless ages with explicitly
#'   unit-bearing intervals remain an error. Near-boundary results can depend on
#'   conversion direction through floating-point rounding; see the Floating-point
#'   precision section in [age()] for consistent-unit guidance and `"none"`.
#' @param allow_approx logical; if FALSE (default), block conversions between fine units
#'   (second/minute/hour/day/week) and coarse units (month/year), or between month
#'   and year, because they are potentially approximate. Calendar month and year
#'   coordinates cannot generally be converted exactly without the original dates.
#'   TRUE permits numerical unit conversion; near category boundaries this can
#'   differ from calculating age directly in the target unit. For exact calendar
#'   classification, calculate age from the original dates in the intervals' unit.
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
#' intervals <- age_cat_iv(age = ages, intervals = age_interval_presets$Yr.10)
#' head(intervals, 12)
age_cat_iv <- function(age, intervals,
                       multiple = c("error", "first", "last"),
                       convert_units = c("age_to_group", "group_to_age", "none"),
                       allow_approx = FALSE){
  UseMethod("age_cat_iv")
}

# normalize and validate age_interval input. Numeric vectors are treated as cut points.
age_cat_iv_haystack <- function(intervals) {
  if(is.numeric(intervals)) intervals <- as_age_interval(intervals)
  if(!is_age_interval(intervals)) {
    stop('Argument: "intervals" must be numeric cut points or an age_interval vector')
  }
  sort(intervals)
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

# Validate the entire expression before any unit comparison or numeric coercion.
# A supported alias denotes one simple time unit; products, powers and ratios
# must not be reduced to their first numerator or their net dimension.
validate_age_unit <- function(unit) {
  if (!is.character(unit) || length(unit) != 1L || is.na(unit)) {
    stop("unit must be one time-unit string identifying a supported simple time unit",
         call. = FALSE)
  }
  normalized <- normalize_age_unit(unit)
  if (!normalized %in% c("second", "minute", "hour", "day", "week", "month", "year")) {
    stop("Unsupported age unit '", unit,
         "': an age must have a supported simple time unit ",
         "(second, minute, hour, day, week, month, or year)", call. = FALSE)
  }
  normalized
}

age_units_unit <- function(x) {
  # deparse_unit() preserves the full symbolic expression, including powers and
  # denominators. The allowlist also excludes compound expressions whose net
  # dimension happens to be time (e.g. second^2 / minute).
  validate_age_unit(units::deparse_unit(x))
}

age_cat_iv_age_unit <- function(age) {
  if (inherits(age, "units")) return(age_units_unit(age))
  if (is_age_interval(age) || is_age(age)) {
    unit <- get_unit(age)
    return(if (is.null(unit)) NULL else validate_age_unit(unit))
  }
  units_attr <- attr(age, "units")
  if (is.null(units_attr)) return(NULL)
  # Retain support for explicit unit attributes, validating the whole expression.
  validate_age_unit(as.character(units_attr, neg_power = TRUE, prod_sep = " "))
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
    (from_unit %in% coarse && to_unit %in% fine) ||
    (from_unit %in% coarse && to_unit %in% coarse && from_unit != to_unit)
}

age_cat_iv_align_units <- function(age, intervals,
                                   convert_units = c("age_to_group", "group_to_age", "none"),
                                   allow_approx = FALSE) {
  convert_units <- match.arg(convert_units)
  age_unit <- age_cat_iv_age_unit(age)
  group_unit <- normalize_age_unit(get_unit(intervals))

  if(is.null(age_unit) && is.null(group_unit)) return(list(age = age, intervals = intervals))
  if(is.null(group_unit)) {
    attr(intervals, "unit") <- age_unit
    return(list(age = age, intervals = intervals))
  }
  if(is.null(age_unit) || is.null(group_unit)) {
    stop('Age and intervals units are not compatible: one has units and the other does not')
  }
  if(identical(age_unit, group_unit)) return(list(age = age, intervals = intervals))

  if(convert_units == "none") {
    stop('Age and intervals units are not compatible')
  }

  from_unit <- if(convert_units == "age_to_group") age_unit else group_unit
  to_unit <- if(convert_units == "age_to_group") group_unit else age_unit
  if(age_cat_iv_is_approx_conversion(from_unit, to_unit) && !isTRUE(allow_approx)) {
    stop(paste("Age unit conversion is approximate. Calendar month and year coordinates",
               "cannot generally be converted exactly without the original dates.",
               "Set allow_approx = TRUE to use numerical unit conversion."), call. = FALSE)
  }

  if(convert_units == "age_to_group") {
    if(is_age_interval(age) || inherits(age, "ivs_iv")) {
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
      start = age_cat_iv_convert_values(ivs::iv_start(intervals), group_unit, age_unit),
      end = age_cat_iv_convert_values(ivs::iv_end(intervals), group_unit, age_unit)
    )
  }

  list(age = age, intervals = intervals,
       haystack = if (convert_units == "group_to_age") haystack else intervals)
}

# convert iv locate output to an ordered factor aligned to input needle order.
age_match_indices <- function(locations, n_needles, multiple = c("error", "first", "last")) {
  multiple <- match.arg(multiple)

  if(anyDuplicated(locations$needles)) {
    if(multiple == "error") {
      stop('Age intervals passed in the age argument match more than one group in the intervals argument')
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

age_cat_iv_to_factor <- function(locations, intervals, n_needles, multiple = c("error", "first", "last")) {
  idx <- age_match_indices(locations, n_needles, multiple)
  factor(x = idx,
         levels = seq_along(intervals),
         labels = age_interval_labels(intervals),
         ordered = TRUE)
}

#' @exportS3Method
age_cat_iv.default <- function(age, intervals,
                               multiple = c("error", "first", "last"),
                               convert_units = c("age_to_group", "group_to_age", "none"),
                               allow_approx = FALSE){
  stop('Argument: "age" must be numeric or an interval/age_interval vector')
}

#' @exportS3Method
age_cat_iv.numeric <- function(age, intervals,
                               multiple = c("error", "first", "last"),
                               convert_units = c("age_to_group", "group_to_age", "none"),
                               allow_approx = FALSE){
  intervals <- age_cat_iv_haystack(intervals)
  aligned <- age_cat_iv_align_units(age = age, intervals = intervals,
                                    convert_units = convert_units, allow_approx = allow_approx)
  age <- aligned$age
  intervals <- aligned$intervals
  locations <- ivs::iv_locate_between(
    needles = as.numeric(age),
    haystack = aligned$haystack %||% intervals
  )
  age_cat_iv_to_factor(locations = locations, intervals = intervals, n_needles = length(age), multiple = multiple)
}

#' @exportS3Method
age_cat_iv.integer <- function(age, intervals,
                               multiple = c("error", "first", "last"),
                               convert_units = c("age_to_group", "group_to_age", "none"),
                               allow_approx = FALSE){
  age_cat_iv.numeric(age = age, intervals = intervals, multiple = multiple,
                     convert_units = convert_units, allow_approx = allow_approx)
}

#' @exportS3Method
age_cat_iv.units <- function(age, intervals,
                             multiple = c("error", "first", "last"),
                             convert_units = c("age_to_group", "group_to_age", "none"),
                             allow_approx = FALSE){
  intervals <- age_cat_iv_haystack(intervals)
  aligned <- age_cat_iv_align_units(age = age, intervals = intervals,
                                    convert_units = convert_units, allow_approx = allow_approx)
  age <- aligned$age
  intervals <- aligned$intervals
  locations <- ivs::iv_locate_between(
    needles = as.numeric(age),
    haystack = aligned$haystack %||% intervals
  )
  age_cat_iv_to_factor(locations = locations, intervals = intervals, n_needles = length(age), multiple = multiple)
}

#' @exportS3Method
age_cat_iv.age_interval <- function(age, intervals,
                                 multiple = c("error", "first", "last"),
                                 convert_units = c("age_to_group", "group_to_age", "none"),
                                 allow_approx = FALSE){
  intervals <- age_cat_iv_haystack(intervals)
  aligned <- age_cat_iv_align_units(age = age, intervals = intervals,
                                    convert_units = convert_units, allow_approx = allow_approx)
  age <- aligned$age
  intervals <- aligned$intervals
  # Unit conversion may produce fractional matching boundaries. Use bare
  # intervals internally and retain the original group labels.
  haystack <- aligned$haystack %||% intervals
  locations <- ivs::iv_locate_overlaps(
    needles = ivs::iv(ivs::iv_start(age), ivs::iv_end(age)),
    haystack = ivs::iv(ivs::iv_start(haystack), ivs::iv_end(haystack)),
    type = "within"
  )
  age_cat_iv_to_factor(locations = locations, intervals = intervals, n_needles = length(age), multiple = multiple)
}

#' @exportS3Method
age_cat_iv.ivs_iv <- function(age, intervals,
                              multiple = c("error", "first", "last"),
                              convert_units = c("age_to_group", "group_to_age", "none"),
                              allow_approx = FALSE){
  age_cat_iv.age_interval(age = age, intervals = intervals, multiple = multiple,
                       convert_units = convert_units, allow_approx = allow_approx)
}

#' @exportS3Method
age_cat_iv.double <- function(age, intervals,
                              multiple = c("error", "first", "last"),
                              convert_units = c("age_to_group", "group_to_age", "none"),
                              allow_approx = FALSE){
  age_cat_iv.numeric(age = age, intervals = intervals, multiple = multiple,
                     convert_units = convert_units, allow_approx = allow_approx)
}

#' @exportS3Method
age_cat_iv.POSIXct <- function(age, intervals,
                               multiple = c("error", "first", "last"),
                               convert_units = c("age_to_group", "group_to_age", "none"),
                               allow_approx = FALSE){
  stop('Argument: "age" as POSIXct is not supported for age_cat_iv()')
}

#' @exportS3Method
age_cat_iv.Date <- function(age, intervals,
                            multiple = c("error", "first", "last"),
                            convert_units = c("age_to_group", "group_to_age", "none"),
                            allow_approx = FALSE){
  stop('Argument: "age" as Date is not supported for age_cat_iv()')
}

# Classification labels are separate from the interval's character rendering.
age_interval_labels <- function(x) {
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
    stop("Distinct age intervals must have unique factor labels", call. = FALSE)
  }
  labels
}

# Shared matching path for single assignment and all-membership output.
age_interval_locations <- function(ages, intervals) {
  if (inherits(ages, "ivs_iv")) {
    ivs::iv_locate_overlaps(
      ivs::iv(ivs::iv_start(ages), ivs::iv_end(ages)),
      ivs::iv(ivs::iv_start(intervals), ivs::iv_end(intervals)), type = "within")
  } else {
    ivs::iv_locate_between(as.numeric(ages), intervals)
  }
}
