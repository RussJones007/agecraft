mud_fixture <- function() dget(test_path("fixtures", "mudnester-0.7.8.R"))

test_that("offline imports preserve all coordinates and cut classification", {
  fixture <- mud_fixture()
  for (i in seq_len(nrow(fixture))) {
    row <- fixture[i, , drop = FALSE]
    expect_warning(s <- mudnester_convert_row(row, "0.7.8"), "clinical applicability")
    g <- scheme_groups(s)
    b <- row$breaks[[1L]]
    unit <- if (as.character(row$age_unit) == "years") "year" else "day"
    expect_identical(ivs::iv_start(g), head(b, -1L))
    expect_identical(ivs::iv_end(g), tail(b, -1L))
    expect_identical(names(g), row$labels[[1L]])
    expect_identical(get_unit(g), unit)
    expect_false(s$verified)
    expect_null(s$version)
    expect_null(s$organization)
    expect_true(s$complete)
    expect_identical(s$id, paste0("mudnester_", row$scheme))
    finite <- b[is.finite(b)]
    values <- sort(unique(c(finite, finite + 1e-9, pmax(0, finite - 1e-9), NA)), na.last = TRUE)
    actual <- categorize_age(age(values, unit = unit), by = s)
    expected <- cut(values, b, labels = row$labels[[1L]], right = FALSE,
                    ordered_result = TRUE)
    expect_identical(as.character(actual), as.character(expected))
    expect_identical(levels(actual), levels(expected))
    expect_identical(as.integer(categorize_age(age(head(b, -1L), unit = unit), by = s)),
                     seq_len(length(b) - 1L))
  }
})

test_that("catalogue provenance and known issues are inspectable without repair", {
  f <- mud_fixture()
  table <- mudnester_companion(f, "0.7.8")
  for (field in c("scheme", "family", "focus_tags", "source", "source_url",
                  "last_checked", "is_illustrative")) expect_identical(table[[field]], f[[field]])
  expect_identical(table$package_version, rep("0.7.8", nrow(f)))
  expect_match(paste(table$issues[[which(f$scheme == "covid19_severity_strata")]], collapse = " "), "disagree")
  expect_match(paste(table$issues[[which(f$scheme == "unicef_child_bands")]], collapse = " "), "numeric \\[0,1\\)")
  expect_match(paste(table$issues[[which(f$scheme == "paediatric_developmental")]], collapse = " "), "not exact elapsed days")
  row <- f[1L, , drop = FALSE]
  row$source <- NA_character_
  row$source_url <- NA_character_
  s <- mudnester_convert_row(row, "0.7.8", warn = FALSE)
  expect_null(s$source)
  expect_null(s$reference)
  expect_match(s$notes, "snapshot 0.7.8")
  expect_match(s$notes, "edition unknown")
  row$breaks[[1L]] <- c(1, 5, 10)
  row$labels[[1L]] <- c("a", "b")
  row$n_bands <- 2L
  expect_false(mudnester_convert_row(row, "future", warn = FALSE)$complete)
})

test_that("malformed schema and rows fail with actionable errors", {
  row <- mud_fixture()[1L, , drop = FALSE]
  expect_error(mudnester_convert_row(row[setdiff(names(row), "labels")], "v"), "schema")
  for (b in list(c(0, NA, Inf), c(0, 0, Inf), c(0, 5, 4), c(-1, 0, Inf),
                 c(0, Inf, Inf), c(Inf, Inf), c(0, NaN, Inf), "bad")) {
    r <- row; r$breaks[[1L]] <- b
    expect_error(mudnester_convert_row(r, "v"), "breaks")
  }
  for (labels in list(c("same", "same"), c("", "b"), c(NA_character_, "b"), "one")) {
    r <- row; r$breaks[[1L]] <- c(0, 1, Inf); r$labels[[1L]] <- labels
    expect_error(mudnester_convert_row(r, "v"), "labels")
  }
  r <- row; r$n_bands <- 1L
  expect_error(mudnester_convert_row(r, "v"), "n_bands")
  r <- row; r$age_unit <- "months"
  expect_error(mudnester_convert_row(r, "v"), "Unsupported.*age_unit")
  r <- row; r$age_unit <- NA_character_
  expect_error(mudnester_convert_row(r, "v"), "age_unit")
  r <- row; r$focus_tags <- list(42)
  expect_error(mudnester_convert_row(r, "v"), "focus_tags")
  expect_error(mudnester_validate_schema(rbind(row, row)), "schema")
})

test_that("public boundaries handle missing dependency and unknown IDs", {
  local_mocked_bindings(mudnester_available = function() FALSE)
  expect_error(import_mudnester_scheme("abs_5yr"), "install.packages")
  expect_error(mudnester_catalogue(), "install.packages")
  expect_error(import_mudnester_scheme(NA_character_), "exact")
})

test_that("public imports are independent and edits track ancestry", {
  f <- mud_fixture()
  local_mocked_bindings(mudnester_snapshot = function() list(data = f, version = "0.7.8"))
  expect_error(import_mudnester_scheme("ABS_5yr"), "Unknown")
  expect_error(import_mudnester_scheme("mudnester_abs_5yr"), "Unknown")
  expect_warning(a <- import_mudnester_scheme("abs_5yr"), "clinical")
  b <- suppressWarnings(import_mudnester_scheme("abs_5yr"))
  names(a$groups)[1L] <- "Local label"
  expect_identical(a$derived_from$id, b$id)
  expect_identical(a$id, paste0(b$id, "_derived"))
  expect_false(a$verified)
  expect_identical(names(b$groups), f$labels[[which(f$scheme == "abs_5yr")]])
  table <- mudnester_catalogue(); table$source[1L] <- "Edited"
  expect_identical(mudnester_catalogue()$source, f$source)
  expect_identical(length(list_age_schemes()$id), 8L)
})

test_that("optional installed catalogue has exact import parity", {
  skip_if_not_installed("mudnester")
  env <- new.env(parent = emptyenv())
  utils::data("age_schemes", package = "mudnester", envir = env)
  f <- env$age_schemes
  table <- mudnester_catalogue()
  expect_identical(table$scheme, f$scheme)
  for (i in seq_len(nrow(f))) {
    s <- suppressWarnings(import_mudnester_scheme(f$scheme[i]))
    expect_identical(ivs::iv_start(s$groups), head(f$breaks[[i]], -1L))
    expect_identical(ivs::iv_end(s$groups), tail(f$breaks[[i]], -1L))
    expect_identical(names(s$groups), f$labels[[i]])
    expect_false(s$verified)
  }
})

test_that("all eight legacy schemes and numeric presets retain parity", {
  env <- new.env(parent = emptyenv())
  utils::data("age_group_presets", "age.groups", package = "agecraft", envir = env)
  expect_identical(env$age_group_presets, env$age.groups)
  ids <- list_age_schemes()$id
  keys <- c("ILI", "IMM", "Yr.5", "Yr.10", "Spec", "Annual", "School", "Covid")
  expect_length(ids, 8L)
  for (i in seq_along(ids)) {
    s <- get_age_scheme(ids[i])
    cuts <- env$age_group_presets[[keys[i]]]
    expect_identical(ivs::iv_start(s$groups), head(cuts, -1L))
    expect_identical(ivs::iv_end(s$groups), tail(cuts, -1L))
    values <- sort(unique(c(head(cuts, -1L), head(cuts, -1L) + 0.1)))
    expect_identical(as.integer(categorize_age(age(values, unit = "year"), by = s)),
                     as.integer(categorize_age(values, by = cuts)))
  }
})
