# agecraft current state — 2026-10-09

Version: **0.1.0.9010**, development package; R >= 4.1.0.

## Implemented

- Standalone renamed agecraft package with source, data, documentation, and tests.
- Corrected documentation examples, dependency declarations, and check notes.
- Explicit age-group unit negotiation, metadata preservation, safe casting, and
  observation-preserving factor coercion, including missing intervals.
- Calendar-based year/month calculations, explicit reversed-date errors, local
  time-zone handling, and non-overlapping automatic unit selection.
- Documented legacy wrappers with persistent once-per-session messages.
- Focused regression tests, a runnable public-health vignette, NEWS, migration
  notes, data provenance for every grouping, portable build/release scripts,
  pkgdown configuration, and a five-job GitHub Actions check matrix.
- Bundled age.groups data retained byte-for-byte from rage.

## Validation

138 test expectations passed: zero failures, warnings, or skips.
`devtools::check(document = FALSE, cran = TRUE)` passed with **0 errors,
0 warnings, and 0 notes**, including examples, installation, namespace loading,
and vignette rebuilding. This Linux check used R 4.6.1 and `--no-manual`;
remote CRAN incoming checks were not enabled. The 16-page PDF reference manual
compiled successfully using installed fonts (`R_RD4PDF=times,hyper`). Logs are
in scripts/validation/.

## Remaining release work

- Execute the CI matrix on GitHub to confirm macOS, Windows, and other R versions.
- Run remote incoming/CRAN checks and choose a non-development release version.
- Confirm external source editions for legacy public-health groupings: they were
  not recorded by rage. The provenance table explicitly marks these unknown.
- Default PDF-manual generation requires the missing system font package
  inconsolata; the reference can be built with `R_RD4PDF=times,hyper`.

GitHub account verified: RussJones007. SSH push authentication works. Repository
creation awaits a signed-in browser session; no GitHub repository URL is claimed
until creation succeeds. The user has requested repository creation and push.
