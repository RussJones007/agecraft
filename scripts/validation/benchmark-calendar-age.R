# Run from the repository root after installing this branch with R CMD INSTALL.
# Requires bench. Pass an optional Git revision for the original R calculation.
library(agecraft)

args <- commandArgs(trailingOnly = TRUE)
baseline_ref <- if (length(args)) args[[1]] else "7e732d4"
baseline_source <- system2("git", c("show", shQuote(paste0(baseline_ref, ":R/Age_calculation.r"))),
                           stdout = TRUE)
stopifnot(length(baseline_source) > 0L, is.null(attr(baseline_source, "status")))
baseline <- new.env(parent = asNamespace("agecraft"))
eval(parse(text = baseline_source), envir = baseline)

format_result <- function(result) {
  data.frame(
    implementation = as.character(result$expression),
    median_ms = round(as.numeric(result$median) * 1000, 4),
    allocated_bytes = as.numeric(result$mem_alloc)
  )
}

set.seed(142)
cat("Baseline:", baseline_ref, "\n")
for (n in c(1L, 1000L, 100000L)) {
  birth <- as.Date("1920-01-01") + sample.int(37000L, n, replace = TRUE) - 1L
  for (layout in c("shared", "pairwise")) {
    reference <- if (layout == "shared") as.Date("2026-02-28") else
      birth + sample.int(36525L, n, replace = TRUE)
    for (unit in c("year", "month")) {
      for (output in c("age", "numeric")) {
        invisible(baseline$calculate_age(birth, reference, unit, output))
        invisible(calculate_age(birth, reference, unit, output))
        cat("\nPublic API:", n, layout, unit, output, "\n")
        timing <- bench::mark(
          original = baseline$calculate_age(birth, reference, unit, output),
          experiment = calculate_age(birth, reference, unit, output),
          min_time = 0.15, max_iterations = 1000, filter_gc = FALSE
        )
        print(format_result(timing), row.names = FALSE)
        if (unit == "year" && output == "numeric" &&
            requireNamespace("timeplyr", quietly = TRUE)) {
          external <- suppressWarnings(timeplyr::age_years(birth, reference))
          if (isTRUE(all.equal(external, timing$result[[2]]))) {
            external_timing <- bench::mark(
              timeplyr = suppressWarnings(timeplyr::age_years(birth, reference)),
              min_time = 0.15, max_iterations = 1000, filter_gc = FALSE
            )
            print(format_result(external_timing), row.names = FALSE)
          } else {
            cat("timeplyr skipped because completed ages differ on this workload.\n")
          }
        }
      }
    }
  }
}

cat("\nCalendar kernels:", n, "pairwise, fractional years\n")
print(format_result(bench::mark(
  original = agecraft:::calendar_age_r(birth, reference, TRUE, TRUE, "mar1"),
  experiment = agecraft:::calendar_age_cpp(birth, reference, TRUE, TRUE, TRUE),
  min_time = 0.15, max_iterations = 1000, filter_gc = FALSE
)), row.names = FALSE)

event <- birth + sample.int(36525L, length(birth), replace = TRUE)
cat("\nAutomatic units:", n, "pairwise\n")
print(format_result(bench::mark(
  original = baseline$age_auto_unit(birth, event),
  experiment = age_auto_unit(birth, event),
  min_time = 0.15, max_iterations = 1000, filter_gc = FALSE
)), row.names = FALSE)
