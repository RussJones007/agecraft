# Migrating age intervals and age groups

Use `age_interval` for bounded age ranges and `age_group` for assigned
categories. An `age_scheme` combines named intervals with reporting metadata.
The naming refactor was implemented in two phases on the same branch.

## Function and data names

| Before the refactor | Phase one | Final name |
| --- | --- | --- |
| Interval age_group() | age_interval() | age_interval() |
| as.age_group() | as_age_interval() | as_age_interval() |
| is.age_group() | is_age_interval() | is_age_interval() |
| compare_age_groups() | compare_age_intervals() | compare_age_intervals() |
| age_group_to_char() | age_interval_to_char() | age_interval_to_char() |
| valid_age_group_symbol() | valid_age_interval_symbol() | valid_age_interval_symbol() |
| scheme_groups() | scheme_intervals() | scheme_intervals() |
| Assignment age_category() | age_category() | age_group() |
| is_age_category() | is_age_category() | is_age_group() |
| category_groups() | category_intervals() | group_intervals() |
| age_group_presets | age_interval_presets | age_interval_presets |

`age_group()` has a different meaning from the old interval constructor. Supply
labels and their definitions, not lower and upper bounds. The class is an ordered
factor with level-aligned intervals. Use `age_interval()` to construct ranges.
The phase-one assignment function names are not retained as aliases.

The data names `age_group_presets` and `age.groups` remain identical aliases of
`age_interval_presets`. `age_cat()`, `age.cat()` and `calc_age()` retain their
existing deprecation policy. `age_cat_iv()` retains its ordinary factor output;
`categorize_age()` returns `age_group` unless interval output is requested.

## Construct and classify

```r
intervals <- age_interval(c(0, 5, 18), c(5, 18, Inf), unit = "year")
names(intervals) <- c("Under 5", "5–17", "18+")
scheme <- age_scheme(intervals = intervals, id = "example", name = "Example")
result <- categorize_age(age(c(3, 12, 44)), by = scheme)
group_intervals(result)
scheme_intervals(scheme)

# Use the constructor when labels have already been assigned.
recorded <- age_group(c("Under 5", "18+", NA), intervals = intervals)
```

Use `intervals =` instead of the pre-refactor `groups =` in `age_scheme()` and
the assignment constructor. Use `intervals =` instead of `age_group =` in
`age_cat_iv()`. The scheme field and assignment metadata attribute are named
`intervals`; prefer the accessors above. Conversion option strings
`age_to_group`/`group_to_age`, factor levels and classification result columns
retain their meanings and names. Scheme intervals remain `age_interval` vectors.

## Existing scripts and saved objects

Review scripts for constructor calls, class checks, accessors, named arguments,
methods and direct metadata access. The installed script at
`system.file("tools", "migrate-age-groups.R", package = "agecraft")` provides
`migrate_age_interval_presets()` for preset names only. Preview is the default;
`write = TRUE` creates backups. It does not migrate classes or saved objects.

An old interval record carrying `age_group` is not a categorical assignment.
`is_age_group()` returns FALSE for it, and dispatched group methods report a
migration error. The predicate distinguishes the representations; it is not a
complete metadata validator. Not every base or inherited operation can be
intercepted, so reconstruct saved objects before use.

Load saved objects with their producing package version and export primitive
components: interval starts/ends, unit, names and display symbols; factor labels,
complete level definitions and observation names/units; and scheme fields
including source, verification and derivative ancestry. Rebuild intervals with
`age_interval()` and restore their names. Reconstruct assignments with
`age_group(labels, intervals)` and schemes with `age_scheme(intervals = ...)`.
Preserve unused levels, missing values and scientific metadata. Retain the
original files until rebuilt objects have been checked.

Phase-one `age_category` objects already contain `age_interval` definitions,
but still require reconstruction with `age_group()`. Do not merely change class
attributes. Reading an RDS file does not upgrade nested definitions, field names
or factor codes. No automatic upgrader is supplied. Avoid reconstructing an old
scheme through ordinary replacement setters, which track substantive derivatives;
check ancestry separately because `derived_from` is protected by those setters.
