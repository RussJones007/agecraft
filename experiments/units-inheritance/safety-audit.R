# Desired safety assertions; a nonzero exit records unresolved prototype defects.
library(testthat)
devtools::load_all(quiet = TRUE)
mode <- if (identical(commandArgs(TRUE)[1], "hybrid")) "hybrid" else "prototype"
options(agecraft.units_experiment.hybrid = mode == "hybrid")
source("experiments/units-inheritance/prototype.R")
root <- normalizePath("experiments/units-inheritance")
results <- testthat::test_dir(file.path(root, "safety"), reporter = "summary",
  env = environment(), stop_on_failure = FALSE)
tab <- as.data.frame(results)
write.csv(tab[c("test", "nb", "failed", "skipped", "error", "warning", "passed")],
  file.path(root, paste0("results/", mode, "-safety-tests.csv")), row.names = FALSE)
quit(status = if (any(tab$failed > 0 | tab$error)) 1L else 0L)
