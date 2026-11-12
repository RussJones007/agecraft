# Run against the phase-one source at e25155c, before renaming assignments.
devtools::load_all()
g <- age_interval(c(0, 5, 18, 65), c(5, 18, 65, Inf), unit = "year")
names(g) <- c("Under 5", "5–17", "18–64", "65+")
a <- age(c(first = 0, second = 5, third = 42, missing = NA), unit = "year")
s <- age_scheme(g, "phase1", "Phase-one checkpoint")
x <- categorize_age(a, by = s)
saveRDS(list(commit = "e25155c", intervals = g, scheme = s, ages = a,
             assignments = x, labels = as.character(x), codes = as.integer(x),
             levels = levels(x), names = names(x),
             units = attr(x, "units"), matched = categorize_age(a, by = s, output = "interval"),
             memberships = classify_age_scheme(a, s), exports = sort(getNamespaceExports("agecraft"))),
        "tests/testthat/fixtures/age-class-naming/phase1.rds")
