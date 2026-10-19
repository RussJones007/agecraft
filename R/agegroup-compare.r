#' Compare age groups and their coverage
#'
#' Compare all pairs of intervals or operate on their overall coverage. All
#' intervals are lower inclusive and upper exclusive; touching intervals do not
#' overlap. Both inputs must be age_group vectors with identical units (or both
#' unitless). No implicit or approximate conversion is performed.
#'
#' @param x,y Age-group vectors. y is unnecessary for operation = "width".
#' @param operation One of "crosswalk", "membership", "ordering", "age_gap",
#'   "intersection", "union", "difference", or "width".
#' @param membership "definite" requires x to be completely contained in y;
#'   "possible" requires a nonempty overlap.
#' @param keep_empty Include empty and missing pairs in a crosswalk. Empty or
#'   unknown intersections have missing bounds; the status column distinguishes
#'   "empty", "missing", and "overlap". Otherwise only overlaps are returned.
#' @param ambiguous For membership, handle an x matching multiple y groups with
#'   "allow", "warn", or "error". For ordering, applies to overlapping pairs
#'   whose order is unresolved. Missing comparisons remain NA.
#'
#' @return Crosswalk, membership, ordering and age_gap return a data frame with
#'   x_id, y_id, x_label, and y_label in input order (each x paired with every y).
#'   Crosswalks add status and an age_group intersection column. Membership adds
#'   a logical member column; ordering adds "before", "after", or "unresolved".
#'   Age gaps describe y minus x with lower and upper bounds, both exclusive,
#'   and a unit column. These are possible real-valued differences, not rounded
#'   differences between completed ages. Infinite bounds denote unbounded gaps.
#'   Set operations return age_group coverage, merging touching ranges and
#'   preserving gaps, following ivs set semantics (including missing intervals).
#'   Width returns end minus start per x, with units when present; calendar-unit
#'   widths describe age coordinates, not elapsed durations.
#'
#' @details A crosswalk retains source-group boundaries and differs from overall
#'   coverage intersection. It cannot allocate aggregate counts without finer
#'   data or assumptions. Missing evidence cannot establish membership/order.
#'   Pairwise outputs contain length(x) * length(y) rows before crosswalk filtering.
#'   Compare ages at a shared reference date; this function does not convert age
#'   at a record date to age at another date or shift calendar ages.
#' @export
#' @examples
#' a <- age_group(c(0, 18), c(18, 65), unit = "year")
#' b <- age_group(c(0, 5, 25), c(5, 25, 65), unit = "year")
#' compare_age_groups(a, b)
#' compare_age_groups(a, b, operation = "membership", membership = "possible")
#' compare_age_groups(a, operation = "width")
compare_age_groups <- function(x, y = NULL,
                               operation = c("crosswalk", "membership", "ordering", "age_gap",
                                             "intersection", "union", "difference", "width"),
                               membership = c("definite", "possible"), keep_empty = FALSE,
                               ambiguous = c("allow", "warn", "error")) {
  operation <- match.arg(operation)
  membership <- match.arg(membership)
  ambiguous <- match.arg(ambiguous)
  if (!is.age_group(x)) stop("x must be an age_group vector", call. = FALSE)
  if (!is.logical(keep_empty) || length(keep_empty) != 1L || is.na(keep_empty)) {
    stop("keep_empty must be TRUE or FALSE", call. = FALSE)
  }
  if (operation == "width") {
    width <- ivs::iv_end(x) - ivs::iv_start(x)
    if (!is.null(get_unit(x))) width <- units::set_units(width, get_unit(x), mode = "standard")
    return(width)
  }
  if (!is.age_group(y)) stop("y must be an age_group vector", call. = FALSE)
  age_group_common_unit(x, y)
  if (operation %in% c("intersection", "union", "difference")) {
    fun <- switch(operation, intersection = ivs::iv_set_intersect,
                  union = ivs::iv_set_union, difference = ivs::iv_set_difference)
    return(fun(x, y))
  }
  ix <- rep(seq_along(x), each = length(y))
  iy <- rep(seq_along(y), times = length(x))
  xs <- ivs::iv_start(x)[ix]; xe <- ivs::iv_end(x)[ix]
  ys <- ivs::iv_start(y)[iy]; ye <- ivs::iv_end(y)[iy]
  out <- data.frame(x_id = ix, y_id = iy,
                    x_label = as.character(x)[ix], y_label = as.character(y)[iy])
  missing <- is.na(xs) | is.na(xe) | is.na(ys) | is.na(ye)
  overlap <- pmax(xs, ys) < pmin(xe, ye)
  issue <- FALSE
  if (operation == "crosswalk") {
    start <- pmax(xs, ys); end <- pmin(xe, ye)
    absent <- missing | !overlap
    start[absent] <- end[absent] <- NA_real_
    out$status <- ifelse(missing, "missing", ifelse(overlap, "overlap", "empty"))
    out$intersection <- new_age_group(start, end, get_symbols(x), get_unit(x))
    if (!keep_empty) out <- out[!missing & overlap, , drop = FALSE]
  } else if (operation == "membership") {
    out$member <- if (membership == "possible") overlap else xs >= ys & xe <= ye
    out$member[missing] <- NA
    issue <- any(tabulate(ix[!is.na(out$member) & out$member], nbins = length(x)) > 1L)
  } else if (operation == "ordering") {
    out$ordering <- ifelse(missing, NA_character_,
                           ifelse(xe <= ys, "before", ifelse(xs >= ye, "after", "unresolved")))
    issue <- any(out$ordering == "unresolved", na.rm = TRUE)
  } else {
    out$lower <- ys - xe
    out$upper <- ye - xs
    out$lower_inclusive <- rep(FALSE, length(ix))
    out$upper_inclusive <- rep(FALSE, length(ix))
    out$lower_inclusive[missing] <- out$upper_inclusive[missing] <- NA
    out$unit <- rep(get_unit(x) %||% NA_character_, length(ix))
  }
  if (issue && ambiguous != "allow") {
    text <- if (operation == "membership") "Some ages match multiple groups" else "Some age orders are unresolved"
    if (ambiguous == "error") stop(text, call. = FALSE) else warning(text, call. = FALSE)
  }
  rownames(out) <- NULL
  out
}
