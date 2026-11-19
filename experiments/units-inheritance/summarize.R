# Combine recorded measurements; does not rerun tests or benchmarks.
root <- "experiments/units-inheritance/results"
b <- read.csv(file.path(root, "baseline-benchmarks.csv"))
p <- read.csv(file.path(root, "prototype-benchmarks.csv"))
stopifnot(nrow(b) == 28L, nrow(p) == 28L)
comparison <- merge(b, p, by = c("n", "task"), suffixes = c("_baseline", "_prototype"))
comparison$time_ratio <- comparison$median_seconds_prototype / comparison$median_seconds_baseline
comparison$allocation_ratio <- ifelse(comparison$allocation_bytes_baseline > 0,
  comparison$allocation_bytes_prototype / comparison$allocation_bytes_baseline, NA_real_)
write.csv(comparison, file.path(root, "benchmark-comparison.csv"), row.names = FALSE)
lines <- c("| N | Operation | Baseline ms | Prototype ms | Time ratio | Baseline MiB | Prototype MiB |",
  "| ---: | --- | ---: | ---: | ---: | ---: | ---: |")
for (i in seq_len(nrow(comparison))) {
  r <- comparison[i, ]
  lines <- c(lines, sprintf("| %s | %s | %.3f | %.3f | %.2f | %.3f | %.3f |",
    format(r$n, scientific = FALSE, trim = TRUE), gsub("_", " ", r$task),
    1000 * r$median_seconds_baseline, 1000 * r$median_seconds_prototype,
    r$time_ratio, r$allocation_bytes_baseline / 1024^2,
    r$allocation_bytes_prototype / 1024^2))
}
writeLines(lines, file.path(root, "benchmark-summary.md"))
for (mode in c("baseline", "prototype", "hybrid")) {
  t <- read.csv(file.path(root, paste0(mode, "-tests.csv")))
  cat(mode, "passes:", sum(t$passed), "failures:", sum(t$failed),
      "warnings:", sum(t$warning), "skips:", sum(t$skipped), "\n")
}
