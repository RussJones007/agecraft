test_that("breaks construct adjacent intervals without an appended boundary", {
  cuts <- c(0, 0.077, 1, 5, Inf)
  bands <- age_interval(breaks = cuts, unit = "years", sep = " to ")
  expect_identical(bands, age_interval(head(cuts, -1), tail(cuts, -1),
                                      unit = "year", sep = " to "))
  expect_identical(age_interval(breaks = 0:2), age_interval(c(0, 1), c(1, 2)))
  expect_length(age_interval(breaks = c(5, Inf)), 1)
  finite <- age_interval(breaks = c(0, 5, 18))
  expect_identical(ivs::iv_end(finite), c(5, 18))
  expect_length(as_age_interval(c(0, 5, 18)), 3)
  expect_null(names(age_interval(breaks = c(a = 0, b = 5, c = 18))))
})

test_that("breaks and direct numeric classification agree at boundaries", {
  cuts <- c(0, 0.5, 5, 18)
  ages <- c(NA, 0, 0.49, 0.5, 5, 17.9, 18, 25, 5)
  bands <- age_interval(breaks = cuts)
  expect_identical(categorize_age(ages, by = bands), categorize_age(ages, by = cuts, above.char = "+"))
  expect_identical(categorize_age(ages, by = bands, output = "interval"),
                   categorize_age(ages, by = cuts, above.char = "+", output = "interval"))
  expect_identical(is.na(categorize_age(ages, by = bands)),
                   c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, FALSE))
  named <- age_interval(breaks = c(0, 5, Inf), unit = "year")
  names(named) <- c("Under 5", "5 and older")
  result <- categorize_age(age(c(0, 5, NA), "year"), by = named)
  expect_identical(group_intervals(result), named)
  expect_identical(as.character(result), c("Under 5", "5 and older", NA_character_))
})

test_that("breaks reject invalid cut points and conflicting bounds", {
  invalid <- list(numeric(), 5, Inf, c(0, NA), c(0, NaN), c(-1, 5),
                  c(-Inf, 5), c(0, Inf, Inf), c(0, 5, 5), c(0, 5, 4),
                  c("0", "5"), c(FALSE, TRUE), list(0, 5), matrix(0:3, 2),
                  age(c(0, 5), "year"), c(0 + 0i, 5 + 0i))
  for (cuts in invalid) expect_error(age_interval(breaks = cuts), "`breaks` must")
  expect_error(age_interval(start = 0, breaks = c(0, 5)), "without `start` or `end`")
  expect_error(age_interval(end = 5, breaks = c(0, 5)), "without `start` or `end`")
  expect_error(age_interval(start = double(), breaks = c(0, 5)), "without")
})

test_that("existing constructor calls retain their behavior", {
  expect_length(age_interval(), 0)
  expect_identical(age_interval(0, 5, "year", "<", " to ", " plus"),
                   age_interval(breaks = c(0, 5), unit = "year",
                                below = "<", sep = " to ", above = " plus"))
  expect_identical(age_interval(c(0, 5), 10), age_interval(c(0, 5), c(10, 10)))
  expect_identical(age_interval(0, 5, breaks = NULL), age_interval(0, 5))
  expect_true(is.na(age_interval(NA_real_, NA_real_)))
})
