test_that("reversed dates warn once and become missing in every output", {
  previous <- options(agecraft.end_before_start = NULL)
  on.exit(options(previous), add = TRUE)
  start <- as.Date("2024-01-01")
  end <- start + c(-1, 0, 366, NA, -30)
  for (unit in c("year", "month", "week", "day", "hour", "minute", "second")) {
    for (output in c("age", "numeric", "units")) {
      expect_warning(out <- calculate_age(start, end, unit, output),
                     "Produced NA for 2 entries where `end` occurs before `start`.",
                     fixed = TRUE)
      expect_identical(is.na(out), c(TRUE, FALSE, FALSE, TRUE, TRUE))
      expect_equal(as.numeric(out)[2:3],
                   as.numeric(calculate_age(start, end[2:3], unit, output)))
      if (output == "age") expect_identical(attr(out, "unit"), unit)
    }
  }
  expect_warning(calculate_age(start, start - 1), "1 entry where", fixed = TRUE)
  expect_no_warning(calculate_age(start, as.Date(c(NA, "2024-01-01"))))
  expect_no_warning(calculate_age(as.Date(character()), start))
  expect_no_warning(calculate_age(as.Date(NA), start - 1))
  options(agecraft.end_before_start = "error")
  expect_error(calculate_age(start, end), "end must not precede start")
  expect_error(age_auto_unit(start, end), "end must not precede start")
  expect_error(calc_age(start, end), "end must not precede start")
})

