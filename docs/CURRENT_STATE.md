# agecraft current state — 2026-11-10

Version: **0.1.0.9015** (development). Branch: `age_scheme`. Requires R >= 4.1.0.

## Lightweight derivative provenance — 2026-11-11

- Added `$<-`, `[[<-` and `[<-` methods sharing one update transaction. Exact
  substantive comparisons include bounds, units, ordered category labels,
  category order, type, domain and completeness. No definition snapshot is stored.
- First substantive or identity/asserted-source changes capture protected
  `derived_from = list(id, version, source, organization, reference)`, give a local
  `_derived` ID, clear inherited version and set verified FALSE. Explicit ID or
  version replacements are honored; current and ancestor IDs must differ.
  Subsequent changes retain first ancestry. Title, purpose, notes and valid
  cosmetic formatting preserve status; identical definition assignments do not
  create derivatives or reset verification. A later explicit verification claim
  remains subject to existing source/reference/version requirements.
- Atomic batch replacement validates final state. Recursive `[[<-` is rejected;
  invalid edits leave the original/catalog unchanged. Optional NULL metadata
  retains its schema field. Legacy serialized objects without ancestry remain
  readable; their first tracked edit captures then-current metadata without
  inventing earlier history. Deliberate S3 reconstruction bypasses tracking.
- Added 439 provenance regression assertions and adapted existing structural
  corruption tests to bypass ordinary setters deliberately. Targeted scheme,
  calendar-conversion and floating-point-boundary tests passed 1,526 assertions
  with zero failures, warnings or skips. The age-schemes vignette rendered into
  `/tmp/agecraft-provenance-vignette`. Roxygen help/registrations were regenerated;
  `git diff --check` passed. Log: `/tmp/agecraft-provenance-targeted.log`.
- No full suite or R CMD check was run for this targeted task. No dependencies,
  histories, fingerprints, timestamps, development-version increment or changes
  to age/interval storage and numerical algorithms were introduced.

## Floating-point precision policy documentation — 2026-11-11

- Retain existing double-precision conversion and classification algorithms,
  exact half-open predicates and conversion-direction options; no numerical
  tolerance, new dependencies, public API change or version increment.
- Document possible rounding and direction-dependent membership near boundaries,
  consistent-unit guidance, and why `convert_units = "none"` cannot recover
  earlier precision loss. Add the 11-second example to the age-scheme vignette
  and cross-reference the shared precision section in age help.
- `devtools::document()` completed. Targeted
  `devtools::test(filter = "^floating-point-boundaries$")` passed 21 assertions
  with zero failures, warnings or skips. The updated vignette rendered with
  `rmarkdown::render()` into `/tmp/agecraft-floating-point-vignette`.
  Parsed executable R expressions are unchanged; `git diff --check` passed.
  Full tests and R CMD check were not rerun for this documentation/test-only
  change. Log: `/tmp/agecraft-floating-point-targeted.log`.

## Complete underlying interval validation — 2026-11-11

- Added private `validate_age_group()` for stored ivs/vctrs record layout,
  endpoint field types and lengths, actual display/unit attributes and optional
  category-name structure. It reuses `new_age_group()` with the actual metadata
  for value checks, without repair, recycling or default substitution.
- Scheme validation now applies this structural check before scheme-specific
  nonempty, supported-unit, missing-category, label and coverage policies. All
  existing classification/accessor/inspection entry points use this validation
  path. Actual category metadata is read by exact attribute name.
- Missing/malformed display symbols and corrupted underlying records now fail
  early. Valid custom/empty scalar display strings, fractional bounds, units,
  overlaps, legacy schemes and representations retain their behavior. General
  age_group vectors may still be empty, unitless or missing. Structural validation
  does not independently verify external provenance.
- Added 693 regression/invariant assertions exercising every scheme entry point,
  individual display symbols, unit/name/boundary/record corruption, mutation
  without repair, valid custom symbols and ordinary operations, and all eight
  legacy schemes. Updated roxygen-generated help, scheme vignette, internal
  age_group documentation, API policy, README and NEWS.
- `devtools::document()` completed. Final targeted structural tests passed 693
  assertions; the full `devtools::test()` suite passed 2,020 assertions with zero
  failures, warnings or skips. `devtools::check(document = FALSE,
  check_dir = "/tmp/agecraft-structure-final-check")` completed with 0 errors,
  0 warnings and 0 notes, including examples, installed tests and rebuilding all
  five vignettes. `git diff --check` passed. Temporary local logs:
  `/tmp/agecraft-structure-final-tests.log` and
  `/tmp/agecraft-structure-final-check.log`.

## Dimensional validation — 2026-11-11

- A shared private validator checks the complete unit expression against the
  supported simple time units and existing aliases. `new_age()` and
  `as_age.units()` use this contract; classification checks dimensions before
  numerical extraction and same-unit shortcuts. Integer classification retains
  explicit unit attributes until validation.
