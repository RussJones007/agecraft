x <- p_age(1, "year")
y <- units::as_units("month")
  test_that("mixed units arithmetic cannot bypass calendar consent", {
    expect_error(x + y, "approximate|unsupported|Invalid")
    expect_error(y + x, "approximate|unsupported|Invalid")
  })
  test_that("base data frame and list conversions retain valid ages", {
    expect_s3_class(as.data.frame(x)$x, "age")
    expect_s3_class(as.list(x)[[1]], "age")
  })
