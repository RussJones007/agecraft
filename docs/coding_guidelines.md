# Agecraft coding guidelines

> Phase-one naming refactor (2026-11-12): interval vectors use `age_interval`;
> categorical assignments remain `age_category`. See
> [the migration guide](age_class_naming_migration.md) for compatibility changes.


**Status:** Development instructions for contributors and coding agents\
**Updated:** 2026-11-10\
**Scope:** The `agecraft` R package (`RussJones007/agecraft`)

## 1. Authority and required reading

These guidelines govern **how to implement changes**. They do not redefine the public API or claim that proposed features are implemented.

Before making a change, consult the documents relevant to the task:

1. `docs/API_POLICY.md`    — authoritative for existing public behavior, compatibility, and deprecation commitments.
2. `docs/CURRENT_STATE.md` — documented implementation baseline and outstanding work; verify against the current source and tests.
3. `docs/architecture.md`  — component boundaries and architectural direction.
4. `docs/age_scheme.md`    — proposed scheme design, when working on schemes.
5. This file — coding, testing, and documentation practices.

If documents disagree, **do not silently choose a new behavior**. Preserve the checked-in public contract in `API_POLICY.md`, inspect the implementation and tests, report the discrepancy, and ask for a decision when a public contract would change. A proposal in `docs/` is not evidence of an implemented function. The repository source and tests determine what actually exists.

## 2. R code style and dependencies

- Use descriptive `snake_case` names for new functions and arguments; preserve existing exported names and argument conventions.
- Use `<-` for assignment, consistent indentation, and short, single-purpose helpers. Use the native pipe `|>` when it makes a sequence clearer; R >= 4.1.0 is supported.
- Prefer straightforward base R and existing declared dependencies over adding packages. Avoid nonstandard evaluation unless the API materially benefits from it.
- Qualify external calls with `package::function()` unless a deliberate roxygen import already exists. Do not add broad imports unnecessarily.
- Validate inputs at public boundaries. Report actionable errors with `call. = FALSE` where consistent with existing code.
- Avoid unrelated refactoring, formatting churn, and changing generated files manually when a generator owns them.
- Prefer extending existing helpers to creating parallel interval, unit, or classification engines.

## 3. S3, vctrs, and class design

- Preserve the existing S3 `age` and `age_interval` classes and their contracts. `age_interval` is an `ivs`-based interval vector; do not replace it with a plain data frame or lower/upper cut-point list.
- Follow the established `vctrs` proxy, prototype, casting, restoration, slicing, and concatenation behavior. Test class and metadata retention after vector operations.
- Use established S3 generics and register methods correctly. Do not add methods to bare `ivs_iv` beyond existing compatibility registrations without an explicit design decision.
- Use validated constructors rather than setting class or internal record fields ad hoc. Keep internal helpers private unless a public use case justifies export.
- Handle length-zero vectors, missing values, and incompatible types deliberately.
- `age_scheme` is a metadata-bearing S3 object **containing** an `age_interval` vector, not inheriting from `age_interval` and not attached to every observation. Consult `docs/age_scheme.md` section 15 for implemented constructors, registry accessors, and validation contracts.

## 4. Age values and interval semantics

These are correctness requirements, not display preferences:

- All age intervals are **left-closed, right-open**: `[start, end)`. For completed whole-year ages, `[1, 5)` corresponds to ages 1–4.
- Preserve fractional boundaries and fractional stored ages. Never round a value merely because its default printed representation shows completed units.
- Require nonnegative finite lower bounds; allow `Inf` only as an upper bound. Missing intervals require both endpoints missing. Reject reversed and zero-width intervals.
- Gaps and overlaps are valid for `age_interval` vectors. Never assume disjointness or complete coverage without scheme-level validation.
- Keep interval identity separate from names and labels. Names affect display and categories, not interval equality or ordering. Distinct intervals must not silently collapse into one factor label.
- Retain `age_interval` names and units when existing vector contracts require it. Coverage operations that merge or split intervals must not carry misleading old labels.

## 5. Units and calendar semantics

- One `age` or `age_interval` vector has one explicit or documented unspecified unit; do not silently introduce mixed per-element units.
- Preserve `calculate_age()`'s current default: a fractional `age` vector whose ordinary display shows completed units. `as.numeric()` returns the retained fractional values; `as.integer()` returns completed units. The `output = "numeric"` and `output = "units"` options return completed values as documented.
- Preserve established calendar-anniversary rules for years and months, including March 1 handling of leap-day birthdays in non-leap years and month-end rollback. Finer units use elapsed time as documented.
- Do not treat calendar months or years as universally fixed numbers of days. Require `allow_approx = TRUE` for month/year conversions and approximate fine/coarse unit conversions.
- Honor existing classification unit rules: unspecified group units may inherit age units; unitless ages with explicitly unit-bearing groups are rejected; conversion direction is controlled by `convert_units`.
- `compare_age_intervals()` requires matching units and must not introduce implicit conversion.

