# agecraft migration — 2026-10-09

Created from the current local rage working tree, version 0.1.0.9009. The original project was preserved. Copied R sources, documentation, tests, packaged data, data-generation scripts, development scripts, license, README, and RStudio project configuration. Git history, IDE/session state, and assistant/cloud configuration were excluded.

Renamed the package, package documentation files, RStudio project, and test runner to agecraft. Regenerated documentation and NAMESPACE with roxygen2. Removed the original GitHub URL/BugReports fields and installation command because no agecraft repository has been created. The minimum R version is now 4.1.0 because existing code uses native pipes and anonymous-function shorthand. Development scripts and review/migration notes are excluded from source package builds.

## Name availability

No case-insensitive exact agecraft match was found in CRAN's current PACKAGES.gz or its source archive directory. Bioconductor 3.23 (release) and 3.24 (development) software, annotation, experiment, and workflow indexes were checked through the official TU Dortmund mirror because the main site's downloads returned HTTP 403. All eight indexes returned zero matches. The main site's removed-packages listing and targeted official-domain searches also returned no matches.

Sources:
- https://cran.r-project.org/src/contrib/PACKAGES.gz
- https://cran.r-project.org/src/contrib/Archive/
- https://bioconductor.org/packages/release/BiocViews.html
- https://bioconductor.org/packages/devel/BiocViews.html
- https://bioconductor.org/about/removed-packages/
- https://bioconductor.org/about/mirrors/

This is a dated availability check, not a name reservation or guarantee of repository acceptance.

## Validation

All 87 existing test expectations passed, with zero failures, warnings, or skips. Source-package installation and namespace loading succeeded in R CMD check. Detailed results are in REVIEW.md and scripts/validation/. The packaged age.groups.rda data is byte-identical to the original. Functional refactoring is intentionally left for follow-up based on the review.

## Refactoring update — 0.1.0.9010

Replace `library(rage)` with `library(agecraft)`. Prefer `calculate_age()` and
`categorize_age()` over the retained, deprecated wrappers. Reversed dates now
raise an error instead of returning negative ages. Age-group concatenation
rejects incompatible units. Automatic unit selection now respects calendar
anniversaries while retaining the legacy day-30 convention. Factor coercion
preserves observation order. Bundled numeric cut points are unchanged.