test_that("date masking covers date-times, fallback and automatic units", {
  previous <- options(agecraft.end_before_start = "warn")
  on.exit(options(previous), add = TRUE)
  start <- as.POSIXct("2024-01-01 12:00:00", tz = "America/Chicago")
  end <- start + c(-1, 0, 3600, NA)
  for (unit in c("year", "month", "hour")) {
    expect_warning(out <- calculate_age(start, end, unit), "1 entry where")
    expect_identical(is.na(out), c(TRUE, FALSE, FALSE, TRUE))
    expect_identical(as.numeric(out)[2], 0)
  }
  birth <- as.Date("2024-01-01")
  warnings <- character()
  out <- withCallingHandlers(age_auto_unit(birth, birth + c(-1, 6, 40, 366, NA)),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  expect_length(warnings, 1)
  expect_match(warnings, "1 entry where")
  expect_identical(out, setNames(c(NA_real_, 6, 1, 1, NA),
                                c("", "Day", "Month", "Year", "")))
  # Force the existing R fallback to verify masking precedes either backend.
  local_mocked_bindings(calendar_age_cpp = function(...) NULL)
  expect_warning(out <- calculate_age(birth, birth + c(-1, 366)), "1 entry where")
  expect_identical(as.numeric(out), c(NA_real_, 1))
})

test_that("fractional display options apply at call time with explicit overrides", {
  x <- age(c(a = 2.75, b = 0.5, c = NA_real_))
  original <- x
  previous <- options(agecraft.display.fractional = NULL)
  on.exit(options(previous), add = TRUE)
  expect_identical(as.character(x), c(a = "2", b = "0", c = NA_character_))
  options(agecraft.display.fractional = TRUE)
  expected <- c(a = "2.75", b = "0.50", c = NA_character_)
  expect_identical(format(x), expected)
  expect_identical(as.character(x), expected)
  expect_identical(format(x, fractional = FALSE),
                   c(a = "2", b = "0", c = NA_character_))
  expect_identical(as.character(x, fractional = FALSE), format(x, fractional = FALSE))
  expect_output(print(x), "2.75", fixed = TRUE)
  expect_identical(as.character(age()), character())
  if (requireNamespace("tibble", quietly = TRUE)) {
    expect_output(print(tibble::tibble(ages = x)), "2.75", fixed = TRUE)
  }
  options(agecraft.display.fractional = FALSE)
  expect_identical(as.character(x, fractional = TRUE), expected)
  expect_identical(x, original)
})

test_that("comparison option controls diagnostics without changing results", {
  x <- age_interval(3, 7)
  y <- age_interval(c(0, 2), c(10, 8))
  previous <- options(agecraft.compare.ambiguous = NULL)
  on.exit(options(previous), add = TRUE)
  expect_no_warning(expected <- compare_age_intervals(x, y, "membership"))
  options(agecraft.compare.ambiguous = "warn")
  expect_warning(out <- compare_age_intervals(x, y, "membership"), "multiple")
  expect_identical(out, expected)
  expect_warning(compare_age_intervals(x, y, "ordering"), "unresolved")
  expect_no_warning(compare_age_intervals(x, y, "membership", ambiguous = "allow"))
  options(agecraft.compare.ambiguous = "error")
  expect_error(compare_age_intervals(x, y, "membership"), "multiple")
  expect_error(compare_age_intervals(x, y, "ordering"), "unresolved")
  expect_no_warning(compare_age_intervals(x, y, "crosswalk"))
  expect_no_warning(compare_age_intervals(x, y, "ordering", ambiguous = "allow"))
})

test_that("unmatched policies cover classification interfaces and input types", {
  g <- age_interval(c(0, 2), c(1, 3), unit = "year")
  names(g) <- c("Infant", "Child")
  scheme <- age_scheme(g, "partial", "Partial coverage")
  inputs <- list(age(c(0.5, 1, 1, 3, NA, NaN)),
                 units::set_units(c(0.5, 1, 1, 3, NA, NaN), "year"),
                 age_interval(c(0, 0.5, 1, 3, NA, NA),
                              c(0.5, 1.5, 2, 4, NA, NA), unit = "year"))
  previous <- options(agecraft.classify.unmatched = NULL)
  on.exit(options(previous), add = TRUE)
  for (x in inputs) {
    calls <- list(function() categorize_age(x, by = g),
                  function() categorize_age(x, by = g, output = "interval"),
                  function() age_cat_iv(x, g),
                  function() classify_age_scheme(x, scheme))
    options(agecraft.classify.unmatched = "allow")
    expected <- lapply(calls, function(f) f())
    options(agecraft.classify.unmatched = "warn")
    for (i in seq_along(calls)) {
      expect_warning(out <- calls[[i]](), "3 non-missing age observations")
      expect_identical(out, expected[[i]])
    }
    options(agecraft.classify.unmatched = "error")
    for (f in calls) expect_error(f(), "3 non-missing age observations")
    expect_no_warning(categorize_age(x[5:6], by = g))
    expect_no_warning(age_cat_iv(x[FALSE], g))
    expect_no_warning(classify_age_scheme(x[FALSE], scheme))
  }
  options(agecraft.classify.unmatched = "warn")
  expect_warning(categorize_age(c(0L, 1L, NA_integer_), by = c(0, 1)),
                 "1 non-missing age observation has")
  expect_warning(age_cat_iv(c(0L, 1L, NA_integer_), age_interval(0, 1)),
                 "1 non-missing age observation has")
  # Empty definitions still distinguish absent input from unmatched observations.
  expect_warning(categorize_age(c(1, NA), by = age_interval()), "1 non-missing")
  options(agecraft.classify.unmatched = "error")
  overlap <- age_interval(c(0, 1), c(3, 4), unit = "year")
  names(overlap) <- c("A", "B")
  s <- age_scheme(overlap, "overlap", "Overlap", type = "classification")
  expect_equal(nrow(classify_age_scheme(age(2), s)), 2)
  expect_error(categorize_age(age(2), by = overlap), "more than one")
})

test_that("invalid option values are rejected and overrides bypass defaults", {
  birth <- as.Date("2024-01-01")
  g <- age_interval(0, 1)
  previous <- options(agecraft.end_before_start = "warn",
                       agecraft.display.fractional = FALSE,
                       agecraft.compare.ambiguous = "allow",
                       agecraft.classify.unmatched = "allow")
  on.exit(options(previous), add = TRUE)
  for (bad in list(NA, logical(), c(TRUE, FALSE), 1, "TRUE")) {
    options(agecraft.display.fractional = bad)
    expect_error(format(age()), "agecraft.display.fractional", fixed = TRUE)
    expect_error(as.character(age()), "agecraft.display.fractional", fixed = TRUE)
    expect_identical(as.character(age(1.5), fractional = TRUE), "1.5")
  }
  for (bad in list(NA_character_, character(), c("warn", "error"), TRUE, "bad", "w")) {
    options(agecraft.end_before_start = bad)
    expect_error(calculate_age(birth, birth), "agecraft.end_before_start", fixed = TRUE)
    expect_error(age_auto_unit(birth, birth), "agecraft.end_before_start", fixed = TRUE)
    options(agecraft.compare.ambiguous = bad)
    expect_error(compare_age_intervals(g, g), "agecraft.compare.ambiguous", fixed = TRUE)
    expect_no_warning(compare_age_intervals(g, g, ambiguous = "allow"))
    options(agecraft.classify.unmatched = bad)
    expect_error(categorize_age(numeric(), by = g), "agecraft.classify.unmatched", fixed = TRUE)
    expect_error(age_cat_iv(numeric(), g), "agecraft.classify.unmatched", fixed = TRUE)
  }
})
