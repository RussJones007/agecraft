# `age_interval` architecture and behavioral contract

> Phase-one naming refactor (2026-11-12): interval vectors use `age_interval`;
> categorical assignments remain `age_category`. See
> [the migration guide](age_class_naming_migration.md) for compatibility changes.


**Package:** `agecraft`\
**Status:** Phase-one interval contract on `refactor/age-class-names`, reviewed 2026-11-12. The former interval class name was `age_group`.\
**Primary sources:** `R/age-interval-class.R`, `R/age-interval-coerce.R`, `R/age-interval-classify.R`, `R/age-interval-print.R`, `R/age-interval-compare.R`, `R/Age_calculation.r`, `API_POLICY.md`, and `CURRENT_STATE.md`.

## 1. Purpose and position in the architecture

`age_interval` is Agecraft's existing **S3 vector class for age intervals**. It builds on `ivs` interval vectors and participates in `vctrs` operations. It represents one or more age ranges with numeric boundaries, an optional common age unit, display symbols, and optional names for individual groups.

It is **not** an age-classification scheme: it does not, by itself, assert a source, reporting purpose, publication date, partition status, or completeness of coverage. The implemented `age_scheme` **contains** an `age_interval` vector and supplies that higher-level information, without subclassing or replacing `age_interval`.

``` text
age_scheme  [implemented: scheme identity, provenance, constraints]
    └── age_interval  [implemented: interval vector, names, units]
            └── ivs interval representation + vctrs methods
```

## 2. Interval model and invariants

Intervals are **left-closed, right-open**: `[start, end)`. For completed whole-year ages, `[1, 5)` corresponds to ages 1–4; `[85, Inf)` means 85 and older. The stored bounds, not the printed labels, determine membership.

The validated constructor enforces:

- Numeric double endpoints; finite endpoints are nonnegative.
- Only an upper endpoint may be `Inf`.
- Each present interval has `start < end`.
- Missing intervals have **both** endpoints missing; a single missing endpoint is invalid.
- Fractional bounds are preserved, not rounded.
- The upper endpoint is exclusive, including for fractional ages.
- Intervals in a vector may have **gaps or overlaps**; neither completeness nor exclusivity is intrinsic to the class.
- An optional `unit` applies to the **whole vector**, not separately to each interval.

These invariants are implemented by internal `new_age_interval()`, which delegates interval construction to `ivs::new_iv(..., class = "age_interval", ...)`.

### Stored-object structural validation

The private `validate_age_interval()` checks the actual stored interval record:
the core S3 class hierarchy, start/end field layout, equal-length double endpoint
vectors, and optional character `group_names` of the correct length. It then
reuses `new_age_interval()` with the object's actual `symbols` and `unit` attributes
for boundary, missing-pair, scalar-unit and display-symbol validation. Validation
does not coerce fields, recycle endpoints, supply defaults or repair metadata.

Display metadata must contain three scalar nonmissing strings named `below`,
`sep` and `above`. Custom strings, including empty strings, and any ordering of
these named entries remain valid. General intervals may be empty, unitless,
missing, or have optional blank/missing names. Schemes apply their additional
nonempty, supported-unit, unique nonblank category and coverage policies after
this structural check. Unrelated user attributes do not become required metadata.
Restoration continues to use the same constructor checks. Structural validation
does not independently verify provenance or source authority.

## 3. Construction and conversion

### Direct construction

The public `age_interval(start, end, unit = NULL, below = "0-", sep = "-", above = "+")` constructor accepts paired bounds. A scalar `end` may be recycled to the number of starts.

``` r
library(agecraft)

groups <- age_interval(
  start = c(0, 1, 5, 18, 65),
  end   = c(1, 5, 18, 65, Inf),
  unit  = "year"
)
names(groups) <- c("Under 1", "1–4", "5–17", "18–64", "65+")
```

### `as_age_interval()` conversion

The existing S3 coercion interface accepts character/factor age labels, numeric cut points, existing `age_interval` values, and bare `ivs` intervals. Numeric cut points must be strictly increasing, nonnegative, and nonmissing. For example, `as_age_interval(c(0, 5, 10, Inf), unit = "year")` produces `[0,5)`, `[5,10)`, and `[10,Inf)`.

**Important legacy distinction:** A finite final numeric cut point without `Inf` creates a final **one-unit interval** under the existing converter. Do not assume a finite cut-point vector implicitly ends at infinity. Use an explicit `Inf` for an open-ended final group. Direct construction is preferable for arbitrary fractional or noncontiguous intervals.

