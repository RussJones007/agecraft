test_that("calendar years and months use documented anniversaries", {
  leap <- as.Date("2020-02-29")
  ends <- as.Date(c("2021-02-28", "2021-03-01", "2024-02-28", "2024-02-29"))
  expect_equal(as.integer(calculate_age(leap, ends)), c(0, 1, 3, 4))
  expect_equal(as.integer(calculate_age(as.Date("2025-01-31"),
    as.Date(c("2025-02-27", "2025-02-28", "2025-03-30", "2025-03-31")), "month")), c(0, 1, 1, 2))
  expect_equal(as.numeric(calculate_age(as.Date("2024-01-01"),
    as.Date("2024-01-08"), "week")), 1)
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
  expect_error(calculate_age(as.Date("2025-02-01"), as.Date("2025-01-01")), "precede")
  expect_error(age_auto_unit(as.Date("2025-02-01"), as.Date("2025-01-01")), "precede")
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
