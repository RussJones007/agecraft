test_that("duplicate-only classifications retain labels, boundaries and statuses", {
  g <- age_interval(c(0, 0), c(5, 5), unit = "year")
  names(g) <- c("Early childhood", "Preschool age")
  s <- age_scheme(g, "duplicates", "Shared range", type = "classification",
                  domain = c(0, 5), complete = TRUE)
  expect_true(summary(s)$covered)
  values <- c(2, 5, 8, NA_real_)
  a <- age(values, unit = "year")
  out <- classify_age_scheme(a, s)
  expect_identical(out$observation, c(1L, 1L, 2L, 3L, 4L))
  expect_identical(out$group_index, c(1L, 2L, NA_integer_, NA_integer_, NA_integer_))
  expect_identical(out$label, c(names(g), NA_character_, NA_character_, NA_character_))
  expect_identical(out$status, c("matched", "matched", "unmatched", "unmatched", "missing"))
  expect_identical(names(out$group), out$label)
  # Plain numeric observations require explicit units for a unit-bearing scheme.
  numeric_units <- units::set_units(values, "year")
  expect_identical(classify_age_scheme(numeric_units, s), out)
  expect_error(categorize_age(a, by = s), "match more than one group")
  for (policy in c("first", "last")) {
    selected <- if (policy == "first") 1L else 2L
    result <- categorize_age(a, by = s, multiple = policy)
    expect_identical(levels(result), names(g))
    expect_identical(as.character(result), c(names(g)[selected], rep(NA_character_, 3)))
    expect_identical(categorize_age(numeric_units, by = s, multiple = policy), result)
    interval <- categorize_age(a, by = s, multiple = policy, output = "interval")
    expect_identical(names(interval), c(names(g)[selected], rep(NA_character_, 3)))
  }
})

test_that("three identical intervals retain every original semantic category", {
  g <- age_interval(rep(0, 3), rep(5, 3), unit = "year")
  names(g) <- c("Third meaning", "First meaning", "Second meaning")
  s <- age_scheme(g, "triple", "Three meanings", type = "classification")
  out <- classify_age_scheme(age(2, unit = "year"), s)
  expect_identical(out$group_index, 1:3)
  expect_identical(out$label, names(g))
  # This records current exact-tie behavior, without promising a new sort policy.
  expect_identical(as.character(categorize_age(age(2, unit = "year"), by = s,
                                               multiple = "last")), names(g)[3])
  names(g) <- rep("Same label", 3)
  expect_error(age_scheme(g, "invalid", "Invalid", type = "classification"),
               "intervals require unique nonblank names")
})

test_that("duplicate intervals cannot fill uncovered portions of a domain", {
  g <- age_interval(c(0, 0, 3), c(1, 1, 5), unit = "year")
  names(g) <- c("First", "Second", "Later")
  s <- age_scheme(g, "gap", "Gap", type = "classification",
                  domain = c(0, 5), complete = FALSE)
  info <- summary(s)
  expect_false(info$covered)
  expect_identical(ivs::iv_start(info$gaps), 1)
  expect_identical(ivs::iv_end(info$gaps), 3)
  expect_error(age_scheme(g, "gap", "Gap", type = "classification",
                          domain = c(0, 5), complete = TRUE),
               "complete does not agree with domain coverage")
})
