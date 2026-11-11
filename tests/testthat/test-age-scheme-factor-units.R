test_that("factor units describe original observations rather than category coordinates", {
  g <- age_group(c(0, 1), c(1, Inf), unit = "day")
  names(g) <- c("Under one day", "One day or older")
  s <- age_scheme(g, "days", "Day bands")
  for (unit in c("hour", "day")) {
    values <- if (unit == "hour") c(12, 36, NA_real_) else c(0.5, 1.5, NA_real_)
    modes <- if (unit == "hour") c("age_to_group", "group_to_age") else
      c("age_to_group", "group_to_age", "none")
    for (mode in modes) {
      a <- age(values, unit = unit)
      u <- units::set_units(values, unit, mode = "standard")
      f <- categorize_age(a, by = s, convert_units = mode)
      expect_identical(attr(f, "units"), unit)
      expect_identical(as.character(f), c(names(g), NA_character_))
      expect_identical(levels(f), names(g))
      expect_identical(categorize_age(u, by = s, convert_units = mode), f)
      intervals <- categorize_age(a, by = s, convert_units = mode, output = "interval")
      expect_identical(intervals, g[c(1L, 2L, NA_integer_)])
      expect_identical(attr(intervals, "unit"), "day")
      expect_identical(categorize_age(u, by = s, convert_units = mode,
                                      output = "interval"), intervals)
      memberships <- classify_age_scheme(a, s, convert_units = mode)
      expect_identical(memberships$group, intervals)
      expect_identical(memberships$status, c("matched", "matched", "missing"))
      expect_identical(classify_age_scheme(u, s, convert_units = mode), memberships)
      for (empty in list(age(numeric(), unit = unit),
                          units::set_units(numeric(), unit, mode = "standard"))) {
        ef <- categorize_age(empty, by = s, convert_units = mode)
        expect_length(ef, 0L)
        expect_identical(attr(ef, "units"), unit)
        expect_identical(levels(ef), names(g))
        ei <- categorize_age(empty, by = s, convert_units = mode, output = "interval")
        expect_identical(ei, g[integer()])
        expect_identical(classify_age_scheme(empty, s, convert_units = mode)$group, ei)
      }
    }
  }
})
