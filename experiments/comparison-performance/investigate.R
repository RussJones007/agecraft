# Baseline-only comparison experiment: run in a fresh process from repository root.
# Changes one S3 registration in this process; does not alter production sources.
library(testthat)
devtools::load_all(quiet = TRUE)
root <- "experiments/comparison-performance"
baseline_cast <- getS3method("vec_cast", "age.age", envir = asNamespace("vctrs"))

source(file.path(root, "candidate.R"))
set_cast <- function(fun) {
  registerS3method("vec_cast", "age.age", fun, envir = asNamespace("vctrs"))
}

# Capture original outputs/errors for matching and mismatched vectors.
cases <- list(
  list(c(a = 0, b = 1.25, c = NA_real_, d = NaN), c(1, 1.25, NA, 0)),
  list(1:3, 2), list(2, 1:3), list(numeric(), numeric()),
  list(numeric(), 1), list(c(NA_real_, NaN), NA_real_),
  list(1:2, 1:3))
ops <- c("==", "!=", "<", "<=", ">", ">=")
observe <- function() {
  lapply(ops, function(op) lapply(cases, function(pair) {
    x <- agecraft::age(pair[[1]], "day")
    y <- agecraft::age(pair[[2]], "day")
    tryCatch(list(result = do.call(op, list(x, y))),
      error = function(e) list(error = class(e)[1]))
  }))
}
expected <- observe()
set_cast(range_cast)
results <- testthat::with_reporter(testthat::SummaryReporter$new(), {
  first_ok <- test_that("all six comparisons preserve values, names, missingness and recycling", {
    expect_identical(observe(), expected)
    for (op in ops) {
      expect_error(do.call(op, list(agecraft::age(1, "day"), agecraft::age(24, "hour"))),
        "incompatible units")
      expect_error(do.call(op, list(agecraft::age(1), 1)))
    }
  })
  second_ok <- test_that("casts retain validation and object representation", {
    for (values in list(numeric(), NA_real_, NaN, c(NA_real_, NaN),
                        c(a = 0, b = .5, c = .Machine$double.xmax), 1:10)) {
      x <- agecraft::age(values, "day")
      expect_identical(range_cast(x, x[0]), baseline_cast(x, x[0]))
    }
    for (values in list(-1, Inf, -Inf, c(NA, Inf), c(NaN, -1))) {
      x <- structure(as.double(values), class = c("age", "vctrs_vctr", "double"), unit = "day")
      expect_error(range_cast(x, agecraft::age(unit = "day")), "nonnegative and finite")
      expect_error(baseline_cast(x, agecraft::age(unit = "day")), "nonnegative and finite")
      for (op in ops) expect_error(do.call(op, list(x, x)), "nonnegative and finite")
    }
    x <- agecraft::age(1)
    attr(x, "unit") <- "kg"
    expect_error(range_cast(x, x), "Unsupported age unit")
  })
  stopifnot(first_ok, second_ok)
})
set_cast(baseline_cast)
rows <- list()
for (n in c(1L, 1000L, 100000L, 1000000L)) {
  values <- rep(c(0, 1.25, 2.5, NA_real_, NaN), length.out = n)
  x <- agecraft::age(values, "day")
  y <- agecraft::age(rev(values), "day")
  for (op in c("==", "<")) {
    for (mode in c("baseline", "range_cast")) {
      set_cast(if (mode == "baseline") baseline_cast else range_cast)
      f <- function() do.call(op, list(x, y))
      for (i in 1:3) invisible(f())
      b <- bench::mark(f(), iterations = 15, check = FALSE, filter_gc = FALSE)
      rows[[length(rows) + 1L]] <- data.frame(n, op, mode,
        median_seconds = as.numeric(b$median), allocation_bytes = as.numeric(b$mem_alloc),
        iterations = b$n_itr, gc = b$n_gc)
    }
  }
}
set_cast(baseline_cast)
write.csv(do.call(rbind, rows), file.path(root, "benchmarks.csv"), row.names = FALSE)
# Profile only the unmodified baseline, with a supported sampling interval.
x <- agecraft::age(rep(c(1.25, 2.5, NA_real_), length.out = 1000000), "day")
profile <- tempfile()
Rprof(profile, interval = .01, memory.profiling = TRUE)
for (i in 1:50) invisible(x == x)
Rprof(NULL)
p <- summaryRprof(profile, memory = "both")
write.csv(p$by.total, file.path(root, "baseline-profile.csv"))
capture.output(sessionInfo(), file = file.path(root, "session.txt"))
cat("Comparison and cast assertions completed; measurements written.\n")
