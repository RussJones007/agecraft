# Age schemes in `agecraft`

**Status:** Initial API implemented — 2026-11-10\
**Scope:** A reusable, source-aware system for defining and applying age classifications.\
**Implementation status:** The initial implementation contract in section 15 is implemented. Sections 1–14 retain the original design rationale and candidate APIs; unresolved alternatives there are superseded by section 15. New authoritative external definitions and downstream integration remain deferred.

## 1. Purpose

`agecraft` should support more than converting an age to a conventional five-year band. Different disciplines and reporting systems use age categories for different purposes: demographic denominators, infectious-disease surveillance, mortality reporting, immunization, eligibility, and developmental life stages. A classification should therefore be **explicit, reproducible, inspectable, and attributable to a source**.

The central design is a new S3 **`age_scheme`** class that *contains* the package's existing **`age_group`** interval vector. It does not replace `age_group`, introduce a second interval engine, or require `age_scheme` to inherit from `age_group`.

## 2. Design principles

1. **Keep `ivs` as the interval foundation.** `age_group` already uses `ivs::new_iv()` and right-open intervals `[start, end)`. Preserve that model.
2. **Separate ages, groups, and schemes.** An age value is an observation; an `age_group` is an interval (or vector of intervals); an `age_scheme` is a named, validated set of intervals with metadata and usage rules.
3. **Preserve units explicitly.** A scheme has a unit shared by its groups (for example, years or days). Never silently equate a month with a fixed number of days or a year with 365 days where calendar semantics matter.
4. **Make analytical intent explicit.** A mutually exclusive partition differs from an overlapping classification. Overlapping groups must never be silently summed as if they partitioned a population.
5. **Treat provenance as data, not commentary.** Keep source, version/edition, reference, purpose, and verification status with each scheme.
6. **Do not rewrite historical definitions.** Source-specific schemes are versioned; changes to authoritative cut points create a new version or identifier.
7. **Keep the core lightweight.** Scheme definitions should be small metadata objects; do not replicate interval definitions for millions of observations.
8. **Support user-defined schemes first.** A curated built-in registry is a convenience, not the only way to use the system.

## 3. Relationship between classes

```text
age values / age vectors
          |
          | classified using
          v
     age_scheme (S3)
       |-- age_group vector (existing S3 class, backed by ivs)
       |     |-- [start, end) intervals
       |     |-- names / labels
       |     `-- unit
       |-- identifier and descriptive metadata
       |-- purpose and provenance
       `-- partition / classification rules
```

`age_scheme` uses **composition**, not inheritance from `age_group`. The existing `age_group()` constructor, interval comparisons, names, formatting, and `vctrs` methods remain the foundation. A scheme should expose its underlying intervals through a documented accessor such as `groups()` or `scheme_groups()` (final naming TBD).

## 4. Proposed `age_scheme` contract

Each scheme should include the following information. Some fields are required for all schemes; others are optional for a user-created scheme but should be populated for curated built-ins.

| Field | Meaning | Suggested rule |
|---|---|---|
| `id` | Stable machine-readable identifier, e.g. `legacy_ili` | Required; unique within a registry |
| `name` | Human-readable title | Required |
| `groups` | Named `age_group` vector | Required; retains `ivs` interval semantics |
| `type` | `partition` or `classification` | Required |
| `unit` | Unit for all interval endpoints | Taken from/consistent with `groups` |
| `domain` | Intended age range or population | Optional but strongly recommended |
| `complete` | Whether groups cover the stated domain | Validated or explicitly unknown |
| `purpose` | Intended analytical/reporting use | Recommended |
| `organization` | WHO, CDC, NCHS, local health department, etc. | Recommended for published schemes |
| `source` | Document title or dataset specification | Recommended for published schemes |
| `reference` | URL, DOI, or citation | Recommended for published schemes |
| `version` | Edition, publication date, or release | Recommended; may be unknown |
| `verified` | Whether cut points were checked against the cited source | Explicit for built-ins |
| `notes` | Caveats, historical status, boundary interpretation | Optional |

**Names and intervals:** Group labels are presentation and category identifiers, not interval identity. The existing `age_group` equality semantics should remain based on interval bounds rather than names. Labels should nevertheless be nonblank and unique within a scheme when used as output categories.

**Boundaries:** Preserve `[start, end)` throughout. Thus completed ages 5–9 are represented by `[5, 10)` years, and 85+ by `[85, Inf)`. Avoid ambiguous inclusive-upper-bound storage. Fractional bounds must remain possible.

