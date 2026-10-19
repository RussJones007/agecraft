test_that("presets preserve legacy values", {
  expect_identical(age_group_presets, age.groups)
  expect_identical(categorize_age(0:100, by = age_group_presets$Annual),
                   categorize_age(0:100, by = age.groups$Annual))
})

test_that("migration previews code references and preserves unrelated text", {
  tool <- new.env(parent = baseenv())
  sys.source(testthat::test_path("..", "..", "inst", "tools", "migrate-age-groups.R"), tool)
  f <- tempfile(fileext = ".R")
  text <- c('# age.groups comment', 'x <- age.groups$Annual; y <- agecraft::age.groups$Yr.5',
            'z <- "age.groups"; a <- x$age.groups; b <- rage::age.groups')
  writeLines(text, f)
  preview <- tool$migrate_age_group_presets(f)
  expect_identical(readLines(f), text)
  expect_equal(sum(preview$action == "replace"), 2)
  tool$migrate_age_group_presets(f, write = TRUE)
  expect_identical(readLines(paste0(f, ".bak")), text)
  changed <- readLines(f)
  expect_match(changed[2], 'age_group_presets$Annual', fixed = TRUE)
  expect_identical(changed[c(1, 3)], text[c(1, 3)])
  expect_error(tool$migrate_age_group_presets(paste0(f, ".bak"), write = FALSE), NA)
  writeLines('age.groups <- list(); x <- age.groups', f)
  expect_true(all(tool$migrate_age_group_presets(f)$action == "local binding: review manually"))
})
