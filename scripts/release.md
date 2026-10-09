# Release steps

Run from the agecraft project root.

1. Choose a release version deliberately with `usethis::use_version()` and update NEWS.md.
2. Run `devtools::document()`, `devtools::test()`, and `devtools::check()`.
3. Run `Rscript scripts/build.r` to create a source archive in build/.
4. Install explicitly with `devtools::install(build_vignettes = TRUE)` if needed.
5. Confirm all GitHub CI matrix jobs pass. Review data provenance and calendar conventions.
6. Before CRAN submission, rerun name availability, check remote incoming requirements,
   and check Windows/development R. The local check does not reserve the package name.

No script changes the version or installs the package automatically.
