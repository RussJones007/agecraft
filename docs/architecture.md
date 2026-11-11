# Agecraft architecture

**Status:** Living architecture and implementation guide\
**Reviewed:** 2026-11-10\
**Repository:** `RussJones007/agecraft`, default branch `main`\
**Baseline:** `CURRENT_STATE.md` dated 2026-11-09; `DESCRIPTION` version `0.1.0.9014`

> **Reading rule:** Sections marked **Current** describe the checked-in implementation and its documented contracts. Sections marked **Proposed** describe agreed direction or open design choices; they are **not** implemented APIs. `API_POLICY.md` governs existing public compatibility commitments. `CURRENT_STATE.md` records implementation and validation status. This document must not silently override either.

## 1. Mission and scope — Current

Agecraft is an R package for calculating ages from dates and date-times, preserving fractional age values and explicit time units, defining age ranges, classifying ages into groups, and comparing interval coverage. Its principal users include public-health surveillance, epidemiology, demography, education, and population research; the underlying abstractions are general-purpose.

The package is an **experimental**, S3/vctrs-oriented R package (R >= 4.1.0). It uses `ivs` for age-group intervals and `units` for explicit conversion. It is **not** an S4 or DelayedArray package; integration with `tarr.pop` should preserve the latter's lazy, dimension-safe behavior without moving those responsibilities into Agecraft.

## 2. Conceptual layers

| Layer | Current representation | Responsibility |
| --- | --- | --- |
| Age calculation | `calculate_age()` and `age_auto_unit()` | Compute age from birth/reference dates under documented calendar and elapsed-time rules |
| Age value | S3 `age` vector (`age()`, `as_age()`, `is_age()`) | Compact numeric observations with fractional precision and one unit per vector |
| Age interval | S3 `age_group` vector built on `ivs` | Right-open interval boundaries, names, units, matching, comparisons, set operations |
| Classification | `categorize_age()`, `age_cat_iv()` | Match ages or interval observations to group intervals, return factors or intervals |
| Reusable definitions | `age_group_presets` (legacy alias `age.groups`) | Numeric cut points for eight conventional reporting groupings |
| Scheme | S3 `age_scheme` object | Compose an `age_group` vector with purpose, validation policy, provenance, and registry identity |

**Design principle:** An `age_scheme` **contains** an `age_group` vector. It does not inherit from `age_group` or replace the `ivs` interval engine. Schemes are small definitions shared across many observations, not an additional per-observation vector class.

## 3. Age calculation and `age` vectors — Current

- `calculate_age(start, end, unit, output = "age")` returns a fractional `age` vector by default. Its display shows completed whole units; `as.numeric()` retrieves stored fractions and `as.integer()` completed units.
- `output = "units"` returns the older completed-age `units` representation; `output = "numeric"` returns plain completed ages. The older `calc_age()` wrapper and `age_auto_unit()` continue to return completed values. Lost fractions cannot be recovered by coercion.
- Age values are nonnegative, finite, or missing. Each `age` vector has one explicit unit. Combining/comparing incompatible units requires explicit conversion.
- Years/months use calendar anniversaries; finer units use elapsed time. Calendar calculation uses civil dates in the start time zone and ignores time of day. Leap-day birthdays advance on March 1 in non-leap years; month-end anniversaries roll back to the last day of shorter months.
- Month/year conversions in either direction, and calendar-versus-finer-unit conversions, are potentially approximate and require `allow_approx = TRUE`. A converted value does not reconstruct the original dates.
- `age_auto_unit()` defaults to day/month/year reporting and optionally supports weeks. Automatic hours and calendar shifting remain deferred.

**Implication for schemes:** Classify the *stored fractional value*, not the rounded display. Do not assume a universal exact mapping between age in months and age in days. A mixed-unit surveillance input column requires deliberate normalization or a separate classification workflow; a single `age` vector does not have per-element units.

## 4. `age_group` intervals — Current

`age_group(start, end, unit = NULL, ...)` uses `ivs::new_iv()` through the package's validated constructor. The interval convention is **`[start, end)`**: lower inclusive, upper exclusive. `[1,5)` represents completed ages 1–4; fractional boundaries are retained and displayed as explicit interval notation, e.g. `[0, 0.077)`.

