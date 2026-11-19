test_that("baseline observations and integration are preserved", {
  expect_equal(observe(), readRDS(file.path(root, "results/baseline.rds")))
  x <- make_age(c(a = 0.25, b = NA), "day")
  for (out in list(x[1], x[[1]], c(x, x), vctrs::vec_slice(x, 1),
                   vctrs::vec_cast(x, x[0]), vctrs::vec_restore(c(1, NA), x),
                   rep(x, 2), unique(x), sort(x), rev(x),
                   x + 1, 1 + x, x - 0.1, mean(x, na.rm = TRUE),
                   stats::median(x, na.rm = TRUE), round(x), abs(x))) {
    expect_s3_class(out, "age")
    if (mode != "baseline") {
      expect_identical(class(out), expected_class)
      expect_identical(p_unit(out), "day")
    }
  }
  expect_equal(as.numeric(make_age(1, "day") + make_age(24, "hour")), 2)
  expect_length(make_age(numeric(), "day") + 1, 0)
  expect_error(make_age(1:2, "day") + 1:3)
  expect_error(x - 1, "nonnegative")
  expect_error(x * 2)
  expect_error(x / 2)
  expect_error(x - x)
  expect_error(1 - x)
  expect_error(sum(x))
  expect_error(log(x))
  expect_error(x + Inf)
  expect_error(c(x, 1))
  expect_error(c(x, make_age(1, "hour")))
  expect_error(x == make_age(1, "hour"))
  expect_error(vctrs::vec_cast(x, make_age(unit = "hour")))
  expect_error(vctrs::vec_restore(-1, x), "nonnegative")
  expect_error(make_age(-1))
  expect_error(make_age(Inf))
  expect_equal(as.numeric(make_age(c(NA_real_, NaN))), c(NA_real_, NaN))
  expect_length(make_age(numeric()), 0)
})

test_that("all directed conversions match current policy and units factors", {
  approved <- c("second", "minute", "hour", "day", "week", "month", "year")
  records <- list()
  for (from in approved) for (to in approved) {
    x <- make_age(c(a = 1, b = NA), from)
    approx <- from != to && any(c(from, to) %in% c("month", "year"))
    if (approx) expect_error(convert(x, to), "approximate")
    else expect_s3_class(convert(x, to), "age")
    out <- convert(x, to, allow_approx = TRUE)
    expected <- units::set_units(units::set_units(c(1, NA), from,
      mode = "standard"), to, mode = "standard")
    expect_equal(as.numeric(out), as.numeric(expected))
    expect_identical(names(out), c("a", "b"))
    expect_equal(as.numeric(convert(out, from, allow_approx = TRUE)), c(1, NA))
    records[[length(records) + 1L]] <- data.frame(from, to, approx,
      factor = as.numeric(expected)[1])
  }
  write.csv(do.call(rbind, records), file.path(root, paste0("results/", mode, "-conversions.csv")), row.names = FALSE)
  for (u in c("km", "kg", "year/day", "year^2", "1/day", "1")) {
    expect_error(make_age(1, u))
    for (v in list(1, NA_real_, numeric())) {
      bad <- units::set_units(v, u, mode = "standard")
      expect_error(convert(bad))
    }
  }
  for (flag in list(NA, 1, NULL, c(TRUE, FALSE))) {
    expect_error(convert(make_age(1), "day", allow_approx = flag))
  }
})

test_that("prototype setters and coercions enforce explicit boundaries", {
  skip_if(mode == "baseline", "Prototype-specific setter contract")
  x <- make_age(c(a = 1, b = NA), "year")
  expect_error(units::set_units(x, "day", mode = "standard"), "approximate")
  expect_error(units::set_units(x, month), "approximate")
  expect_error(units(x) <- "month", "approximate")
  expect_error(units(x) <- NULL)
  for (u in c("km", "kg", "year^2", "1/day", "1")) {
    expect_error(units::set_units(x, u, mode = "standard"))
    expect_error(units(x) <- u)
  }
  d <- make_age(c(a = 1, b = NA), "day")
  expect_equal(as.numeric(units::set_units(d, hour)), c(24, NA))
  units(d) <- units::as_units("hour")
  expect_identical(class(d), expected_class)
  expect_equal(as.numeric(d), c(24, NA))
  d[1] <- make_age(2, "hour")
  expect_equal(as.numeric(d), c(2, NA))
  expect_error(d[1] <- make_age(2, "day"))
  expect_error(d[1] <- -1)
  expect_error(vctrs::vec_cast(x, units::set_units(1, "day", mode = "standard")))
  expect_error(vctrs::vec_c(x, units::set_units(1, "day", mode = "standard")))
})

test_that("tibble and dplyr preserve vectors and classification", {
  skip_if_not_installed("tibble")
  x <- make_age(c(1, 5, NA), "day")
  tab <- tibble::tibble(x = x)
  expect_s3_class(tab$x, "age")
  expect_s3_class(vctrs::vec_rbind(tab, tab)$x, "age")
  expect_s3_class(tab[1:2, ]$x, "age")
  skip_if_not_installed("dplyr")
  out <- dplyr::mutate(tab, y = x + 1)
  expect_s3_class(out$y, "age")
  expect_equal(as.numeric(out$y), c(2, 6, NA))
  expect_s3_class(dplyr::bind_rows(tab, tab)$x, "age")
  expect_equal(as.numeric(dplyr::arrange(tab, x)$x), c(1, 5, NA))
  expect_equal(as.numeric(dplyr::summarise(tab, x = mean(x, na.rm = TRUE))$x), 3)
})


test_that("prototype public conversions and unit removal have explicit returns", {
  skip_if(mode == "baseline", "Prototype-specific inheritance contract")
  x <- make_age(c(a = 1, b = NA), "day")
  expect_identical(class(convert(units::set_units(1, "day", mode = "standard"))),
                   expected_class)
  expect_identical(class(convert(1)), expected_class)
  expect_identical(class(units::drop_units(x)), "numeric")
  expect_equal(units::drop_units(x), c(1, NA))
  expect_error(diff(x))
  expect_error(units(x) <- 2 * units::as_units("day"))
  expect_s3_class(units::set_units(x, "hour"), "age")
  # These operations were observed to drop the subclass without adapters.
  expect_s3_class(rep(x, 2), "age")
  expect_s3_class(unique(x), "age")
})

test_that("classification conversions preserve interval and group contracts", {
  days <- agecraft::age_interval(breaks = c(0, 1, 3, Inf), unit = "day")
  names(days) <- c("First", "Next", "Later")
  x <- make_age(c(0, 24, 72, NA), "hour")
  for (direction in c("age_to_group", "group_to_age")) {
    out <- agecraft::categorize_age(x, by = days, convert_units = direction)
    expect_s3_class(out, "age_group")
    expect_equal(as.character(out), c("First", "Next", "Later", NA))
    expect_equal(agecraft::group_intervals(out), days)
    expect_s3_class(agecraft::categorize_age(x, by = days,
      convert_units = direction, output = "interval"), "age_interval")
  }
  expect_error(agecraft::categorize_age(x, by = days, convert_units = "none"))
  months <- agecraft::age_interval(breaks = c(0, 12, 60, Inf), unit = "month")
  x <- make_age(c(0.25, 2, 10, NA), "year")
  for (direction in c("age_to_group", "group_to_age")) {
    expect_error(agecraft::categorize_age(x, by = months,
      convert_units = direction), "approximate")
    expect_equal(as.integer(agecraft::categorize_age(x, by = months,
      convert_units = direction, allow_approx = TRUE)), c(1L, 2L, 3L, NA_integer_))
  }
})