## 6. Classification and analytical integrity

- Keep `categorize_age()`'s existing default of **one assignment per observation**, ordered-factor output, and an error on multiple matches. Preserve `multiple = "first"` / `"last"` and `output = "interval"` behavior unless an approved API change says otherwise.
- Missing or unmatched ages must not be assigned an invented category. Test exact boundary values, fractional ages, and interval inputs.
- **Scheme distinction:** partitions require disjoint groups; overlapping classifications may intentionally assign multiple memberships. Use `classify_age_scheme()` for explicit multi-membership output while preserving the existing default.
- Never sum overlapping classification categories as if they were additive. Validate disjointness and required coverage before using a scheme for population denominators or rates.
- A crosswalk between grouped intervals does **not** determine how many people belong to finer target groups. Do not allocate aggregated counts without finer data or a documented assumption.

## 7. Age-scheme implementation rules

When extending the initial implementation in `docs/age_scheme.md` section 15:

- Reuse `age_interval` for boundaries, units, labels, and matching. Scheme metadata should describe identity, purpose, provenance, and validation policy without duplicating interval coordinates.
- Distinguish an individually valid interval from a valid **partition** and from a potentially overlapping **classification**. Treat coverage completeness as a separate, explicit property.
- Define how sorting, subsetting, relabeling, combining, and set operations affect scheme validity and provenance. Do not silently retain claims of completeness or official identity after altering boundaries.
- Provide stable identifiers, human-readable names, source/edition/date where known, and explicit uncertainty where not known. Do not present historical presets as current official clinical guidance.
- Preserve all eight `age_interval_presets` cut-point definitions and the `age.groups` compatibility alias under the documented deprecation policy. Migrate through an additive interface rather than replacing numeric presets abruptly.
- Keep scheme definitions lightweight and reusable. Prefer a small curated registry with clear provenance and user-defined schemes over hard-coded assumptions about a single universal CDC or WHO standard.
- Confirm any proposed function name, signature, and S3 dispatch approach before treating it as a public contract.

## 8. Performance and interoperability

- Prefer vectorized operations and avoid unnecessary copies of age observations. Keep scheme-level metadata separate from large observation vectors.
- Be mindful that pairwise crosswalks can require `length(x) * length(y)` rows; document or guard against unexpectedly large allocations.

## 9. Tests and validation

Use `testthat` edition 3 and add focused tests under `tests/testthat/` alongside the affected component. Test both successful results and expected errors. At minimum, consider:

- Exact lower/upper boundaries, touching intervals, gaps, overlaps, `Inf`, fractional bounds, missing and zero-length inputs.
- Calendar boundaries, leap days, short months, and fractional age precision.
- Unit inheritance, incompatibility, explicit conversion, and approximate-conversion guards.
- Names, factor level order, interval equality, class restoration, and metadata retention after slicing/combining.
- Multiple matches, missing/unmatched classifications, and partition-versus-classification validation.
- Compatibility of legacy wrappers, presets, and documented defaults.

Run `devtools::test()` for implementation changes and `devtools::check()` before calling a release-ready change complete. For documentation changes, run `devtools::document()` and relevant example/vignette checks. Record the commands and outcomes; **never claim a test or check passed if it was not executed**. Do not copy historical assertion counts from `CURRENT_STATE.md` as if they were new results.

## 10. Documentation and releases

- Document exported functions with roxygen2: purpose, `@param`, `@return`, examples, and relevant `@seealso` links. Document error behavior, units, and interval boundaries when they affect interpretation.
- Keep examples runnable and small. Favor realistic surveillance, demographic, and general-purpose use cases without asserting that illustrative age cut points are authoritative.
- Regenerate `man/` and `NAMESPACE` with `devtools::document()` rather than hand-editing generated files.
- Update `README.md`, vignettes, `NEWS.md`, and `CURRENT_STATE.md` when a change affects public use or the documented implementation status. Update `API_POLICY.md` only through an intentional API decision.
- Do not remove deprecated APIs or compatibility aliases earlier than the policy permits. Identify breaking changes and version/release implications before implementation.

## 11. Working procedure for Codex and contributors

For each task:

1. **Read** relevant policies and design documents, then inspect the current source and nearby tests.
2. **State** whether the requested behavior is current, proposed, or a public API change; flag conflicts before coding.
3. **Implement** the smallest coherent change using existing class and helper infrastructure.
4. **Test** normal paths, boundaries, failures, and metadata behavior; add regression tests for bugs.
5. **Document** exported behavior and update affected design/status documents.
6. **Validate** with the relevant development commands and report what actually ran.
7. **Summarize** changed files, compatibility effects, remaining decisions, and any unrun checks.

Do not silently alter public defaults, rename exports, rewrite legacy data, invent source provenance, or implement unrelated features. If a design choice remains open, describe the alternatives and request a decision instead of embedding an arbitrary choice in code.
