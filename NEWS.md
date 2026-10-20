# agecraft 0.1.0.9013

## Date calculation returns age vectors

- Change `calculate_age()` to return the fractional `age` class by default.
  Add `output = c("age", "units", "numeric")`: `units` preserves the previous
  completed-age units output and `numeric` returns completed ages as doubles.
  `as.numeric()` on the default result now extracts fractions; `as.integer()`
  extracts completed units. This is an intentional development API change.
- Calculate fractional years using completed birthdays plus elapsed civil days
  between consecutive birthdays, and fractional months using calendar month
  anniversaries. Anchor both anniversaries to the original birth date. Preserve
  March 1 for leap birthdays in non-leap years and end-of-month rollback for
  shorter months. Calendar calculations use the start time zone and ignore time
  of day; finer units retain fractional elapsed time, including daylight saving.
- Preserve the completed-unit output formats of `calc_age()` and `age_auto_unit()`.
  Document migration choices and end-to-end fractional named-group classification.

## Fractional age vectors

- Add the numeric S3 `age` class using vctrs, with fractional precision and one
  explicit time unit per vector. Export `age()`, `as_age()`, and `is_age()`.
  Normalize common time-unit aliases; reject negative, infinite, nonnumeric,
  multidimensional, and unsupported-unit inputs while retaining missing ages.
- Display completed whole units by default without truncating stored values.
  Use `format(x, fractional = TRUE)` for fractional display, `as.numeric()` for
  full-precision extraction, and `as.integer()` for completed units.
- Preserve units, names and precision through vector slicing, sorting, repetition,
  concatenation, casts, and data-frame binding. Combining and comparing age
  vectors requires matching units; bare numbers are not implicitly combined.
- Convert numeric ages and time-units vectors with `as_age()`. Require explicit
  unit conversion and guard approximate month/year-to-finer-unit conversions
  with `allow_approx`. Means, extrema and rounding retain the class; unsupported
  arithmetic and mathematical transformations require explicit numeric extraction.
- Integrate `age` vectors with `categorize_age()` and `age_cat_iv()`, including
  fractional named groups, unit alignment, missing and unmatched observations,
  and interval output. Classification always uses the stored fractional values.
- Document numeric construction, date-based calculation, display, extraction,
  and the distinction between calendar fractions and approximate unit conversions.
- Add regression coverage for class validation, precision, display, metadata,
  conversions, calendar fractions, elapsed time, output options, compatibility,
  missing and empty inputs, and named-group classification. All 416 assertions
  pass. The 0.1.0.9013 built-package check, examples and vignettes pass with zero
  errors and warnings; remote clock verification produces one environment note.

# agecraft 0.1.0.9012

## Fractional age groups

- Allow fractional nonnegative endpoints in `age_group()`, internal construction,
  numeric `as.age_group()` cut points, interval conversion, and casts. Preserve
  bounds without rounding; retain validation of negative, reversed, infinite,
  and incompletely missing bounds.
- Display intervals with fractional endpoints using explicit right-open notation,
  such as `[0, 0.077)`, while preserving existing whole-number age labels.
  Fractional numeric widths and cut points also work in `categorize_age()`.
  Legacy character input continues to describe whole completed ages.

## Named categories

- Support reading, assigning, and clearing category names with `names()`.
  Preserve names through slicing, sorting, repetition, concatenation, data-frame
  binding, casts, and conversion of existing age groups. Names do not affect
  interval equality or ordering; interval set operations discard names because
  they may create different intervals.
- Use nonblank category names as ordered-factor labels in `categorize_age()`
  and `age_cat_iv()`, and as labels in `generics::as.factor()` and
  `generics::as.ordered()`. Missing or blank names fall back to interval labels.
  Reject label collisions between distinct intervals to prevent silent merging
  of factor levels. Preserve chronological level ordering and existing handling
  of missing, unmatched, and multiply matched observations.
- Preserve matched category names in `categorize_age(output = "interval")`.
  Character conversion continues to describe interval boundaries.
- Add examples for approximate neonatal, infant, toddler, and young-child groups.
  Explain that sub-year classification requires fractional input ages;
  `calculate_age()` and `age_auto_unit()` still return completed units. No new
  calendar-year convention or mixed-unit representation is introduced.

## Validation

- Add regression coverage for exact fractional boundaries, half-open matching,
  missing and unmatched ages, interval operations, named factor labels, label
  collisions, metadata preservation, and unchanged whole-number behavior.
- Full suite: 307 passing assertions. Built-package check, examples, and vignettes
  pass with zero errors and zero warnings; remote clock verification is unavailable
  in the restricted environment and produces one check note.

# agecraft 0.1.0.9011

## Public interface

