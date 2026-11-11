# Arithmetic dispatch deliberately differs from common-type negotiation:
# only arithmetic converts the right age into the left age's unit.
#' @exportS3Method vctrs::vec_arith
vec_arith.age <- function(op, x, y, ...) UseMethod("vec_arith.age", y)

#' @export
vec_arith.age.default <- function(op, x, y, ...) {
  vctrs::stop_incompatible_op(op, x, y)
}

#' @export
vec_arith.age.age <- function(op, x, y, ...) {
  if (op != "+") vctrs::stop_incompatible_op(op, x, y)
  y <- as_age(y, unit = attr(x, "unit"))
  new_age(vctrs::vec_arith_base(op, x, y), attr(x, "unit"))
}

#' @export
vec_arith.age.numeric <- function(op, x, y, ...) {
  if (!op %in% c("+", "-") || is.object(y) || !is.null(dim(y))) {
    vctrs::stop_incompatible_op(op, x, y)
  }
  if (any(!is.na(y) & !is.finite(y))) {
    stop("Age offsets must be finite or missing", call. = FALSE)
  }
  new_age(vctrs::vec_arith_base(op, x, y), attr(x, "unit"))
}

#' @exportS3Method vctrs::vec_arith.numeric
vec_arith.numeric.age <- function(op, x, y, ...) {
  if (op != "+") vctrs::stop_incompatible_op(op, x, y)
  vec_arith.age.numeric(op, y, x, ...)
}


# Median is not routed through vec_math by vctrs.
#' @exportS3Method stats::median
median.age <- function(x, na.rm = FALSE, ...) {
  new_age(stats::median(vctrs::vec_data(x), na.rm = na.rm, ...), attr(x, "unit"))
}
