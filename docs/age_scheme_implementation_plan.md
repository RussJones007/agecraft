# Age-scheme implementation plan

Status: All six initial implementation milestones complete.
Prepared: 2026-11-10. Branch: `age_scheme`.

Read alongside `AGENTS.md`, `docs/age_scheme.md`, `docs/architecture.md`,
`docs/age_group.md`, `docs/coding_guidelines.md`, and `docs/API_POLICY.md`.

## Scope and design decisions

Build a small S3 object containing an existing `age_group` vector. Keep the
current interval engine, fractional precision, labels, matching, and conversion
rules. Deliver user-defined schemes first, then classification integration and
a registry of the eight legacy presets. Add independently verified published
schemes separately. Direct changes to `tarr.pop` are outside this repository's
initial implementation.

The following initial API decisions are adopted for this implementation:

- Use one `age_scheme` class with a validated `type` field (`partition` or
  `classification`); avoid subclasses until behavior requires them.
- Use `age_scheme()` only for construction, `scheme_groups()` for intervals,
  `is_age_scheme()` for identification, and `validate_age_scheme()` for validation.
  Reserve `get_age_scheme()` and `list_age_schemes()` for built-in discovery.
- Keep unit and interval coordinates solely in `groups`. Require explicit units
  for new scheme definitions. Unitless numeric observations must be made explicit
  by the caller when applying a unit-bearing scheme; preserve existing rejection
  of unitless ages against unit-bearing groups.
- Require a nonempty validated group vector with nonmissing intervals and unique,
  nonblank category names. Preserve caller-defined group order in the object;
  single-category classification retains the existing sorted-interval behavior.
- Model `domain` as a single right-open range in the groups' unit. Omission means
  unspecified, rather than inferred full coverage. Define `complete` as TRUE,
  FALSE, or NA (unknown); a TRUE claim requires an explicit domain and exact
  coverage. Reject groups outside a declared domain. A partition may have gaps
  when completeness is not claimed. Detect overlap independently of coverage.
- Reject contradictory metadata. Source verification must not be inferred from
  a familiar scheme name. Avoid general replacement, subsetting, and set-operation
  methods on schemes initially; construct and validate a new scheme after editing
  its groups, and do not automatically retain official provenance claims.
- Prefer a separate `classify_age_scheme()` interface for all memberships, with
  a base data-frame result. Keep `categorize_age(..., by = scheme)` for the
  existing factor/interval outputs and explicit first/last resolution.
- Use private, version-controlled R definitions/factories for the initial registry,
  reusing packaged preset cut points and the existing provenance table rather
  than maintaining a second independent copy of those boundaries.

## Milestone 1 — Resolve the API and establish the baseline

Files: update `docs/age_scheme.md` and this plan with agreed decisions.

1. Finalize constructor arguments, metadata requirements, domain/completeness
   semantics, registry identifiers, and membership output before exporting APIs.
2. Specify the long-result columns and cardinality: observation index, scheme
   identifier, category index/label, matched interval, and explicit missing or
   unmatched status. Preserve observation identity and original category indices.
   Include one placeholder row for observations with no membership; missing ages
   and present-but-unmatched ages must remain distinguishable. Define empty input.
3. Preserve existing interval-input semantics: full containment is membership;
   partial overlap is not silently substituted. Reject unsupported input types
   and document negative/nonfinite-age handling consistently with existing APIs.
4. Inspect nearby tests and run `devtools::test()` to establish a fresh baseline.
   Record actual outcomes rather than reusing historical assertion counts.

Completion: a settled API contract, explicit edge-case behavior, and recorded
baseline results. No unresolved public design choice is embedded in source.

## Milestone 2 — Construct and inspect user-defined schemes

Create:

- `R/age-scheme-class.R`: internal construction, public constructor, predicate,
  accessor, and validator.
- `R/age-scheme-validation.R`: private overlap, gap, domain, and coverage helpers,
  using existing `ivs` operations rather than a separate interval engine.
- `R/age-scheme-methods.R`: print, summary, and data-frame methods.
- `tests/testthat/test-age-scheme-class.R` and
  `tests/testthat/test-age-scheme-methods.R`.

Test valid partitions and overlapping classifications; touching endpoints;
fractional bounds; `Inf`; gaps; missing/empty groups; label validation; malformed
metadata; explicit units; contradictory completeness claims; and inspection
methods. Summary reports domain, coverage, overlaps, gaps, source/version, and
verification status. Data-frame conversion must document which metadata stays
in columns or attributes and what a round trip can preserve.

Completion: users can construct, validate, inspect, and serialize/reload schemes
without changing `age_group` identity or behavior.

## Milestone 3 — Apply schemes with existing classification behavior

Modify `R/Age_calculation.r` to recognize a scheme in `by`, validate it, extract
its groups, and continue through the current classification path. The current
function is not an S3 generic; keep this integration small.

Create `tests/testthat/test-age-scheme-categorize.R`. Extend existing
classification tests only where needed. Test equality with the underlying
`age_group` for factor and interval output, category order, missing/unmatched
values, fractional ages, boundaries, interval containment, unit conversions,
approximation guards, and all current multiple-match policies. Invalid schemes
must fail rather than bypass validation through direct object mutation.

