# Migrating to age intervals: phase one

Use `age_interval` for bounded age ranges and `age_category` for categorical
assignments. An `age_scheme` combines named intervals with reporting metadata.
The `age_group` class and constructor are unavailable in this intermediate phase.

## Function and data names

| Earlier name | Phase-one name |
| --- | --- |
| age_group() | age_interval() |
| as.age_group() | as_age_interval() |
| is.age_group() | is_age_interval() |
| compare_age_groups() | compare_age_intervals() |
| age_group_to_char() | age_interval_to_char() |
| valid_age_group_symbol() | valid_age_interval_symbol() |
| scheme_groups() | scheme_intervals() |
| category_groups() | category_intervals() |
| age_group_presets | age_interval_presets |

The two old data names, `age_group_presets` and `age.groups`, remain available as
identical aliases. Interval functions do not retain aliases under their old names.
`age_cat()`, `age.cat()` and `calc_age()` retain their existing deprecation policy.

## Construct and classify

```r
intervals <- age_interval(c(0, 5, 18), c(5, 18, Inf), unit = "year")
names(intervals) <- c("Under 5", "5–17", "18+")
scheme <- age_scheme(intervals = intervals, id = "example", name = "Example")
result <- categorize_age(age(c(3, 12, 44)), by = scheme)
category_intervals(result)
scheme_intervals(scheme)
```

Use `intervals =` instead of `groups =` in `age_scheme()` and `age_category()`.
Use `intervals =` instead of `age_group =` in `age_cat_iv()`. Positional calls
retain their argument order. The scheme's stored field and the category's
metadata attribute are also named `intervals`; prefer the accessors above.
Conversion option strings `age_to_group`/`group_to_age`, factor levels and
classification result columns retain their meanings and names.

## Existing scripts and saved objects

Review scripts for constructor calls, class checks, accessors, named arguments,
methods and direct metadata access. The installed script at
`system.file("tools", "migrate-age-groups.R", package = "agecraft")` provides
`migrate_age_interval_presets()` for preset names only. Preview is the default;
`write = TRUE` creates backups. It does not migrate class names or saved objects.

Load saved objects in a session using the old package version and export primitive
components: interval starts/ends, unit, optional names and display symbols; factor
labels, complete level definitions and observation names/units; and scheme fields
including source, verification and derivative ancestry. In a new-version session,
rebuild intervals with `age_interval()`, restore their names, then reconstruct
categories with `age_category()` and schemes with `age_scheme(intervals = ...)`.
Preserve unused levels and missing values. Record which package version produced
the old object and retain the original file until the rebuilt result is checked.

Do not merely change an object's class attribute. Reading an old RDS file does
not migrate nested definitions or stored fields. This phase provides no automatic
object upgrader. Reconstruction must preserve scientific metadata; avoid editing
old schemes through replacement setters, which track substantive derivatives.
Check ancestry separately if restoring a derived scheme because `derived_from`
is protected by ordinary replacement methods.

Phase two will reuse `age_group` for assignments. Migrate old interval objects
before using that release: the same class spelling will represent a different
kind of data.
