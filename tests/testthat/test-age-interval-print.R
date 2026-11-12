test_that("age groups have a single common unit", {
  expect_error(age_interval(c(0, 5), c(5, Inf), unit = c("year", "day")),
               "scalar string")
  x <- age_interval(c(0, 5), c(5, Inf), unit = "years")
  expect_identical(attr(x, "unit"), "year")
})

test_that("age-group printing shows units only in the header", {
  x <- age_interval(c(0, 5, NA), c(5, Inf, NA), unit = "year")
  for (value in list(x, x[0], x[3], age_interval(0.5, 1.5, unit = "year"))) {
    output <- capture.output(result <- withVisible(print(value)))
    expect_identical(output[1],
                     sprintf("<age_interval (year) [%d]>", length(value)))
    expect_identical(output[-1], capture.output(print(as.character(value), quote = FALSE)))
    expect_false(any(grepl("year", output[-1], fixed = TRUE)))
    expect_identical(result$value, value)
    expect_false(result$visible)
  }
  expect_identical(capture.output(print(age_interval(0, 5)))[1],
                   "<age_interval (unknown) [1]>")
  expect_identical(format(x), c("0-4", "5+", NA_character_))
})
