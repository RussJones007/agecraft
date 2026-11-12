# Run only with agecraft 0.1.0.9020 before the class rename.
devtools::load_all()
g <- age_group(c(0, 5, 18), c(5, 18, Inf), unit = "year")
names(g) <- c("Under 5", "5–17", "18+")
a <- age(c(0, 4.9, 5, 18, NA), unit = "year")
s <- age_scheme(g, id = "naming_baseline", name = "Naming baseline")
x <- categorize_age(a, by = s)
saveRDS(list(version = "0.1.0.9020", intervals = g, assignments = x,
             scheme = s, ages = a, presets = age_group_presets,
             exports = sort(getNamespaceExports("agecraft")),
             labels = as.character(x), codes = as.integer(x),
             matched = categorize_age(a, by = s, output = "interval"),
             session = sessionInfo()),
        "tests/testthat/fixtures/age-class-naming/baseline.rds")
