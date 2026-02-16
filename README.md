# rage

<!-- badges: start -->

![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)

<!-- badges: end -->

`rage` is an R package for age-focused data work:

-   calculate ages from dates or date-times in multiple units
-   represent age groups with a dedicated S3 class (`age_group`)
-   categorize ages into ordered age-group factors
-   reuse common public-health age-group definitions

## Why this package

Age data often needs consistent handling across analysis steps. `rage` provides a single workflow for:

1.  computing age from time values
2.  converting between human-readable age labels and interval-based age groups
3.  assigning individuals or events into standard age categories

Internally, `age_group` is built on [`ivs`](https://davisvaughan.github.io/ivs/) intervals, so age ranges behave like first-class interval vectors. Age units are provided by the [`units`](https://r-quantities.github.io/units/) package.

## Installation

`rage` is not currently on CRAN.

Install from a local checkout:

``` r
# from the project root
install.packages(".", repos = NULL, type = "source")
```

Or install from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("russjones007/rage")
```

For development from a local clone:

``` r
# install.packages("devtools")
devtools::load_all()
```

## Quick Start

``` r
library(rage)

# Calculate age in years
birth_dates <- as.Date(c("1980-04-14", "2000-01-02", "2018-11-30"))
ref_date <- as.Date("2025-12-25")
age_years <- calculate_age(start = birth_dates, end = ref_date, unit = "year")
age_years

# Categorize ages using included definitions
categories <- categorize_age(ages = as.numeric(age_years), by = age.groups$Annual)
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
-   `age_auto_unit(birth, event)`

Also exported:

-   `age_cat()` is an alias of `categorize_age()`
-   `calc_age()` is a deprecated wrapper for `calculate_age()`

## Included age-group definitions

The package includes `age.groups`, a named list of commonly used cut points:

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
library(rage)

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
categories <- categorize_age(ages = ages, by = age.groups$Annual)
categories

# 5) Preserve units when categorizing
age_days <- calculate_age(start = as.Date("2025-01-01"), end = as.Date("2025-02-15"), unit = "day")
age_days
categorize_age(ages = age_days, by = c(0, 7, 14, 30, 60, Inf))
```

## Notes

-   Inputs to `calculate_age()` must be either both `Date` or both `POSIXct`.
-   Vector lengths are recycled in `calculate_age()` when one side has length 1.
-   The age can be easily changed from one unit to another, e.g., ix is in "days" then units(x) \<- "month", recalculates the number to match value to the new number of months. .
    -   Converting between some time units (especially month/year) is approximate; prefer calculating directly in the unit you need.

## License

MIT (`LICENSE` file).
