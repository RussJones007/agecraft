# Run from the repository root with an installed phase-one package:
# TZ=UTC Rscript --vanilla -e '.libPaths(c("/tmp/agecraft-phase1-lib", .libPaths())); source("scripts/validation/age-class-naming/check-installed.R")'
library(agecraft)
old <- readRDS("tests/testthat/fixtures/age-class-naming/baseline.rds")
b <- unclass(old$intervals)
g <- age_interval(b$start, b$end, unit = attr(old$intervals, "unit"))
names(g) <- attr(old$intervals, "group_names")
s <- age_scheme(intervals = g, id = "naming_baseline", name = "Naming baseline")
x <- categorize_age(old$ages, by = s)
stopifnot(identical(as.character(x), old$labels), identical(as.integer(x), old$codes),
          identical(class(x), c("age_category", "ordered", "factor")),
          identical(category_intervals(x), g), identical(scheme_intervals(s), g),
          !inherits(g, "age_group"), inherits(g, "ivs_iv"),
          identical(as_age_interval(g), g),
          identical(as_age_interval(ivs::iv(0, 5)), age_interval(0, 5)),
          identical(vctrs::vec_c(g, g), c(g, g)),
          identical(ivs::iv_start(g[c(3, 1)]), c(18, 0)),
          inherits(compare_age_intervals(g, g, operation = "union"), "age_interval"))
for (nm in c("age_interval_presets", "age_group_presets", "age.groups")) {
  e <- new.env(parent = emptyenv())
  utils::data(list = nm, package = "agecraft", envir = e)
  stopifnot(identical(e[[nm]], old$presets))
}
stopifnot(nrow(list_age_schemes()) == 8L)
for (id in list_age_schemes()$id) {
  stopifnot(is_age_interval(scheme_intervals(get_age_scheme(id))))
}
exports <- getNamespaceExports("agecraft")
stopifnot(!any(c("age_group", "as.age_group", "is.age_group", "category_groups",
                "scheme_groups", "compare_age_groups") %in% exports))
writeLines(sort(exports), "scripts/validation/age-class-naming/phase1-exports.txt")
cat("Installed phase-one dispatch, baseline parity, all registry schemes, exports and data aliases passed.\n")
