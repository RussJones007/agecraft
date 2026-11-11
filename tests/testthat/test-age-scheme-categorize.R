test_that("scheme classification delegates to existing groups", {
  g <- age_group(c(18, 0, 65), c(65, 18, Inf), unit = "year")
  names(g) <- c("Adult", "Child", "Older")
  s <- age_scheme(g, "test", "Test")
  a <- age(c(0, 17.999, 18, 65, NA, 30, 30), unit = "year")
  for (output in c("factor", "interval")) {
    expect_identical(categorize_age(a, by = s, output = output),
                     categorize_age(a, by = g, output = output))
  }
  expect_identical(levels(categorize_age(a, by = s)), c("Child", "Adult", "Older"))
  expect_error(categorize_age(c(0, 18), by = s), "units")
  expect_length(categorize_age(age(numeric(), unit = "year"), by = s), 0L)
  interval <- age_group(c(0, 17, 20), c(10, 19, 21), unit = "year")
  expect_identical(categorize_age(interval, by = s), categorize_age(interval, by = g))
  expect_true(is.na(categorize_age(interval, by = s)[2]))
  altered <- s
  altered$groups <- unname(g)
  expect_error(categorize_age(a, by = altered), "names")
})

test_that("scheme classification retains overlap and conversion policies", {
  g <- age_group(c(0, 2), c(5, 10), unit = "year")
  names(g) <- c("First", "Second")
  s <- age_scheme(g, "overlap", "Overlap", type = "classification")
  a <- age(c(1, 3, 8, 11, NA), unit = "year")
  expect_error(categorize_age(a, by = s), "multiple|Multiple|match")
  for (multiple in c("first", "last")) {
    expect_identical(categorize_age(a, by = s, multiple = multiple),
                     categorize_age(a, by = g, multiple = multiple))
  }
  months <- age(c(12, 96), unit = "month")
  for (direction in c("age_to_group", "group_to_age")) {
    expect_identical(categorize_age(months, by = s, convert_units = direction, allow_approx = TRUE),
                     categorize_age(months, by = g, convert_units = direction, allow_approx = TRUE))
  }
  expect_error(categorize_age(months, by = s, convert_units = "none"), "compatible")
  days <- age(365, unit = "day")
  expect_error(categorize_age(days, by = s), "approximate")
  expect_identical(categorize_age(days, by = s, allow_approx = TRUE),
                   categorize_age(days, by = g, allow_approx = TRUE))
})
