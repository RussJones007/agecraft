test_that("calculate_age defaults to fractional age with completed display", {
  start <- as.Date("2024-01-01")
  end <- as.Date(c("2024-01-01", "2024-07-02", "2025-01-01", NA))
  x <- calculate_age(start, end)
  expect_s3_class(x, "age")
  expect_identical(attr(x, "unit"), "year")
  expect_equal(as.numeric(x), c(0, 0.5, 1, NA))
  expect_identical(as.integer(x), c(0L, 0L, 1L, NA_integer_))
  expect_identical(format(x), c("0 year", "0 year", "1 year", NA_character_))
  expect_identical(calculate_age(start, end, output = "numeric"), c(0, 0, 1, NA_real_))
  legacy <- calculate_age(start, end, output = "units")
  expect_s3_class(legacy, "units")
  expect_identical(as.numeric(legacy), c(0, 0, 1, NA_real_))
  expect_equal(as.numeric(calculate_age(as.Date("2023-01-01"), as.Date("2023-07-02"))), 182 / 365)
  expect_error(calculate_age(start, end, output = "bad"), "arg")
})

test_that("calendar fractions retain leap-birthday and short-month policies", {
  leap <- as.Date("2020-02-29")
  ends <- as.Date(c("2021-02-28", "2021-03-01", "2024-02-28", "2024-02-29"))
  expect_equal(as.numeric(calculate_age(leap, ends)), c(365 / 366, 1, 3 + 364 / 365, 4))
  expect_identical(calculate_age(leap, ends, output = "numeric"), c(0, 1, 3, 4))
  end <- as.Date(c("2025-02-27", "2025-02-28", "2025-03-01", "2025-03-30", "2025-03-31"))
  months <- calculate_age(as.Date("2025-01-31"), end, "month")
  expect_equal(as.numeric(months), c(27 / 28, 1, 1 + 1 / 31, 1 + 30 / 31, 2))
  expect_identical(as.integer(months), c(0L, 1L, 1L, 1L, 2L))
  expect_equal(as.numeric(calculate_age(as.Date("2024-01-31"), as.Date("2024-02-29"), "month")), 1)
  expect_equal(as.numeric(calculate_age(as.Date("2024-01-31"), as.Date("2024-03-01"), "month")), 1 + 1 / 31)
})

test_that("smaller units retain elapsed fractions including daylight saving", {
  start <- as.POSIXct("2025-03-08 12:00:00", tz = "America/Chicago")
  end <- as.POSIXct("2025-03-09 12:00:00", tz = "America/Chicago")
  expect_equal(as.numeric(calculate_age(start, end, "day")), 23 / 24)
  expect_identical(calculate_age(start, end, "day", output = "numeric"), 0)
  expect_equal(as.numeric(calculate_age(start, start + 5400, "hour")), 1.5)
  expect_equal(as.numeric(calculate_age(start, start + 90, "minute")), 1.5)
  expect_equal(as.numeric(calculate_age(start, start + 1.5, "second")), 1.5)
  expect_equal(as.numeric(calculate_age(as.Date("2025-01-01"), as.Date("2025-01-11"), "week")), 10 / 7)
  start <- as.POSIXct("2025-11-01 12:00:00", tz = "America/Chicago")
  end <- as.POSIXct("2025-11-02 12:00:00", tz = "America/Chicago")
  expect_equal(as.numeric(calculate_age(start, end, "day")), 25 / 24)
  birth <- as.POSIXct("2000-01-01 18:00:00", tz = "America/Chicago")
  reference <- as.POSIXct("2020-01-02 01:00:00", tz = "UTC")
  expect_equal(as.numeric(calculate_age(birth, reference)), 20)
})

test_that("calculated fractional ages flow directly to named groups", {
  groups <- age_group(c(0, 0.077, 1), c(0.077, 1, 3), unit = "year")
  names(groups) <- c("Neonate", "Infant", "Toddler")
  ages <- calculate_age(as.Date("2024-01-01"), as.Date(c("2024-01-10", "2024-07-02", "2025-01-01", NA)))
  expect_identical(as.character(categorize_age(ages, by = groups)), c("Neonate", "Infant", "Toddler", NA))
  expect_identical(as.character(age_cat_iv(ages, groups)), c("Neonate", "Infant", "Toddler", NA))
  for (unit in c("year", "month", "day")) {
    for (output in c("age", "units", "numeric")) {
      expect_length(calculate_age(as.Date(character()), as.Date("2025-01-01"), unit, output), 0)
    }
  }
  missing <- calculate_age(as.Date(c(NA, NA)), as.Date("2025-01-01"))
  expect_identical(as.numeric(missing), c(NA_real_, NA_real_))
  # Automatic-unit surveillance exports retain completed values and names.
  expect_identical(age_auto_unit(as.Date("2024-01-01"), as.Date("2024-07-02")), c(Month = 6))
  expect_s3_class(suppressMessages(calc_age(as.Date("2024-01-01"), as.Date("2024-07-02"))), "units")
})
