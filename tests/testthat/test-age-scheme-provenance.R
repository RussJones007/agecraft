provenance_scheme <- function(verified = TRUE) {
  g <- age_interval(c(0, 10), c(10, Inf), unit = "year")
  names(g) <- c("Younger", "Older")
  age_scheme(g, "original", "Original title", domain = c(0, Inf), complete = TRUE,
             source = "Source", version = "v1", reference = "Citation",
             organization = "Organization", verified = verified)
}

expect_derivative <- function(x, original) {
  expect_false(x$verified)
  expect_false(identical(x$id, original$id))
  expect_identical(x$derived_from, unclass(original)[c("id", "version", "source", "organization", "reference")])
  expect_identical(validate_age_scheme(x), x)
}

test_that("replacement forms create independent derivatives and preserve catalog data", {
  for (id in list_age_schemes()$id) {
    original <- get_age_scheme(id)
    saved <- serialize(original, NULL)
    for (mode in c("dollar", "double", "single", "position")) {
      x <- original
      g <- x$intervals
      names(g)[1] <- "Revised category"
      if (mode == "dollar") x$intervals <- g
      if (mode == "double") x[["intervals"]] <- g
      if (mode == "single") x["intervals"] <- list(g)
      if (mode == "position") x[[1L]] <- g
      expect_derivative(x, original)
      expect_identical(x$id, paste0(id, "_derived"))
      expect_null(x$version)
      expect_identical(names(x$intervals)[1], "Revised category")
      expect_identical(serialize(original, NULL), saved)
      expect_identical(serialize(get_age_scheme(id), NULL), saved)
    }
  }
})

test_that("nested labels, interval replacements and units are substantive", {
  original <- provenance_scheme()
  x <- original
  names(x$intervals)[1] <- "New meaning"
  expect_true(all(vctrs::vec_equal(x$intervals, original$intervals)))
  expect_derivative(x, original)
  x <- original
  attr(x$intervals, "group_names")[1] <- "New meaning"
  expect_derivative(x, original)
  x <- original
  names(x[["intervals"]])[1] <- "New meaning"
  expect_derivative(x, original)
  x <- original
  g <- age_interval(0, 9, unit = "year")
  names(g) <- "Younger"
  x[c("intervals", "complete")] <- list(c(g, original$intervals[2]), FALSE)
  expect_derivative(x, original)
  replacement <- age_interval(0, 8, unit = "year")
  names(replacement) <- "Younger"
  x$intervals[1] <- replacement
  expect_identical(ivs::iv_end(x$intervals)[1], 8)
  expect_derivative(x, original)
  x <- original
  attr(x$intervals, "unit") <- "day"
  expect_derivative(x, original)
  expect_identical(ivs::iv_start(x$intervals), c(0, 10))
  x <- original
  x$intervals <- x$intervals[2:1]
  expect_derivative(x, original)
  x <- original
  x$type <- "classification"
  expect_derivative(x, original)
  x <- original
  x$domain <- c(0, Inf) # identical domain
  expect_identical(x, original)
  x$complete <- NA
  expect_derivative(x, original)
})

test_that("cosmetic and identical edits preserve verification and ancestry", {
  for (verified in c(TRUE, FALSE)) {
    original <- provenance_scheme(verified)
    x <- original
    x$name <- "Descriptive title"
    x$notes <- "Descriptive notes"
    attr(x$intervals, "symbols")$sep <- " through "
    expect_null(x$derived_from)
    expect_identical(x$verified, verified)
    expect_identical(x$id, original$id)
    expect_identical(x$version, original$version)
    for (mode in c("dollar", "double", "single")) {
      y <- original
      if (mode == "dollar") y$intervals <- y$intervals
      if (mode == "double") y[["intervals"]] <- y$intervals
      if (mode == "single") y["intervals"] <- list(y$intervals)
      expect_identical(y, original)
    }
    x$notes <- NULL
    expect_true("notes" %in% names(x))
    expect_null(x$notes)
    expect_identical(validate_age_scheme(x), x)
  }
})

test_that("repeated edits and reversions preserve first ancestry", {
  original <- provenance_scheme()
  x <- original
  names(x$intervals)[1] <- "Revised"
  ancestry <- x$derived_from
  id <- x$id
  names(x$intervals)[2] <- "Second revision"
  x$intervals <- original$intervals
  x$name <- "Another title"
  expect_identical(x$derived_from, ancestry)
  expect_identical(x$id, id)
  expect_false(x$verified)
  expect_identical(x$intervals, original$intervals)
  expect_true(original$verified)
  expect_null(original$derived_from)
})

test_that("identity and asserted-source edits clear inherited verification", {
  original <- provenance_scheme()
  for (field in c("source", "organization", "reference", "version", "id")) {
    x <- original
    x[[field]] <- "replacement"
    expect_derivative(x, original)
    if (field == "id") expect_identical(x$id, "replacement")
    if (field == "version") expect_identical(x$version, "replacement")
  }
  x <- original
  x[c("source", "verified")] <- list("New source", TRUE)
  expect_false(x$verified) # same-batch TRUE cannot silently carry a claim forward
  x[c("version", "reference")] <- list("New edition", "New citation")
  x$verified <- TRUE # explicit separate caller claim under existing contract
  expect_true(x$verified)
  expect_identical(x$derived_from$source, original$source)
  names(x$intervals)[1] <- "Changed again"
  expect_false(x$verified)
  expect_null(x$version)
})

