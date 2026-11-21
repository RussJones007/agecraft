#' Category assignments with interval definitions
#'
#' An `age_group` vector represents the categories assigned to observations.
#' One element is one observation's assignment. The vector also retains the
#' age intervals defining every available category, including unused categories.
#'
#' @section What the object contains:
#' The classes are `c("age_group", "ordered", "factor")`. Like an ordered factor,
#' the vector represents assignments using integer codes and category levels.
#' The character labels supplied to [age_group()] are represented by those codes
#' and levels, rather than stored as a separate character vector. The codes are
#' category identifiers, not numerical ages.
#'
#' An associated `age_interval` vector supplies one defining interval per level,
#' in the same chronological order. Each definition is present and has a unique,
#' nonblank label. Observation names are independent of category names. Missing
#' assignments use `NA`; missingness is not an additional category. Empty
#' assignment vectors and empty category definitions are supported.
#'
#' Original numerical ages and scheme provenance are not retained. Keep those
#' separately when you need them. A group contains interval definitions; it does
#' not inherit from `age_interval`.
#' @section Creation and inspection:
#' Use [age_group()] when you already have category labels and their interval
#' definitions. Use [categorize_age()] to classify numerical ages or observed
#' intervals; its default result is an `age_group` object.
#'
#' `as.character(x)` retrieves one label per observation. `levels(x)` lists all
#' available categories. [group_intervals()] retrieves one defining interval per
#' category, including unused categories, rather than one interval per observation.
#' For matched intervals per observation, request `output = "interval"` from
#' [categorize_age()]. [is_age_group()] identifies the assignment representation;
#' it is not a full metadata validator.
#'
#' Definition units belong to the intervals returned by `group_intervals()`.
#' An optional observation-unit attribute on classified groups describes the
#' original observations and can differ from the definition unit.
#' @section Supported operations:
#' Subsetting retains all levels and their interval definitions. `droplevels()`
#' removes unused levels and their definitions together. Combining groups
#' requires matching ordered category labels, interval bounds and definition
#' units. Unique nonblank relabeling updates the associated interval names;
#' reordering or merging levels is rejected. To change boundaries, classify the
#' original ages again using the new definition.
#'
#' Use `generics::as.factor()` or `generics::as.ordered()` to obtain ordinary
#' factors without interval metadata. Base factor coercers retain existing
#' factor subclasses. Use `vctrs::vec_rbind()` for validated data-frame binding;
#' base binding can discard interval metadata. See [age_group()] for saved-object
#' migration guidance.
#' @seealso [age_group()] for construction; [group_intervals()] for definitions;
#'   [agecraft-classes] for the other package classes.
#' @examples
#' bands <- age_interval(breaks = c(0, 5, 18, Inf), unit = "year")
#' names(bands) <- c("Preschool", "School age", "Adult")
#' groups <- age_group(c("Adult", "Preschool", NA), bands)
#' class(groups)
#' as.character(groups)
#' levels(groups)
#' group_intervals(groups)
#' group_intervals(droplevels(groups))
#' @name age_group-class
NULL

#' Classes for ages, intervals, assignments and schemes
#'
#' Agecraft provides four complementary S3 classes. Choose a class according to
#' whether you need age values, interval definitions, category assignments, or a
#' reusable classification with provenance.
#'
#' @section Age values (age):
#' An `age` vector stores numerical ages with fractional precision and one
#' explicit time unit. Create it with [age()], convert with [as_age()], or
#' calculate it from dates with [calculate_age()]. Printing shows completed units
#' by default; `as.numeric()` retrieves stored fractions. See [age()] for display
#' options, conversions and supported operations.
#' @section Interval definitions (age_interval):
#' An `age_interval` vector represents age ranges using the `ivs` interval
#' representation. Each range includes its start and excludes its end: `[start,
#' end)`. For example, `[1, 5)` includes completed ages 1 through 4. A vector can
#' carry category names and one common unit. Use [age_interval()] to define
#' ranges and [as_age_interval()] to convert supported inputs. These ranges can
#' define categories or represent observations whose exact ages are unknown.
#' @section Category assignments (age_group):
#' An `age_group` vector records one category assignment per observation as an
#' ordered factor and retains the interval definition for each available
#' category. [categorize_age()] creates it by classifying ages; [age_group()]
#' constructs it from existing labels and definitions. [group_intervals()]
#' retrieves those definitions, including unused categories. See [age_group class][age_group-class]
#' for the representation and supported operations.
#' @section Reusable classification definitions (age_scheme):
#' An `age_scheme` contains named `age_interval` definitions with identity,
#' purpose, provenance and coverage information. It represents a reusable
#' classification, rather than observations or their assignments. Its domain
#' can be inferred from the interval span or specified explicitly; completeness
#' is calculated. Use [age_scheme()] to construct one and [scheme_intervals()]
#' to retrieve its interval definitions. Schemes and groups contain intervals;
#' neither inherits from the interval class.
#' @section How the classes work together:
#' Start with `age` values and define categories with an `age_interval` vector
#' or an `age_scheme`. Pass them to [categorize_age()] to obtain `age_group`
#' assignments. The result retains category definitions, but not original ages
#' or scheme provenance. Keep those inputs separately for later reclassification
#' or attribution. [classify_age_scheme()] provides all memberships as a data
#' frame when categories can overlap.
#' @seealso [age_group class][age_group-class] for categorical assignment behavior;
#'   [age()], [age_interval()], [age_scheme()] for constructor and class contracts.
#' @examples
#' ages <- age(c(2, 10, 30, NA), unit = "year")
#' bands <- age_interval(breaks = c(0, 5, 18, Inf), unit = "year")
#' names(bands) <- c("Preschool", "School age", "Adult")
#' groups <- categorize_age(ages, by = bands)
#' as.character(groups)
#' group_intervals(groups)
#' scheme <- age_scheme(bands, "example", "Example age bands")
#' categorize_age(ages, by = scheme)
#' @name agecraft-classes
NULL
