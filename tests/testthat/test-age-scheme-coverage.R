coverage_intervals <- function(start, end) {
  g <- age_interval(start, end, unit = "year")
  names(g) <- paste0("G", seq_along(start))
  g
}

test_that("Boolean overlap respects exact half-open endpoints", {
  cases <- list(
    list(c(0, 1), c(1, 2), FALSE),
    list(c(0, 1), c(2, 3), TRUE),
    list(c(0, 1, 3), c(10, 2, 4), TRUE),
    list(c(0, 0), c(1, 1), TRUE),
    list(c(2, 0, 1), c(3, 1, 2), FALSE),
    list(c(0, 0.5 + 2^-50), c(0.5, 1), FALSE),
    list(c(0, 0.5 - 2^-50), c(0.5, 1), TRUE),
    list(c(1, 0), c(Inf, 1), FALSE),
    list(c(0, 2), c(Inf, Inf), TRUE),
    list(0, Inf, FALSE)
  )
  for (case in cases) {
    g <- coverage_intervals(case[[1]], case[[2]])
    before <- g
    assessment <- agecraft:::age_scheme_coverage(g, NULL)
    expect_identical(assessment$overlaps, case[[3]])
    expect_null(assessment$gaps)
    expect_identical(assessment$covered, NA)
    expect_identical(g, before)
    if (case[[3]]) {
      expect_error(age_scheme(g, "p", "Partition"), "partition intervals must not overlap")
    } else {
      expect_s3_class(age_scheme(g, "p", "Partition"), "age_scheme")
    }
    expect_s3_class(age_scheme(g, "c", "Classification", type = "classification"),
                    "age_scheme")
  }
})

test_that("sorted overlap agrees with an independent pairwise oracle", {
  set.seed(601)
  for (iteration in seq_len(100)) {
    n <- sample.int(12, 1)
    start <- sample(0:30, n, replace = TRUE) / 4
    end <- start + sample(1:40, n, replace = TRUE) / 8
    if (iteration %% 5 == 0) end[sample.int(n, 1)] <- Inf
    expected <- FALSE
    if (n > 1) {
      for (i in seq_len(n - 1L)) {
        for (j in seq.int(i + 1L, n)) {
          expected <- expected || (start[i] < end[j] && start[j] < end[i])
        }
      }
    }
    g <- coverage_intervals(start, end)
    expect_identical(agecraft:::age_scheme_coverage(g, NULL)$overlaps, expected)
  }
})

test_that("coverage and completeness retain exact gaps and infinite domains", {
  g <- coverage_intervals(c(1, 0, 0.5 + 2^-50), c(Inf, 0.5, 1))
  s <- age_scheme(g, "gapped", "Gapped", domain = c(0, Inf), complete = FALSE)
  info <- summary(s)
  expect_false(info$covered)
  expect_false(info$overlaps)
  expect_identical(ivs::iv_start(info$gaps), 0.5)
  expect_identical(ivs::iv_end(info$gaps), 0.5 + 2^-50)
  expect_error(age_scheme(g, "wrong", "Wrong", domain = c(0, Inf), complete = TRUE),
               "complete does not agree with domain coverage")
  adjacent <- coverage_intervals(c(1, 0), c(Inf, 1))
  complete <- age_scheme(adjacent, "complete", "Complete", domain = c(0, Inf),
                          complete = TRUE)
  expect_true(summary(complete)$covered)
  expect_length(summary(complete)$gaps, 0)
  expect_error(age_scheme(adjacent, "wrong", "Wrong", domain = c(0, 2)),
               "intervals must lie within domain")
  expect_error(age_scheme(adjacent, "wrong", "Wrong", complete = TRUE),
               "completeness claim requires an explicit domain")
})

test_that("assessment preserves category order and classification memberships", {
  g <- coverage_intervals(c(2, 0, 1), c(Inf, 1, 2))
  s <- age_scheme(g, "ordered", "Ordered", domain = c(0, Inf), complete = TRUE)
  a <- age(c(0, 1, 2, NA), unit = "year")
  expect_identical(scheme_intervals(s), g)
  expect_identical(classify_age_scheme(a, s)$group_index, c(2L, 3L, 1L, NA_integer_))
  expect_identical(categorize_age(a, by = s), categorize_age(a, by = g))
  overlapping <- coverage_intervals(c(1, 0, 0), c(2, 3, 3))
  s <- age_scheme(overlapping, "overlap", "Overlap", type = "classification",
                  domain = c(0, 3), complete = TRUE)
  expect_true(summary(s)$overlaps)
  expect_true(summary(s)$covered)
  expect_identical(classify_age_scheme(age(1, unit = "year"), s)$group_index, 1:3)
  expect_identical(scheme_intervals(s), overlapping)
  result <- withVisible(validate_age_scheme(s))
  expect_false(result$visible)
  expect_identical(result$value, s)
})

test_that("summary performs one coverage assessment while validating", {
  g <- coverage_intervals(c(0, 1), c(1, 2))
  s <- age_scheme(g, "summary", "Summary", domain = c(0, 2), complete = TRUE)
  calls <- 0L
  original <- agecraft:::age_scheme_coverage
  local_mocked_bindings(age_scheme_coverage = function(...) {
    calls <<- calls + 1L
    original(...)
  }, .package = "agecraft")
  expect_true(summary(s)$covered)
  expect_identical(calls, 1L)
})