Legacy character strings such as `"<5"`, `"1-4"`, `"85+"`, `"14"`, `"all"`, and `"total"` express completed whole ages. A single age such as `"14"` maps to `[14,15)`. Character parsing is **not** a general parser for fractional interval notation; use numeric bounds or interval conversion for fractional definitions.

## 4. Units and conversions

Supported normalized unit names in the implementation include `second`, `minute`, `hour`, `day`, `week`, `month`, and `year`, with common aliases normalized by `normalize_age_unit()`.

- An `age_interval` may be unitless (`unit = NULL`), but that is not the same as a verified year-based definition.
- Combining or casting `age_interval` vectors requires matching normalized units, including matching presence/absence of units. Conversion must be explicit.
- When classifying an age vector, **unitless groups inherit the input ages' unit** for that operation.
- Unitless ages cannot be classified against explicitly unit-bearing groups.
- `categorize_age()` and the lower-level matching infrastructure offer `convert_units = "age_to_group"`, `"group_to_age"`, or `"none"`.
- Conversions between month and year, or between either calendar unit and fine elapsed-time units (week/day/hour/minute/second), are potentially approximate and require `allow_approx = TRUE`.
- `compare_age_intervals()` requires identical units and performs **no implicit conversion**.

Calendar ages and elapsed durations are not interchangeable. A scheme that needs year, month, or day boundaries should state the intended age measurement and unit explicitly.

## 5. Group names, labels, and display

`age_interval` uses `names(x)` and `names(x) <- value` to expose **group names**. Internally these are stored in a `group_names` attribute because the `ivs`/`vctrs` record representation reserves physical field names.

- Nonblank names become category labels; blank or missing names fall back to formatted interval labels.
- Distinct intervals must have unique resulting classification labels, to prevent unintended merging.
- Names **do not** affect interval equality or chronological ordering.
- Whole-number intervals use completed-age notation (`1-4`, `85+`); fractional endpoints use explicit right-open notation (`[0, 0.077)`).
- Display customization uses the `below`, `sep`, and `above` symbols; these are presentation metadata, not interval semantics.

`format.age_interval()`, `print.age_interval()`, `as.character.age_interval()`, and factor coercion methods provide display and label behavior. `age_interval_to_char()` remains exported for compatibility, but `as.character()` is preferred in new code.

Standalone printing shows `<age_interval (year) [10]>`, for example, with the common
unit once in the header and no unit suffix on individual intervals. Unitless
vectors show `unknown`. `format()` returns interval labels without unit suffixes.

## 6. Vector behavior and metadata

The class implements `vctrs` prototype, restoration, cast, common-type, proxy, equality, and comparison methods, as well as `ivs` restoration. The design intent and documented behavior are:

- Preserve bounds, units, and applicable group names through ordinary slicing, sorting, concatenation, and compatible casts/binding.
- Reject incompatible units instead of silently discarding or converting them.
- Normalize conflicting display symbols to canonical defaults when combining compatible vectors.
- Compare interval identity by bounds, not group names.
- Allow explicit casting to bare `ivs` intervals, with loss of age-specific metadata.
- Drop group names from coverage set operations that can merge or split intervals; newly produced intervals must not inherit potentially misleading labels.

These are behavioral contracts to retain when extending `age_interval`. Do not attach scheme-level provenance to individual vector elements or assume that arbitrary interval transformations preserve a source scheme's identity.

## 7. Classification of ages

`categorize_age()` is the primary public classification workflow. It accepts numeric widths, numeric cut points, or an `age_interval` vector as `by`. It sorts groups by interval order and uses `ivs` matching functions.

``` r
ages <- c(0, 4, 5, 17, 18, 65)
labels <- categorize_age(ages, by = as_age_interval(c(0, 5, 18, 65, Inf)))
```

Current behavior:

- Default `output = "factor"` returns an **ordered factor**.
- `output = "interval"` returns the matched `age_interval` interval per observation.
- Unmatched and missing ages produce missing assignments.
- The default `multiple = "error"` rejects ages that match more than one group.
- `multiple = "first"` and `"last"` resolve multiple matches in **sorted interval order**, not necessarily the caller's original input order.
- Classification uses the actual fractional age value, even when an `age` vector displays completed whole units.
- Interval-valued ages use containment matching, rather than pretending an age interval is a single point.

`age_cat_iv()` is an existing exported S3 generic/matching interface; the package's primary workflow, per `API_POLICY.md`, favors `categorize_age()`. Do not create a competing classification implementation for `age_scheme`: adapt or delegate to the existing matching behavior.

**Overlapping classifications:** An `age_scheme` may contain overlapping groups. The default single-assignment factor output still errors on multiple matches; use `classify_age_scheme()` for explicit all-membership output.

## 8. Comparing age groups