- `as_age()`, `categorize_age()`, `age_cat_iv()`, and `classify_age_scheme()` reject
  compound, squared, inverse, dimensionless, non-time and unsupported expressions,
  including missing and empty inputs. Errors identify the stored expression.
  Valid units, aliases, fractional precision, missingness and the calendar
  approximation safeguards retain their behavior. No representation or public
  signature changes were introduced.
- Added 538 regression assertions in `test-dimensional-validation.R`, covering
  the audit reproduction, apparent matching numerators, conversion modes,
  invalid and valid expressions, aliases, constructor metadata, empty/missing
  inputs and early validation. Updated roxygen help, README, NEWS, the scheme
  vignette and API policy.
- `devtools::document()` completed. The focused dimensional/calendar regression
  run passed 711 assertions before the final integer-attribute coverage was
  added; the final full `devtools::test()` passed 1,327 assertions with zero
  failures, warnings, or skips, including all new regression assertions.
- `devtools::check(document = FALSE,
  check_dir = "/tmp/agecraft-dimensional-check")` completed with 0 errors,
  0 warnings and 0 notes, including examples, installed tests and rebuilding
  all five vignettes. `git diff --check` passed. Logs are temporary local files:
  `/tmp/agecraft-dimensional-regression.log`, `/tmp/agecraft-dimensional-tests.log`
  and `/tmp/agecraft-dimensional-check.log`.

## Calendar conversion safeguard — 2026-11-11

- Month/year conversion in either direction now requires `allow_approx = TRUE`
  in `as_age()`, `categorize_age()`, `age_cat_iv()`, and
  `classify_age_scheme()`, including conversion of ages or group boundaries.
  The error explains why calendar coordinates need original dates for exact
  conversion. Explicit opt-in preserves numerical unit conversion behavior.
- This is an intentional public-default compatibility change. Matching units
  and supported elapsed-time conversions retain existing behavior; the `age`
  representation remains unchanged.
- Regression tests cover February 1–March 1, 2021, both calendar conversion
  directions, age/units/interval inputs, both classification directions, and
  opt-in results. Roxygen help, the age-schemes vignette, NEWS, and policy
  summaries describe the safeguard and direct target-unit age calculation.
- `devtools::document()` completed. `devtools::test()` passed 789 assertions
  with zero failures, warnings, or skips.
- `devtools::check(document = FALSE,
  check_dir = "/tmp/agecraft-calendar-check")` completed with 0 errors,
  0 warnings, and 0 notes, including examples, installed tests, and rebuilding
  all five vignettes. Logs: `/tmp/agecraft-calendar-tests.log` and
  `/tmp/agecraft-calendar-check.log` (temporary local validation artifacts).

## Newly implemented age schemes

- `age_scheme()` constructs a metadata object containing the existing interval
  vector. Validation requires nonempty named groups with explicit time units,
  checks nonoverlapping partitions independently of domain coverage, and checks
  declared complete/incomplete coverage. Source verification is recorded as a
  caller's claim and requires source, reference and version.
- `is_age_scheme()`, `validate_age_scheme()`, and `scheme_groups()` provide
  identification, validation, and group access. Print, summary and data-frame
  methods expose intervals, units, metadata, gaps, overlaps, and coverage.
- `categorize_age(..., by = scheme)` uses the existing classification path.
  Factor/interval defaults, overlap resolution and unit conversion are preserved.
- `classify_age_scheme()` returns every matching category in a long data frame,
  retaining original observation/category indices and explicit missing/unmatched
  statuses. Interval inputs require full containment.
- `get_age_scheme()` and `list_age_schemes()` expose all eight legacy presets as
  year-based definitions with unchanged cut points and uncertain external source
  editions. Numeric presets and the compatibility alias are unchanged.
- Roxygen-generated help, a new age-schemes vignette, README examples, and focused
  regression tests cover the new API. No new dependency was introduced.

## Feature validation — 2026-11-10

- Baseline `devtools::test()`: 416 passing assertions, zero failures/warnings/skips.
- Final feature `devtools::test()`: 609 passing assertions, zero failures/warnings/skips.
- `devtools::document()` completed and `devtools::check(document = FALSE)`
  finished with **0 errors, 0 warnings, 0 notes**. Examples, installed tests and
  all five vignettes passed, including vignette rebuilding.
- Version `0.1.0.9015` was checked again after the version increment:
  **0 errors, 0 warnings, 0 notes**, including installed tests, examples and
  rebuilding all five vignettes. Log: `/tmp/agecraft-scheme-version-check.log`.
- Local logs: `/tmp/agecraft-scheme-baseline.log`,
  `/tmp/agecraft-scheme-full-tests.log`, and `/tmp/agecraft-scheme-check.log`.
  These are temporary validation logs, not portable release artifacts.

## Remaining work

