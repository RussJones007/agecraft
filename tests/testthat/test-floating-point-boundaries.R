test_that("the documented 11-second conversion can classify differently by direction", {
  g <- age_group(c(0, 11), c(11, Inf), unit = "second")
  names(g) <- c("Under eleven", "Eleven or more")
  s <- age_scheme(g, "seconds", "Second categories")
  x <- as_age(age(11, "second"), "day")
  back <- as_age(x, "second")
  # Test the boundary effect, without requiring a particular printed decimal.
  expect_lt(as.numeric(back), 11)
  for (direction in c("age_to_group", "group_to_age")) {
    expected <- if (direction == "age_to_group") "Under eleven" else "Eleven or more"
    expect_identical(classify_age_scheme(x, s, convert_units = direction)$label, expected)
    expect_identical(as.character(categorize_age(x, by = s, convert_units = direction)), expected)
    expect_identical(as.character(age_cat_iv(x, g, convert_units = direction)), expected)
  }
  expect_error(classify_age_scheme(x, s, convert_units = "none"), "compatible")
  expect_error(categorize_age(x, by = s, convert_units = "none"), "compatible")
  expect_identical(classify_age_scheme(back, s, convert_units = "none")$label, "Under eleven")
})

test_that("same-unit classification retains exact half-open boundaries without tolerance", {
  step <- 2^-49 # One representable step on either side of 11.
  g <- age_group(c(0, 11), c(11, Inf), unit = "second")
  names(g) <- c("Under eleven", "Eleven or more")
  s <- age_scheme(g, "seconds", "Second categories")
  values <- c(0, 11 - step, 11, 11 + step, NA_real_)
  expected <- c("Under eleven", "Under eleven", "Eleven or more", "Eleven or more", NA_character_)
  x <- age(values, "second")
  for (direction in c("none", "age_to_group", "group_to_age")) {
    expect_identical(classify_age_scheme(x, s, convert_units = direction)$label, expected)
    expect_identical(as.character(categorize_age(x, by = s, convert_units = direction)), expected)
    expect_identical(as.character(age_cat_iv(x, g, convert_units = direction)), expected)
  }
  # A genuine one-step gap must not be filled by a tolerance.
  gap <- age_group(c(0, 11 + step), c(11, Inf), unit = "second")
  names(gap) <- names(g)
  partial <- age_scheme(gap, "gap", "One-step gap", domain = c(0, Inf), complete = FALSE)
  probes <- age(c(11 - step, 11, 11 + step), "second")
  expect_identical(classify_age_scheme(probes, partial, convert_units = "none")$status,
                   c("matched", "unmatched", "matched"))
  expect_identical(as.character(categorize_age(probes, by = partial, convert_units = "none")),
                   c("Under eleven", NA_character_, "Eleven or more"))
})
