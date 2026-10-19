test_that("constructor recycles only end and validates endpoints", {
  x <- new_age_group(c(0L, 5L, 10L), 20L)
  expect_identical(ivs::iv_end(x), rep(20, 3))
  expect_identical(ivs::iv_start(x), c(0, 5, 10))
  expect_length(new_age_group(double(), Inf), 0)
  expect_error(new_age_group(0, c(5, 10)), "recycle")
  expect_error(new_age_group(c(0, 5, 10), c(5, 10)), "recycle")
  expect_error(new_age_group(5, 5), "start < end")
  expect_error(new_age_group(10, 5), "start < end")
  expect_error(new_age_group(-1, 5), "nonnegative")
  expect_error(new_age_group(Inf, Inf), "only.*end")
  expect_error(new_age_group(0.5, 5), "whole numbers")
  expect_error(new_age_group(0, 5.5), "whole numbers")
  expect_error(new_age_group(NA_real_, 5), "both endpoints")
  expect_error(new_age_group(0, 5, list(a = "a", b = "b", c = "c")), "symbols")
  expect_error(new_age_group(0, 5, unit = NA_character_), "unit")
  expect_error(new_age_group(0, 5, unit = ""), "unit")
})

test_that("numeric helper handles empty scalar and invalid cuts", {
  expect_length(as.age_group(), 0)
  expect_length(as.age_group(double()), 0)
  expect_length(as.age_group(integer()), 0)
  expect_identical(as.character(as.age_group(5)), "5")
  expect_identical(as.character(as.age_group(5L)), "5")
  expect_identical(as.character(as.age_group(c(0, 5, Inf))), c("0-4", "5+"))
  expect_error(as.age_group(c(5, 0, Inf)), "strictly increasing")
  expect_error(as.age_group(c(0, 5, 5)), "strictly increasing")
  expect_error(as.age_group(Inf), "finite preceding")
  expect_error(as.age_group(c(0, NA_real_, 5)), "nonmissing")
  expect_error(as.age_group(c(0, 5.5, Inf)), "whole numbers")
  expect_error(as.age_group(ivs::iv(0, 0.5)), "whole numbers")
  expect_error(vctrs::vec_cast(ivs::iv(0, 0.5), as.age_group()), "whole numbers")
  expect_error(as.age_group("0-4.5"), "malformed")
  expect_error(as.age_group("-5"), "malformed")
})

test_that("conversion and formatting preserve missing observations and metadata", {
  x <- as.age_group(c("0 to 4", NA, "5+"), unit = "years")
  expect_length(x, 3)
  expect_identical(as.character(x), c("0 to 4", NA_character_, "5+"))
  expect_identical(format(x), c("0 to 4 [year]", NA_character_, "5+ [year]"))
  expect_identical(as.age_group(x), x)
  expect_identical(attr(as.age_group(x, sep = "-"), "symbols")$sep, "-")
  expect_error(as.age_group(x, unit = "day"), "explicit conversion")
  y <- as.age_group(ivs::iv(c(0, NA_real_), c(5, NA_real_)))
  expect_identical(as.character(y), c("0-4", NA_character_))
  expect_identical(as.character(as.age_group(factor(c("0-4", NA)))), c("0-4", NA_character_))
  expect_true(is.na(as.character(vctrs::vec_c(x[1], NA)))[2])
  x[1] <- x[3]
  expect_identical(as.character(x), c("5+", NA_character_, "5+"))
})

test_that("full type includes units and documented plus spelling parses", {
  expect_identical(vctrs::vec_ptype_full(as.age_group()), "age_group")
  expect_identical(vctrs::vec_ptype_full(as.age_group(unit = "days")), "age_group<day>")
  expect_identical(as.character(as.age_group("65 plus")), "65 plus")
})

test_that("temporary unit conversions keep fractional boundaries out of age groups", {
  groups <- as.age_group(c(0, 5, Inf), unit = "year")
  ages <- units::set_units(c(365, 365 * 8), "day")
  expect_identical(as.character(age_cat_iv(ages, groups, convert_units = "group_to_age", allow_approx = TRUE)), c("0-4", "5+"))
  intervals <- as.age_group(c("0", "8"), unit = "year")
  days <- as.age_group(c(0, 1000, Inf), unit = "day")
  expect_identical(as.character(age_cat_iv(intervals, days, allow_approx = TRUE)), c("0-999", "1000+"))
})


test_that("intersection requires matching classes and explains conversion", {
  groups <- as.age_group("0-9", unit = "year")
  intervals <- ivs::iv(5, 15)
  message <- paste0(
    "Arguments must have the same class. Convert bare intervals with ",
    "as.age_group() before combining or calling ivs::iv_set_intersect()"
  )

  expect_error(ivs::iv_set_intersect(groups, intervals), message, fixed = TRUE)
  expect_error(ivs::iv_set_intersect(intervals, groups), message, fixed = TRUE)
  expect_error(ivs::iv_set_intersect(groups[FALSE], intervals), message, fixed = TRUE)
  expect_error(ivs::iv_set_intersect(intervals, groups[FALSE]), message, fixed = TRUE)

  converted <- as.age_group(intervals, unit = "year")
  expected <- as.age_group("5-9", unit = "year")
  expect_identical(ivs::iv_set_intersect(groups, converted), expected)
  expect_identical(ivs::iv_set_intersect(converted, groups), expected)
  expect_error(
    ivs::iv_set_intersect(groups, as.age_group(intervals, unit = "day")),
    "incompatible units"
  )
})
