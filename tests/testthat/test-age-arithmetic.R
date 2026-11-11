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