**Missingness:** The underlying `age_group` class supports missing intervals; the scheme constructor should normally reject missing category intervals, since a reference scheme with undefined cut points is not usable.

## 5. Two kinds of schemes

### 5.1 `age_partition`

A **partition** has mutually exclusive intervals. Examples include five-year demographic bands and many surveillance reporting categories.

- No overlapping intervals.
- Gaps may be allowed, but must be detectable and described; a *complete* partition must cover its declared domain without gaps.
- A value in the domain maps to **at most one** group, and to **exactly one** group when the partition is complete and the age is valid.
- Suitable for additive counts and rates **only when the source data and target intervals are compatible**.

### 5.2 `age_classification`

A **classification** permits overlaps, and possibly gaps. Examples include WHO's overlapping adolescent/youth/young-person terms and certain developmental life stages.

- An age may belong to zero, one, or several groups.
- The API must not silently choose one match or silently count overlapping memberships as mutually exclusive categories.
- Classification should offer an explicit *all-matches* result; a one-label/factor result should require nonoverlap or an explicit conflict-resolution policy.
- Overlapping categories cannot be summed to obtain a population total without a separate deduplication rule.

**Class design option:** Use `age_scheme` as the shared base S3 class with `age_partition` and `age_classification` subclasses. The constructor can select the subclass based on `type`; validation enforces the corresponding rules. This is a proposal, not an existing implementation.

## 6. Proposed public API

The exact names and signatures should be finalized after reviewing existing `agecraft` generics, especially `categorize_age()`.

```r
# Existing foundation:
g <- age_group(
  start = c(0, 1, 5, 15, 25, 40, 65),
  end   = c(1, 5, 15, 25, 40, 65, Inf),
  unit  = "year"
)
names(g) <- c("<1", "1-4", "5-14", "15-24", "25-39", "40-64", "65+")

# Proposed new constructor:
s <- age_scheme(
  groups = g,
  id = "example_surveillance",
  name = "Example surveillance age bands",
  type = "partition",
  purpose = "Illustrative reporting example",
  domain = c(0, Inf)
)

# Proposed discovery/accessors:
list_age_schemes()
get_age_scheme("legacy_ili")
scheme_groups(s)
summary(s)
as.data.frame(s)

# Proposed application (prefer extending the existing generic):
categorize_age(ages, by = s)
```

The cut points above are **illustrative**, not a claim about the current official NNDSS specification.

**Constructor behavior:** Validate bounds and labels, verify that group units agree, determine overlaps/gaps, check declared completeness against the domain, and reject contradictory metadata. Prefer validated construction/update helpers over unsupported direct mutation.

**Classification output:** For a partition, retain the existing ordered-factor behavior of `categorize_age()` where practical. For an overlapping classification, define a separate explicit multiple-membership representation (for example, a list-column or long table) rather than silently forcing a factor.

**Conversions:** Preserve `as.data.frame.age_scheme()` and `print.age_scheme()` as useful S3 integrations. `summary.age_scheme()` should report type, unit, number of groups, domain, gaps, overlaps, source/version, and verification status. Consider `format()` and `[` methods only if they have clear semantics.

## 7. Built-in registry

The built-in library should be **small, curated, versioned, and discoverable**. It should not be an indiscriminate catalog of every age grouping ever published. Prioritize commonly useful demographic and epidemiologic definitions, while allowing users to construct any other scheme.

### 7.1 Migrate existing `age_group_presets`

The repository currently documents eight presets in `R/misc.r`:

| Existing preset | Existing description | Migration direction |
|---|---|---|
| `ILI` | ESSENCE/CDC influenza-like illness reporting bands | Preserve exact historical cut points; identify as legacy/unverified until sourced |
| `IMM` | Immunization reporting bands | Preserve; avoid implying current vaccine guidance |
| `Yr.5` | Five-year age bands | Prefer generated standard partition |
| `Yr.10` | Ten-year age bands | Prefer generated standard partition |
| `Spec` | Specialized reporting bands | Preserve with explicit local/unknown provenance |
| `Annual` | Annual disease report bands | Preserve with reporting context |
| `School` | School-oriented reporting bands | Preserve with reporting context |
| `Covid` | COVID-19 reporting bands | Preserve as historical/versioned |

