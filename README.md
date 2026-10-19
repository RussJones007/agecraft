# agecraft

Renamed from the original `rage` package. Development version 0.1.0.9010. Requires R 4.1.0 or later.

<!-- badges: start -->

![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)

<!-- badges: end -->

`agecraft` is an R package for age-focused data work:

-   calculate ages from dates or date-times in multiple units
-   represent age groups with a dedicated S3 class (`age_group`)
-   categorize ages into ordered age-group factors
-   reuse common public-health age-group definitions

## Why this package

Age data often needs consistent handling across analysis steps. `agecraft` provides a single workflow for:

1.  computing age from time values
2.  converting between human-readable age labels and interval-based age groups
3.  assigning individuals or events into standard age categories

Internally, `age_group` is built on [`ivs`](https://davisvaughan.github.io/ivs/) intervals, so age ranges behave like first-class interval vectors. Age units are provided by the [`units`](https://r-quantities.github.io/units/) package.

## Installation

`agecraft` is not currently on CRAN.

Install from a local checkout:

``` r
# from the project root
devtools::install()
```

For development from a local clone:

``` r
# install.packages("devtools")
devtools::load_all()
```

## Quick Start

``` r
library(agecraft)

# Calculate age in years
birth_dates <- as.Date(c("1980-04-14", "2000-01-02", "2018-11-30"))
ref_date <- as.Date("2025-12-25")
age_years <- calculate_age(start = birth_dates, end = ref_date, unit = "year")
age_years

# Categorize ages using included definitions
categories <- categorize_age(ages = as.numeric(age_years), by = age_group_presets$Annual)
categories

# Work with the age_group S3 class
ag <- as.age_group(c("< 5", "5-9", "10-14", "15-19", "20+"))
as.character(ag)
```

## Core Concepts

### `age_group` S3 class

`age_group` stores age ranges as right-open intervals:

-   `"0-4"` is represented as `[0, 5)`
-   `"14"` (single year) is represented as `[14, 15)`
-   `"85+"` is represented as `[85, Inf)`
-   `"All"`/`"total"` is represented as `[0, Inf)`

You can construct `age_group` vectors from:

-   character/factor labels (`"< 5"`, `"10-14"`, `"65+"`, `"All"`)
-   numeric cut points (`c(0, 5, 10, 15, Inf)`)
-   `ivs::iv()` interval vectors

## Main functions

-   `calculate_age(start, end = lubridate::now(), unit = ...)`
-   `categorize_age(ages, lower = 0, upper = 70, by = 10, sep = "-", above.char = " +")`
-   `as.age_group(x, below = "0-", sep = "-", above = "+")`
-   `is.age_group(x)`
-   `age_group_to_char(groups, ...)`
-   `age_auto_unit(birth, event, allowed_units = c("day", "month", "year"))`
-   `age_group(start, end, unit = NULL, ...)`
-   `compare_age_groups(x, y, operation = ...)`

Also exported:

-   `age_cat()` and `age.cat()` are deprecated wrappers for `categorize_age()`
-   `calc_age()` is a deprecated wrapper for `calculate_age()`; `age_cat()` warns once per session; the other wrappers emit messages once per session

## Included age-group definitions

The package includes `age_group_presets`, a named list of commonly used cut points:

-   `ILI`
-   `IMM`
-   `Yr.5`
-   `Yr.10`
-   `Spec`
-   `Annual`
-   `School`
-   `Covid`

These are numeric break vectors (typically ending in `Inf`) intended for `categorize_age()` or `cut()`.

## More Examples

``` r
library(agecraft)

# 1) Calculate age in years
birth_dates <- as.Date(c("1980-04-14", "2000-01-02", "2018-11-30"))
ref_date <- as.Date("2025-12-25")
age_years <- calculate_age(start = birth_dates, end = ref_date, unit = "year")
age_years

# 2) Convert labels to age_group and back
labs <- c("< 5", "5-9", "10-14", "15-19", "20+")
ag <- as.age_group(labs)
ag
as.character(ag)

# 3) Build age groups from cut points
cuts <- c(0, 1, 5, 10, 20, 40, 60, Inf)
special_groups <- as.age_group(cuts)
as.character(special_groups)

# 4) Categorize ages using included definitions
ages <- c(0, 1, 4, 8, 17, 23, 39, 54, 72, 88)
categories <- categorize_age(ages = ages, by = age_group_presets$Annual)
categories

# 5) Preserve units when categorizing
age_days <- calculate_age(start = as.Date("2025-01-01"), end = as.Date("2025-02-15"), unit = "day")
age_days
categorize_age(ages = age_days, by = c(0, 7, 14, 30, 60, Inf))
```

## Notes

-   When `start` is `Date`, `calculate_age()` converts `end` with `as.Date()`. When `start` is `POSIXct`, `end` must also be `POSIXct`.
-   Vector lengths are recycled when one side has length 1. Missing pairs return `NA`; empty recyclable inputs return a zero-length vector. Reversed dates are rejected.
-   Converting elapsed days to months or years with `units::set_units()` is approximate. Calculate calendar ages directly in the required unit instead.

## Interval matching and units

``` r
groups <- as.age_group(c(0, 5, 18, 65, Inf), unit = "year")
age_years <- calculate_age(as.Date(c("2020-01-01", "1980-01-01")),
                           as.Date("2025-01-01"))
age_cat_iv(age_years, groups)
```

`age_cat_iv()` supports numeric ages and intervals. Overlapping definitions raise
an error by default; `multiple = "first"` or `"last"` selects a match in sorted
interval order. Unmatched and missing ages return `NA`.

Units must exist on both sides or neither side. `convert_units = "age_to_group"`
(the default) or `"group_to_age"` converts one side; `"none"` rejects differing
units. Conversions between month/year and smaller elapsed units require
`allow_approx = TRUE`.

Concatenation and data-frame binding preserve `age_group` and its units.
Different units, or mixing unit-bearing and unitless groups, raise errors.
Different display symbols use canonical `0-`, `-`, and `+` formatting.
Explicit casting to a bare `ivs` interval discards age metadata.

## Calendar conventions

Years use completed birthdays, with February 29 birthdays advancing on March 1
in a non-leap year. Months use calendar anniversaries, falling on the last day of
a shorter month. For date-times, calendar ages use the start time zone and ignore
time of day; smaller units use elapsed time, including daylight-saving effects.

By default, `age_auto_unit()` reports days through day 30, then completed years if available,
then completed months, otherwise days. Its numeric result has `Day`, `Month`, or
`Year` names, with blank names for missing pairs.

## Documentation and development

See the public-health workflow vignette with
`vignette("public-health-workflow", package = "agecraft")` after installation
with vignettes. Bundled definitions are legacy reporting conventions rather than
current clinical guidance. Their provenance and limitations are recorded in
`inst/extdata/age-group-provenance.csv` and the `age_group_presets` help page.

``` r
devtools::document()
devtools::test()
devtools::check()
# Optional local reference website (install pkgdown first):
pkgdown::build_site()
```

`Rscript scripts/build.r` only builds a source archive into `build/`.
Version changes and installation are separate explicit steps; see
`scripts/release.md`. CI checks Linux, macOS, and Windows when hosted on GitHub.

## License

MIT (`LICENSE` file).

## Migrating preset references

`age_group_presets` replaces `age.groups`; entry names and cut points are
unchanged. The old list remains available through the next non-development
release. Removal requires a later announced breaking release.

Preview targeted script edits with the installed helper:

```r
tool <- system.file("tools", "migrate-age-groups.R", package = "agecraft")
source(tool)
migrate_age_group_presets("analysis.R")
# Apply reviewed edits, keeping analysis.R.bak:
migrate_age_group_presets("analysis.R", write = TRUE)
```

The helper changes value references to the list, including
`agecraft::age.groups`, and preserves entry selections. Comments and strings
remain untouched; strings, local bindings, member names, and other package
namespaces are flagged for review. It does not perform a general rage migration.
Use it on R scripts; edit R Markdown/Quarto code chunks manually. Existing
backups are never overwritten.

## Changes for users migrating from rage

`agecraft` is a refactor of `rage`. Replace `library(rage)` with
`library(agecraft)` and update package-qualified calls. R >= 4.1.0 is required.

| Previous interface | Current recommendation |
| --- | --- |
| `calc_age()` | `calculate_age()` |
| `age.cat()`, `age_cat()` | `categorize_age()` |
| `age.groups$Yr.5` | `age_group_presets$Yr.5` |
| Label or interval conversion | `as.age_group()` (retained) |
| Direct start/end bounds | `age_group()` (new) |

The wrappers and old preset list remain available through the next
non-development release. Removal requires a later announced breaking release.
`age_cat()` now produces a warning once per session; `calc_age()` and `age.cat()`
retain once-per-session messages. Preset entry names and numeric values are unchanged.

`calculate_age()` returns a units vector. It rejects reversed dates, uses
completed calendar birthdays/month anniversaries, and preserves missing pairs.
Empty recyclable inputs return an empty vector. These behaviors differ from the
original rage code; check analyses that depended on negative ages or month-end
arithmetic. Combining age groups now enforces compatible units, while factor
conversion preserves observation order and missing values.

`categorize_age()` still returns an ordered factor by default. New
`output = "interval"` returns one matched `age_group` per input observation,
including repeated and missing assignments, in the grouping definition's units.
It is not the unique list of group definitions. Advanced `multiple`,
`convert_units`, and `allow_approx` arguments expose the interval matching controls
through the main interface. Interval inputs require complete containment.

```r
groups <- age_group(c(1, 5), c(5, Inf), unit = "year")
ages <- units::set_units(c(2, 7, NA, 2), "year")
categorize_age(ages, by = groups, output = "interval")
```

Age-group bounds remain whole numbers: `[1,5)` prints `1-4`, representing ages
from 1 up to 5 exclusively. Unit-aware formatting adds the unit. Fractional
bounds, negative bounds, and incomplete missing pairs are errors; they are not
rounded. Only upper bounds may be infinite. A scalar upper bound is recycled
to the length of the starts; starts are not recycled. Gaps and overlaps are retained.
`as.age_group()` remains the converter for labels, factors, cut points and intervals.

Weeks are opt-in, so existing automatic-unit results retain their defaults:

```r
birth <- as.Date("2024-01-01")
event <- birth + c(6, 7, 28, 31, 366, NA)
age_auto_unit(birth, event, allowed_units = c("day", "week", "month", "year"))
tibble::enframe(age_auto_unit(birth, event), name = "age_unit", value = "age")
```

With weeks enabled, selection uses completed years, then calendar months, then
completed weeks, then days. The result remains a named numeric vector. This
value/unit pattern supports surveillance records where 6 days, months and years
have different meanings. Hours remain unsupported in automatic selection.

`compare_age_groups()` adds crosswalks, definite/possible membership, ordering,
age-gap bounds, coverage intersection/union/difference, and width. Both sides
must have identical units (or both be unitless). See
`vignette("age-range-comparisons", package = "agecraft")` for genealogy,
sociology and economics examples. Crosswalks cannot redistribute aggregate
counts without additional information. Calendar shifting and a general rage
script converter remain future work.
