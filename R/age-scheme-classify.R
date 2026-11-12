#' Return every membership in an age scheme
#'
#' @param ages An `age`, `units`, or unit-bearing interval vector. Present numeric
#'   ages must be finite and nonnegative. Interval ages must have valid nonnegative
#'   bounds; membership requires full containment, not partial overlap. `units`
#'   inputs must already have a supported simple time unit or alias: second,
#'   minute, hour, day, week, month or year. Compound, squared, inverse,
#'   dimensionless and non-time quantities are rejected, including empty and
#'   missing inputs. Use `age(x, unit = ...)` to assign a known unit to plain
#'   numeric observations; schemes do not infer it.
#' @param scheme A validated `age_scheme`.
#' @param convert_units Conversion direction: `"age_to_group"` (default),
#'   `"group_to_age"`, or `"none"`. Near-boundary results can depend on conversion
#'   direction through floating-point rounding; see the Floating-point precision
#'   section in [age()] for consistent-unit guidance and the limits of `"none"`.
#' @param allow_approx Allow potentially approximate numerical conversion between
#'   month and year, or between either calendar unit and finer units. Defaults to
#'   FALSE, as in [categorize_age()]. Calendar month and year coordinates cannot
#'   generally be converted exactly without the original dates. TRUE permits
#'   unit-factor conversion in either direction; near category boundaries this
#'   may differ from calculating age directly in the target unit. For exact
#'   calendar classification, calculate age from the original dates in the
#'   scheme's unit.
#' @return A base data frame with `observation` (one-based input index),
#'   `scheme_id`, `group_index` (original position in the scheme), `label`,
#'   `status` (`"matched"`, `"missing"`, or `"unmatched"`), and `group` (the matched
#'   `age_interval` interval in the scheme's original units). One row per match;
#'   missing/unmatched observations each have one placeholder row with missing
#'   group fields. Rows are ordered by observation and then original group index.
#'   Empty input yields zero rows with the same columns and types. Scheme metadata
#'   is not replicated per observation; retain the scheme separately.
#' @details Multiple rows for an observation are intentional. Overlapping groups
#'   cannot be summed as mutually exclusive population categories. This interface
#'   never silently selects the first matching group. For a single factor or
#'   interval assignment, use [categorize_age()] with explicit overlap policy.
#'   Unit-bearing schemes require unit-bearing observations; plain numbers are
#'   not silently interpreted as years. Missing ages differ from present ages
#'   outside the scheme's intervals. Even a complete scheme may have unmatched
#'   inputs outside its declared domain.
#' @seealso [age_scheme()], [scheme_intervals()]
#' @examples
#' g <- age_interval(c(10, 15), c(20, 25), unit = "year")
#' names(g) <- c("Group A", "Group B")
#' s <- age_scheme(g, "overlap_example", "Illustrative overlap",
#'                 type = "classification")
#' classify_age_scheme(age(c(12, 17, 30, NA), unit = "year"), s)
#' @export
classify_age_scheme <- function(ages, scheme,
                                convert_units = c("age_to_group", "group_to_age", "none"),
                                allow_approx = FALSE) {
  groups <- scheme_intervals(scheme)
  convert_units <- match.arg(convert_units)
  if (inherits(ages, "Date") || inherits(ages, "POSIXt") ||
      !(is.numeric(ages) || inherits(ages, "ivs_iv"))) {
    stop("ages must be numeric or an interval vector", call. = FALSE)
  }
  if (!is.logical(allow_approx) || length(allow_approx) != 1L || is.na(allow_approx)) {
    stop("allow_approx must be TRUE or FALSE", call. = FALSE)
  }
  if (inherits(ages, "ivs_iv")) {
    new_age_interval(ivs::iv_start(ages), ivs::iv_end(ages))
    missing <- is.na(ivs::iv_start(ages))
  } else {
    # Validate dimensions before numeric coercion can hide the unit expression.
    age_cat_iv_age_unit(ages)
    values <- as.numeric(ages)
    missing <- is.na(values)
    if (any(!missing & (!is.finite(values) | values < 0))) {
      stop("present ages must be finite and nonnegative", call. = FALSE)
    }
  }
  aligned <- age_cat_iv_align_units(ages, groups, convert_units, allow_approx)
  locations <- age_interval_locations(aligned$age, aligned$haystack %||% groups)
  keep <- !is.na(locations$haystack) & !missing[locations$needles]
  observation <- locations$needles[keep]
  index <- locations$haystack[keep]
  absent <- setdiff(seq_along(ages), observation)
  observation <- c(observation, absent)
  index <- c(index, rep.int(NA_integer_, length(absent)))
  ord <- order(observation, index, na.last = TRUE)
  observation <- as.integer(observation[ord])
  index <- as.integer(index[ord])
  status <- ifelse(missing[observation], "missing",
                   ifelse(is.na(index), "unmatched", "matched"))
  out <- data.frame(observation = observation,
                    scheme_id = rep.int(scheme$id, length(index)),
                    group_index = index, label = names(groups)[index],
                    status = as.character(status), stringsAsFactors = FALSE)
  out$group <- groups[index]
  out
}
