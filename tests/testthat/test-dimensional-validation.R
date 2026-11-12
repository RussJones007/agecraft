test_that("all age interfaces reject unsupported dimensional expressions", {
  g <- age_interval(c(0, 1), c(1, Inf), unit = "year")
  names(g) <- c("Under one", "One or older")
  s <- age_scheme(g, "example", "Example")
  expressions <- c("year/day", "year^2", "1/day", "m", "kg", "1",
                   "day/day", "year*kg", "s^2/minute", "millisecond")
  for (expression in expressions) {
    for (values in list(0.5, NA_real_, numeric())) {
      x <- units::set_units(values, expression, mode = "standard")
      displayed <- units::deparse_unit(x)
      error <- paste0("Unsupported age unit '", displayed,
                      "': an age must have a supported simple time unit")
      expect_error(as_age(x), error, fixed = TRUE)
      # Neither an explicit target unit nor approximation consent can repair dimensions.
      expect_error(as_age(x, "year", allow_approx = TRUE), error, fixed = TRUE)
      expect_error(categorize_age(x, by = s), error, fixed = TRUE)
      expect_error(categorize_age(x, by = c(0, 1, Inf)), error, fixed = TRUE)
      expect_error(classify_age_scheme(x, s), error, fixed = TRUE)
      expect_error(age_cat_iv(x, g), error, fixed = TRUE)
    }
  }
})

test_that("same-unit shortcuts and conversion options cannot conceal dimensions", {
  for (unit in c("year", "day")) {
    g <- age_interval(c(0, 1), c(1, Inf), unit = unit)
    names(g) <- c("Under one", "One or older")
    s <- age_scheme(g, "same_numerator", "Same numerator")
    for (expression in c(paste0(unit, "/day"), paste0(unit, "^2"))) {
      # Negative values also verify that dimensions are checked before numeric validation.
      x <- units::set_units(-0.5, expression, mode = "standard")
      for (direction in c("age_to_group", "group_to_age", "none")) {
        expect_error(categorize_age(x, by = s, convert_units = direction,
                                    allow_approx = TRUE), "supported simple time unit")
        expect_error(classify_age_scheme(x, s, convert_units = direction,
                                         allow_approx = TRUE), "supported simple time unit")
        expect_error(age_cat_iv(x, g, convert_units = direction,
                               allow_approx = TRUE), "supported simple time unit")
      }
    }
  }
})

test_that("simple time quantities retain precision, missingness and classification", {
  aliases <- list(second = c("second", "s", "sec", "seconds"),
                  minute = c("minute", "min", "minutes"),
                  hour = c("hour", "h", "hours"), day = c("day", "d", "days"),
                  week = c("week", "weeks"), month = c("month", "months"),
                  year = c("year", "yr", "years"))
  for (unit in names(aliases)) {
    g <- age_interval(c(0, 1), c(1, Inf), unit = unit)
    names(g) <- c("Under one", "One or older")
    s <- age_scheme(g, "simple", "Simple unit")
    for (alias in aliases[[unit]]) {
      values <- c(0.5, 1, NA_real_)
      x <- units::set_units(values, alias, mode = "standard")
      expected <- c("Under one", "One or older", NA_character_)
      expect_identical(as_age(x), age(values, unit))
      expect_identical(age(values, alias), age(values, unit))
      for (direction in c("age_to_group", "group_to_age", "none")) {
        expect_identical(as.character(categorize_age(x, by = s, convert_units = direction)),
                         expected)
        expect_identical(classify_age_scheme(x, s, convert_units = direction)$label,
                         expected)
        expect_identical(as.character(age_cat_iv(x, g, convert_units = direction)), expected)
      }
    }
    for (values in list(NA_real_, numeric())) {
      x <- units::set_units(values, unit, mode = "standard")
      expect_identical(as_age(x), age(values, unit))
      expect_length(categorize_age(x, by = s), length(values))
      out <- classify_age_scheme(x, s)
      expect_equal(nrow(out), length(values))
      expect_identical(out$status, rep("missing", length(values)))
      expect_length(age_cat_iv(x, g), length(values))
    }
  }
  named <- units::set_units(c(first = 0.5, absent = NA_real_), "day")
  expect_identical(names(as_age(named)), names(named))
  expect_identical(as_age(units::set_units(1.5, "week"), "day"), age(10.5, "day"))
})

test_that("explicit constructor units and unit attributes cannot hide malformed expressions", {
  for (unit in c("year/day", "year^2", "1/day", "m", "kg", "1", "", "s^2/minute")) {
    expect_error(age(0.5, unit), "supported simple time unit")
    expect_error(as_age(0.5, unit), "supported simple time unit")
  }
  for (unit in list(NULL, c("year", "day"), NA_character_, 1)) {
    expect_error(age(0.5, unit), "one time-unit string")
  }
  g <- age_interval(0, Inf, unit = "year")
  names(g) <- "All"
  # Explicit scalar unit attributes remain supported, but are validated in full.
  expect_identical(as.character(categorize_age(structure(0.5, units = "year"), by = g)), "All")
  for (unit in list("year/day", attr(units::set_units(1, "year^2"), "units"))) {
    for (value in list(0.5, 1L)) {
      x <- structure(value, units = unit)
      expect_error(categorize_age(x, by = g), "supported simple time unit")
      expect_error(age_cat_iv(x, g), "supported simple time unit")
    }
  }
  expect_identical(as.character(age_cat_iv(structure(1L, units = "year"), g)), "All")
})