test_that("batch replacements validate final state and failed edits are atomic", {
  original <- provenance_scheme()
  saved <- serialize(original, NULL)
  partial <- original$intervals[1]
  expect_error(original$intervals <- partial, "coverage")
  expect_identical(serialize(original, NULL), saved)
  x <- original
  x[c("intervals", "complete")] <- list(partial, FALSE)
  expect_derivative(x, original)
  expect_false(summary(x)$covered)
  saved_candidate <- serialize(x, NULL)
  expect_error(x$intervals <- unname(x$intervals), "names")
  expect_error(x[[c("intervals", "start")]] <- 0, "recursive")
  expect_error(x[[list("intervals")]] <- partial, "recursive")
  expect_error(x$gro <- partial, "known scheme fields")
  expect_error(x[[100]] <- partial, "position")
  expect_error(x[[NA_character_]] <- partial, "protected")
  expect_error(x[c("intervals", "intervals")] <- list(partial, partial), "exactly once")
  expect_error(x["intervals"] <- partial, "list of replacement")
  expect_error(x$derived_from$id <- "tampered", "protected")
  expect_error(x$derived_from <- NULL, "protected")
  expect_error(x[["derived_from"]] <- list(), "protected")
  expect_error(x["derived_from"] <- list(NULL), "protected")
  expect_error(x$id <- original$id, "distinct")
  expect_error(x[c("domain", "complete")] <- list(c(0, 5), NA), "within domain")
  expect_error(attr(x$intervals, "symbols") <- NULL, "symbols")
  expect_identical(serialize(original, NULL), saved)
  expect_identical(serialize(x, NULL), saved_candidate)
  expect_identical(validate_age_scheme(x), x)
})

test_that("serialization, legacy schema and classification remain supported", {
  original <- provenance_scheme()
  legacy <- unclass(original)
  legacy$derived_from <- NULL
  class(legacy) <- "age_scheme"
  expect_identical(validate_age_scheme(legacy), legacy)
  expect_identical(unserialize(serialize(legacy, NULL)), legacy)
  x <- legacy
  names(x$intervals)[1] <- "Revised"
  expect_derivative(x, original)
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  saveRDS(x, path)
  expect_identical(readRDS(path), x)
  expect_identical(unserialize(serialize(x, NULL)), x)
  expect_output(print(x), "Derived from: original")
  expect_identical(summary(x)$derived_from, x$derived_from)
  expect_identical(attr(as.data.frame(x), "scheme_metadata")$derived_from, x$derived_from)
  ages <- age(c(0, 10, NA), "year")
  expect_identical(as.character(categorize_age(ages, by = x)), c("Revised", "Older", NA_character_))
  expect_identical(classify_age_scheme(ages, x)$group_index, c(1L, 2L, NA_integer_))
  expect_identical(classify_age_scheme(ages, x)$scheme_id, rep(x$id, 3))
  raw <- unclass(x)
  raw$derived_from <- list(id = "incomplete")
  class(raw) <- "age_scheme"
  expect_error(validate_age_scheme(raw), "derived_from")
})

test_that("user-defined and older schemes retain only known ancestry", {
  g <- age_interval(0, 20, unit = "year")
  names(g) <- "All recorded ages"
  original <- age_scheme(g, "local", "Local definition", domain = c(0L, 20L), complete = TRUE)
  x <- original
  x$domain <- c(0, 20) # storage type differs, but both bounds are exactly identical
  expect_identical(x$derived_from, NULL)
  expect_identical(x$id, original$id)
  names(x$intervals)[1] <- "Local label meaning"
  expect_derivative(x, original)
  expect_null(x$derived_from$source)
  expect_null(x$derived_from$version)
  before <- x$derived_from
  x$name <- "Retitled derivative"
  attr(x$intervals, "symbols")$above <- " and older"
  expect_identical(x$derived_from, before)
  expect_false(x$verified)
  for (field in c("id", "version", "source", "organization", "reference")) {
    raw <- unclass(x)
    raw$derived_from[field] <- list(NA_character_)
    class(raw) <- "age_scheme"
    expect_error(validate_age_scheme(raw), "derived_from")
  }
})

test_that("cosmetic edits preserve an explicitly reverified derivative", {
  x <- provenance_scheme()
  names(x$intervals)[1] <- "Revised"
  x$version <- "Local checked edition"
  x$verified <- TRUE
  ancestry <- x$derived_from
  x["name"] <- list("A descriptive title")
  attr(x$intervals, "symbols")$sep <- " to "
  expect_true(x$verified)
  expect_identical(x$derived_from, ancestry)
  expect_identical(x$version, "Local checked edition")
})
