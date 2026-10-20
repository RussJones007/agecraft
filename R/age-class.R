#' Fractional ages with completed-unit display
#'
#' A numeric vctrs vector storing nonnegative fractional ages and one explicit
#' time unit for the entire vector. Display uses completed units, but comparison,
#' sorting and classification use the stored fractional values.
#'
#' @param x A numeric vector for `age()`, or an age, numeric, or time-units vector
#'   for `as_age()`. Missing values are allowed; negative and infinite ages are not.
#' @param unit A single time unit: second, minute, hour, day, week, month, or year.
#'   Common aliases are normalized. Defaults to year for numeric input and the
#'   existing unit for age or units input.
#' @param allow_approx Allow approximate conversion between month/year and finer
#'   units. Defaults to FALSE. Conversion uses the units package, not birthdays.
#' @param ... Reserved for future extensions.
#' @details
#' `as.numeric()` extracts full precision and `as.integer()` extracts completed units. `format(x, fractional = TRUE)` shows
#' fractions; `format(x)` and printing show completed whole units (floor).
#' Names, units and precision survive slicing, sorting, repetition and binding.
#' Combining or comparing ages requires matching units; convert explicitly with
#' `as_age(x, unit = ...)` first. Bare numbers are not implicitly combined with
#' ages. Means, extrema and rounding retain the class. Arithmetic and other
#' mathematical transformations are unsupported: use explicit numeric extraction
#' or units vectors for calculations and construct an age from the result.
#'
#' This class does not calculate fractional ages from dates. Existing
#' [calculate_age()] and [age_auto_unit()] still return completed units; wrapping
#' those values cannot recover fractional precision. Fractional years are not
#' exact elapsed days without an explicit calendar convention.
#' @return `age()` and `as_age()` return an age vector. `is_age()` returns a scalar
#'   logical indicating whether x inherits from age.
#' @export
#' @examples
#' x <- age(c(0.02, 0.5, 2.75, NA), unit = "year")
#' x
#' as.numeric(x)
#' format(x, fractional = TRUE)
#' groups <- age_group(c(0, 0.077, 1), c(0.077, 1, 3), unit = "year")
#' names(groups) <- c("Neonate", "Infant", "Toddler")
#' categorize_age(x, by = groups)
age <- function(x = double(), unit = "year") {
  if (is.object(x) || !is.null(dim(x)) || !(is.double(x) || is.integer(x))) {
    stop("x must be a plain numeric vector; use as_age() for conversion", call. = FALSE)
  }
  new_age(vctrs::vec_cast(x, double()), unit)
}

# Internal construction also validates results restored by vctrs.
new_age <- function(x = double(), unit = "year") {
  x <- vctrs::vec_data(x)
  if (!is.character(unit) || length(unit) != 1L || is.na(unit)) {
    stop("unit must be one time-unit string", call. = FALSE)
  }
  unit <- normalize_age_unit(unit)
  if (!unit %in% c("second", "minute", "hour", "day", "week", "month", "year")) {
    stop("Unsupported age unit", call. = FALSE)
  }
  if (any(!is.na(x) & (!is.finite(x) | x < 0))) {
    stop("Ages must be nonnegative and finite, or missing", call. = FALSE)
  }
  vctrs::new_vctr(x, unit = unit, class = "age", inherit_base_type = TRUE)
}

#' @rdname age
#' @export
is_age <- function(x) inherits(x, "age")

#' @rdname age
#' @export
as_age <- function(x, unit = NULL, allow_approx = FALSE, ...) {
  if (!is.logical(allow_approx) || length(allow_approx) != 1L || is.na(allow_approx)) {
    stop("allow_approx must be TRUE or FALSE", call. = FALSE)
  }
  UseMethod("as_age")
}

#' @exportS3Method
as_age.default <- function(x, unit = NULL, allow_approx = FALSE, ...) {
  stop("Cannot convert this object to age; supply numeric ages or time units", call. = FALSE)
}

#' @exportS3Method
as_age.numeric <- function(x, unit = NULL, allow_approx = FALSE, ...) {
  age(x, unit = unit %||% "year")
}

