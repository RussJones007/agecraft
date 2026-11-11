# Public interface and compatibility

## Primary workflow

The main workflow uses `calculate_age()`, `age()`, `as_age()`, `is_age()`,
`categorize_age()`, `age_group()`, `as.age_group()`, `is.age_group()`,
`age_auto_unit()`, and `compare_age_groups()`. Registered S3 methods remain
infrastructure. `age_group_to_char()` and `valid_age_group_symbol()` stay exported
for compatibility; use `as.character()` and `as.age_group()` in new code.

## Age precision and return formats

`calculate_age()` defaults to `output = "age"`, retaining fractional precision
with one explicit time unit per vector. Printing displays completed whole units;
`as.numeric()` extracts the fractions and `as.integer()` extracts completed units.
Years and months use calendar anniversaries; finer units use elapsed time.

This default changed during development in 0.1.0.9013. Use `output = "units"`
for the previous completed-age units vector or `output = "numeric"` for plain
completed ages. `calc_age()` and `age_auto_unit()` retain completed-age outputs.
Converting those completed values to `age` cannot recover discarded fractions.

Age values must be nonnegative and finite, or missing. Combining and comparing
age vectors requires matching units; use `as_age()` to convert explicitly.
Conversions between month and year, or between either calendar unit and finer
units, require `allow_approx = TRUE`
and do not reconstruct exact elapsed time from the original dates.

## Age-group bounds and names

Age-group bounds may be nonnegative whole numbers or fractions. Fractional
bounds are preserved without rounding in direct construction, numeric cut points,
and supported interval conversions. Only upper bounds may be `Inf`. Missing
intervals require both bounds to be missing; reversed bounds are rejected.

Intervals include their lower bound and exclude their upper bound. Whole-number
intervals retain completed-age labels: `[1,5)` is labelled `1-4`. Intervals with
fractional bounds use explicit right-open notation, such as `[0, 0.077)`.
Legacy character input continues to describe whole completed ages; use numeric
bounds or intervals for fractional definitions.

Group names are optional. Nonblank names supply ordered-factor labels; blank or
missing names fall back to interval labels. Distinct intervals must have unique
resulting labels to prevent categories from silently merging. Names do not change
interval equality or ordering. Vector operations preserve names and units;
coverage set operations discard names because they may merge or split intervals.

Classification uses stored fractional values, regardless of the displayed age.
`categorize_age()` defaults to ordered-factor output; `output = "interval"`
retains matched intervals and category names per observation. Missing and
unmatched ages return missing assignments. Multiple matches error by default;
`multiple = "first"` or `"last"` resolves them in sorted interval order.

Unspecified group units inherit the input ages' unit for classification.
Unitless ages with explicitly unit-bearing groups are rejected. When specified
units differ, `convert_units` chooses conversion of ages or groups, or rejects
conversion with `"none"`. Approximate conversions require `allow_approx = TRUE`.
`compare_age_groups()` requires matching units and does not convert implicitly.

## Compatibility commitments

`age_cat()` warns once per session. `calc_age()` and `age.cat()` retain their
once-per-session messages and direct users to the primary functions. All three
remain available through the next non-development release. `age.groups` remains
a compatibility alias for `age_group_presets` through that release. Removal
requires a later announced breaking release; no removal date is set.

The existing `as.character.ivs_iv()` and `summary.ivs_iv()` registrations are
retained for compatibility. New features operate on `age_group` explicitly and
will not add methods to the bare ivs class.

## Age schemes

`age_scheme()`, `is_age_scheme()`, `validate_age_scheme()`, `scheme_groups()`,
`classify_age_scheme()`, `get_age_scheme()`, and `list_age_schemes()` are additive
public interfaces. A scheme contains the existing interval vector; it does not
change `age_group` equality or vector semantics. It requires nonempty named
intervals with an explicit supported time unit. Partitions prohibit overlaps;
coverage is independently checked against an optional right-open domain.
`complete = TRUE` or FALSE asserts actual completeness/incompleteness and requires
a domain; NA makes no claim.

`categorize_age(..., by = scheme)` retains its existing default outputs and
multiple-match policy. `classify_age_scheme()` explicitly returns every match in
a long data frame, with original observation/category indices and separate
missing/unmatched statuses. Present negative or nonfinite numeric ages are
rejected by the new all-membership interface. Intervals require full containment.
Unit-bearing schemes do not silently assign units to plain numeric observations.
Existing explicit conversion and approximation controls apply.

The initial registry contains eight legacy schemes with year units and stable
`legacy_` identifiers. It preserves preset boundaries and provenance uncertainty;
legacy numeric lists and aliases retain their existing behavior. Verification
metadata records a caller's claim, not external validation by the constructor.
Scheme transformations have no automatic provenance-retention contract; construct
and validate a new scheme after changing its definition.

## Calendar conversion safeguard — 2026-11-11

Month-to-year and year-to-month conversion now require explicit approximation
consent in `as_age()`, `categorize_age()`, `age_cat_iv()`, and
`classify_age_scheme()`, including conversion of observations or boundaries.
This intentionally tightens the public default: previous calls must supply
`allow_approx = TRUE` to retain numerical unit-factor conversion. Calendar month
and year coordinates cannot generally be converted exactly without the original
dates. Near boundaries, conversion can classify differently from calculating age
directly in the target unit. For exact calendar classification, calculate age
from original dates in the scheme's unit. Matching units and supported
elapsed-time conversions retain existing behavior. No date or calculation-basis
metadata is added to `age`.
