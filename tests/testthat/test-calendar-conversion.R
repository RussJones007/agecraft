test_that("calendar month/year conversions require explicit approximation consent", {
  for (source in c("month", "year")) {
    target <- if (source == "month") "year" else "month"
    values <- c(0, 0.5, 1, NA_real_)
    for (x in list(age(values, source), units::set_units(values, source, mode = "standard"))) {
      expect_error(as_age(x, target), "cannot generally be converted exactly without the original dates")
      expected <- as.numeric(units::set_units(
        units::set_units(values, source, mode = "standard"), target, mode = "standard"))
      converted <- as_age(x, target, allow_approx = TRUE)
      expect_equal(as.numeric(converted), expected)
      expect_identical(attr(converted, "unit"), target)
    }
    expect_identical(as_age(age(values, source), source), age(values, source))
  }
})

test_that("February calendar classification blocks silent cross-unit assignments", {
  birth <- as.Date("2021-02-01")
  event <- as.Date("2021-03-01")
  months <- calculate_age(birth, event, unit = "month")
  years <- calculate_age(birth, event, unit = "year")
  expect_equal(as.numeric(months), 1)
  expect_equal(as.numeric(years), 28 / 365)
  expect_equal(as.numeric(as_age(years, "month", allow_approx = TRUE)), 12 * 28 / 365)

  for (target in c("month", "year")) {
    # Equivalent nominal one-month cutoffs expose the calendar-coordinate mismatch.
    boundary <- if (target == "month") 1 else 1 / 12
    g <- age_group(c(0, boundary), c(boundary, Inf), unit = target)
    names(g) <- c("Below cutoff", "At or above cutoff")
    s <- age_scheme(g, "calendar_example", "Calendar example")
    direct <- if (target == "month") months else years
    cross_unit <- if (target == "month") years else months
    direct_label <- if (target == "month") "At or above cutoff" else "Below cutoff"
    approximate_label <- if (target == "month") "Below cutoff" else "At or above cutoff"

    expect_identical(as.character(categorize_age(direct, by = s)), direct_label)
    expect_identical(classify_age_scheme(direct, s)$label, direct_label)
    source <- attr(cross_unit, "unit")
    value <- as.numeric(cross_unit)
    inputs <- list(cross_unit, units::set_units(value, source, mode = "standard"),
                   age_group(value, value + value / 100, unit = source))
    for (direction in c("age_to_group", "group_to_age")) {
      for (x in inputs) {
        expect_error(classify_age_scheme(x, s, convert_units = direction),
                     "cannot generally be converted exactly without the original dates")
        expect_identical(classify_age_scheme(x, s, convert_units = direction,
                                             allow_approx = TRUE)$label, approximate_label)
        for (definition in list(g, s)) {
          for (output in c("factor", "interval")) {
            expect_error(categorize_age(x, by = definition, output = output,
                                        convert_units = direction),
                         "cannot generally be converted exactly without the original dates")
            result <- categorize_age(x, by = definition, output = output,
                                     convert_units = direction, allow_approx = TRUE)
            labels <- if (output == "factor") as.character(result) else names(result)
            expect_identical(labels, approximate_label)
          }
        }
        expect_error(age_cat_iv(x, g, convert_units = direction), "original dates")
        expect_identical(as.character(age_cat_iv(x, g, convert_units = direction,
                                                 allow_approx = TRUE)), approximate_label)
      }
    }
  }
})

test_that("matching calendar units and elapsed conversions keep their behavior", {
  for (unit in c("month", "year", "week")) {
    g <- age_group(c(0, 1), c(1, Inf), unit = unit)
    names(g) <- c("Below", "Above")
    s <- age_scheme(g, "same_unit", "Same unit")
    x <- age(c(0.5, 1, NA), unit)
    if (unit == "week") x <- as_age(x, "day")
    for (direction in c("age_to_group", "group_to_age")) {
      expect_identical(as.character(categorize_age(x, by = s, convert_units = direction)),
                       c("Below", "Above", NA_character_))
      expect_identical(classify_age_scheme(x, s, convert_units = direction)$label,
                       c("Below", "Above", NA_character_))
    }
    expect_error(categorize_age(age(1, "hour"), by = s, convert_units = "none"), "compatible")
  }
})
