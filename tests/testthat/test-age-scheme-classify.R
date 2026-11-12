test_that("all memberships retain observations and original category indices", {
  g <- age_interval(c(15, 10), c(25, 20), unit = "year")
  names(g) <- c("B", "A")
  s <- age_scheme(g, "test", "Overlap", type = "classification")
  a <- age(c(12, 17, 30, NA, 20, 10, 25), unit = "year")
  out <- classify_age_scheme(a, s)
  expect_identical(out$observation, c(1L, 2L, 2L, 3L, 4L, 5L, 6L, 7L))
  expect_identical(out$group_index, c(2L, 1L, 2L, NA_integer_, NA_integer_, 1L, 2L, NA_integer_))
  expect_identical(out$status, c("matched", "matched", "matched", "unmatched",
                                  "missing", "matched", "matched", "unmatched"))
  expect_identical(out$label, c("A", "B", "A", NA, NA, "B", "A", NA))
  expect_identical(out$group, g[out$group_index])
  empty <- classify_age_scheme(age(numeric(), unit = "year"), s)
  expect_equal(nrow(empty), 0)
  expect_identical(names(empty), names(out))
  expect_type(empty$observation, "integer")
  expect_type(empty$label, "character")
  expect_type(empty$status, "character")
  expect_s3_class(empty$group, "age_interval")
  all_missing <- classify_age_scheme(age(c(NA_real_, NA_real_), unit = "year"), s)
  expect_identical(all_missing$status, c("missing", "missing"))
})

test_that("membership matching respects fractional containment and units", {
  g <- age_interval(c(0, 1.5), c(2, 3), unit = "year")
  names(g) <- c("A", "B")
  s <- age_scheme(g, "test", "Test", type = "classification")
  intervals <- age_interval(c(1.5, 1, NA), c(2, 2.5, NA), unit = "year")
  out <- classify_age_scheme(intervals, s)
  expect_identical(out$group_index, c(1L, 2L, NA_integer_, NA_integer_))
  expect_identical(out$status, c("matched", "matched", "unmatched", "missing"))
  a <- age(c(0, 1.5, 2, 3), unit = "year")
  expected <- classify_age_scheme(a, s)
  for (direction in c("age_to_group", "group_to_age")) {
    expect_identical(classify_age_scheme(as_age(a, unit = "month", allow_approx = TRUE), s,
                                         convert_units = direction, allow_approx = TRUE), expected)
  }
  expect_error(classify_age_scheme(c(1, 2), s), "units")
  expect_error(classify_age_scheme(age(12, unit = "month"), s,
                                   convert_units = "none"), "compatible")
  expect_error(classify_age_scheme(age(1, unit = "day"), s), "approximate")
  expect_equal(nrow(classify_age_scheme(age(1, unit = "day"), s,
                                       allow_approx = TRUE)), 1)
  for (values in list(-1, Inf, -Inf)) {
    x <- units::set_units(values, "year")
    expect_error(classify_age_scheme(x, s), "finite and nonnegative")
  }
  expect_error(classify_age_scheme(Sys.Date(), s), "numeric or an interval")
  expect_error(classify_age_scheme(a, s, allow_approx = NA), "TRUE or FALSE")
})
