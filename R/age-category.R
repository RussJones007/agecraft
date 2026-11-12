#' Assign category labels to age intervals
#'
#' Create an ordered factor when you already have age-category labels and
#' their interval definitions. Each level corresponds to one defining interval.
#' To classify numerical ages instead, use [categorize_age()].
#'
#' Subsetting retains unused levels and their definitions. Use `droplevels()`
#' to remove them together, or [category_intervals()] to retrieve the definitions.
#' When combining vectors, the bounds, labels and definition units must match.
#' Unique nonblank relabeling is allowed; reordering or merging levels is not.
#'
#' Use `generics::as.factor()` or `generics::as.ordered()` to discard interval
#' metadata. Base coercers retain existing factor subclasses. For data-frame
#' binding, use `vctrs::vec_rbind()`; base binding can discard the metadata.
#' Original numerical ages and scheme provenance are not stored. The `units`
#' attribute, when present, describes the original observations; definition
#' units are available from `category_intervals()`.
#' @param x Character category labels or a factor; missing values are allowed.
#' @param intervals An `age_interval` vector in chronological order. Each
#'   interval must be present and have a unique nonblank label, supplied by
#'   its name or formatted bounds. Unused intervals are retained as levels.
#' @return `age_category()` returns an ordered-factor subclass;
#'   `is_age_category()` returns a logical scalar; `category_intervals()` returns
#'   the defining `age_interval` vector, including unused categories.
#' @examples
#' intervals <- age_interval(c(0, 5), c(5, Inf))
#' x <- age_category(c("0-4", "5+", NA), intervals)
#' category_intervals(x)
#' droplevels(x[1])
#' @export
age_category <- function(x = character(), intervals) {
  validate_age_interval(intervals)
  labels <- age_interval_labels(intervals)
  if (anyNA(intervals) || anyNA(labels) || anyDuplicated(labels) ||
      any(!nzchar(trimws(labels))) || !identical(order(intervals), seq_along(intervals))) {
    stop("intervals must have present intervals, unique nonblank labels and chronological order", call. = FALSE)
  }
  if (!(is.character(x) || is.factor(x))) stop("x must contain category labels", call. = FALSE)
  values <- as.character(x)
  if (any(!is.na(values) & !values %in% labels)) stop("Unknown category label", call. = FALSE)
  out <- new_age_category(match(values, labels), intervals, labels)
  names(out) <- names(x)
  out
}

new_age_category <- function(codes, intervals, labels = age_interval_labels(intervals), units = NULL) {
  structure(as.integer(codes), levels = labels, intervals = intervals, units = units,
            class = c("age_category", "ordered", "factor"))
}

validate_age_category <- function(x) {
  g <- attr(x, "intervals", exact = TRUE)
  validate_age_interval(g)
  labels <- levels(x)
  codes <- unclass(x)
  if (!identical(class(x), c("age_category", "ordered", "factor")) ||
      !is.integer(codes) || !is.character(labels) ||
      length(labels) != length(g) || anyNA(g) ||
      anyNA(labels) || anyDuplicated(labels) || any(!nzchar(trimws(labels))) ||
      !identical(labels, age_interval_labels(g)) ||
      !identical(order(g), seq_along(g)) ||
      any(!is.na(codes) & (codes < 1L | codes > length(labels)))) {
    stop("Invalid age_category level-to-interval mapping", call. = FALSE)
  }
  invisible(x)
}

#' @rdname age_category
#' @export
is_age_category <- function(x) inherits(x, "age_category")

#' @rdname age_category
#' @export
category_intervals <- function(x) {
  validate_age_category(x)
  attr(x, "intervals", exact = TRUE)
}

#' @export
`[.age_category` <- function(x, i, ..., drop = FALSE) {
  validate_age_category(x)
  out <- NextMethod("[", drop = FALSE)
  attr(out, "intervals") <- attr(x, "intervals", exact = TRUE)
  attr(out, "units") <- attr(x, "units", exact = TRUE)
  if (drop) out <- droplevels(out)
  out
}

#' @export
`[[.age_category` <- function(x, ...) x[..., drop = FALSE]

#' @export
droplevels.age_category <- function(x, exclude = NA, ...) {
  validate_age_category(x)
  if (!identical(exclude, NA)) {
    stop("age_category only supports exclude = NA; missing values are not categories", call. = FALSE)
  }
  used <- seq_along(levels(x)) %in% as.integer(x)
  out <- new_age_category(match(as.integer(x), which(used)), category_intervals(x)[used],
                          levels(x)[used], attr(x, "units", exact = TRUE))
  names(out) <- names(x)
  out
}

#' @export
`levels<-.age_category` <- function(x, value) {
  validate_age_category(x)
  if (!is.character(value) || length(value) != nlevels(x) || anyNA(value) ||
      anyDuplicated(value) || any(!nzchar(trimws(value))) ||
      (!identical(value, levels(x)) && setequal(value, levels(x)))) {
    stop("Use unique nonblank labels without reordering or merging categories", call. = FALSE)
  }
  g <- category_intervals(x)
  attr(x, "levels") <- value
  names(g) <- value
  attr(x, "intervals") <- g
  x
}

#' @export
as.factor.age_category <- function(x, ...) {
  validate_age_category(x)
  out <- factor(as.character(x), levels = levels(x))
  names(out) <- names(x)
  out
}

