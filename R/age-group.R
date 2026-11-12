#' Create age groups with interval definitions
#'
#' Create an ordered factor when you already have age-category labels and
#' their interval definitions. Each level corresponds to one defining interval.
#' To classify numerical ages instead, use [categorize_age()].
#'
#' Subsetting retains unused levels and their definitions. Use `droplevels()`
#' to remove them together, or [group_intervals()] to retrieve the definitions.
#' When combining vectors, the bounds, labels and definition units must match.
#' Unique nonblank relabeling is allowed; reordering or merging levels is not.
#'
#' Use `generics::as.factor()` or `generics::as.ordered()` to discard interval
#' metadata. Base coercers retain existing factor subclasses. For data-frame
#' binding, use `vctrs::vec_rbind()`; base binding can discard the metadata.
#' Original numerical ages and scheme provenance are not stored. The `units`
#' attribute, when present, describes the original observations; definition
#' units are available from `group_intervals()`.
#' @param x Character category labels or a factor; missing values are allowed.
#' @param intervals An `age_interval` vector in chronological order. Each
#'   interval must be present and have a unique nonblank label, supplied by
#'   its name or formatted bounds. Unused intervals are retained as levels.
#' @return `age_group()` returns an ordered-factor subclass with the same
#'   length and observation names as `x`;
#'   `is_age_group()` returns a logical scalar; `group_intervals()` returns
#'   the defining `age_interval` vector, including unused categories.
#' @section Saved objects:
#' Earlier development versions used the class name `age_group` for interval
#' records. Reconstruct those ranges with [age_interval()] before using them.
#' They are not categorical assignments: `is_age_group()` returns `FALSE`,
#' and group methods reject them with migration guidance.
#' @examples
#' intervals <- age_interval(c(0, 5), c(5, Inf))
#' x <- age_group(c("0-4", "5+", NA), intervals)
#' group_intervals(x)
#' droplevels(x[1])
#' @export
age_group <- function(x = character(), intervals) {
  reject_legacy_age_group(x)
  validate_age_interval(intervals)
  labels <- age_interval_labels(intervals)
  if (anyNA(intervals) || anyNA(labels) || anyDuplicated(labels) ||
      any(!nzchar(trimws(labels))) || !identical(order(intervals), seq_along(intervals))) {
    stop("intervals must have present intervals, unique nonblank labels and chronological order", call. = FALSE)
  }
  if (!(is.character(x) || is.factor(x))) stop("x must contain category labels", call. = FALSE)
  values <- as.character(x)
  if (any(!is.na(values) & !values %in% labels)) stop("Unknown category label", call. = FALSE)
  out <- new_age_group(match(values, labels), intervals, labels)
  names(out) <- names(x)
  out
}

new_age_group <- function(codes, intervals, labels = age_interval_labels(intervals), units = NULL) {
  structure(as.integer(codes), levels = labels, intervals = intervals, units = units,
            class = c("age_group", "ordered", "factor"))
}

validate_age_group <- function(x) {
  reject_legacy_age_group(x)
  g <- attr(x, "intervals", exact = TRUE)
  validate_age_interval(g)
  labels <- levels(x)
  codes <- unclass(x)
  if (!identical(class(x), c("age_group", "ordered", "factor")) ||
      !is.integer(codes) || !is.character(labels) ||
      length(labels) != length(g) || anyNA(g) ||
      anyNA(labels) || anyDuplicated(labels) || any(!nzchar(trimws(labels))) ||
      !identical(labels, age_interval_labels(g)) ||
      !identical(order(g), seq_along(g)) ||
      any(!is.na(codes) & (codes < 1L | codes > length(labels)))) {
    stop("Invalid age_group level-to-interval mapping", call. = FALSE)
  }
  invisible(x)
}

# Reject the pre-refactor interval representation before factor dispatch.
reject_legacy_age_group <- function(x) {
  if (inherits(x, "age_group") && inherits(x, "ivs_iv")) {
    stop(paste("Legacy age_group interval object: rebuild it with age_interval()",
               "using the original bounds, units and names before use.",
               "age_group now represents categorical assignments."), call. = FALSE)
  }
  invisible(NULL)
}

