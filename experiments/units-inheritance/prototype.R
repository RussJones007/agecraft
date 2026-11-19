# Session-only prototype. Source after devtools::load_all() in a fresh R process.
# No package namespace, export, production source, or installed file is changed.
# S3 registrations last only for this process; do not source in a work session.
p_unit <- function(x) agecraft:::age_units_unit(x)
p_values <- function(x) {
  out <- unclass(x)
  attributes(out) <- attributes(out)["names"]
  out
}
p_age <- function(x = double(), unit = "year") {
  if (is.object(x) || !is.null(dim(x)) || !is.numeric(x)) {
    stop("x must be a plain numeric vector")
  }
  unit <- agecraft:::validate_age_unit(unit)
  if (any(!is.na(x) & (!is.finite(x) | x < 0))) {
    stop("Ages must be nonnegative and finite, or missing")
  }
  out <- units::set_units(as.double(x), unit, mode = "standard")
  names(out) <- names(x)
  if (isTRUE(getOption("agecraft.units_experiment.hybrid"))) {
    out <- vctrs::new_vctr(p_values(out), units = units(out),
      class = c("age", "units"), inherit_base_type = TRUE)
    class(out) <- c("age", "vctrs_vctr", "units", "double")
    names(out) <- names(x)
  } else {
    class(out) <- c("age", class(out))
  }
  # Existing agecraft code reads this metadata; units remains authoritative.
  attr(out, "unit") <- unit
  out
}
p_bare_units <- function(x) {
  class(x) <- "units"
  attr(x, "unit") <- NULL
  x
}
p_as_age <- function(x, unit = NULL, allow_approx = FALSE, ...) {
  if (!is.logical(allow_approx) || length(allow_approx) != 1L ||
      is.na(allow_approx)) stop("allow_approx must be TRUE or FALSE")
  source <- p_unit(x)
  target <- if (is.null(unit)) source else agecraft:::validate_age_unit(unit)
  if (agecraft:::age_cat_iv_is_approx_conversion(source, target) &&
      !allow_approx) stop("Age unit conversion is approximate; set allow_approx = TRUE")
  converted <- units::set_units(p_bare_units(x), target, mode = "standard")
  p_age(stats::setNames(as.numeric(converted), names(x)), target)
}
p_common <- function(x, y) {
  if (!identical(p_unit(x), p_unit(y))) stop("Ages have incompatible units")
  p_unit(x)
}
p_restore <- function(x, to, ...) p_age(p_values(x), p_unit(to))
p_proxy <- function(x, ...) p_values(x)
p_ptype <- function(x, y, ...) p_age(unit = p_common(x, y))
p_cast <- function(x, to, ...) p_age(p_values(x), p_common(x, to))
p_cast_double <- function(x, to, ...) p_values(x)
p_reject_cast <- function(x, to, ...) stop("Convert explicitly with as_age()")
p_set_units <- function(x, value, ..., mode = units::units_options("set_units_mode")) {
  if (missing(value)) stop("An age must retain a supported time unit")
  if (mode == "symbols") {
    expr <- substitute(value)
    value <- if (is.character(expr)) expr else deparse(expr)
  }
  if (inherits(value, "symbolic_units")) {
    value <- units::deparse_unit(units::set_units(1, value, mode = "standard"))
  }
  p_as_age(x, value)
}
p_units_replace <- function(x, value) {
  if (is.null(value)) stop("An age must retain a supported time unit")
  # Reject scaled quantities; replacement accepts a unit expression only.
  if (inherits(value, "units")) {
    if (!identical(as.numeric(value), 1)) stop("Scaled unit replacement is unsupported")
    value <- units::deparse_unit(value)
  }
  if (inherits(value, "symbolic_units")) {
    value <- units::deparse_unit(units::set_units(1, value, mode = "standard"))
  }
  p_as_age(x, value)
}
p_ops <- function(e1, e2) {
  if (missing(e2)) stop("Unary operation unsupported in minimal prototype")
  a <- inherits(e1, "age")
  b <- inherits(e2, "age")
  op <- .Generic
  if (op %in% c("==", "!=", "<", "<=", ">", ">=")) {
    if (!a || !b) stop("Comparisons require ages")
    p_common(e1, e2)
    return(unname(do.call(op, vctrs::vec_recycle_common(p_values(e1), p_values(e2)))))
  }
  if (!op %in% c("+", "-") || (!a && op == "-") || (b && op == "-")) {
    stop("Operation unsupported for ages")
  }
  if (!a) { tmp <- e1; e1 <- e2; e2 <- tmp; b <- FALSE }
  unit <- p_unit(e1)
  if (b) e2 <- p_values(p_as_age(e2, unit))
  if (is.object(e2) || !is.numeric(e2) || !is.null(dim(e2)) ||
      any(!is.na(e2) & !is.finite(e2))) stop("Invalid numeric offset")
  args <- vctrs::vec_recycle_common(p_values(e1), e2)
  p_age(do.call(op, args), unit)
}
p_subset <- function(x, ...) p_age(p_values(x)[...], p_unit(x))
p_subset2 <- function(x, ...) p_age(p_values(x)[[...]], p_unit(x))
p_replace <- function(x, ..., value) {
  p_common(x, value)
  out <- p_values(x)
  out[...] <- p_values(value)
  p_age(out, p_unit(x))
}
p_concat <- function(..., recursive = FALSE) vctrs::vec_c(...)
p_format <- function(x, ..., fractional = FALSE) {
  values <- p_values(x)
  if (!fractional) values <- floor(values)
  out <- format(values, trim = TRUE, ...)
  out[is.na(values)] <- NA_character_
  names(out) <- names(x)
  out
}
p_print <- function(x, ...) {
  cat("<age [", p_unit(x), "][", length(x), "]>\n", sep = "")
  print(p_format(x), quote = FALSE)
  invisible(x)
}
p_math <- function(x, ...) {
  if (!.Generic %in% c("abs", "signif", "round", "floor", "ceiling", "trunc")) {
    stop("Operation unsupported for ages")
  }
  p_age(do.call(.Generic, c(list(p_values(x)), list(...))), p_unit(x))
}
p_summary <- function(..., na.rm = FALSE) {
  if (!.Generic %in% c("min", "max", "range")) stop("Operation unsupported for ages")
  x <- vctrs::vec_c(...)
  p_age(do.call(.Generic, list(p_values(x), na.rm = na.rm)), p_unit(x))
}
p_mean <- function(x, ...) p_age(mean(p_values(x), ...), p_unit(x))
p_median <- function(x, ...) p_age(stats::median(p_values(x), ...), p_unit(x))
p_register <- function() {
  methods <- list(Ops = p_ops, Math = p_math, Summary = p_summary,
    mean = p_mean, median = p_median, format = p_format, print = p_print,
    `[` = p_subset, `[[` = p_subset2, `[<-` = p_replace, `[[<-` = p_replace,
    c = p_concat,
    rep = function(x, ...) p_age(rep(p_values(x), ...), p_unit(x)),
    unique = function(x, ...) p_age(unique(p_values(x), ...), p_unit(x)),
    diff = function(x, ...) stop("Operation unsupported for ages"),
    drop_units = function(x) unname(p_values(x)),
    as.double = function(x, ...) unname(p_values(x)),
    as.integer = function(x, ...) as.integer(p_values(x)),
    `units<-` = p_units_replace, set_units = p_set_units,
    as_age = p_as_age, vec_proxy = p_proxy, vec_proxy_equal = p_proxy,
    vec_proxy_compare = p_proxy, vec_restore = p_restore)
  if (isTRUE(getOption("agecraft.units_experiment.hybrid"))) {
    methods[c("[", "[[", "[<-", "[[<-", "c", "rep", "unique")] <- NULL
  }
  for (generic in names(methods)) {
    ns <- if (generic %in% c("set_units", "units<-", "drop_units")) asNamespace("units") else
      if (generic == "as_age") asNamespace("agecraft") else
      if (startsWith(generic, "vec_")) asNamespace("vctrs") else
      if (generic == "median") asNamespace("stats") else baseenv()
    registerS3method(generic, "age", methods[[generic]], envir = ns)
  }
  for (generic in c("vec_ptype2", "vec_cast")) {
    registerS3method(generic, "age.age", if (generic == "vec_cast") p_cast else p_ptype,
                     envir = asNamespace("vctrs"))
    for (pair in c("age.units", "units.age", "age.double", "double.age",
                   "age.integer", "integer.age")) {
      fun <- if (generic == "vec_cast" && pair == "double.age") p_cast_double else p_reject_cast
      registerS3method(generic, pair, fun, envir = asNamespace("vctrs"))
    }
  }
}
p_register()
registerS3method("as_age", "units", p_as_age, envir = asNamespace("agecraft"))
registerS3method("as_age", "numeric", function(x, unit = NULL, allow_approx = FALSE, ...) {
  p_age(x, if (is.null(unit)) "year" else unit)
}, envir = asNamespace("agecraft"))
