# Run from the package root: Rscript scripts/build.r
# Build only; does not change the version, install packages, or change bspm.
if (!file.exists("DESCRIPTION")) stop("Run this script from the package root")
dir.create("build", showWarnings = FALSE)
archive <- devtools::build(path = "build", binary = FALSE, vignettes = TRUE)
cat("Built:", archive, "\n")