#' @rdname age_group
#' @export
is_age_group <- function(x) {
  inherits(x, "age_group") && typeof(x) == "integer" && is.ordered(x) &&
    !inherits(x, "ivs_iv")
}

#' @rdname age_group
#' @export
group_intervals <- function(x) {
  validate_age_group(x)
  attr(x, "intervals", exact = TRUE)
}

#' @export
`[.age_group` <- function(x, i, ..., drop = FALSE) {
  validate_age_group(x)
  out <- NextMethod("[", drop = FALSE)
  attr(out, "intervals") <- attr(x, "intervals", exact = TRUE)
  attr(out, "units") <- attr(x, "units", exact = TRUE)
  if (drop) out <- droplevels(out)
  out
}

#' @export
`[[.age_group` <- function(x, ...) x[..., drop = FALSE]

#' @export
droplevels.age_group <- function(x, exclude = NA, ...) {
  validate_age_group(x)
  if (!identical(exclude, NA)) {
    stop("age_group only supports exclude = NA; missing values are not categories", call. = FALSE)
  }
  used <- seq_along(levels(x)) %in% as.integer(x)
  out <- new_age_group(match(as.integer(x), which(used)), group_intervals(x)[used],
                          levels(x)[used], attr(x, "units", exact = TRUE))
  names(out) <- names(x)
  out
}

#' @export
`levels<-.age_group` <- function(x, value) {
  validate_age_group(x)
  if (!is.character(value) || length(value) != nlevels(x) || anyNA(value) ||
      anyDuplicated(value) || any(!nzchar(trimws(value))) ||
      (!identical(value, levels(x)) && setequal(value, levels(x)))) {
    stop("Use unique nonblank labels without reordering or merging categories", call. = FALSE)
  }
  g <- group_intervals(x)
  attr(x, "levels") <- value
  names(g) <- value
  attr(x, "intervals") <- g
  x
}

#' @export
as.factor.age_group <- function(x, ...) {
  validate_age_group(x)
  out <- factor(as.character(x), levels = levels(x))
  names(out) <- names(x)
  out
}

#' @export
as.ordered.age_group <- function(x, ...) {
  out <- as.factor.age_group(x)
  class(out) <- c("ordered", "factor")
  out
}

#' @export
rep.age_group <- function(x, ...) {
  validate_age_group(x)
  idx <- rep(seq_along(x), ...)
  x[idx]
}

#' @export
`[<-.age_group` <- function(x, i, ..., value) {
  validate_age_group(x)
  if (is_age_group(value)) {
    age_group_common(x, value)
    value <- as.character(value)
  }
  if (any(!is.na(value) & !as.character(value) %in% levels(x))) {
    stop("Replacement must use existing category labels", call. = FALSE)
  }
  out <- NextMethod("[<-")
  validate_age_group(out)
  out
}

age_group_common <- function(x, y) {
  gx <- group_intervals(x)
  gy <- group_intervals(y)
  if (!identical(levels(x), levels(y)) ||
      !identical(ivs::iv_start(gx), ivs::iv_start(gy)) ||
      !identical(ivs::iv_end(gx), ivs::iv_end(gy)) ||
      !identical(attr(gx, "unit"), attr(gy, "unit"))) {
    stop("age_group definitions, labels and units must match", call. = FALSE)
  }
  if (!identical(attr(gx, "symbols"), attr(gy, "symbols"))) {
    attr(gx, "symbols") <- attr(age_interval(numeric(), numeric()), "symbols")
  }
  names(gx) <- levels(x)
  unit <- attr(x, "units", exact = TRUE)
  if (!identical(unit, attr(y, "units", exact = TRUE))) unit <- NULL
  new_age_group(integer(), gx, levels(x), unit)
}

#' @export
c.age_group <- function(..., recursive = FALSE) {
  xs <- list(...)
  invisible(lapply(xs, reject_legacy_age_group))
  if (!all(vapply(xs, is_age_group, logical(1)))) {
    stop("Convert explicitly before mixing age_group with other types", call. = FALSE)
  }
  ptype <- Reduce(age_group_common, xs)
  codes <- do.call(c, lapply(xs, function(x) {
    out <- as.integer(x)
    names(out) <- names(x)
    out
  }))
  out <- new_age_group(codes, group_intervals(ptype), levels(ptype), attr(ptype, "units"))
  names(out) <- names(codes)
  out
}

