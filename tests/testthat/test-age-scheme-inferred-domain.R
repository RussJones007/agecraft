inferred_groups <- function(start, end) {
  g <- age_interval(start, end, unit = "year")
  names(g) <- paste0("Category ", seq_along(start))
  g
}

test_that("domain inference and explicit coverage preserve distinct intent", {
  g <- inferred_groups(c(40, 18), c(65, 40))
  s <- age_scheme(g, "adult", "Adult ages")
  expect_null(s$domain)
  expect_true(s$complete)
  info <- summary(s)
  expect_identical(info$domain, c(18, 65))
  expect_true(info$domain_inferred)
  expect_true(info$complete)
  expect_true(info$covered)
  expect_length(info$gaps, 0)
  expect_identical(s$intervals, g)
  wider <- age_scheme(g, "all", "All intended ages", domain = c(0, Inf))
  expect_false(wider$complete)
  expect_false(summary(wider)$domain_inferred)
  expect_identical(ivs::iv_start(summary(wider)$gaps), c(0, 65))
  expect_identical(ivs::iv_end(summary(wider)$gaps), c(18, Inf))
  expect_false("complete" %in% names(formals(age_scheme)))
  expect_error(age_scheme(g, "old", "Old", complete = TRUE), "unused argument")
})

test_that("inferred coverage detects gaps independently of overlap", {
  gap <- age_scheme(inferred_groups(c(0, 10), c(5, Inf)), "gap", "Gap")
  expect_false(gap$complete)
  expect_identical(summary(gap)$domain, c(0, Inf))
  overlap <- age_scheme(inferred_groups(c(10, 15), c(20, 25)),
                        "overlap", "Overlap", type = "classification")
  expect_true(overlap$complete)
  expect_true(summary(overlap)$overlaps)
  tiny <- age_scheme(inferred_groups(c(0, 0.5 + 2^-50), c(0.5, 1)),
                     "tiny", "Tiny gap")
  expect_false(tiny$complete)
  expect_identical(ivs::iv_end(summary(tiny)$gaps), 0.5 + 2^-50)
})

test_that("edits recalculate inferred domains and retain explicit domains", {
  g <- inferred_groups(c(0, 10), c(10, 20))
  original <- age_scheme(g, "original", "Original")
  x <- original
  x$intervals <- g[1]
  expect_identical(summary(x)$domain, c(0, 10))
  expect_true(x$complete)
  expect_identical(x$derived_from$id, original$id)
  x$domain <- c(0, 20)
  expect_false(x$complete)
  expect_false(summary(x)$domain_inferred)
  x$domain <- NULL
  expect_true(x$complete)
  expect_true(summary(x)$domain_inferred)
  explicit <- age_scheme(g, "explicit", "Explicit", domain = c(0, 20))
  explicit$intervals <- g[1]
  expect_false(explicit$complete)
  expect_identical(summary(explicit)$domain, c(0, 20))
  saved <- serialize(explicit, NULL)
  expect_error(explicit$complete <- TRUE, "cannot be assigned")
  expect_error(explicit[["complete"]] <- FALSE, "cannot be assigned")
  expect_error(explicit["complete"] <- list(NA), "cannot be assigned")
  expect_identical(serialize(explicit, NULL), saved)
  expect_identical(unserialize(serialize(x, NULL)), x)
})

test_that("legacy unknown coverage remains readable and is calculated on inspection", {
  g <- inferred_groups(c(0, 10), c(5, 20))
  legacy <- unclass(age_scheme(g, "legacy", "Legacy"))
  legacy$complete <- NA
  legacy$derived_from <- NULL
  class(legacy) <- "age_scheme"
  saved <- serialize(legacy, NULL)
  expect_identical(validate_age_scheme(legacy), legacy)
  expect_false(summary(legacy)$complete)
  expect_identical(summary(legacy)$domain, c(0, 20))
  expect_identical(serialize(legacy, NULL), saved)
  legacy$notes <- "Clarified purpose"
  expect_false(legacy$complete)
  expect_null(legacy$derived_from)
  malformed <- unclass(legacy)
  malformed$complete <- TRUE
  class(malformed) <- "age_scheme"
  expect_error(validate_age_scheme(malformed), "coverage")
})
