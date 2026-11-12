# Phase-two validation

Baseline commit: e25155c. Working tree was clean before phase two.
Version: 0.1.0.9020. See docs/CURRENT_STATE.md for results and limitations.

Executed from the repository root, with TZ=UTC:

```sh
Rscript -e 'devtools::test()' # phase-one baseline: 3324 pass, one optional skip
Rscript scripts/validation/age-class-naming/capture-phase1.R
# Apply renames and collision guards, then regenerate help.
Rscript -e 'devtools::document()'
Rscript -e 'devtools::test(filter = "age-group|age-interval-naming")'
Rscript -e 'devtools::test()' # phase two: 3389 pass, one optional skip
Rscript -e 'devtools::check(document = FALSE, check_dir = "/tmp/agecraft-phase2-check")'
R CMD INSTALL --library=/tmp/agecraft-phase2-lib .
Rscript --vanilla -e '.libPaths(c("/tmp/agecraft-phase2-lib", .libPaths())); source("scripts/validation/age-class-naming/check-phase2-installed.R")'
git diff --check
```

Focused tests: 185 passing assertions. Package check: zero errors, zero warnings,
one environment note (remote clock verification). Installed tests: 3389 pass and
one skip because mudnester is not installed. All seven vignettes rebuilt.

A separate yaml check verified that all pkgdown reference topics resolve to
man/*.Rd files. Additional fresh source probes confirmed actionable legacy
rejection through as.numeric(), as.data.frame(), vec_slice() and vec_c().
No website build or real installed-mudnester catalogue test was performed.