#' @exportS3Method
as_age.age <- function(x, unit = NULL, allow_approx = FALSE, ...) {
  if (is.null(unit)) return(x)
  target <- attr(new_age(unit = unit), "unit")
  source <- attr(x, "unit")
  if (identical(source, target)) return(x)
  if (!is.logical(allow_approx) || length(allow_approx) != 1L || is.na(allow_approx)) {
    stop("allow_approx must be TRUE or FALSE", call. = FALSE)
  }
  if (age_cat_iv_is_approx_conversion(source, target) && !allow_approx) {
    stop("Age unit conversion is approximate; set allow_approx = TRUE", call. = FALSE)
  }
  values <- age_cat_iv_convert_values(as.numeric(x), source, target)
  names(values) <- names(x)
  new_age(values, target)
}

#' @exportS3Method
as_age.units <- function(x, unit = NULL, allow_approx = FALSE, ...) {
  source <- units::deparse_unit(x)
  # Ask units to reject compound, inverse and non-time quantities.
  reference <- units::set_units(1, source, mode = "standard")
  units::set_units(reference, "second", mode = "standard")
  source <- normalize_age_unit(source)
  out <- new_age(stats::setNames(as.numeric(x), names(x)), source)
  as_age(out, unit = unit, allow_approx = allow_approx)
}

#' @exportS3Method
format.age <- function(x, ..., fractional = FALSE) {
  if (!is.logical(fractional) || length(fractional) != 1L || is.na(fractional)) {
    stop("fractional must be TRUE or FALSE", call. = FALSE)
  }
  values <- vctrs::vec_data(x)
  if (!fractional) values <- floor(values)
  out <- paste(format(values, trim = TRUE, ...), attr(x, "unit"))
  out[is.na(values)] <- NA_character_
  names(out) <- names(x)
  out
}

#' @exportS3Method vctrs::vec_ptype_abbr
vec_ptype_abbr.age <- function(x, ...) paste0("age<", attr(x, "unit"), ">")

#' @exportS3Method vctrs::vec_ptype_full
vec_ptype_full.age <- function(x, ...) paste0("age<", attr(x, "unit"), ">")

#' @exportS3Method vctrs::vec_restore
vec_restore.age <- function(x, to, ...) new_age(x, attr(to, "unit"))

age_common_unit <- function(x, y) {
  if (!identical(attr(x, "unit"), attr(y, "unit"))) {
    stop("Ages have incompatible units; convert explicitly with as_age()", call. = FALSE)
  }
  attr(x, "unit")
}

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.age.age <- function(x, y, ...) new_age(unit = age_common_unit(x, y))

#' @exportS3Method vctrs::vec_cast
vec_cast.age.age <- function(x, to, ...) {
  new_age(vctrs::vec_data(x), age_common_unit(x, to))
}

#' @exportS3Method vctrs::vec_cast
vec_cast.double.age <- function(x, to, ...) vctrs::vec_data(x)

#' @exportS3Method
as.double.age <- function(x, ...) as.double(vctrs::vec_data(x))

#' @exportS3Method
age_cat_iv.age <- function(age, age_group,
                           multiple = c("error", "first", "last"),
                           convert_units = c("age_to_group", "group_to_age", "none"),
                           allow_approx = FALSE) {
  age_cat_iv.numeric(age, age_group, multiple, convert_units, allow_approx)
}

# Only operations whose results are still ages retain the class.
#' @exportS3Method vctrs::vec_math
vec_math.age <- function(.fn, .x, ...) {
  predicates <- c("is.nan", "is.finite", "is.infinite", "any", "all", "anyNA")
  summaries <- c("mean", "min", "max", "range", "abs", "signif", "round",
                 "floor", "ceiling", "trunc")
  if (!.fn %in% c(predicates, summaries)) {
    stop("This mathematical operation is not defined for ages; use as.numeric() explicitly", call. = FALSE)
  }
  out <- vctrs::vec_math_base(.fn, .x, ...)
  if (.fn %in% predicates) out else new_age(out, attr(.x, "unit"))
}

#' @exportS3Method
as.integer.age <- function(x, ...) as.integer(vctrs::vec_data(x))