Independently verify authoritative published scheme editions before adding them.
Scheme transformation APIs and downstream `tarr.pop` integration remain deferred.
Scheme definitions must not force lazy arrays into memory or authorize splitting
aggregate counts. Release stabilization, final release version, external name
availability and release checks remain separate from this development increment.

The earlier implementation and validation baseline is retained below as history.

---

# agecraft current state — 2026-11-09

Version: **0.1.0.9014** (development). Requires R >= 4.1.0.
The package remains experimental; the core workflow is implemented and the next
stage is public API stabilization and release preparation.

## Implemented

- `calculate_age()` returns a fractional `age` vector by default. Years and
  months use calendar anniversaries; finer units measure elapsed time.
  Leap birthdays advance on March 1 in non-leap years, and month anniversaries
  roll back to the last day of shorter months. Calendar calculations use civil
  dates in the start time zone and ignore time of day.
- `age()`, `as_age()`, and `is_age()` construct, convert, and identify numeric
  age vectors with one explicit unit. Display shows completed whole units while
  retaining fractional precision. `as.numeric()` extracts fractions;
  `as.integer()` extracts completed units. Explicit unit conversion guards
  approximate conversions between months/years and finer units.
- `calculate_age(output = "units")` preserves the previous completed-age units
  output; `output = "numeric"` returns plain completed ages. `calc_age()` and
  `age_auto_unit()` retain their completed-age outputs.
- `age_group()` supports nonnegative fractional bounds without rounding, gaps,
  overlaps, explicit or unspecified units, and missing intervals. Intervals are
  lower inclusive and upper exclusive. `[1,5)` is labelled `1-4`; fractional
  bounds use explicit interval notation such as `[0, 0.077)`.
- Optional group names supply ordered-factor labels, with interval-label fallback
  for blank or missing names. Distinct intervals must have unique resulting
  labels. Names and units survive slicing, sorting, concatenation and binding;
  coverage set operations discard names because they can change intervals.
- `categorize_age()` supports factor or per-observation interval output,
  fractional matching, containment of interval inputs, overlap resolution and
  unit conversion controls. Unspecified group units inherit the ages' unit;
  unitless ages with specified group units are rejected.
- `age_group_presets` is the preferred list name; `age.groups` remains an
  identical compatibility alias. The installed targeted R-script migration helper
  previews edits, preserves comments/strings/line endings and writes backups.
- `age_auto_unit()` supports opt-in weeks with configurable eligible units,
  retaining the legacy day/month/year default and named numeric output.
- `compare_age_groups()` supports labelled crosswalks, definite/possible
  membership, ordering, exclusive age-gap bounds, set operations and widths.
  Comparisons require matching units and do not allocate aggregate counts.
- `age_cat()` warns once per session. `calc_age()` and `age.cat()` emit
  once-per-session messages. Deprecated wrappers and the old preset name remain
  through the next non-development release; removal requires a later announced
  breaking release. S3 compatibility infrastructure remains registered.
- README, migration guidance and four runnable vignettes cover getting started,
  the two vector classes, public-health reporting, and range comparisons in
  genealogy, sociology and economics.

## Validation

Local validation on 2026-11-09 at version 0.1.0.9014:

- `devtools::test()`: **416 passing assertions**, no failures, warnings or skips.
- `devtools::check()`: **0 errors, 0 warnings, 0 notes**, including examples,
  installed-package tests and rebuilding all four vignettes.
- Review-session logs: `/tmp/agecraft-review-tests.log` and
  `/tmp/agecraft-review-check.log` (temporary local files, not release artifacts).

The latest GitHub Actions run verified on 2026-11-09 was completed successfully
on 2026-11-03 for commit `a196c09`: Linux release/devel/oldrel-1, macOS release,
and Windows release. See
[the run](https://github.com/RussJones007/agecraft/actions/runs/41645900473).
These results describe the code before the subsequent documentation refresh;
new release checks should be recorded against the final release commit.
After the documentation refresh, `devtools::build(vignettes = TRUE, path =
"/tmp")` also succeeded, executing and rebuilding all four vignettes. Its log
is `/tmp/agecraft-doc-refresh-build.log`; `git diff --check` passed.

## Repository and remaining work

Repository: https://github.com/RussJones007/agecraft . At the review baseline,
local and remote `main` matched commit `a196c09` and the working tree was clean.
The latest code commits are dated 2026-10-20; no release tags were present locally.

Before a non-development release, stabilize the public API, document the changed
`calculate_age()` default return type, choose a release version, rerun the full
checks and CI, and complete `scripts/release.md`. CRAN incoming checks and current
package-name availability still need verification before submission.

Calendar shifting, automatic hours, and a general rage-script converter remain
deferred. Fractional age-group bounds are implemented. Preset provenance still
has unknown external source editions; these are inherited reporting conventions,
not verified current clinical guidance.
