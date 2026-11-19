# Separate class-order experiment: do vctrs constructors restore inherited results?
# Run in a fresh process. No prototype methods are installed by this script.
devtools::load_all(quiet = TRUE)
library(vctrs)
library(units)
trial_values <- function(x) {
  out <- unclass(x)
  attributes(out) <- attributes(out)["names"]
  out
}
trial_new <- function(x = double(), unit = "year", order = "units_first") {
  unit <- agecraft:::validate_age_unit(unit)
  if (any(!is.na(x) & (!is.finite(x) | x < 0))) stop("Invalid age")
  valid <- units::set_units(as.double(x), unit, mode = "standard")
  # new_vctr supplies vctrs_vctr. Units-first uses its standard class ordering.
  out <- vctrs::new_vctr(trial_values(valid), units = units(valid), unit = unit,
    order = order, class = c("trial_age", "units"), inherit_base_type = TRUE)
  names(out) <- names(x)
  if (order == "vctrs_first") {
    class(out) <- c("trial_age", "vctrs_vctr", "units", "double")
  }
  out
}
vec_proxy.trial_age <- function(x, ...) trial_values(x)
vec_restore.trial_age <- function(x, to, ...) {
  trial_new(trial_values(x), attr(to, "unit"), attr(to, "order"))
}
vec_ptype2.trial_age.trial_age <- function(x, y, ...) {
  stopifnot(identical(attr(x, "unit"), attr(y, "unit")))
  trial_new(unit = attr(x, "unit"), order = attr(x, "order"))
}
vec_cast.trial_age.trial_age <- function(x, to, ...) {
  stopifnot(identical(attr(x, "unit"), attr(to, "unit")))
  vec_restore.trial_age(x, to)
}
# Explicit registration makes results independent of attached environment lookup.
for (g in c("vec_proxy", "vec_restore")) {
  registerS3method(g, "trial_age", get(paste0(g, ".trial_age")), asNamespace("vctrs"))
}
for (g in c("vec_ptype2", "vec_cast")) {
  registerS3method(g, "trial_age.trial_age", get(paste0(g, ".trial_age.trial_age")), asNamespace("vctrs"))
}
rows <- list()
for (order in c("units_first", "vctrs_first")) {
  x <- trial_new(c(a = 1, b = NA), "year", order)
  probes <- list(slice = function() x[1], vec_slice = function() vctrs::vec_slice(x, 1),
    concat = function() c(x, x), vec_c = function() vctrs::vec_c(x, x),
    rep = function() rep(x, 2), unique = function() unique(x),
    data_frame = function() as.data.frame(x)$x, list_element = function() as.list(x)[[1]],
    conversion = function() units::set_units(x, "day", mode = "standard"),
    replacement = function() { units(x) <- "month"; x },
    mixed_add = function() x + units::as_units("month"),
    numeric_offset = function() x + 1)
  for (op in names(probes)) {
    warnings <- character()
    out <- tryCatch(withCallingHandlers(probes[[op]](), warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning")
    }), error = function(e) e)
    rows[[length(rows) + 1L]] <- data.frame(order, operation = op,
      class = paste(class(out), collapse = "/"),
      retained = inherits(out, "trial_age"),
      value = if (inherits(out, "error")) conditionMessage(out) else
        paste(utils::head(trial_values(out), 3), collapse = ","),
      warnings = paste(warnings, collapse = " | "))
  }
}
write.csv(do.call(rbind, rows), "experiments/units-inheritance/results/hybrid-audit.csv", row.names = FALSE)
print(do.call(rbind, rows), row.names = FALSE)
# Concrete benefit checks, separate from the production-shaped prototype.
results <- do.call(rbind, rows)
core <- c("slice", "vec_slice", "concat", "vec_c", "rep", "unique", "data_frame", "list_element")
stopifnot(all(results$retained[results$order == "vctrs_first" & results$operation %in% core]))
stopifnot(sum(results$retained[results$order == "units_first" & results$operation %in% core]) == 3L)
stopifnot(!any(results$retained[results$operation %in% c("conversion", "replacement")]))
