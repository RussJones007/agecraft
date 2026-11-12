scheme_test_groups <- function(start = c(0, 5), end = c(5, Inf)) {
  g <- age_interval(start, end, unit = "year")
  names(g) <- paste0("Group ", seq_along(g))
  g
}

test_that("schemes preserve groups and validate coverage independently of overlap", {
  g <- scheme_test_groups()
  s <- age_scheme(g, "test", "Test", domain = c(0, Inf), complete = TRUE)
  expect_true(is_age_scheme(s))
  expect_false(is_age_interval(s))
  expect_identical(scheme_intervals(s), g)
  expect_identical(validate_age_scheme(s), s)
  expect_identical(unserialize(serialize(s, NULL)), s)
  overlap <- scheme_test_groups(c(0, 2), c(5, Inf))
  expect_error(age_scheme(overlap, "test", "Test"), "overlap")
  s2 <- age_scheme(overlap, "test", "Test", type = "classification",
                   domain = c(0, Inf), complete = TRUE)
  expect_true(summary(s2)$overlaps)
  expect_true(summary(s2)$covered)
  gapped <- scheme_test_groups(c(0, 5.25), c(5, Inf))
  expect_error(age_scheme(gapped, "test", "Test", domain = c(0, Inf),
                         complete = TRUE), "coverage")
  partial <- age_scheme(gapped, "test", "Test", domain = c(0, Inf), complete = FALSE)
  expect_equal(ivs::iv_start(summary(partial)$gaps), 5)
  expect_equal(ivs::iv_end(summary(partial)$gaps), 5.25)
  expect_error(age_scheme(g, "test", "Test", domain = c(0, Inf), complete = FALSE),
               "coverage")
  expect_error(age_scheme(g, "test", "Test", complete = TRUE), "domain")
  expect_error(age_scheme(g, "test", "Test", domain = c(0, 5)), "within domain")
})

test_that("scheme construction rejects malformed definitions and metadata", {
  g <- scheme_test_groups()
  expect_error(age_scheme(age_interval(), "test", "Test"), "nonempty")
  missing <- age_interval(NA_real_, NA_real_, unit = "year")
  names(missing) <- "Missing"
  expect_error(age_scheme(missing, "test", "Test"), "missing")
  expect_error(age_scheme(unname(g), "test", "Test"), "names")
  for (labels in list(c("A", "A"), c("A", " "), c("A", NA))) {
    names(g) <- labels
    expect_error(age_scheme(g, "test", "Test"), "names")
  }
  g <- scheme_test_groups()
  unitless <- g
  attr(unitless, "unit") <- NULL
  expect_error(age_scheme(unitless, "test", "Test"), "unit")
  badunit <- g
  attr(badunit, "unit") <- "metre"
  expect_error(age_scheme(badunit, "test", "Test"), "unit")
  expect_error(age_scheme(g, "bad id", "Test"), "id")
  expect_error(age_scheme(g, "test", ""), "name")
  expect_error(age_scheme(g, "test", "Test", purpose = NA_character_), "purpose")
  expect_error(age_scheme(g, "test", "Test", verified = NA), "verified")
  expect_error(age_scheme(g, "test", "Test", verified = TRUE), "source")
  expect_error(age_scheme(g, "test", "Test", complete = 1), "complete")
  for (domain in list(c(5, 0), c(-1, Inf), c(NA, Inf), c(0, 0), c(Inf, Inf))) {
    expect_error(age_scheme(g, "test", "Test", domain = domain), "domain")
  }
  s <- age_scheme(g, "test", "Test")
  s <- unclass(s)
  s$type <- "other"
  class(s) <- "age_scheme"
  expect_error(validate_age_scheme(s), "type")
  s <- unclass(s)
  s$intervals <- unitless
  class(s) <- "age_scheme"
  expect_error(scheme_intervals(s))
  expect_error(validate_age_scheme(structure(list(), class = "age_scheme")), "fields")
})
