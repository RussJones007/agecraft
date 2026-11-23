#' agecraft: Calculate ages and define age groups
#'
#' @description
#' Calculate ages from dates, define age intervals, and classify observations
#' into age groups. Explicit time units and interval boundaries help you
#' construct classifications suited to your analysis.
#'
#' \if{html}{\figure{logo.png}{options: align="right" width="120" alt="agecraft logo"}}
#'
#' @details
#' The package provides four complementary S3 classes.
#' See [agecraft-classes] for a class overview and an example connecting them,
#' and [age_group class][age_group-class] for the structure of categorical assignments.
#'
#' * **`age`** represents age values with fractional precision and an explicit
#'   time unit. Printed values show completed units while the stored values
#'   retain their fractional detail.
#' * **`age_interval`** represents a collection of age ranges. Each interval
#'   includes its lower bound and excludes its upper bound: `[lower, upper)`.
#'   For example, ages 1–4 years are represented by `[1, 5)`.
#' * **`age_group`** represents the categories assigned to observations after
#'   classification. It is an ordered-factor subclass that retains the
#'   interval definition associated with each category.
#' * **`age_scheme`** contains named age intervals together with their purpose,
#'   source information, and validation rules. It records a reusable
#'   classification definition separately from the observations classified
#'   with it.
#'
#' @section Calculate and classify ages:
#' Use [calculate_age()] to calculate ages from birth and reference dates.
#' Years and months use calendar anniversaries; finer units measure elapsed
#' time. Use [age()] to attach a known unit to numeric age values.
#'
#' Define ranges with [age_interval()], or convert numeric cutpoints with
#' [as_age_interval()]. Use [categorize_age()] to assign observations to
#' categories and [group_intervals()] to inspect the resulting category
#' definitions.
#'
#' @section Choose and document a scheme:
#' Choose boundaries that preserve age-related differences relevant to your
#' question and support the intended comparisons. When calculating rates,
#' ensure that case and population denominators use compatible boundaries.
#'
#' Use [age_scheme()] to retain interval definitions with their purpose and
#' provenance. Validation checks the structure and declared coverage of a
#' scheme; it does not establish its suitability for a particular analysis
#' or independently verify its source.
#'
#' @seealso
#' [calculate_age()], [age()], [age_interval()], [as_age_interval()],
#' [categorize_age()], [age_scheme()], [agecraft-classes], [age_group class][age_group-class]
#'
#' @examples
#' ages <- age(c(0.5, 1, 4.9, 5, 17, 65), unit = "year")
#'
#' intervals <- as_age_interval(
#'   c(0, 1, 5, 18, 65, Inf),
#'   unit = "year"
#' )
#'
#' groups <- categorize_age(ages, by = intervals)
#' groups
#' group_intervals(groups)
#'
#' @keywords internal
"_PACKAGE"

#' @importFrom generics as.factor as.ordered
#' @importFrom assertthat assert_that
#' @importFrom ivs iv iv_start iv_end
#' @importFrom vctrs field
#' @importFrom rlang %||%
#' @importFrom purrr compose attr_getter pluck
#' @importFrom dplyr select filter mutate group_by summarise between case_when replace_when
#' @importFrom Rcpp evalCpp
#' @importFrom stringr str_extract str_detect str_replace str_to_lower str_trim regex
#' @useDynLib agecraft, .registration = TRUE
NULL
