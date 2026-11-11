test_that("age invariants are enforced through construction, restore and cast", {
  expect_identical(age(0), age(0L))
  expect_identical(as.numeric(age(NA_real_)), NA_real_)
  for (value in c(-1, -0.001, Inf, -Inf)) {
    expect_error(age(value), "nonnegative and finite")
    expect_error(vctrs::vec_restore(value, age()), "nonnegative and finite")
    corrupt <- vctrs::new_vctr(value, unit = "year", class = "age")
    expect_error(vctrs::vec_cast(corrupt, age()), "nonnegative and finite")
  }
  expect_identical(vctrs::vec_restore(c(0, 0.25, NA), age(unit = "day")),
                   age(c(0, 0.25, NA), "day"))
})


test_that("numeric offsets preserve age semantics and vector sizes", {
  x <- age(c(a = 25.25, b = NA_real_), "year")
  expect_identical(x + 1, age(c(a = 26.25, b = NA_real_)))
  expect_identical(1L + x, x + 1)
  expect_identical(x - 25.25, age(c(a = 0, b = NA_real_)))
  expect_identical(x + (-1), x - 1)
  expect_identical(age(25) + 1, age(26))
  expect_error(age(0) - 1, "nonnegative")
  expect_error(age(0) + (-1), "nonnegative")
  expect_identical(age() + 1, age())
  expect_identical(1 + age(), age())
  expect_identical(age(1) - numeric(), age())
  expect_identical(age(1) + c(1L, 2L), age(c(2, 3)))
  expect_error(age(1:2) + 1:3, class = "vctrs_error_incompatible_size")
  expect_identical(age(NA_real_) + NA_real_, age(NA_real_))
  for (offset in c(Inf, -Inf)) expect_error(x + offset, "finite")
  expect_error(x + TRUE, class = "vctrs_error_incompatible_op")
  expect_error(vctrs::vec_arith("+", x, units::set_units(1, "day")),
               class = "vctrs_error_incompatible_op")
  expect_error(x + matrix(1), class = "vctrs_error_incompatible_op")
})

test_that("age addition converts only exact right-hand units automatically", {
  expect_identical(age(2, "week") + age(3.5, "day"), age(2.5, "week"))
  expect_identical(age(3.5, "day") + age(2, "week"), age(17.5, "day"))
  expect_identical(age(c(a = 1, b = NA), "hour") + age(30, "minute"),
                   age(c(a = 1.5, b = NA), "hour"))
  expect_identical(age(unit = "day") + age(1, "week"), age(unit = "day"))
  expect_error(age(2, "year") + age(6, "month"), "approximate")
  expect_error(age(6, "month") + age(2, "year"), "approximate")
  expect_equal(age(2, "year") + as_age(age(6, "month"), "year", allow_approx = TRUE), age(2.5))
  expect_equal(age(6, "month") + as_age(age(2, "year"), "month", allow_approx = TRUE), age(30, "month"))
  expect_error(age(1, "day") + age(1, "month"), "approximate")
  expect_error(age(1) - age(2), class = "vctrs_error_incompatible_op")
  expect_error(age(2) - age(1), class = "vctrs_error_incompatible_op")
  expect_error(2 - age(1), class = "vctrs_error_incompatible_op")
  for (op in c("*", "/", "^", "%%", "%/%")) {
    expect_error(do.call(op, list(age(2), 2)), class = "vctrs_error_incompatible_op")
  }
  expect_error(age(1, "day") < age(1, "week"), "incompatible units")
  expect_error(vctrs::vec_c(age(1, "day"), age(1, "week")), "incompatible units")
})


test_that("supported transformations and summaries preserve class and units", {
  x <- age(c(1.25, 2.75, NA), "day")
  for (fn in c("round", "floor", "ceiling", "trunc", "abs")) {
    expected <- do.call(fn, list(c(1.25, 2.75, NA)))
    expect_identical(do.call(fn, list(x)), age(expected, "day"))
    expect_identical(do.call(fn, list(age(unit = "day"))), age(unit = "day"))
  }
  for (fn in c("mean", "median", "min", "max", "range")) {
    expected <- do.call(fn, list(c(1.25, 2.75, NA), na.rm = TRUE))
    expect_identical(do.call(fn, list(x, na.rm = TRUE)), age(expected, "day"))
    expect_identical(do.call(fn, list(x)),
                     age(do.call(fn, list(c(1.25, 2.75, NA))), "day"))
  }
  expect_identical(median(age(unit = "day")), age(NA_real_, "day"))
  expect_true(is.nan(as.numeric(mean(age()))))
  for (fn in c("min", "max", "range")) {
    expect_error(suppressWarnings(do.call(fn, list(age()))), "nonnegative and finite")
    expect_error(suppressWarnings(do.call(fn, list(age(NA_real_), na.rm = TRUE))), "nonnegative and finite")
  }
  for (fn in c("sum", "prod", "log", "exp", "sqrt")) {
    expect_error(do.call(fn, list(x)), "not defined for ages")
  }
})
