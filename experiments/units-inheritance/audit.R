# Record installed methods and unguarded inheritance before prototype registration.
devtools::load_all(quiet = TRUE)
library(units)
library(vctrs)
root <- "experiments/units-inheritance/results"
sink(file.path(root, "installed-api-audit.txt"))
print(sessionInfo())
x <- units::set_units(c(a = 1, b = NA), "year", mode = "standard")
dput(x)
cat("storage:", typeof(x), "\n")
for (n in c("set_units.units", "units<-.units", "Ops.units", "[.units",
            "[<-.units", "c.units", "Math.units", "Summary.units",
            "restore_units", "vec_restore.units", "vec_proxy.units",
            "vec_ptype2.units.units", "vec_cast.units.units")) {
  cat("\n", n, "\n")
  print(get0(n, asNamespace("units")))
}
for (topic in c("units", "set_units")) {
  print(tools::Rd2txt(utils:::.getHelpFile(help(topic, package = "units"))))
}
raw <- x
class(raw) <- c("age", "units")
attr(raw, "unit") <- "year"
probe <- function(label, expr) {
  cat("\nPROBE:", label, "\n")
  tryCatch({out <- force(expr); dput(out)}, error = function(e) cat("ERROR:", conditionMessage(e), "\n"))
}
probe("raw set_units year to day without consent", units::set_units(raw, "day", mode = "standard"))
probe("raw replacement year to month without consent", { y <- raw; units(y) <- "month"; y })
probe("raw multiplication creates squared units", raw * raw)
probe("raw subtraction produces negative age", raw - units::set_units(2, "year", mode = "standard"))
probe("raw comparison silently converts calendar units", raw == units::set_units(12, "month", mode = "standard"))
probe("raw vctrs slice", vctrs::vec_slice(raw, 1))
probe("raw numeric offset", raw + 1)
cat("\nUDUNITS definitions\n")
print(sapply(c("month", "year"), function(u) as.numeric(units::set_units(units::set_units(1, u, mode = "standard"), "day", mode = "standard"))))
sink()