- Add exported `age_group(start, end, unit = NULL, below = "0-", sep = "-",
  above = "+")` for direct construction from whole-number bounds. Gaps and
  overlaps are retained. Intervals include the lower bound and exclude the upper:
  `[1,5)` prints `1-4`. Only upper bounds may be infinite; fractions are rejected
  without rounding. A scalar end is recycled to the length of start.
- Add `output = c("factor", "interval")` to `categorize_age()`. The default
  remains an ordered factor. Interval output returns a matched `age_group` for
  each observation, preserving input order, repeated assignments, missing and
  unmatched observations, and the grouping definition's units.
- Expose `multiple`, `convert_units`, and `allow_approx` through
  `categorize_age()`, and support interval inputs with complete-containment
  matching. Numeric cut points inherit input age units. Overlap resolution uses
  sorted group order. `age_cat_iv()` remains available with its existing API.
- Retain `age_cat()` with a real once-per-session deprecation warning.
  `calc_age()` and `age.cat()` retain once-per-session messages; all legacy
  guidance now directs users to `calculate_age()` or `categorize_age()`.
  Wrappers remain available through the next non-development release; removal
  requires a later announced breaking release.

## Presets and script migration

- Introduce `age_group_presets` as the preferred name for `age.groups`, retaining
  identical entry names and numeric cut points. `age.groups` remains a
  compatibility alias through the next non-development release; removal requires
  a later announced breaking release.
- Include the targeted `tools/migrate-age-groups.R` helper in the installed
  package. Preview replacements of code references before writing; writes keep
  `.bak` backups and refuse to overwrite existing backups. Preserve comments,
  strings, tabs, and Windows line endings. Flag strings, local bindings, member
  names and other package namespaces for manual review. This helper operates on
  R scripts and does not perform a general rage migration.

## Automatic age units

- Add `allowed_units` to `age_auto_unit()` to opt into weeks while preserving
  the existing day/month/year default and named numeric return structure.
  With weeks enabled, select completed years, then completed calendar months,
  then completed weeks, otherwise days. Missing ages retain blank unit names.
- Explain the surveillance value/unit use case and add a `tibble::enframe()`
  example with `age_unit` and `age` columns. Automatic hours remain unsupported.

## Interval analysis

- Add `compare_age_groups()` with operations for source-labelled crosswalks,
  definite/possible membership, definite ordering, possible age-gap bounds,
  coverage intersection/union/difference, and interval widths.
- Crosswalks retain both source row identifiers and labels and nonempty
  intersections. Optionally retain empty/missing pairs with explicit status.
  Coverage set operations may merge touching groups while preserving gaps.
- Definite membership requires containment; possible membership requires
  nonempty overlap. Optional warnings or errors flag multiple memberships and
  unresolved ordering. Touching right-open intervals do not overlap.
- Age-gap bounds describe the second age minus the first, with exclusive
  endpoints and explicit units. Widths use the age-coordinate unit rather than
  inferring elapsed calendar durations. Comparisons require matching units.
- Explain that crosswalks cannot allocate aggregate counts without additional
  data or assumptions. Calendar shifting remains deferred pending explicit
  reference-date semantics.

## Validation and documentation

- Validate nonnegative whole-number endpoints and metadata, reject malformed
  and fractional labels/cuts, and require both endpoints of missing intervals
  to be missing. Handle empty and scalar conversions; reject unordered,
  duplicate and missing numeric cut points.
- Preserve missing character, factor, and interval observations and existing
  display metadata. Missing formatted ages do not acquire unit text. Include
  units in full vector type names and accept the documented `plus` suffix.
- Keep temporary fractional unit-conversion boundaries separate from stored
  age groups, preserving original labels without rounding.
- Expand the README migration guide, retain S3 infrastructure and compatibility
  exports, update preset references, and add genealogy, sociology and economics
  worked examples with explicit units, endpoints, uncertainty and reference dates.
- Add regression tests covering constructor contracts, both categorization
  outputs, unit negotiation, migration edits, automatic weeks and comparisons.

# agecraft 0.1.0.9010

* Rename the original rage package to agecraft; require R >= 4.1.0.
* Retain age_group class, units, and display metadata through vector operations.
  Incompatible units and implicit mixing with bare intervals/numbers now fail.
* Preserve observation order during factor conversion; order only factor levels.
* Reject end dates before start dates. Calendar years use March 1 for leap
  birthdays in non-leap years; month anniversaries use the last day of shorter
  months. Document time-zone and daylight-saving behavior.
* Select automatic units with non-overlapping rules: days through day 30,
  then completed calendar years, completed calendar months, or days.
* Fix runnable examples, dependency declarations, partial argument matching,
  and once-per-session deprecation messages. Keep legacy wrappers documented.
* Add regression tests, a public-health vignette, data provenance, portable
  build/release instructions, and an R CMD check CI matrix.