#' @exportS3Method vctrs::vec_proxy
vec_proxy.age_group <- function(x, ...) {
  validate_age_group(x)
  out <- as.integer(x)
  names(out) <- names(x)
  out
}

#' @exportS3Method vctrs::vec_restore
vec_restore.age_group <- function(x, to, ...) {
  reject_legacy_age_group(x)
  out <- new_age_group(x, group_intervals(to), levels(to), attr(to, "units"))
  names(out) <- names(x)
  validate_age_group(out)
  out
}

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.age_group.age_group <- function(x, y, ...) age_group_common(x, y)

#' @exportS3Method vctrs::vec_cast
vec_cast.age_group.age_group <- function(x, to, ...) {
  age_group_common(x, to)
  codes <- as.integer(x)
  names(codes) <- names(x)
  vec_restore.age_group(codes, to)
}

#' @export
`[[<-.age_group` <- function(x, i, ..., value) {
  x[i] <- value
  x
}

#' @export
Ops.age_group <- function(e1, e2) {
  reject_legacy_age_group(e1)
  if (!missing(e2)) reject_legacy_age_group(e2)
  if (is_age_group(e1) && is_age_group(e2)) age_group_common(e1, e2)
  else if (is.factor(e1) && is.factor(e2)) {
    stop("Convert explicitly before comparing categories with ordinary factors", call. = FALSE)
  }
  NextMethod()
}

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.age_group.factor <- function(x, y, ...) {
  reject_legacy_age_group(x)
  stop("Convert explicitly before mixing age_group with other types", call. = FALSE)
}
#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.factor.age_group <- function(x, y, ...) vec_ptype2.age_group.factor(y, x, ...)
#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.age_group.ordered <- function(x, y, ...) vec_ptype2.age_group.factor(x, y, ...)
#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.ordered.age_group <- function(x, y, ...) vec_ptype2.age_group.factor(y, x, ...)
#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.age_group.character <- function(x, y, ...) vec_ptype2.age_group.factor(x, y, ...)
#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.character.age_group <- function(x, y, ...) vec_ptype2.age_group.factor(y, x, ...)

#' @exportS3Method vctrs::vec_ptype_full
vec_ptype_full.age_group <- function(x, ...) {
  unit <- attr(group_intervals(x), "unit", exact = TRUE)
  if (is.null(unit)) unit <- "unspecified"
  paste0("age_group [", unit, "]")
}

#' @exportS3Method vctrs::vec_ptype_abbr
vec_ptype_abbr.age_group <- function(x, ...) {
  unit <- attr(group_intervals(x), "unit", exact = TRUE)
  if (is.null(unit)) unit <- "unk"
  paste0("aGrp-", unit)
}

#' @export
print.age_group <- function(x, ...) {
  validate_age_group(x)
  unit <- attr(attr(x, "intervals", exact = TRUE), "unit", exact = TRUE)
  if (is.null(unit)) unit <- "unknown"
  cat(sprintf("<age_group (%s) [%d]>\n", unit, length(x)))
  print(as.ordered.age_group(x), ...)
  invisible(x)
}

#' @exportS3Method stats::reorder
reorder.age_group <- function(x, ...) {
  validate_age_group(x)
  stop("Category levels must remain chronological; convert to an ordinary factor for display ordering", call. = FALSE)
}

#' @exportS3Method stats::relevel
relevel.age_group <- function(x, ref, ...) {
  validate_age_group(x)
  stop("Category levels must remain chronological; convert to an ordinary factor for display ordering", call. = FALSE)
}

# Forward valid assignments to ordinary factor methods; never interpret an old
# interval record as factor codes through inherited coercion/formatting paths.
#' @export
as.character.age_group <- function(x, ...) {
  validate_age_group(x)
  NextMethod("as.character")
}

#' @export
as.integer.age_group <- function(x, ...) {
  validate_age_group(x)
  NextMethod("as.integer")
}

#' @export
format.age_group <- function(x, ...) {
  validate_age_group(x)
  NextMethod("format")
}

#' @exportS3Method vctrs::vec_ptype
vec_ptype.age_group <- function(x, ...) {
  validate_age_group(x)
  x[0]
}
