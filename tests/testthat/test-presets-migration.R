test_that("presets preserve legacy values", {
  expect_identical(age_interval_presets, age.groups)
  expect_identical(categorize_age(0:100, by = age_interval_presets$Annual),
                   categorize_age(0:100, by = age.groups$Annual))
})

test_that("migration previews code references and preserves unrelated text", {
  tool <- new.env(parent = baseenv())
  sys.source(system.file("tools", "migrate-age-groups.R", package = "agecraft", mustWork = TRUE), tool)
  f <- tempfile(fileext = ".R")
  text <- c('# age.groups comment', 'x <- age.groups$Annual; y <- agecraft::age.groups$Yr.5',
            'z <- "age.groups"; a <- x$age.groups; b <- rage::age.groups')
  writeLines(text, f)
  preview <- tool$migrate_age_interval_presets(f)
  expect_identical(readLines(f), text)
  expect_equal(sum(preview$action == "replace"), 2)
  tool$migrate_age_interval_presets(f, write = TRUE)
  expect_identical(readLines(paste0(f, ".bak")), text)
  changed <- readLines(f)
  expect_match(changed[2], 'age_interval_presets$Annual', fixed = TRUE)
  expect_identical(changed[c(1, 3)], text[c(1, 3)])
  expect_error(tool$migrate_age_interval_presets(paste0(f, ".bak"), write = FALSE), NA)
  writeLines('age.groups <- list(); x <- age.groups', f)
  expect_true(all(tool$migrate_age_interval_presets(f)$action == "local binding: review manually"))
})

test_that("migration preserves tabs, CRLF and function bindings", {
  tool <- new.env(parent = baseenv())
  sys.source(system.file("tools", "migrate-age-groups.R", package = "agecraft", mustWork = TRUE), tool)
  f <- tempfile(fileext = ".R")
  con <- file(f, "wb")
  writeBin(charToRaw("\tx <- age.groups$Annual\r\nf <- function(z) age.groups$ILI\r\n"), con)
  close(con)
  tool$migrate_age_interval_presets(f, write = TRUE)
  expect_identical(readBin(f, "raw", file.info(f)$size),
    charToRaw("\tx <- age_interval_presets$Annual\r\nf <- function(z) age_interval_presets$ILI\r\n"))
  writeLines("f <- function(age.groups) age.groups", f)
  expect_true(all(tool$migrate_age_interval_presets(f)$action == "local binding: review manually"))
})

test_that("migration handles both old preset names", {
  tool <- new.env(parent = baseenv())
  sys.source(system.file("tools", "migrate-age-groups.R", package = "agecraft", mustWork = TRUE), tool)
  f <- tempfile(fileext = ".R")
  writeLines(c("x <- age_group_presets$ILI", "y <- agecraft::age_group_presets$Annual",
               "z <- age.groups$Yr.5", '# age_group_presets', 's <- "age_group_presets"'), f)
  preview <- tool$migrate_age_interval_presets(f)
  expect_equal(sum(preview$action == "replace"), 3)
  tool$migrate_age_interval_presets(f, write = TRUE)
  expect_identical(readLines(f), c("x <- age_interval_presets$ILI",
    "y <- agecraft::age_interval_presets$Annual", "z <- age_interval_presets$Yr.5",
    '# age_group_presets', 's <- "age_group_presets"'))
  writeLines("age_group_presets <- list(); x <- age_group_presets", f)
  expect_true(all(tool$migrate_age_interval_presets(f)$action == "local binding: review manually"))
})