`compare_age_intervals(x, y, operation = ...)` currently provides:

- `crosswalk`: pairwise intersections with source labels and interval bounds;
- `membership`: definite containment or possible overlap;
- `ordering`: before, after, or unresolved;
- `age_gap`: possible real-valued differences with exclusive gap bounds;
- `intersection`, `union`, `difference`: overall interval coverage operations;
- `width`: interval width in the age coordinate unit.

Pairwise comparisons can produce `length(x) * length(y)` rows before filtering. Set operations represent **coverage**, not a labeled category-to-category crosswalk. Comparisons do **not** allocate population counts or infer how totals should be split when age bands only partially overlap.

For `tarr.pop` or other aggregate population systems, do not reallocate counts between incompatible age partitions without sufficiently fine source data or an explicitly documented modeling assumption.

## 9. Legacy presets and the implemented `age_scheme`

`age_interval_presets` remains a named list of numeric cut points and `age.groups`
remains its compatibility alias. The eight presets are unchanged. Equivalent
unit-bearing schemes are now available through `get_age_scheme()` and
`list_age_schemes()`, recording uncertainty from
`inst/extdata/age-group-provenance.csv`. They are not verified current standards.

The S3 `age_scheme` contains the existing interval vector plus identity, purpose,
provenance, and validation policy. It distinguishes partitions from potentially
overlapping classifications. Completeness is separately checked against a domain.
`categorize_age()` now accepts a scheme through its `by` argument without changing
existing defaults. `classify_age_scheme()` returns all memberships explicitly.
See `docs/age_scheme.md` section 15 for the implemented contract.

## 10. Tests and change-management requirements

When changing the class or its methods, add or update `testthat` tests covering:

- Boundary inclusion/exclusion, fractional endpoints, `Inf`, gaps, overlaps, missing pairs, and empty vectors.
- Direct construction versus numeric cut-point and legacy character conversion.
- Named group labels, fallback labels, duplicate-label rejection, and equality independent of names.
- Slicing, sorting, concatenation, casting, data-frame binding, and preservation/loss of metadata as specified.
- Matching age values exactly at boundaries, missing/unmatched ages, interval-valued ages, and multiple-match policy.
- Explicit unit conversion and rejection of incompatible or approximate conversions without permission.
- Pairwise crosswalk semantics, coverage set operations, and protection against inferred aggregate count allocation.
- Scheme validation, legacy preset parity, and classification with overlapping groups.

Relevant existing test files include `tests/testthat/test-age-interval.R`, `test-age-interval-contract.R`, `test-age-interval-compare.R`, `test-fractional-groups.R`, `test-named-groups.R`, `test-vector-metadata.R`, `test-categorize-output.R`, and `test-presets-migration.R`.

Run `devtools::test()` and `devtools::check()` after implementation changes. The repository's `CURRENT_STATE.md` reports prior successful checks, but those are historical results, **not** a claim that this documentation review reran them.

## 11. Source-of-truth and known documentation cautions

In case of disagreement, follow `API_POLICY.md` for public behavior and compatibility; inspect implementation and tests to establish what currently happens. `CURRENT_STATE.md` is a dated status snapshot, not a substitute for source inspection.

The roxygen text in `R/age-interval-coerce.R` still contains some older explanatory wording for character ranges and numeric cut points. In particular, do not infer from older examples that displayed `"5-10"` is always a stored `[5,11)` interval: **numeric cut points and character completed-age labels have different conversion rules**. Also, the general `age_interval` class allows overlaps and gaps even though numeric cut-point conversion produces contiguous groups.

## Age-category assignments — 2026-11-11

`categorize_age(output = "factor")` now returns `age_category`, an ordered-factor
subclass with level-aligned `age_interval` definitions accessed by `category_intervals()`.
Readable labels, codes, unused categories, missing assignments and matching rules
are retained. This intentionally changes exact class and attribute comparisons.
Interval output and `age_cat_iv()` are unchanged. Original ages and scheme
provenance are not stored. Unitless definitions inherit observation units.

Subsetting preserves definitions; explicit `droplevels()` removes unused levels
and intervals together. Combining requires matching ordered bounds, labels and
definition units. Conflicting display symbols normalize to package defaults.
Unique nonblank relabeling updates group names; implicit merging or reordering
is rejected. Structural changes require a new definition and reclassification.

Use `vctrs::vec_rbind()` for validated binding. Base `rbind.data.frame()` can
rebuild factor columns and discard metadata. Use `generics::as.factor()` or
`generics::as.ordered()` for ordinary factors; base coercers retain existing
factor subclasses. Differing legacy observation-unit attributes are dropped on
combination; category definition units must always match. See `age_category.md`.