The existing `age_group_presets` list is a set of numeric cut points used by `categorize_age()`/`cut()`, **not yet a collection of `age_scheme` objects**. Migration should convert the cut points into named `age_group` intervals and attach metadata **without changing their boundaries**.

The repository also documents a legacy alias `age.groups` and a provenance file at `inst/extdata/age-group-provenance.csv`. Preserve these compatibility commitments. The existing documentation says that `age.groups` will remain through the next non-development release, with removal only after a later announced breaking release.

### 7.2 Curated published schemes to investigate

Potential built-ins, subject to checking exact boundaries, units, authoritative editions, and usage conditions:

- **WHO** adolescent (10–19), youth (15–24), and young people (10–24): an overlapping classification, not a partition.
- **CDC / *Emerging Infectious Diseases*** editorial life-stage terminology: potentially overlapping categories and editorial conventions, not necessarily a universal clinical standard.
- **CDC NNDSS / CDC WONDER** surveillance age groups: identify the exact table, dataset, and edition before freezing boundaries.
- **NCHS mortality** age groups: source- and table-specific partition, versioned accordingly.
- **UN population / demographic five-year bands**: demographic partitions, including explicit treatment of the final open-ended group.
- **SEER** cancer reporting/age-adjustment categories: distinguish age bands from age-adjustment standards and document changes across releases.
- **Texas Demographic Center** projection/estimate age bands: especially relevant for compatibility with `tarr.pop` population denominators.
- **UNICEF, Eurostat, Census Bureau, OECD, and AAP** definitions: future candidates where there is a well-defined, useful, citable scheme.

Do **not** expose a vague `age_scheme_cdc()` as if CDC had one universal set of ages. Prefer descriptive identifiers such as `cdc_eid_life_stages_<edition>` or `nchs_mortality_<edition>`, subject to a consistent naming convention.

## 8. Units and age semantics

`age_group` already supports a vector-level unit. A scheme should continue to have **one unit per scheme**, with explicit conversions when needed.

- Support age bands in years, months, weeks, days, and hours as appropriate.
- Distinguish **completed age** (for example, completed years) from elapsed duration.
- Calendar months and years have variable durations; conversion may require birth date and observation date. Do not silently use approximate fixed conversions for clinical or surveillance classification.
- Clearly specify how negative, missing, nonfinite, and out-of-domain ages are handled.
- Consider explicit handling of neonatal definitions measured in days versus infant definitions measured in months, including their boundary conventions.

The existing `age` class already provides explicit unit-aware conversion through `as_age()`. Reuse that behavior and its approximate-conversion guards when applying schemes.

## 9. Interoperability with `tarr.pop`

`agecraft` should remain independently useful, but scheme objects can describe the age dimension of a `tarr.pop` population cube.

- Keep the scheme as **dimension metadata**, not duplicated across cells.
- Preserve the `DelayedArray`/`HDF5Array` lazy representation; merely attaching or inspecting a scheme must not realize population data.
- Exact regrouping is possible when source bands can be combined without splitting them. Splitting a source interval (for example, 10–19 into 10–14 and 15–19) is **not exact** without additional data or a declared estimation method.
- Reject or explicitly flag aggregation across overlapping categories that would double count population.
- Preserve original age labels and source metadata; transformations should record the target scheme and any information loss.

This specification does not propose changing `tarr.pop`'s S4 inheritance or forcing array realization.

## 10. Migration plan

1. **Inventory the existing code:** `age_group` constructor, `ivs` operations, `categorize_age()`, existing presets, tests, and public compatibility commitments.
2. **Implement `age_scheme`:** S3 constructor, validator, accessors, printing, summary, data-frame conversion, and partition/classification contracts.
3. **Adapt `categorize_age()`:** Accept a scheme by extracting its `age_group` vector; preserve existing behavior for raw numeric cut points and `age_group` inputs.
4. **Migrate the eight presets:** Create equivalent scheme definitions, retaining original cut points and uncertain provenance. Add equivalence tests.
5. **Provide registry discovery:** List, retrieve, and inspect schemes. Keep user-defined construction first-class.
6. **Add authoritative schemes selectively:** Verify sources and editions before inclusion; record provenance and overlapping/gap semantics.
7. **Document and release carefully:** Add a vignette comparing partitions and classifications; retain `age_group_presets` and `age.groups` according to the documented compatibility policy.

## 11. Tests to add (`testthat`)