- Finite starts are nonnegative; only upper ends may be `Inf`; missing intervals have two missing endpoints; reversed or zero-width bounds are rejected.
- Gaps and overlaps are valid *interval data* and are preserved. `age_group` does not itself promise an exhaustive or disjoint partition.
- A vector has one normalized unit, or an unspecified unit. Unit metadata is maintained by the documented vector operations. Explicit mismatches are not silently ignored.
- `names()` exposes optional observation/group names (internally `group_names`), distinct from the `ivs` record's physical field names. Nonblank names become factor labels; blank/missing names fall back to formatted intervals. Distinct intervals cannot silently share a classification label.
- Equality and ordering depend on interval bounds, **not names**. Slicing, sorting, concatenation, casts, and supported bindings retain names and units. Coverage set operations may merge/split intervals and therefore discard names.
- The implementation includes vctrs proxy/restore methods, `ivs` restoration, formatting, factor/ordered-factor coercion, and explicit interval comparison operations.

**Preserve this class and its `ivs` basis.** New scheme behavior should delegate to existing interval functions where possible rather than reimplement interval containment or boundary semantics.

## 5. Classification and comparison — Current

`categorize_age()` accepts numeric cut points, widths, or `age_group` definitions. It classifies using fractional age values and supports ordered-factor output (default) or matched `age_group` intervals (`output = "interval"`). Missing or unmatched observations remain missing.

- Overlapping matches **error by default**; `multiple = "first"` or `"last"` selects in sorted interval order.
- Unspecified group units inherit the input ages' unit; unitless ages cannot be matched to explicitly unit-bearing groups without resolution. `convert_units` governs direction/denial of conversion; month/year conversions and approximate calendar-to-finer conversions require explicit permission.
- `compare_age_groups()` provides crosswalk, definite/possible membership, ordering, age-gap bounds, coverage intersection/union/difference, and widths. It requires matching units and performs **no implicit conversion**.
- Pairwise comparisons can produce `length(x) * length(y)` rows. Crosswalks express possible/definite interval relationships, **not allocation of aggregate counts**. Splitting an aggregated band into finer bands is not justified without additional data or assumptions.

**Analytical safety:** Overlapping classifications cannot be treated as additive partitions. For population denominators, incidence rates, or other summed quantities, validate disjointness and coverage separately from whether the intervals are individually valid.

## 6. Preset definitions and provenance — Current

`age_group_presets` is a named list of numeric cut points used by `categorize_age()` or `cut()`. The legacy `age.groups` is an identical compatibility alias. Documented entries:

| Key | Described purpose |
| --- | --- |
| `ILI` | Legacy ESSENCE/CDC influenza-like illness reporting groups |
| `IMM` | Immunization reporting |
| `Yr.5` | Five-year bands |
| `Yr.10` | Ten-year bands |
| `Spec` | Specialized reporting |
| `Annual` | Annual disease report |
| `School` | School-oriented reporting |
| `Covid` | COVID-19 reporting |

These are **historical cut-point conventions**, not necessarily current authoritative CDC/clinical standards. Their original source editions/dates are partly unknown. Preserve cut points unchanged during migration; provenance is recorded in `inst/extdata/age-group-provenance.csv`. Do not infer source authority from the name alone.

## 7. Implemented `age_scheme` layer

`age_scheme()` constructs one S3 metadata object containing a named, nonempty,
unit-bearing `age_group` vector. `is_age_scheme()`, `validate_age_scheme()`, and
`scheme_groups()` identify, validate, and access it. Printing, summary, and
data-frame inspection expose its identity, bounds, unit, provenance, coverage,
gaps, and overlaps. Metadata is stored once per definition, not per observation.

A validated `type` distinguishes nonoverlapping partitions from classifications
that may overlap. A domain is optional; any `complete = TRUE` or FALSE claim
requires an explicit domain and must agree with actual coverage. Category names
must be nonblank and unique. Unit and coordinate metadata live in `groups`.
There are no automatic provenance-preserving scheme transformations.

`categorize_age(..., by = scheme)` extracts groups and retains current factor,
interval, overlap-resolution, and unit-conversion behavior. The function remains
a regular function, not a new S3 generic. `classify_age_scheme()` explicitly
returns all memberships, preserving original observation/category indices and
distinguishing missing from unmatched observations. Both use the same private
interval matching helper. Unitless observations are not silently assigned years.

`get_age_scheme()` and `list_age_schemes()` expose eight legacy definitions via
private factories using existing packaged cut points and provenance. The numeric
presets and alias remain unchanged. These schemes use explicit year units and
record uncertain source editions rather than claim current official authority.
Published definitions beyond this registry require separate verification.

The source modules are `R/age-scheme-class.R`, `age-scheme-validation.R`,
`age-scheme-methods.R`, `age-scheme-classify.R`, and `age-scheme-registry.R`.
See `age_scheme.md` section 15 for the adopted contract and
`age_scheme_implementation_plan.md` for milestone results.

## 8. `tarr.pop` integration — Proposed downstream behavior