Completion: `categorize_age(ages, by = scheme)` works while all existing input
paths, defaults, compatibility wrappers, and output contracts remain intact.

## Milestone 4 — Return all memberships explicitly

Create `R/age-scheme-classify.R` and
`tests/testthat/test-age-scheme-classify.R`.

Implement the agreed long-form membership interface. Reuse current unit
alignment, fractional matching, `ivs` location functions, and containment rules.
Share small private helpers with `R/agegroup-methods.r` or `R/Age_calculation.r`
only when needed; do not duplicate matching logic or change existing defaults.

Test one, several, and zero matches; missing and empty observations; unit-bearing
ages and interval inputs; deterministic row order and stable category indices;
and explicit unmatched status. Avoid a full observation-by-category Cartesian
product when indexed interval matching suffices. Document that memberships in
overlapping classifications cannot be summed as a population partition.

Completion: overlapping schemes return every membership through an explicit
interface, without silently selecting a category or modifying factor defaults.

## Milestone 5 — Add a compatible legacy registry

Create `R/age-scheme-registry.R` and
`tests/testthat/test-age-scheme-registry.R`. Reuse
`inst/extdata/age-group-provenance.csv`; extend it only if a new field is needed.

Expose lookup and a metadata listing for all eight existing presets. Assign
stable identifiers such as `legacy_ili`, with documented mapping from current
preset keys. Store source uncertainty explicitly and use year units as recorded
in the provenance table. Leave `age_group_presets`, `age.groups`, and their
numeric-input behavior unchanged.

Compare bounds and assignments at every cut point and immediately around each
cut point against `categorize_age()` using the legacy numeric preset. Construct
intervals from adjacent cut points; do not inadvertently add the terminal
one-unit interval that `as.age_group()` creates for a finite final cut point.
Compare using equivalent explicitly year-bearing ages for scheme classification.
Test unknown identifiers, metadata listings, reproducibility, and independence
of returned objects.

Completion: eight discoverable schemes with exact legacy-boundary equivalence,
honest provenance, and unchanged legacy interfaces.

## Milestone 6 — Document, validate, and prepare integration

Create `vignettes/age-schemes.Rmd`: user-defined five-year partition, an
overlapping illustrative classification, and a legacy surveillance preset.
A WHO-branded example requires independently verified authoritative boundaries
and edition; until verified, keep the overlap example explicitly illustrative.

Update `README.md`, `NEWS.md`, `docs/API_POLICY.md`, `docs/CURRENT_STATE.md`,
`docs/architecture.md`, and `docs/age_scheme.md` to distinguish implemented
features from remaining proposals. Update `DESCRIPTION` if warranted by the
development version or metadata. Generate `man/` help and S3/export entries in
`NAMESPACE` through roxygen2, not manual edits.

Run focused tests during each milestone, then run `devtools::document()`, the
full `devtools::test()`, and `devtools::check()` on the final implementation,
including examples and the new vignette. Record results and explain any
remaining errors, warnings, or notes before considering the work complete.
Review compatibility, dependency changes, and generated-file diffs.

Completion: documented APIs, passing validation, and a reviewable implementation
with one coherent commit per milestone where practical.

## Subsequent work

- Add selectively verified WHO, NCHS, SEER, or other published definitions with
  exact source/edition, verification date, and stable versioned identity.
- Design validated scheme transformations if practical use requires them.
- Coordinate `tarr.pop` integration separately: one definition per age dimension,
  lazy arrays preserved, and exact/nonoverlapping regrouping established before
  additive aggregation. Crosswalk overlap alone never authorizes splitting counts.

## Current execution status

All initial feature milestones are implemented and validated on `age_scheme`.
Published schemes beyond the legacy registry, scheme transformations and direct
`tarr.pop` integration remain subsequent work. The development-version increment
and GitHub push follow the milestone commits.

## Milestone log

1. API decisions adopted above. Baseline `devtools::test()`: 416 passing
   assertions, zero failures, warnings, or skips (2026-11-10). Subsequent milestone
   implementation is authorized; each milestone will be summarized and committed.

2. Constructor, coverage validation, and inspection methods implemented. Focused
   class/method tests: 52 passing assertions, no failures, warnings, or skips.
   Roxygen comments added; generated help/exports will be finalized in milestone 6.

3. Scheme adapter added to `categorize_age()`. Focused adapter and related
   classification regressions: 72 passing assertions, no failures/warnings/skips.

4. Explicit all-membership classification implemented with shared interval matching.
   Focused scheme/classification suite: 108 passing assertions, no failures,
   warnings, or skips. Corrected an all-missing test fixture to use numeric NAs.

5. Eight-scheme legacy registry implemented, reusing packaged data/provenance.
   Registry/migration tests: 111 passing assertions, zero failures/warnings/skips.
   Boundary assignments and interval bounds match the unchanged numeric presets.

6. Roxygen help/exports, vignette, README, API policy and design/status documents
   updated. Full suite: 609 passing assertions, zero failures/warnings/skips.
   `devtools::check(document = FALSE)`: zero errors, warnings or notes, including
   examples, installed tests and rebuilding five vignettes. No new dependencies.

Development version incremented separately to `0.1.0.9015`. The versioned package
passed `devtools::check(document = FALSE)` with zero errors, warnings or notes,
including examples, installed tests and rebuilding all five vignettes.
