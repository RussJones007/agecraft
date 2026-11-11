#' Inspect an age scheme
#'
#' @param x,object An `age_scheme`. Inspection first validates the complete stored
#'   interval representation, including display metadata; malformed objects error
#'   without repair. This does not independently verify external provenance.
#' @param ... Additional arguments, currently unused.
#' @return `print()` invisibly returns its input. `summary()` returns a list
#'   containing identity, unit, group count, declared completeness, observed
#'   coverage, overlap flag, uncovered domain intervals, and provenance.
#'   `as.data.frame()` returns one row per group, with labels, numeric bounds,
#'   unit, and scheme identifier. Its `scheme_metadata` attribute contains the
#'   remaining scheme fields. This is an inspection format, not an automatic
#'   round-trip constructor; data-frame operations may discard the attribute.
#'   Without a domain, gaps and coverage are unspecified (NULL and NA).
#' @param row.names Optional row names for the data frame.
#' @param optional Logical, passed to [data.frame()].
#' @name age_scheme_methods
#' @examples
#' g <- age_group(c(0, 10), c(5, 20), unit = "year")
#' names(g) <- c("Young", "Older")
#' s <- age_scheme(g, "partial", "Partial coverage", domain = c(0, 20),
#'                 complete = FALSE)
#' summary(s)
#' as.data.frame(s)
NULL

#' @rdname age_scheme_methods
#' @export
print.age_scheme <- function(x, ...) {
  validate_age_scheme(x)
  cat("<age_scheme:", x$id, ">", x$name, "\n")
  cat("Type:", x$type, "| Unit:", get_unit(x$groups), "| Groups:",
      length(x$groups), "| Verified:", x$verified, "\n")
  print(x$groups)
  invisible(x)
}

#' @rdname age_scheme_methods
#' @export
summary.age_scheme <- function(object, ...) {
  validate_age_scheme(object)
  coverage <- age_scheme_coverage(object$groups, object$domain)
  c(object[setdiff(names(object), "groups")],
    list(unit = get_unit(object$groups), n_groups = length(object$groups),
         overlaps = coverage$overlaps, gaps = coverage$gaps,
         covered = coverage$covered))
}

#' @rdname age_scheme_methods
#' @export
as.data.frame.age_scheme <- function(x, row.names = NULL, optional = FALSE, ...) {
  validate_age_scheme(x)
  g <- x$groups
  out <- data.frame(scheme_id = x$id, group_index = seq_along(g),
                    label = names(g), start = ivs::iv_start(g),
                    end = ivs::iv_end(g), unit = get_unit(g),
                    row.names = row.names, optional = optional,
                    stringsAsFactors = FALSE)
  attr(out, "scheme_metadata") <- x[setdiff(names(x), "groups")]
  out
}
