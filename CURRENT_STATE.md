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
