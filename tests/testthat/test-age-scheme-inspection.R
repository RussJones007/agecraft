inspection_scheme <- function(...) {
  g <- age_interval(c(0, 5), c(5, Inf), unit = "year")
  names(g) <- c("Under 5", "5+")
  age_scheme(g, "example", "Example age bands", ...)
}

test_that("summary keeps metadata accessible and prints provenance", {
  s <- inspection_scheme(source = "Reporting handbook", version = "Edition A",
                         reference = "https://example.org/guide",
                         organization = "Example Agency", verified = TRUE)
  info <- summary(s)
  expect_s3_class(info, "summary_age_scheme")
  for (field in setdiff(names(s), "intervals")) {
    expect_identical(info[[field]], s[[field]])
  }
  expect_identical(info$n_groups, 2L)
  expect_null(info$gaps)
  expect_output(print(info), "source: Reporting handbook")
  expect_output(print(info), "version: Edition A")
  expect_output(print(info), "verified: TRUE")
  expect_output(print(info), "unknown")
  expect_identical(withVisible(print(info))$visible, FALSE)
  s$intervals <- rev(s$intervals)
  expect_output(print(summary(s)), "Derived from:")
  expect_identical(summary(s)$derived_from, s$derived_from)
})

test_that("standard BibTeX dispatch exports recorded scheme metadata", {
  s <- inspection_scheme(source = "Reporting handbook", version = "Edition A",
                         reference = "https://example.org/guide",
                         organization = "Example Agency", verified = TRUE,
                         purpose = "Reporting", notes = "Use completed years")
  before <- serialize(s, NULL)
  bib <- utils::toBibtex(s)
  expect_s3_class(bib, "Bibtex")
  text <- paste(bib, collapse = "\n")
  for (part in c("@Misc{example,", "title = {Example age bands}",
                 "Example Agency: Reporting handbook", "Version: Edition A",
                 "url = {https://example.org/guide}",
                 "Source verification claimed: TRUE", "purpose: Reporting",
                 "notes: Use completed years")) {
    expect_true(grepl(part, text, fixed = TRUE), info = part)
  }
  expect_false(grepl("year =", text, fixed = TRUE))
  expect_false(grepl("author =", text, fixed = TRUE))
  expect_identical(serialize(s, NULL), before)
})

test_that("BibTeX handles missing metadata and non-URL references honestly", {
  for (reference in list(NULL, "10.1234/example", "Agency (2020). Handbook.")) {
    s <- inspection_scheme(reference = reference)
    text <- paste(utils::toBibtex(s), collapse = "\n")
    expect_match(text, "Source: unknown", fixed = TRUE)
    expect_match(text, "Version: unknown", fixed = TRUE)
    expect_match(text, "Source verification claimed: FALSE", fixed = TRUE)
    expect_false(grepl("url =", text, fixed = TRUE))
    expect_false(grepl("year =", text, fixed = TRUE))
    expect_match(text, paste0("Reference: ", reference %||% "unknown"),
                 fixed = TRUE)
  }
  for (id in list_age_schemes()$id) {
    expect_s3_class(utils::toBibtex(get_age_scheme(id)), "Bibtex")
  }
})

test_that("BibTeX distinguishes derivatives and supports older schemes", {
  s <- inspection_scheme(source = "Original handbook", version = "Release B",
                         reference = "Original reference", verified = TRUE)
  s$name <- "Local age bands"
  s$intervals <- rev(s$intervals)
  text <- paste(utils::toBibtex(s), collapse = "\n")
  for (part in c("@Misc{example_derived,", "title = {Local age bands}",
                 "Version: unknown", "Source verification claimed: FALSE",
                 "Adapted from scheme: example", "Ancestor version: Release B",
                 "Ancestor source: Original handbook",
                 "Ancestor reference: Original reference")) {
    expect_match(text, part, fixed = TRUE)
  }
  old <- unclass(inspection_scheme())
  old$derived_from <- NULL
  class(old) <- "age_scheme"
  expect_s3_class(utils::toBibtex(old), "Bibtex")
  bad <- unclass(old)
  bad$intervals <- unname(bad$intervals)
  class(bad) <- "age_scheme"
  expect_error(utils::toBibtex(bad), "names")
  expect_error(summary(bad), "names")
})
