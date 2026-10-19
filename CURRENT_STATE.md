# agecraft current state — 2026-10-18

Version: **0.1.0.9011**, incremented with `usethis::use_version("dev")`.
Requires R >= 4.1.0.

## Implemented

- Public whole-number `age_group()` constructor; fractional bounds remain errors.
  `[1,5)` is labelled `1-4`. Gaps, overlaps, units and missing pairs are supported.
- `categorize_age()` supports factor or per-observation interval output,
  containment of interval inputs, overlap resolution and unit conversion controls.
- `age_group_presets` replaces the preferred list name; `age.groups` remains an
  identical compatibility alias. The installed targeted R-script migration helper
  previews edits, preserves comments/strings/line endings and writes backups.
- `age_auto_unit()` supports opt-in weeks with configurable eligible units,
  retaining the legacy default and named numeric output.
- `compare_age_groups()` supports labelled crosswalks, definite/possible
  membership, ordering, exclusive age-gap bounds, set operations and widths.
- `age_cat()` warns once per session. Deprecated wrappers and the old preset
  name remain through the next non-development release; removal requires a
  later announced breaking release. S3 infrastructure remains registered.
- README migration guidance, API policy, NEWS and two runnable vignettes cover
  public health, genealogy, sociology and economics.

## Validation

All **259 test expectations pass**, including installed-package tests, with no
failures, warnings or skips. Final `devtools::check(document = FALSE, cran = TRUE,
manual = TRUE, remote = FALSE)` on R 4.6.1 reports **0 errors, 0 warnings, 1 note**.
The note is unavailable HTML Tidy validation because the system lacks `tidy`.
Examples, both vignette rebuilds and the PDF manual pass. The manual uses
`R_RD4PDF=times,hyper`; remote system-clock verification was disabled.
The check log is saved in `scripts/validation/check-0.1.0.9011.log`.

## Repository and remaining work

Repository: https://github.com/RussJones007/agecraft . The local `main` history
contains separate implementation commits; the pre-existing remote `master`
history is preserved. Cross-platform GitHub Actions results are separate from
local validation and are not claimed here.

Calendar shifting, automatic hours, fractional age-group bounds and a general
rage-script converter are outside this implementation. Preset provenance still
has unknown external source editions; these are legacy reporting conventions,
not current clinical guidance. CRAN incoming checks have not been run.
