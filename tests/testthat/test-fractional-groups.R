test_that("fractional groups classify exact right-open boundaries", {
  groups <- age_group(c(0, 0.077, 1), c(0.077, 1, 3))
  ages <- c(0, 0.076999, 0.077, 0.999, 1, 3, NA)
  expected <- c("[0, 0.077)", "[0, 0.077)", "[0.077, 1)", "[0.077, 1)", "1-2", NA, NA)
  expect_identical(as.character(categorize_age(ages, by = groups)), expected)
  expect_identical(as.character(age_cat_iv(ages, groups)), expected)
  expect_identical(as.character(age_group(c(0.5, 1.5), c(1.5, Inf))),
                   c("[0.5, 1.5)", "[1.5, Inf)"))
  expect_identical(as.character(as.age_group(c(0, 0.077, 1, Inf))),
                   c("[0, 0.077)", "[0.077, 1)", "1+"))
  expect_identical(ivs::iv_start(as.age_group(ivs::iv(0.0001, 0.077))), 0.0001)
  expect_identical(ivs::iv_end(ivs::iv_set_intersect(age_group(0, 0.5), age_group(0.25, 1))), 0.5)
})
