test_that("all eight registry definitions preserve legacy boundaries and assignments", {
  listing <- list_age_schemes()
  expect_identical(listing$preset, names(age_interval_presets))
  expect_equal(nrow(listing), 8)
  expect_false(anyDuplicated(listing$id) > 0)
  expect_true(all(!listing$verified))
  expect_identical(age.groups, age_interval_presets)
  before <- serialize(age_interval_presets, NULL)
  for (i in seq_len(nrow(listing))) {
    s <- get_age_scheme(listing$id[i])
    cuts <- age_interval_presets[[listing$preset[i]]]
    g <- scheme_intervals(s)
    expect_identical(ivs::iv_start(g), as.double(utils::head(cuts, -1)))
    expect_identical(ivs::iv_end(g), as.double(utils::tail(cuts, -1)))
    expect_identical(get_unit(g), "year")
    expect_true(summary(s)$covered)
    expect_false(summary(s)$overlaps)
    finite <- cuts[is.finite(cuts)]
    probes <- c(finite, finite + 1e-7, pmax(0, finite - 1e-7), 100, NA)
    ages <- age(probes, unit = "year")
    legacy <- categorize_age(ages, by = cuts)
    migrated <- categorize_age(ages, by = s)
    # Numeric presets use their caller-selected display symbols. Compare group
    # assignments and bounds rather than requiring identical whitespace in labels.
    expect_identical(as.integer(migrated), as.integer(legacy))
    expect_identical(ivs::iv_start(categorize_age(ages, by = s, output = "interval")),
                     ivs::iv_start(categorize_age(ages, by = cuts, output = "interval")))
    expect_identical(ivs::iv_end(categorize_age(ages, by = s, output = "interval")),
                     ivs::iv_end(categorize_age(ages, by = cuts, output = "interval")))
    expect_identical(s$source, listing$source[i])
    expect_identical(s$version, listing$version[i])
    expect_false(s$verified)
  }
  expect_identical(serialize(age_interval_presets, NULL), before)
  s <- get_age_scheme(listing$id[1])
  s$name <- "Changed"
  names(s$intervals)[1] <- "Changed"
  expect_false(identical(get_age_scheme(listing$id[1]), s))
  for (id in list("missing", "ILI", NA_character_, character(), c("a", "b"))) {
    expect_error(get_age_scheme(id), "Unknown scheme id")
  }
})
