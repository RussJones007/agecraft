#' Categorized ages with retained interval definitions
#'
#' Creates an age_category object which is an ordered factor whose levels map one-to-one to chronological age intervals.
#' Subsetting retains unused categories; use `droplevels()` to remove them. When combining two or more of age_category
#' vectors, they must match on the age intervals used, labels and units.
#' Convert explicitly with `generics::as.factor()` or `generics::as.ordered()` to discard interval metadata. Base
#' coercers leave existing factor subclasses unchanged. Use `vctrs::vec_rbind()` for binding: base data-frame binding
#' can discard metadata. Reordering and implicit category merging are rejected. Original exact ages and scheme
#' provenance are not stored. The legacy `units` attribute describes observations; definition units live in `groups`.
#' Differing observation units are dropped on combination; definition units must match.
#' Printing shows the class, length and category-definition unit in the header.
#' vctrs type descriptions also use the category-definition unit.
#' @param x Character category labels or a factor; missing values are allowed.
#' @param groups An `age_group` vector in chronological order, with unique labels.
#' @return `age_category()` returns an ordered-factor subclass;
#'   `is_age_category()` returns a logical scalar; `category_groups()` returns
#'   the defining `age_group` vector, including unused categories.
#' @examples
#' groups <- age_group(c(0, 5), c(5, Inf))
#' x <- age_category(c("0-4", "5+", NA), groups)
#' category_groups(x)
#' droplevels(x[1])
#' @export
age_category <- function(x = character(), groups) {
  validate_age_group(groups)
  labels <- age_group_labels(groups)
  if (anyNA(groups) || anyNA(labels) || anyDuplicated(labels) ||
      any(!nzchar(trimws(labels))) || !identical(order(groups), seq_along(groups))) {
    stop("groups must have present intervals, unique nonblank labels and chronological order", call. = FALSE)
  }
  if (!(is.character(x) || is.factor(x))) stop("x must contain category labels", call. = FALSE)
  values <- as.character(x)
  if (any(!is.na(values) & !values %in% labels)) stop("Unknown category label", call. = FALSE)
  out <- new_age_category(match(values, labels), groups, labels)
  names(out) <- names(x)
  out
}

new_age_category <- function(codes, groups, labels = age_group_labels(groups), units = NULL) {
  structure(as.integer(codes), levels = labels, groups = groups, units = units,
            class = c("age_category", "ordered", "factor"))
}

validate_age_category <- function(x) {
  g <- attr(x, "groups", exact = TRUE)
  validate_age_group(g)
  labels <- levels(x)
  codes <- unclass(x)
  if (!identical(class(x), c("age_category", "ordered", "factor")) ||
      !is.integer(codes) || !is.character(labels) ||
      length(labels) != length(g) || anyNA(g) ||
      anyNA(labels) || anyDuplicated(labels) || any(!nzchar(trimws(labels))) ||
      !identical(labels, age_group_labels(g)) ||
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
category_groups <- function(x) {
  validate_age_category(x)
  attr(x, "groups", exact = TRUE)
}

#' @export
`[.age_category` <- function(x, i, ..., drop = FALSE) {
  validate_age_category(x)
  out <- NextMethod("[", drop = FALSE)
  attr(out, "groups") <- attr(x, "groups", exact = TRUE)
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
  out <- new_age_category(match(as.integer(x), which(used)), category_groups(x)[used],
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
  g <- category_groups(x)
  attr(x, "levels") <- value
  names(g) <- value
  attr(x, "groups") <- g
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
  gx <- category_groups(x)
  gy <- category_groups(y)
  if (!identical(levels(x), levels(y)) ||
      !identical(ivs::iv_start(gx), ivs::iv_start(gy)) ||
      !identical(ivs::iv_end(gx), ivs::iv_end(gy)) ||
      !identical(attr(gx, "unit"), attr(gy, "unit"))) {
    stop("age_category definitions, labels and units must match", call. = FALSE)
  }
  if (!identical(attr(gx, "symbols"), attr(gy, "symbols"))) {
    attr(gx, "symbols") <- attr(age_group(numeric(), numeric()), "symbols")
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
  out <- new_age_category(codes, category_groups(ptype), levels(ptype), attr(ptype, "units"))
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
  out <- new_age_category(x, category_groups(to), levels(to), attr(to, "units"))
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
  unit <- attr(category_groups(x), "unit", exact = TRUE)
  if (is.null(unit)) unit <- "unspecified"
  paste0("age_category [", unit, "]")
}

#' @exportS3Method vctrs::vec_ptype_abbr
vec_ptype_abbr.age_category <- function(x, ...) {
  unit <- attr(category_groups(x), "unit", exact = TRUE)
  if (is.null(unit)) unit <- "unk"
  paste0("aCat-", unit)
}

#' @export
print.age_category <- function(x, ...) {
  validate_age_category(x)
  unit <- attr(attr(x, "groups", exact = TRUE), "unit", exact = TRUE)
  if (is.null(unit)) unit <- "unknown"
  cat(sprintf("<age_category[%d]; unit: %s>\n", length(x), unit))
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
