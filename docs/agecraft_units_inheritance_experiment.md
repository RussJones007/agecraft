# Codex Task: Experiment with `units` inheritance in agecraft

## Objective
Evaluate whether agecraft's `age` S3 class should inherit from `units`, using explicit `vctrs` integration where needed. The experiment should establish whether this improves interoperability and reduces duplicated conversion/arithmetic code while preserving agecraft's time-unit restrictions and `allow_approx` safeguards.

**This is an experiment, not approval to migrate the production implementation.**

## 1. Branch and safety

1. Open the agecraft repository and inspect `git status` and the current branches.
2. Do not discard uncommitted changes. If the working tree is dirty, stop and report it.
3. Start from an up-to-date local `main` and create `experiment/units-inheritance`.
4. Keep all prototype work, tests, benchmarks, and the report on this branch. Do not merge or push without explicit instruction.

## 2. Establish the baseline

Inspect the current `age` constructor, storage, class vector, unit metadata, `as_age()`, `allow_approx`, arithmetic, comparison, formatting, subsetting, and relevant vctrs methods. Identify conversion code that agecraft implements itself versus code delegated to `units` or other dependencies.

Record baseline outputs and tests for:

- Exact conversions: seconds ↔ minutes, hours ↔ days, days ↔ weeks, and seconds ↔ weeks.
- Calendar-sensitive conversions: months ↔ years, years ↔ days, months ↔ days, both with and without `allow_approx`.
- Arithmetic, comparisons, missing values, concatenation, subsetting, casting, and invalid units.
- Interactions with `age_interval`, `age_group`, `age_scheme`, and `categorize_age()`.

**Do not assume which conversions are exact:** document the current agecraft policy and the factors used by `units`, especially for months and years.

## 3. Inspect the `units` and `vctrs` APIs

Determine the actual S3 class hierarchy of a `units` object, its attributes and numeric representation, supported conversions, replacement setters, arithmetic and comparison methods, and existing vctrs integration. Inspect relevant installed package code and documentation rather than assuming behavior.

Pay particular attention to whether `units::set_units()`, `units<-`, arithmetic, or coercion can bypass subclass-specific validation. Document potential method-dispatch issues.

## 4. Implement a minimal prototype

Construct a valid `units` object first, then add an `age` subclass (conceptually `c("age", "units")`, preserving any additional classes actually required). Prefer inherited behavior over reimplementing conversions.

Requirements:

- Only approved time units are valid; reject distance, mass, and other dimensions.
- `as_age()` remains the public conversion interface.
- Preserve existing `allow_approx` behavior for calendar-sensitive conversions.
- Preserve values, missing values, and class invariants after supported operations.
- Explicitly define which operations return `age`, `units`, numeric, or an error.
- Prototype vctrs methods as necessary (`vec_proxy`, `vec_restore`, `vec_ptype2`, `vec_cast`, `vec_c`, `vec_slice`). Do **not** add `vctrs_vctr` to the class vector unless a separate test demonstrates a concrete benefit and compatibility.

Keep experimental code isolated and avoid unnecessary changes to existing public APIs.

## 5. Test safety and compatibility

Create tests comparing prototype and baseline for:

1. Exact and approximate conversions and their numerical values.
2. Rejection of prohibited conversions without `allow_approx`.
3. Rejection of invalid units such as kilometers and kilograms.
4. Direct `units::set_units()` and `units<-` operations, including attempts to bypass safeguards.
5. Arithmetic, comparisons, concatenation, subsetting, missing values, restoration, and casts.
6. Compatibility with `age_interval`, `age_group`, `age_scheme`, and `categorize_age()`.
7. Typical tibble/dplyr workflows, if those dependencies are available.

If inherited operations cannot reliably preserve invariants, document that explicitly; do not conceal failures by silently converting to an ordinary `units` object.

## 6. Benchmark and maintenance assessment

Benchmark baseline and prototype with identical vectors of 1, 1,000, 100,000, and 1,000,000 elements where feasible. Compare construction, exact/approximate conversion, arithmetic, comparison, concatenation, and subsetting. Use warm-ups and repeated runs; report medians, allocations, and relative performance.

Assess the impact of requiring `units` and UDUNITS2 for CRAN/Linux/macOS/Windows installations. Estimate code removed versus adapter/override code added, and identify ongoing maintenance risks.

## 7. Deliverables

Create `docs/experiments/age_units_inheritance.md` on the experiment branch with:

- Current architecture and prototype design.
- Observed class hierarchy and method-dispatch behavior.
- Conversion-policy comparison, including exact versus approximate rules.
- Tests passed, failed, or not run; compatibility regressions.
- Benchmark results and dependency costs.
- Estimated net code reduction.
- A recommendation: **Adopt**, **Revise**, or **Retain**, with supporting evidence and source-file references.

Commit the experimental code, tests, and report **only** to `experiment/units-inheritance`. Leave `main` unchanged. Do not migrate the production implementation or merge the branch. Stop and wait for a go/no-go decision.
