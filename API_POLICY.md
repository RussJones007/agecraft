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
Conversions between months/years and finer units require `allow_approx = TRUE`
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