- Construction preserves the exact `age_group` interval bounds, `Inf`, labels, and unit.
- Right-open boundaries behave correctly at every cut point; fractional endpoints are preserved.
- Partitions reject overlaps and detect gaps; completeness is evaluated relative to the declared domain.
- Classifications permit overlaps and return all matching groups without silently selecting one.
- Duplicate/blank labels, missing intervals, invalid domains, contradictory units, and malformed metadata fail informatively.
- Out-of-domain and missing ages have documented results.
- Scheme-based classification agrees with existing `categorize_age()` for each legacy preset on representative ages and all boundaries.
- Existing `age_group_presets` and `age.groups` remain compatible as promised.
- Print/summary/data-frame conversions preserve labels, bounds, and provenance.
- No scheme operation accidentally changes interval identity based on display names.
- `tarr.pop` integration does not force HDF5-backed arrays into memory and refuses inexact regrouping without an explicit policy.

Run with `devtools::test()`; generate help files with `devtools::document()` after adding roxygen2 documentation.

## 12. Documentation expectations

For exported constructors and accessors, use roxygen2 `@param`, `@return`, `@examples`, `@seealso`, and `@export` as appropriate. Document the interval convention, units, overlap behavior, missingness, provenance, and output cardinality. Include a vignette with three examples: a standard five-year partition, an overlapping WHO classification, and a legacy surveillance preset.

## 13. Open design decisions

The following should be settled before implementation rather than assumed:

1. Whether `age_partition` and `age_classification` are separate subclasses or one class with a validated `type` field.
2. Whether `age_scheme()` is strictly a constructor, with `get_age_scheme()` reserved for registry lookup (recommended), and the final accessor name for the underlying `age_group`.
3. Whether the registry stores serialized scheme objects, constructor functions, or compact source definitions.
4. The multiple-membership output format for overlapping classifications.
5. The policy for completeness, gaps, and open-ended domains.
6. How unit conversions and completed-age semantics interact with birth dates and observation dates.
7. The naming/versioning convention for authoritative schemes, and what qualifies a built-in as source-verified.

## 14. Working decision

**Build `age_scheme` as a small, source-aware S3 wrapper around the existing `ivs`-based `age_group` class.** Make user-defined schemes easy; distinguish partitions from overlapping classifications; migrate the eight historical presets without breaking callers; and add a curated, carefully verified library of epidemiologic and demographic definitions. Reuse existing `agecraft` interval and classification machinery rather than creating a parallel system.

## 15. Initial implementation contract — implemented 2026-11-10

The implementation follows `age_scheme_implementation_plan.md`. Use one S3
`age_scheme` class with a validated `type` field, without partition/classification
subclasses. The constructor requires named, nonempty `age_group` intervals with
an explicit supported time unit. Category names must be nonblank and unique.
`scheme_groups()` accesses intervals; `is_age_scheme()` identifies the class;
`validate_age_scheme()` checks the full object, including after direct mutation.

`domain` is NULL or a numeric pair describing a right-open interval in the group
unit. Groups must lie inside a declared domain. `complete = NA` makes no coverage
claim; TRUE/FALSE assert complete/incomplete coverage and require a domain.
Overlap is independent of completeness; partitions reject overlap. There are
no scheme subsetting/replacement/set-operation methods in the initial release.
Reconstruct a scheme to change its definition and reconsider its provenance.

`categorize_age(..., by = scheme)` delegates to existing single-assignment
behavior. `classify_age_scheme(ages, scheme)` returns a base data frame with
`observation`, `scheme_id`, `group_index`, `label`, `status`, and an `age_group`
column named `group`. Matches retain original category indices and are ordered
by observation then category. Missing and unmatched observations each produce
one placeholder row (`status` is `missing` or `unmatched`); matches have status
`matched`. Empty input returns the same columns with zero rows. Interval-valued
ages require full containment. Present negative or nonfinite numeric ages are
rejected by this new interface; existing classification contracts stay intact.
Unit-bearing schemes require unit-bearing observations under existing conversion
rules. Neither interface silently assumes that plain numbers are years.

`get_age_scheme()` retrieves a definition and `list_age_schemes()` lists metadata.
Private factories reuse existing preset data and provenance; legacy identifiers
are `legacy_ili`, `legacy_imm`, `legacy_yr_5`, `legacy_yr_10`, `legacy_spec`,
`legacy_annual`, `legacy_school`, and `legacy_covid`. The original numeric lists
remain unchanged. Published schemes beyond these legacy definitions are deferred
until independently verified.
