# Age arithmetic implementation plan

**Project:** Agecraft\
**Purpose:** Codex implementation instructions; proposed behavior, not yet implemented.

## Scope and prerequisites

Read `AGENTS.md`, `docs/API_POLICY.md`, the existing age-class documentation, and the current implementations and tests for `age`, `age_group`, `categorize_age()`, unit conversion, and `vctrs` methods. Treat existing public contracts as authoritative. Report any conflict before changing behavior. Keep this work separate from `age_scheme` implementation.

## Agreed design

1.  An `age` represents a nonnegative elapsed age. Nonmissing values must be \>= 0. Reject negative values in construction and operations that return an age; never clamp to zero. Preserve the existing date-ordering contract. Missing ages may remain `NA`.
2.  Numeric offsets are interpreted in the `age` operand's unit: an age of 25 years plus 1 means 26 years. Preserve fractional precision and class/unit metadata.
3.  For operations involving ages in different units, the intended arithmetic policy is to convert the right-hand age to the left-hand age's unit and return the left-hand unit. Examples: 2 years + 6 months -\> 2.5 years; 6 months + 2 years -\> 30 months. **Verify how this interacts with existing `vctrs` dispatch and common-type behavior; do not claim that left-unit precedence is a universal `vctrs` rule.** Document any asymmetric result-unit behavior.
4.  Reuse the package's existing unit conversion rules and approximation safeguards. Never silently round fractional ages or assume a fixed number of days in a calendar month without an explicit, documented policy.
5.  Keep signed *differences* distinct from nonnegative `age` values. Before implementing `age - age`, determine whether the result is a signed numeric difference, a separate duration type, or unsupported; do not silently return a negative `age`.
6.  Do not add arithmetic to `age_group` or `age_scheme` in this change. Preserve right-open `[start, end)` interval semantics, including open-ended upper bounds such as `Inf`, and preserve existing classification behavior. Unit-bearing ages must classify consistently after arithmetic.

## Implementation sequence

1.  Inspect constructors, validators, `vctrs` proxy/restore/cast/type methods, and current `Ops`, `Math`, `Summary`, `mean`, and `median` behavior. Identify the minimal extension points.
2.  Implement nonnegative age validation centrally, including any relevant restoration and casting paths. Check existing uses of negative sentinel values or negative-age test fixtures before enforcing the invariant.
3.  Implement and document numeric addition/subtraction and compatible mixed-unit arithmetic, respecting the unit policy and nonnegative results. Support comparisons only where compatible with existing class semantics.
4.  Evaluate `round`, `floor`, `ceiling`, `trunc`, `abs`, `mean`, `median`, `min`, `max`, and `range` for appropriate class/unit preservation. Do not automatically enable `log`, `exp`, `sum`, multiplication, or division without a separately reviewed semantic contract.
5.  Add focused `testthat` tests and regression tests; generate documentation with `devtools::document()`, run `devtools::test()` and `devtools::check()`, and report actual results.

## Essential tests

- Zero accepted; negative construction and negative arithmetic results rejected; `NA` preserved.
- `age(25, 'year') + 1` yields 26 years; subtracting to exactly zero succeeds.
- `2 years + 6 months` yields 2.5 years; reversed operands yield 30 months, subject to verified dispatch and conversion behavior.
- Fractional values retained; no silent rounding or unapproved approximate conversions.
- Vector lengths, recycling, empty vectors, missing values, incompatible units, and errors.
- Comparison at exact age-group boundaries; classification after arithmetic remains correct for `[5, 10)` and for mixed units.
- Existing `age_group`, `age_scheme`, and `categorize_age()` behavior unchanged.

## Decisions to surface before implementation

- Precise semantics and return type of `age - age`, especially when the result is negative.
- Whether `age + age` is meaningful and should be supported beyond the discussed mixed-unit examples.
- Whether the existing package already permits negative values or has public APIs depending on them.
- Any mismatch between the proposed left-hand-unit policy and established `vctrs` common-type behavior.

Do not silently resolve these open design questions by changing public behavior. Summarize findings and recommended choices before implementing them.


## Implementation record

### Step 1 — inspection

- `new_age()` already enforces finite nonnegative values (or missing values).
  `vec_restore.age()` and `vec_cast.age.age()` route through that constructor.
  No negative age sentinel dependencies were found in the source or tests;
  negative fixtures test rejection. Date ordering remains outside this change.
- Arithmetic currently falls through to vctrs incompatible-operation errors.
  Extend `vec_arith` dispatch without relaxing common-type/cast rules.
  Mixed-unit concatenation and comparisons will still require explicit conversion.
- Existing `vec_math.age()` preserves ages for rounding, absolute values, means
  and extrema, but median currently errors. Empty extrema produce infinities and
  are rejected by the constructor; do not manufacture valid ages from them.
- Calendar conversions, including month/year, require explicit approximation
  consent. Operators cannot accept `allow_approx`; users must convert the right
  operand explicitly with `as_age(..., allow_approx = TRUE)` before such arithmetic.
  Exact elapsed-unit arithmetic can convert the right age to the left unit.
- The age-to-age subtraction decision has been surfaced to the user before
  implementation, as required above.

### Steps 2–3 — validation and arithmetic

- Existing central validation is retained and covered by regression tests.
- User decision: support age + age; leave age - age unsupported. Numeric
  subtraction is an offset operation returning a nonnegative age, not a signed
  difference. Numeric minus age is unsupported.
- Added vctrs arithmetic double dispatch for numeric offsets and age addition.
  Right ages convert to left units through `as_age()` with its default safeguards.
  Bare offsets must be finite or missing; vctrs controls recycling and sizes.
- Unit-bearing `units` objects must be explicitly converted to ages before use;
  the arithmetic dispatch rejects them. R can resolve conflicting S3 operator
  methods outside vctrs, so mixing independent vector classes is not supported.
- Focused age-class/arithmetic tests passed after documentation generation.

### Step 4 — transformations and summaries

- Retained the existing rounding, floor, ceiling, truncation, absolute-value,
  mean and extrema methods. Added `median.age()` because vctrs does not route
  median through `vec_math`. All age results use central validation.
- Missing results remain missing; empty extrema or all-missing extrema with
  removal still reject infinite results. No clamping or invented empty values.
- Added regression coverage for supported methods and rejection of sums,
  products, logs, exponentials and square roots.