#' @export
as.ordered.age_category <- function(x, ...) {
  out <- as.factor.age_category(x)
  class(out) <- c("ordered", "factor")
  out
}

#' @export
rep.age_category <- function(x, ...) {
  idx <- rep(seq_along(x), ...)
  x[idx]
}

#' @export
`[<-.age_category` <- function(x, i, ..., value) {
  validate_age_category(x)
  if (is_age_category(value)) {
    age_category_common(x, value)
    value <- as.character(value)
  }
  if (any(!is.na(value) & !as.character(value) %in% levels(x))) {
    stop("Replacement must use existing category labels", call. = FALSE)
  }
  out <- NextMethod("[<-")
  validate_age_category(out)
  out
}

age_category_common <- function(x, y) {
  gx <- category_intervals(x)
  gy <- category_intervals(y)
  if (!identical(levels(x), levels(y)) ||
      !identical(ivs::iv_start(gx), ivs::iv_start(gy)) ||
      !identical(ivs::iv_end(gx), ivs::iv_end(gy)) ||
      !identical(attr(gx, "unit"), attr(gy, "unit"))) {
    stop("age_category definitions, labels and units must match", call. = FALSE)
  }
  if (!identical(attr(gx, "symbols"), attr(gy, "symbols"))) {
    attr(gx, "symbols") <- attr(age_interval(numeric(), numeric()), "symbols")
  }
  names(gx) <- levels(x)
  unit <- attr(x, "units", exact = TRUE)
  if (!identical(unit, attr(y, "units", exact = TRUE))) unit <- NULL
  new_age_category(integer(), gx, levels(x), unit)
}

#' @export
c.age_category <- function(..., recursive = FALSE) {
  xs <- list(...)
  if (!all(vapply(xs, is_age_category, logical(1)))) {
    stop("Convert explicitly before mixing age_category with other types", call. = FALSE)
  }
  ptype <- Reduce(age_category_common, xs)
  codes <- do.call(c, lapply(xs, function(x) {
    out <- as.integer(x)
    names(out) <- names(x)
    out
  }))
  out <- new_age_category(codes, category_intervals(ptype), levels(ptype), attr(ptype, "units"))
  names(out) <- names(codes)
  out
}

#' @exportS3Method vctrs::vec_proxy
vec_proxy.age_category <- function(x, ...) {
  out <- as.integer(x)
  names(out) <- names(x)
  out
}

#' @exportS3Method vctrs::vec_restore
vec_restore.age_category <- function(x, to, ...) {
  out <- new_age_category(x, category_intervals(to), levels(to), attr(to, "units"))
  names(out) <- names(x)
  validate_age_category(out)
  out
}

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.age_category.age_category <- function(x, y, ...) age_category_common(x, y)

#' @exportS3Method vctrs::vec_cast
vec_cast.age_category.age_category <- function(x, to, ...) {
  age_category_common(x, to)
  codes <- as.integer(x)
  names(codes) <- names(x)
  vec_restore.age_category(codes, to)
}

#' @export
`[[<-.age_category` <- function(x, i, ..., value) {
  x[i] <- value
  x
}

#' @export
Ops.age_category <- function(e1, e2) {
  if (is_age_category(e1) && is_age_category(e2)) age_category_common(e1, e2)
  else if (is.factor(e1) && is.factor(e2)) {
    stop("Convert explicitly before comparing categories with ordinary factors", call. = FALSE)
  }
  NextMethod()
}

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.age_category.factor <- function(x, y, ...) {
  stop("Convert explicitly before mixing age_category with other types", call. = FALSE)
}
#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.factor.age_category <- function(x, y, ...) vec_ptype2.age_category.factor(y, x, ...)
#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.age_category.ordered <- function(x, y, ...) vec_ptype2.age_category.factor(x, y, ...)
#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.ordered.age_category <- function(x, y, ...) vec_ptype2.age_category.factor(y, x, ...)
#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.age_category.character <- function(x, y, ...) vec_ptype2.age_category.factor(x, y, ...)
#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.character.age_category <- function(x, y, ...) vec_ptype2.age_category.factor(y, x, ...)

#' @exportS3Method vctrs::vec_ptype_full
vec_ptype_full.age_category <- function(x, ...) {
  unit <- attr(category_intervals(x), "unit", exact = TRUE)
  if (is.null(unit)) unit <- "unspecified"
  paste0("age_category [", unit, "]")
}

#' @exportS3Method vctrs::vec_ptype_abbr
vec_ptype_abbr.age_category <- function(x, ...) {
  unit <- attr(category_intervals(x), "unit", exact = TRUE)
  if (is.null(unit)) unit <- "unk"
  paste0("aCat-", unit)
}

#' @export
print.age_category <- function(x, ...) {
  validate_age_category(x)
  unit <- attr(attr(x, "intervals", exact = TRUE), "unit", exact = TRUE)
  if (is.null(unit)) unit <- "unknown"
  cat(sprintf("<age_category (%s) [%d]>\n", unit, length(x)))
  print(as.ordered.age_category(x), ...)
  invisible(x)
}

#' @exportS3Method stats::reorder
reorder.age_category <- function(x, ...) {
  stop("Category levels must remain chronological; convert to an ordinary factor for display ordering", call. = FALSE)
}

#' @exportS3Method stats::relevel
relevel.age_category <- function(x, ref, ...) {
  stop("Category levels must remain chronological; convert to an ordinary factor for display ordering", call. = FALSE)
}
