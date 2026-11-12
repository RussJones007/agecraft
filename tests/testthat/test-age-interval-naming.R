test_that("phase one reproduces captured classification and interval definitions", {
  old <- readRDS(test_path("fixtures", "age-class-naming", "baseline.rds"))
  # Read primitive components without dispatching methods on old class tags.
  bounds <- unclass(old$intervals)
  g <- age_interval(bounds$start, bounds$end,
                    unit = attr(old$intervals, "unit"))
  names(g) <- attr(old$intervals, "group_names")
  s <- age_scheme(intervals = g, id = "naming_baseline", name = "Naming baseline")
  x <- categorize_age(old$ages, by = s)
  expect_identical(class(g), c("age_interval", "ivs_iv", "vctrs_rcrd", "vctrs_vctr"))
  expect_false(inherits(g, "age_group"))
  expect_identical(class(x), c("age_category", "ordered", "factor"))
  expect_identical(as.character(x), old$labels)
  expect_identical(as.integer(x), old$codes)
  expect_identical(levels(x), levels(old$assignments))
  expect_identical(category_intervals(x), g)
  expect_identical(scheme_intervals(s), g)
  expect_identical(unclass(categorize_age(old$ages, by = s, output = "interval")),
                   unclass(old$matched))
  expect_identical(attr(x, "units"), attr(old$assignments, "units"))
  expect_null(attr(x, "groups", exact = TRUE))
  expect_false("groups" %in% names(s))
  expect_identical(unclass(s)[setdiff(names(s), "intervals")],
                   unclass(old$scheme)[setdiff(names(old$scheme), "groups")])
  expect_null(s$derived_from)
  expect_identical(age_interval_presets, old$presets)
  expect_identical(age_group_presets, old$presets)
  expect_identical(age.groups, old$presets)
  for (name in c("age_interval_presets", "age_group_presets", "age.groups")) {
    e <- new.env(parent = emptyenv())
    utils::data(list = name, package = "agecraft", envir = e)
    expect_identical(e[[name]], old$presets)
  }
})

test_that("phase one exposes interval names and keeps factor assignments separate", {
  exports <- getNamespaceExports("agecraft")
  expect_true(all(c("age_interval", "as_age_interval", "is_age_interval",
                    "compare_age_intervals", "scheme_intervals", "category_intervals",
                    "age_category", "is_age_category") %in% exports))
  expect_false(any(c("age_group", "as.age_group", "is.age_group", "compare_age_groups",
                     "category_groups", "scheme_groups") %in% exports))
  expect_identical(names(formals(age_scheme))[1], "intervals")
  expect_identical(names(formals(age_category))[2], "intervals")
  expect_identical(names(formals(age_cat_iv))[2], "intervals")
  expect_s3_class(age_cat_iv(age(c(0, 5)), intervals = age_interval(c(0, 5), c(5, Inf))),
                  "ordered")
  expect_s3_class(as_age_interval(c("0-4", "5+")), "age_interval")
  expect_true(is_age_interval(age_interval(0, 5)))
  expect_false(is_age_interval(age_category("0-4", age_interval(0, 5))))
})

test_that("old stored schemas require explicit reconstruction", {
  old <- readRDS(test_path("fixtures", "age-class-naming", "baseline.rds"))
  expect_false(is_age_interval(old$intervals))
  expect_error(scheme_intervals(old$scheme), "required fields")
  expect_error(category_intervals(old$assignments), "age_interval structure")
})