Agecraft defines intervals and classification semantics; `tarr.pop` owns HDF5-backed array storage, dimensional roles, metadata, and lazy aggregation. A `tarr.pop` age dimension may reference or serialize a scheme definition **once per dimension**, not per population cell. Any operation that collapses age bands must prove exact coverage and nonoverlap before additive aggregation. Crosswalk overlap alone does not authorize distributing counts from broad bands to narrow ones. Avoid coercing a DelayedArray to a data frame or ordinary vector just to apply scheme metadata.

## 9. Public API and compatibility — Current commitments

`API_POLICY.md` identifies the primary public workflow as `calculate_age()`, `age()`, `as_age()`, `is_age()`, `categorize_age()`, `age_group()`, `as.age_group()`, `is.age_group()`, `age_auto_unit()`, and `compare_age_groups()`. S3 registrations are supporting infrastructure. `age_group_to_char()` and `valid_age_group_symbol()` remain exported for compatibility but are not preferred for new usage.

The deprecated `age_cat()`, `calc_age()`, `age.cat()` and the `age.groups` alias must remain through the **next non-development release**; removal requires a later announced breaking release, with no current removal date. Existing `as.character.ivs_iv()` and `summary.ivs_iv()` registrations are retained; do not extend bare `ivs` with new scheme methods.

Scheme implementation should be additive and must not silently change `calculate_age()` output defaults, age precision, group equality, label behavior, overlap errors, or unit conversion rules. Document any proposed API change before coding.

## 10. Package organization and development practices

**Current:** Source code is organized under `R/` by age calculation, age class, age-group construction/coercion/comparison/methods/printing, and utilities. Tests are under `tests/testthat/`. User guides live under `vignettes/`; public help is generated with roxygen2 into `man/`. `DESCRIPTION` imports `ivs`, `vctrs`, `units`, `lubridate`, and other helpers. Development policies and AI instructions now live under `docs/`, with the entry point at root `AGENTS.md`.

**Documentation layout:** Keep this architecture document at `docs/architecture.md`, the scheme specification at `docs/age_scheme.md`, and a root `AGENTS.md` that instructs Codex to consult `API_POLICY.md`, `CURRENT_STATE.md`, and relevant design docs. Add scheme-specific source modules and tests without rewriting stable interval internals. Generate documentation with `devtools::document()` and test with `devtools::test()` and `devtools::check()`.

**Baseline evidence, not a fresh test run:** `CURRENT_STATE.md` reports 416 passing assertions and `devtools::check()` with 0 errors, 0 warnings, and 0 notes on 2026-11-09. Its recorded GitHub Actions run predates later documentation updates. Re-run checks on the actual release commit.

## 11. Remaining design and validation concerns

1. **Published definitions:** External editions for historical presets remain
   unknown; do not relabel them as current official standards. New authoritative
   schemes require verified boundaries, editions, references and dates.
2. **Transformations:** Scheme subsetting, replacement and coverage operations
   have no implicit validity/provenance-retention promise. Reconstruct and
   validate a new definition after editing intervals.
3. **Unit migration:** Legacy numeric presets retain caller-unit behavior.
   Equivalent registry schemes have explicit year units and require explicit
   observation units. This difference is intentional and documented.
4. **Aggregation:** Membership overlap cannot justify splitting aggregate counts
   or summing overlapping categories as an additive denominator.
5. **Validation:** Historical validation statements above remain dated baseline
   evidence. Consult `CURRENT_STATE.md` for the current feature validation.

## 12. Further work

- Curate source-verified published schemes independently of legacy migration.
- Add validated scheme transformations only when use cases require them.
- Coordinate downstream lazy population-array integration separately.

## 13. Source-of-truth references

- [`API_POLICY.md`](API_POLICY.md) — existing public API and compatibility promises.
- [`CURRENT_STATE.md`](CURRENT_STATE.md) — implemented functionality and validation baseline.
- [`DESCRIPTION`](../DESCRIPTION) — package metadata and dependencies.
- [`R/age-class.R`](../R/age-class.R), [`R/Age_calculation.r`](../R/Age_calculation.r) — age values and calculations.
- [`R/agegroup-class.r`](../R/agegroup-class.r), [`R/agegroup-coerce.r`](../R/agegroup-coerce.r), [`R/agegroup-methods.r`](../R/agegroup-methods.r), [`R/agegroup-compare.r`](../R/agegroup-compare.r) — interval class, coercion, classification, comparisons.
- [`R/misc.r`](../R/misc.r), [`inst/extdata/age-group-provenance.csv`](../inst/extdata/age-group-provenance.csv) — legacy presets and provenance.
- [`age_scheme.md`](age_scheme.md) — detailed scheme proposal, if placed alongside this file.

This document summarizes repository state and our design discussions. It does not certify external CDC/WHO scheme editions or claim that proposed functions already exist.
