structure_test_groups <- function() {
  g <- age_group(c(0, 11), c(11, Inf), unit = "second")
  names(g) <- c("Under eleven", "Eleven or more")
  g
}

expect_scheme_rejects_groups <- function(g, pattern) {
  expect_error(age_scheme(g, "broken", "Broken"), pattern)
  s <- age_scheme(structure_test_groups(), "example", "Example")
  s <- unclass(s)
  s$groups <- g
  class(s) <- "age_scheme"
  original <- serialize(s, NULL)
  expect_error(validate_age_scheme(s), pattern)
  expect_error(scheme_groups(s), pattern)
  expect_error(categorize_age(age(1, "second"), by = s), pattern)
  expect_error(classify_age_scheme(age(1, "second"), s), pattern)
  expect_error(print(s), pattern)
  expect_error(summary(s), pattern)
  expect_error(as.data.frame(s), pattern)
  expect_identical(serialize(s, NULL), original)
}

test_that("every scheme entry point rejects actual malformed display metadata", {
  g <- structure_test_groups()
  attr(g, "symbols") <- NULL
  expect_scheme_rejects_groups(g, "symbols")
  for (symbols in list(c(below = "<", sep = "-", above = "+"), list(), list("<", "-", "+"),
                       list(below = "<", sep = "-", wrong = "+"),
                       list(below = "<", sep = "-", above = "+", extra = "!"))) {
    g <- structure_test_groups()
    attr(g, "symbols") <- symbols
    expect_scheme_rejects_groups(g, "symbols")
  }
  for (field in c("below", "sep", "above")) {
    for (value in list(NULL, 1, character(), c("a", "b"), NA_character_, list("x"))) {
      g <- structure_test_groups()
      symbols <- attr(g, "symbols")
      symbols[field] <- list(value)
      attr(g, "symbols") <- symbols
      expect_scheme_rejects_groups(g, "symbols")
    }
    g <- structure_test_groups()
    symbols <- attr(g, "symbols")
    names(symbols)[names(symbols) == field] <- paste0(field, "_wrong")
    attr(g, "symbols") <- symbols
    expect_scheme_rejects_groups(g, "symbols")
    g <- structure_test_groups()
    symbols <- attr(g, "symbols")
    symbols[[field]] <- NULL
    attr(g, "symbols") <- symbols
    expect_scheme_rejects_groups(g, "symbols")
  }
})

test_that("schemes reject malformed stored units and category names", {
  for (unit in list(NULL, "", NA_character_, c("second", "day"), 1, "year/day", "metre")) {
    g <- structure_test_groups()
    attr(g, "unit") <- unit
    expect_scheme_rejects_groups(g, "unit")
  }
  g <- structure_test_groups()
  attr(g, "group_names") <- NULL
  attr(g, "group_names_extra") <- c("A", "B")
  expect_scheme_rejects_groups(g, "names")
  for (labels in list(NULL, c("A", "A"), c("A", ""), c("A", NA_character_),
                      "Short", 1:2, matrix(c("A", "B"), 1))) {
    g <- structure_test_groups()
    attr(g, "group_names") <- labels
    expect_scheme_rejects_groups(g, "names")
  }
})

test_that("scheme validation rejects corrupted interval records without repair", {
  valid <- structure_test_groups()
  for (field in c("start", "end")) {
    for (value in list(NULL, 1, c(0L, 1L), c("0", "1"), matrix(c(0, 1), 1),
                       structure(c(0, 1), class = "Date"))) {
      raw <- unclass(valid)
      raw[field] <- list(value)
      class(raw) <- class(valid)
      expect_scheme_rejects_groups(raw, "endpoints")
    }
  }
  for (fields in list(c("wrong", "end"), c("start", "wrong"), c("end", "start"))) {
    raw <- unclass(valid)
    names(raw) <- fields
    class(raw) <- class(valid)
    expect_scheme_rejects_groups(raw, "fields")
  }
  for (bounds in list(list(c(-1, 11), c(11, Inf)), list(c(0, Inf), c(11, Inf)),
                      list(c(11, 11), c(0, Inf)), list(c(0, 11), c(0, Inf)),
                      list(c(0, 11), c(-Inf, Inf)), list(c(NA_real_, 11), c(11, Inf)))) {
    raw <- unclass(valid)
    raw$start <- bounds[[1]]
    raw$end <- bounds[[2]]
    class(raw) <- class(valid)
    expect_scheme_rejects_groups(raw, "endpoints|start < end|Missing intervals")
  }
  for (cl in c("ivs_iv", "vctrs_rcrd", "vctrs_vctr")) {
    g <- valid
    class(g) <- setdiff(class(g), cl)
    expect_scheme_rejects_groups(g, "structure")
  }
  g <- valid
  class(g) <- rev(class(g))
  expect_scheme_rejects_groups(g, "structure")
  g <- valid
  attr(g, "dim") <- c(1L, 2L)
  expect_scheme_rejects_groups(g, "structure")
})

test_that("validated schemes support ordinary operations and custom display symbols", {
  for (symbols in list(list(above = " and up", below = "< ", sep = " through "),
                       list(below = "", sep = "", above = ""))) {
    g <- age_group(c(0, 5, 11.5), c(5, 11.5, Inf), unit = "second",
                   below = symbols$below, sep = symbols$sep, above = symbols$above)
    names(g) <- c("Young", "Middle", "Older")
    # Named list ordering has no semantic significance.
    attr(g, "symbols") <- symbols
    attr(g, "user_note") <- "Unrelated attributes are permitted"
    s <- age_scheme(g, "custom", "Custom", domain = c(0, Inf), complete = TRUE)
    before <- serialize(s, NULL)
    expect_identical(validate_age_scheme(s), s)
    out <- scheme_groups(s)
    expect_identical(out, g)
    expect_identical(attr(out[c(3, 1)], "symbols"), symbols)
    expect_identical(names(out[c(3, 1)]), c("Older", "Young"))
    expect_identical(ivs::iv_start(out[c(3, 1)]), c(11.5, 0))
    expect_identical(as.character(categorize_age(age(c(1, 5, 11.5), "second"), by = s)),
                     names(g))
    classified <- classify_age_scheme(age(c(1, 5, 11.5), "second"), s)
    expect_identical(classified$group, g[seq_along(g)])
    expect_identical(attr(classified$group, "symbols"), symbols)
    expect_identical(format(out), format(g))
    expect_output(print(s), "Custom")
    expect_true(summary(s)$covered)
    expect_equal(as.data.frame(s)$start, c(0, 5, 11.5))
    expect_identical(serialize(s, NULL), before)
  }
  for (id in list_age_schemes()$id) {
    s <- get_age_scheme(id)
    expect_identical(validate_age_scheme(s), s)
    expect_no_error(format(scheme_groups(s)[1]))
    expect_equal(nrow(classify_age_scheme(age(1, "year"), s)), 1)
  }
})

test_that("general interval validation retains optional metadata and empty vectors", {
  empty <- age_group()
  expect_identical(validate_age_group(empty), empty)
  expect_error(age_scheme(empty, "empty", "Empty"), "nonempty")
  g <- age_group(c(0, NA_real_), c(5, NA_real_))
  names(g) <- c("", NA_character_)
  expect_identical(validate_age_group(g), g)
  # Arbitrary nonblank units remain permitted by age_group, but not by schemes.
  custom <- age_group(0, 5, unit = "custom")
  expect_identical(validate_age_group(custom), custom)
})
