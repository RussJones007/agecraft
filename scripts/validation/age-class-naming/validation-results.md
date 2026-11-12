# Phase-one validation record

See docs/CURRENT_STATE.md for outcomes and environment limitations.
Baseline tests: 3,289 pass; final tests: 3,324 pass; each has one optional
mudnester skip. Check transcripts are saved alongside this file.

Commands executed from the repository root:

```sh
Rscript -e 'devtools::test()'
Rscript -e 'devtools::check(document = FALSE, check_dir = "/tmp/agecraft-naming-baseline-check")'
Rscript tests/testthat/fixtures/age-class-naming/capture-baseline.R
TZ=UTC Rscript -e 'devtools::document()'
TZ=UTC Rscript -e 'devtools::test()'
TZ=UTC Rscript -e 'devtools::check(document = FALSE, check_dir = "/tmp/agecraft-naming-phase1-final-check")'
TZ=UTC R CMD INSTALL --library=/tmp/agecraft-phase1-lib .
TZ=UTC Rscript --vanilla -e '.libPaths(c("/tmp/agecraft-phase1-lib", .libPaths())); source("scripts/validation/age-class-naming/check-installed.R")'
git diff --check
```

Baseline capture occurred before production edits. The capture script was then
moved to scripts/validation/age-class-naming/capture-baseline.R. It is retained for
reproduction with the old package source; do not regenerate the fixture with
phase-one code. The installed check explicitly selects its library because a
startup configuration initially selected a different installed package when
only R_LIBS was supplied. The isolated --vanilla check above passed.

No release, merge or publication was performed.
