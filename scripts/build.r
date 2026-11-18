# Run from the package root: Rscript scripts/build.r
# Build only; does not change the version, install packages, or change bspm.
source_pkg <- build(vignettes = TRUE, binary = FALSE)
binary_pkg <- build(pkg = src_pkg, binary = TRUE)
