# Check whether the mixed operator-dispatch issue predates the prototype.
devtools::load_all(quiet = TRUE)
sink("experiments/units-inheritance/results/baseline-mixed-ops.txt")
x <- agecraft::age(1, "year")
y <- units::as_units("month")
for (expr in c("x + y", "y + x", "as.data.frame(x)", "as.list(x)")) {
  cat(expr, "\n")
  tryCatch(withCallingHandlers(dput(eval(parse(text = expr))),
    warning = function(w) {
      cat("WARNING:", conditionMessage(w), "\n")
      invokeRestart("muffleWarning")
    }), error = function(e) cat("ERROR:", conditionMessage(e), "\n"))
}
sink()
