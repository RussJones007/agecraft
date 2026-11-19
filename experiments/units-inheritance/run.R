# Run from repository root: Rscript experiments/units-inheritance/run.R baseline|prototype
library(agecraft) # load_all below ensures the checked-out source is used.
library(testthat)
library(units)
library(vctrs)
devtools::load_all(quiet = TRUE)
mode <- commandArgs(TRUE)[1]
stopifnot(mode %in% c("baseline", "prototype", "hybrid"))
root <- normalizePath("experiments/units-inheritance")
options(agecraft.units_experiment.hybrid = mode == "hybrid")
expected_class <- if (mode == "hybrid") c("age", "vctrs_vctr", "units", "double") else c("age", "units")
if (mode != "baseline") source(file.path(root, "prototype.R"))
make_age <- if (mode != "baseline") p_age else agecraft::age
convert <- agecraft::as_age
# Portable baseline observations, not serialized age objects.
observe <- function() {
  x <- make_age(c(a = 0.25, b = 5, c = NA_real_), "year")
  groups <- agecraft::age_interval(breaks = c(0, 1, 5, Inf), unit = "year")
  names(groups) <- c("Infant", "Child", "Older")
  scheme <- agecraft::age_scheme(groups, id = "experiment", name = "Experiment")
  list(values = as.numeric(x), integer = as.integer(x), display = format(x),
    fractional = format(x, fractional = TRUE), names = names(x),
    slice = as.numeric(x[c(3, 1)]), concat = as.numeric(c(x, x)),
    cast = as.numeric(vctrs::vec_cast(x, x[0])),
    restore = as.numeric(vctrs::vec_restore(c(0.25, NA), x)),
    add = as.numeric(x + 2), reverse_add = as.numeric(2 + x),
    subtract = as.numeric(x - 0.1), compare = x == x,
    mean = as.numeric(mean(x, na.rm = TRUE)),
    median = as.numeric(stats::median(x, na.rm = TRUE)),
    groups = as.character(agecraft::categorize_age(x, by = groups)),
    scheme = as.character(agecraft::categorize_age(x, by = scheme)),
    interval = format(agecraft::categorize_age(x, by = scheme, output = "interval")),
    membership = agecraft::classify_age_scheme(x, scheme)[c("observation", "label", "status")])
}
if (mode == "baseline") saveRDS(observe(), file.path(root, "results/baseline.rds"))
test_results <- testthat::test_dir(file.path(root, "testthat"), reporter = "summary",
                   env = environment(), stop_on_failure = TRUE)
test_table <- as.data.frame(test_results)
write.csv(test_table[c("test", "nb", "failed", "skipped", "error", "warning", "passed")],
  file.path(root, paste0("results/", mode, "-tests.csv")), row.names = FALSE)
saveRDS(observe(), file.path(root, paste0("results/", mode, "-observations.rds")))
if (!"--tests-only" %in% commandArgs(TRUE) && mode != "hybrid" && requireNamespace("bench", quietly = TRUE)) {
  rows <- list()
  for (n in c(1L, 1000L, 100000L, 1000000L)) {
    values <- rep(c(1.25, 2.5, NA_real_), length.out = n)
    x <- make_age(values, "day")
    y <- make_age(values, "year")
    workloads <- list(construction = function() make_age(values, "day"),
      exact_conversion = function() convert(x, "hour"),
      approximate_conversion = function() convert(y, "day", allow_approx = TRUE),
      arithmetic = function() x + 1, comparison = function() x == x,
      concatenation = function() c(x, x), subsetting = function() x[seq_len(n)])
    for (task in names(workloads)) {
      cat("Benchmark:", mode, n, task, "\n")
      f <- workloads[[task]]
      for (i in seq_len(3)) invisible(f())
      b <- bench::mark(f(), iterations = 7, check = FALSE, filter_gc = FALSE)
      rows[[length(rows) + 1L]] <- data.frame(mode, n, task,
        median_seconds = as.numeric(b$median), allocation_bytes = as.numeric(b$mem_alloc),
        iterations = b$n_itr, gc = b$n_gc)
      write.csv(do.call(rbind, rows), file.path(root,
        paste0("results/", mode, "-benchmarks.csv")), row.names = FALSE)
    }
  }
  write.csv(do.call(rbind, rows), file.path(root, paste0("results/", mode, "-benchmarks.csv")), row.names = FALSE)
}
capture.output(sessionInfo(), file = file.path(root, paste0("results/", mode, "-session.txt")))
