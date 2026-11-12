# agecraft

Calculate ages, keep their units and precision, and turn them into useful named categories. **agecraft** brings these common steps together for public health, education, population research, and other work with age data.

<!-- badges: start -->

agecraft <img src="man/figures/craft_badge_2.png" alt="agecraft logo" align="right" height="140"/>

![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)

<!-- badges: end -->

The package provides:

- Calendar-based fractional ages from birth and reference or event dates.
- An **`age`** class that retains fractions while displaying completed whole units.
- An **`age_interval`** class with explicit units, fractional interval boundaries, and optional category names.
- Classification into ordered factors for tables and analysis, or matched intervals when you need to retain the boundaries.
- Reusable `age_scheme` definitions with provenance, partition validation, and explicit all-membership output for overlapping classifications.
- Reusable group definitions, automatic reporting-unit selection, and interval comparisons such as crosswalks, membership, and coverage operations.

The `age` and `age_interval` vector classes use the [vctrs](https://vctrs.r-lib.org/) framework. Group intervals build on [ivs](https://davisvaughan.github.io/ivs/), and explicit unit conversions use [units](https://r-quantities.github.io/units/). Requires R 4.1.0 or later. The package is under active development; see [NEWS](NEWS.md) for API changes.

## Start with dates, finish with named categories

``` r
library(agecraft)

visits <- data.frame(
  birth_date = as.Date(c("2024-01-01", "2023-01-01", "2020-01-01")),
  visit_date = rep(as.Date("2024-07-02"), 3)
)

# Keep fractional ages and their year unit; display completed whole years.
visits$age <- calculate_age(visits$birth_date, visits$visit_date, unit = "year")

# Include each lower bound and exclude each upper bound.
groups <- age_interval(start = c(0, 1, 3), end = c(1, 3, 6), unit = "year")
names(groups) <- c("Infant", "Toddler", "Young child")

visits$category <- categorize_age(visits$age, by = groups)
visits
table(visits$category)
# Infant      Toddler  Young child
#      1            1            1
```

Names become the labels in the ordered factor and its frequency table. The example boundaries are illustrative; choose definitions that fit your analysis. An interval `[1, 3)` starts on the first birthday and ends just before the third. Its ordinary interval label is `1-2`.

## Installation and guides

From a local checkout:

``` r
# install.packages("devtools")
devtools::install(build_vignettes = TRUE)
```

For development in the repository, use `devtools::load_all()`.

| Guide | What it covers |
|:---|:---|
| [Getting started](vignettes/getting-started.Rmd) | A beginner workflow: dates, output choices, supplied groups, names, and tables |
| [Working with age and age_interval](vignettes/age-and-age-interval.Rmd) | Both classes in detail, using one sample data frame throughout |
| [A public-health age workflow](vignettes/public-health-workflow.Rmd) | Reporting groups, units, and overlapping definitions |
| [Comparing age ranges](vignettes/age-range-comparisons.Rmd) | Crosswalks, membership, ordering, age gaps, and interval coverage |

After installing with vignettes, use `vignette("getting-started", package = "agecraft")` or `vignette("age-and-age-group", package = "agecraft")`.

## Calculate ages and choose the return format

`calculate_age(start, end, unit)` accepts Date or POSIXct vectors. Supply a birth date for `start` and a reference or event date for `end`. A single date is reused across the other vector; otherwise the lengths must match. Omit `end` for the current date-time, or supply `Sys.Date()` for today's date explicitly.

Supported units are `"year"` (default), `"month"`, `"week"`, `"day"`, `"hour"`, `"minute"`, and `"second"`.

| `output` | Return value | Values stored |
|:---|:---|:---|
| `"age"` (default) | An `age` vector with one explicit unit | Fractional ages; completed whole units displayed |
| `"numeric"` | Plain numeric values | Completed whole units, without unit metadata |
| `"units"` | A units-package vector | Completed whole units, preserving the previous return format |

``` r
x <- calculate_age(as.Date("2024-01-01"), as.Date("2024-07-02"))
x                            # displays 0, with year in the class header
as.numeric(x)                # 0.5: full fractional precision
as.integer(x)                # 0: completed whole units
format(x, fractional = TRUE) # display the fraction

calculate_age(as.Date("2024-01-01"), as.Date("2024-07-02"), output = "numeric")
# 0
```

`as.numeric(x)` on an age object retains its fractions. It is different from asking `calculate_age()` for `output = "numeric"`, which returns completed ages. Missing date pairs return `NA`; empty recyclable inputs return an empty vector. An end date before its start raises an error.

### Calendar conventions

Fractional years are completed birthdays plus the fraction of civil days between the previous and next birthdays. February 29 birthdays advance on March 1 in non-leap years. Fractional months use calendar month anniversaries, falling on the last day of shorter months. Anniversaries are anchored to the original birth date to avoid drift.

For POSIXct inputs, years and months use civil dates in the starting time zone and ignore time of day. Smaller units measure elapsed time: a day is 24 hours and a week is seven such days. Daylight-saving transitions can therefore yield fractional days. When `start` is Date, `end` is converted with `as.Date()`; when `start` is POSIXct, `end` must also be POSIXct.

## Work with age vectors and units

Use `age()` to construct from plain numeric values, `as_age()` to convert numeric, age, or time-units vectors, and `is_age()` to identify the class.

``` r
reported_ages <- age(c(0.5, 2.75, NA), unit = "year")
is_age(reported_ages)
attr(reported_ages, "unit")

elapsed_days <- age(c(7, 10.5, 14), unit = "day")
as_age(elapsed_days, unit = "week")
```

Names, units, and fractional precision survive slicing, sorting, repetition, concatenation, and data-frame binding. Combining or comparing age vectors requires matching units. Means, medians, extrema, and rounding retain the class. Numeric offsets use the age's unit; addition of two ages converts the right age to the left age's unit. Negative or infinite results are rejected. Age minus age, numeric minus age, multiplication, division, sums and general transformations remain unsupported.

``` r
age(25, "year") + 1                 # 26 years
age(25, "year") - 25                # zero years
age(2, "week") + age(3.5, "day")     # 2.5 weeks
age(3.5, "day") + age(2, "week")     # 17.5 days
# Calendar conversion still needs explicit approximation consent:
age(2, "year") + as_age(age(6, "month"), "year", allow_approx = TRUE)
```

Arithmetic preserves stored fractions and uses vctrs scalar recycling rules. Convert time-units objects with `as_age()` before using them in arithmetic.

Conversions between finer units and months/years require `allow_approx = TRUE`:

``` r
approximate_days <- as_age(reported_ages, unit = "day", allow_approx = TRUE)
as.numeric(approximate_days)
```

The fractional part is now a fraction of a day. Conversion uses the units package's factors, not the original birth and event dates. For exact elapsed days, calculate directly from those dates with `calculate_age(..., unit = "day")`.

## Define groups with boundaries, units, and names

`age_interval(start, end, unit)` constructs right-open intervals directly. Fractional bounds are preserved without rounding; `[0, 0.077)` displays explicitly, while whole-number intervals retain completed-age labels such as `1-4` for `[1, 5)`. One unit applies to every interval in a group vector; `NULL` leaves the unit unspecified. Only upper bounds may be infinite. A scalar `end` is recycled to the length of `start`; starts are not recycled. Missing intervals require both bounds to be missing.

``` r
fine_groups <- age_interval(c(0, 0.077, 1, 3), c(0.077, 1, 3, 6), unit = "year")
names(fine_groups) <- c("Neonate", "Infant", "Toddler", "Young child")
fine_ages <- age(c(0.02, 0.5, 2, 4, NA), unit = "year")
categorize_age(fine_ages, by = fine_groups)
# Neonate Infant Toddler Young child <NA>
```

The `0.077`-year cutoff approximates 28 days. Use day-based ages and groups when an exact day boundary matters. Classification uses the stored fractional values, even when several ages display as `0` under a year header.

Use `as_age_interval()` for supported completed-age labels, factors of those labels, numeric cut points, or `ivs::iv()` intervals:

``` r
as_age_interval(c("< 5", "5-9", "10+"), unit = "year")
as_age_interval(c(0, 5, 10, Inf), unit = "year")
```

A final `Inf` in numeric cuts produces an open-ended final group. With a final finite cut, `as_age_interval()` adds a final one-unit interval. Use explicit `age_interval(start, end)` bounds when every upper boundary must be specified.

### Supplied age-group definitions

`age_interval_presets` is a named list of numeric cut points: `ILI`, `IMM`, `Yr.5`, `Yr.10`, `Spec`, `Annual`, `School`, and `Covid`. Assign their intended unit when constructing groups:

``` r
reporting_groups <- as_age_interval(age_interval_presets$Yr.5, unit = "year")
categorize_age(visits$age, by = reporting_groups)
```

These are inherited reporting conventions. Their provenance and limitations are recorded in `inst/extdata/age-group-provenance.csv` and the `age_interval_presets` help page. Confirm that a definition fits your reporting requirements.

## Classification and interval analysis

`categorize_age()` returns an ordered factor by default. Nonblank group names supply its labels; blank or missing names fall back to interval labels. Distinct intervals require unique resulting labels. Levels follow sorted interval order. Unmatched or missing observations return `NA`.

To keep one matched interval per observation, including repeats and missing assignments, request interval output:

``` r
matched <- categorize_age(visits$age, by = groups, output = "interval")
matched
names(matched)
```

Gaps and overlaps are allowed. Multiple matches raise an error by default; `multiple = "first"` or `"last"` selects a match in sorted interval order. Interval inputs must be completely contained in a group to match. `age_cat_iv()` provides the alternative interval-classification interface.

Groups with unspecified units inherit the age vector's unit for matching. Unitless numeric ages with explicitly unit-bearing groups are rejected. When specified units differ, `convert_units = "age_to_group"` (default) or `"group_to_age"` converts one side; `"none"` rejects conversion. Approximate conversions require `allow_approx = TRUE`.

`compare_age_intervals()` supports crosswalks, definite or possible membership, ordering, possible age-gap bounds, intersection, union, difference, and widths:

``` r
broad_groups <- age_interval(c(0, 18, 65), c(18, 65, Inf), unit = "year")
compare_age_intervals(broad_groups, operation = "width")
head(compare_age_intervals(reporting_groups, broad_groups, operation = "crosswalk"))
```

Comparison requires matching units. Widths use the interval's coordinate unit; they are not exact calendar-day durations. Crosswalks describe overlaps but cannot redistribute aggregate counts without additional information.

For group vectors, slicing, sorting, concatenation, and casts preserve names and units. Combining groups requires matching units, including whether a unit is specified. Interval set operations can merge or split groups, so they discard category names. Explicit casting to a bare ivs interval discards age metadata.

## Select a reporting unit automatically

`age_auto_unit()` returns a **named numeric vector of completed ages**. Its names identify the selected unit, rather than participants or categories. It does not return the fractional `age` class.

``` r
birth <- as.Date("2024-01-01")
events <- birth + c(6, 7, 28, 31, 366, NA)
age_auto_unit(birth, events, allowed_units = c("day", "week", "month", "year"))
```

By default, allowed units are day/month/year: ages through 30 days remain in days, then completed years are preferred, followed by completed months, otherwise days. Include `"week"` to select completed years, then calendar months, then weeks, then days. Omit `"month"` for day/week/year reporting. `"day"` is required. Missing ages have blank unit names; automatic hours are unsupported.

## Migrating existing code

The package was renamed from `rage`. Replace `library(rage)` with `library(agecraft)` and update package-qualified calls.

| Previous interface           | Current recommendation   |
|:-----------------------------|:-------------------------|
| `calc_age()`                 | `calculate_age()`        |
| `age.cat()`, `age_cat()`     | `categorize_age()`       |
| `age.groups$Yr.5`            | `age_interval_presets$Yr.5` |
| Label or interval conversion | `as_age_interval()`         |
| Direct start/end bounds      | `age_interval()`            |

`calculate_age()` now defaults to fractional `age` output. Use `output = "units"` for the previous completed-age units vector, or `output = "numeric"` for plain completed ages. `calc_age()` and `age_auto_unit()` retain completed-age outputs.

The deprecated wrappers and `age.groups` remain available through the next non-development release; removal requires a later announced breaking release. `age_cat()` warns once per session. `calc_age()` and `age.cat()` emit messages once per session.

For targeted preset-reference changes in R scripts, preview the installed helper:

``` r
tool <- system.file("tools", "migrate-age-groups.R", package = "agecraft")
source(tool)
migrate_age_interval_presets("analysis.R")
# After reviewing: migrate_age_interval_presets("analysis.R", write = TRUE)
```

The helper preserves list entry selections, comments, strings, and line endings. Strings, local bindings, member names, and other package namespaces are flagged for review. Writes keep `.bak` backups and refuse to overwrite existing backups. It is a targeted R-script helper; edit R Markdown/Quarto chunks manually.

## Development

``` r
devtools::document()
devtools::test()
devtools::check()
```

`Rscript scripts/build.r` builds a source archive into `build/`. Version changes and installation are separate steps; see `scripts/release.md`. Optional reference site generation uses `pkgdown::build_site()`. GitHub CI is configured for Linux, macOS, and Windows.

## License

MIT. See [LICENSE](LICENSE).

## Reusable age schemes

Wrap named, unit-bearing groups in `age_scheme()` to declare a partition or overlapping classification with purpose and provenance. Use the same scheme across datasets; completeness is validated against an explicit age domain.

``` r
legacy_ili <- get_age_scheme("legacy_ili")
ages <- age(c(2, 15, 40, 70, NA), unit = "year")
categorize_age(ages, by = legacy_ili)
classify_age_scheme(ages, legacy_ili)
```

`list_age_schemes()` lists eight legacy definitions with unchanged cut points and unverified external editions. Unit-bearing schemes require unit-bearing ages. Existing numeric presets and classification defaults remain available. For user-defined partitions and overlapping classifications, see the [age-schemes guide](vignettes/age-schemes.Rmd).

Unit-bearing observations must use a supported simple time unit (second, minute, hour, day, week, month or year, including supported aliases). `as_age()` and classification functions reject compound, squared, inverse, dimensionless and non-time quantities before conversion or matching. For plain numeric ages with a known unit, use `age(x, unit = "year")` (or the appropriate supported unit).

Scheme construction, classification and inspection validate the complete stored interval representation, including display symbols, units, category names and boundaries. Malformed metadata errors without default substitution; valid custom display symbols remain supported. Structural validity does not verify external source authority or provenance.

Ordinary edits to local scheme copies now track minimal derivative ancestry. For example, `names(modified$intervals)[1] <- "Revised category"` creates a local `_derived` identity, clears verification, and retains original identity/source metadata in `derived_from`. Changing the descriptive title does not create a derivative. See the age-schemes guide for batch edits and tracking limits.

### Optional external catalogue

With `mudnester` installed, `import_mudnester_scheme("abs_5yr")` imports a validated, unverified scheme; `mudnester_catalogue()` exposes upstream provenance, package snapshot version and known issues. Imports warn about applicability and preserve numeric boundaries and labels faithfully. The eight legacy schemes and numeric presets are unchanged. See the age-schemes vignette for caveats.

## Age-category assignments

`categorize_age()` returns an `age_category` ordered factor with readable labels
and retained interval definitions.

```r
groups <- age_interval(c(0, 5, 10), c(5, 10, Inf), sep = " to ")
categories <- categorize_age(c(2, 7, NA), by = groups)
category_intervals(categories)
category_intervals(droplevels(categories[1]))
```

Subsetting retains unused categories. Combining requires matching definitions,
labels and units. Use `vctrs::vec_rbind()` for binding with metadata validation,
and `generics::as.factor()` for an ordinary factor. Base coercers retain factor
subclasses, while base data-frame binding may discard their metadata. See the
[age-categories guide](vignettes/age-categories.Rmd) for the full contracts.

### Interval naming transition

On this development branch, use `age_interval()` to define age ranges and
`age_category` for assigned categories. Schemes and categories expose definitions
through `scheme_intervals()` and `category_intervals()`. The canonical cut-point
list is `age_interval_presets`; its two earlier names remain data aliases.
See the [phase-one migration guide](docs/age_class_naming_migration.md) for renamed
functions, arguments and saved-object handling.
