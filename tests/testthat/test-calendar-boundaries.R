test_that("calendar years and months use documented anniversaries", {
  leap <- as.Date("2020-02-29")
  ends <- as.Date(c("2021-02-28", "2021-03-01", "2024-02-28", "2024-02-29"))
  expect_equal(as.integer(calculate_age(leap, ends)), c(0, 1, 3, 4))
  expect_equal(as.integer(calculate_age(as.Date("2025-01-31"),
    as.Date(c("2025-02-27", "2025-02-28", "2025-03-30", "2025-03-31")), "month")), c(0, 1, 1, 2))
  expect_equal(as.numeric(calculate_age(as.Date("2024-01-01"),
    as.Date("2024-01-08"), "week")), 1)
})

test_that("February 28 can be the yearly anniversary of a leap-day birth", {
  birth <- as.Date("2020-02-29")
  ends <- as.Date(c(
    "2021-02-27", "2021-02-28", "2021-03-01", "2024-02-28", "2024-02-29", NA
  ))
  completed <- c(0, 1, 1, 3, 4, NA_real_)
  fractional <- calculate_age(birth, ends, leap_day = "feb28")
  expect_equal(as.numeric(fractional), c(364 / 365, 1, 1 + 1 / 365, 3 + 365 / 366, 4, NA))
  expect_identical(as.integer(fractional), as.integer(completed))
  expect_identical(calculate_age(birth, ends, output = "numeric", leap_day = "feb28"), completed)
  expect_identical(as.numeric(calculate_age(birth, ends, output = "units", leap_day = "feb28")), completed)
  expect_identical(calculate_age(birth, ends), calculate_age(birth, ends, leap_day = "mar1"))
  expect_identical(calculate_age(birth, ends, "month"), calculate_age(birth, ends, "month", leap_day = "feb28"))
  expect_error(calculate_age(birth, ends, leap_day = "march2"), "arg")
})

test_that("leap-day anniversaries use civil dates and elapsed units use timestamps", {
  birth <- as.POSIXct("2020-02-29 18:00:00", tz = "America/Chicago")
  reference <- as.POSIXct("2021-03-01 01:00:00", tz = "UTC")
  expect_equal(as.numeric(calculate_age(birth, reference, leap_day = "feb28")), 1)
  expect_equal(as.numeric(calculate_age(birth, reference)), 365 / 366)

  end <- birth + 5401.5
  expect_equal(as.numeric(calculate_age(birth, end, "second", leap_day = "feb28")), 5401.5)
  expect_equal(as.numeric(calculate_age(birth, end, "minute", leap_day = "feb28")), 5401.5 / 60)
  expect_equal(as.numeric(calculate_age(birth, end, "hour", leap_day = "feb28")), 5401.5 / 3600)
})

test_that("native calendar ages agree with R across mixed date pairs", {
  birth <- as.Date(c("1896-02-29", "1900-02-28", "1969-12-31", "2000-02-29",
                     "2024-01-31", "2024-03-30", NA))
  offsets <- c(0, 1, 28:32, 59:62, 364:367, 1460:1462, NA_integer_)
  start <- rep(birth, each = length(offsets))
  end <- start + rep(offsets, times = length(birth))
  for (unit in c("year", "month")) {
    for (leap_day in c("mar1", "feb28")) {
      yearly <- unit == "year"
      expect_identical(
        as.numeric(calculate_age(start, end, unit, leap_day = leap_day)),
        calendar_age_r(start, end, yearly, TRUE, leap_day)
      )
      expect_identical(
        calculate_age(start, end, unit, output = "numeric", leap_day = leap_day),
        calendar_age_r(start, end, yearly, FALSE, leap_day)
      )
    }
  }

  integer_start <- structure(as.integer(start), class = "Date")
  expect_identical(calculate_age(integer_start, end), calculate_age(start, end))

  fractional_end <- as.Date("2025-07-02") + 0.5
  start <- as.Date("2025-01-01")
  expect_identical(
    as.numeric(calculate_age(start, fractional_end)),
    calendar_age_r(start, fractional_end, TRUE, TRUE, "mar1")
  )
})

test_that("automatic units have exact, non-overlapping calendar boundaries", {
  birth <- as.Date("2020-01-01")
  offsets <- c(29, 30, 31, 364, 365, 366)
  expect_equal(age_auto_unit(birth, birth + offsets),
    c(Day = 29, Day = 30, Month = 1, Month = 11, Month = 11, Year = 1))
  expect_equal(age_auto_unit(as.Date("2020-02-29"), as.Date(c("2021-02-28", "2021-03-01"))),
    c(Month = 12, Year = 1))
  expect_equal(age_auto_unit(as.Date("2025-01-31"), as.Date("2025-03-03")), c(Month = 1))
})

test_that("missing, empty and incompatible inputs are handled consistently", {
  birth <- as.Date(c("2025-01-01", NA))
  expect_equal(as.numeric(calculate_age(birth, as.Date("2025-01-31"), "day")), c(30, NA))
  expect_equal(age_auto_unit(birth, as.Date("2025-01-31")), setNames(c(30, NA_real_), c("Day", "")))
  empty <- as.Date(character())
  out <- calculate_age(empty, as.Date("2025-01-01"))
  expect_s3_class(out, "age")
  expect_length(out, 0)
  expect_identical(age_auto_unit(empty, empty), setNames(numeric(), character()))
  expect_error(calculate_age(rep(birth, 2), rep(as.Date("2025-01-31"), 3)), "recycle")
  expect_error(age_auto_unit(rep(birth, 2), rep(as.Date("2025-01-31"), 3)), "recycle")
  expect_warning(calculate_age(as.Date("2025-02-01"), as.Date("2025-01-01")), "1 entry where")
  expect_warning(age_auto_unit(as.Date("2025-02-01"), as.Date("2025-01-01")), "1 entry where")
  expect_error(age_auto_unit("2025-01-01", as.Date("2025-01-02")), "Date or POSIXct")
})

test_that("elapsed units respect daylight saving and calendar dates use the start zone", {
  start <- as.POSIXct("2025-03-08 12:00:00", tz = "America/Chicago")
  end <- as.POSIXct("2025-03-09 12:00:00", tz = "America/Chicago")
  expect_equal(as.numeric(calculate_age(start, end, "hour")), 23)
  expect_equal(as.numeric(calculate_age(start, end, "day")), 23 / 24)
  start <- as.POSIXct("2025-11-01 12:00:00", tz = "America/Chicago")
  end <- as.POSIXct("2025-11-02 12:00:00", tz = "America/Chicago")
  expect_equal(as.numeric(calculate_age(start, end, "hour")), 25)
  birth <- as.POSIXct("2000-01-01 18:00:00", tz = "America/Chicago")
  end <- as.POSIXct("2020-01-02 01:00:00", tz = "UTC")
  expect_equal(as.numeric(calculate_age(birth, end)), 20)
  expect_error(calculate_age(birth, as.Date("2020-01-01")), "is.POSIXct")
})
