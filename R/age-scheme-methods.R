#' Inspect an age scheme
#'
#' @param x,object An `age_scheme`, or for printing a summary, the result of
#'   `summary()` on a scheme. Inspection first validates the complete stored
#'   interval representation, including display metadata; malformed objects error
#'   without repair. This does not independently verify external provenance.
#' @param ... Additional arguments, currently unused.
#' @return `print()` invisibly returns its input. `summary()` returns a list
#'   of class `summary_age_scheme`, with a readable print method,
#'   containing identity, unit, group count, declared completeness, observed
#'   coverage, overlap flag, uncovered domain intervals, and provenance.
#'   `as.data.frame()` returns one row per group, with labels, numeric bounds,
#'   unit, and scheme identifier. Its `scheme_metadata` attribute contains the
#'   remaining scheme fields. This is an inspection format, not an automatic
#'   round-trip constructor; data-frame operations may discard the attribute.
#'   Without a domain, gaps and coverage are unspecified (NULL and NA).
#'   Derivatives print their ancestor ID/version; summaries and data-frame metadata
#'   include `derived_from`. See [age_scheme()] for editing and ancestry rules.
#' @param row.names Optional row names for the data frame.
#' @param optional Logical, passed to [data.frame()].
#' @name age_scheme_methods
#' @examples
#' g <- age_interval(c(0, 10), c(5, 20), unit = "year")
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
  cat("Type:", x$type, "| Unit:", get_unit(x$intervals), "| Groups:",
      length(x$intervals), "| Verified:", x$verified, "\n")
  if (!is.null(x$derived_from)) {
    cat("Derived from:", x$derived_from$id, "| Source version:",
        x$derived_from$version %||% "unknown", "\n")
  }
  print(x$intervals)
  invisible(x)
}

#' @rdname age_scheme_methods
#' @export
summary.age_scheme <- function(object, ...) {
  coverage <- age_scheme_assess(object)
  out <- c(object[setdiff(names(object), "intervals")],
    list(unit = get_unit(object$intervals), n_groups = length(object$intervals),
         overlaps = coverage$overlaps, gaps = coverage$gaps,
         covered = coverage$covered))
  class(out) <- "summary_age_scheme"
  out
}

#' @rdname age_scheme_methods
#' @export
print.summary_age_scheme <- function(x, ...) {
  cat("<age_scheme summary:", x$id, ">", x$name, "\n")
  fields <- c("type", "unit", "n_groups", "domain", "complete", "covered",
              "overlaps", "purpose", "organization", "source", "reference",
              "version", "verified", "notes")
  for (field in fields) {
    value <- x[[field]]
    text <- if (is.null(value) || anyNA(value)) "unknown" else
      paste(value, collapse = ", ")
    cat(field, ": ", text, "\n", sep = "")
  }
  cat("Uncovered domain intervals:\n")
  if (is.null(x$gaps)) cat("unknown\n") else print(x$gaps)
  if (!is.null(x$derived_from)) {
    cat("Derived from:\n")
    print(x$derived_from)
  }
  invisible(x)
}

#' @rdname age_scheme_methods
#' @export
as.data.frame.age_scheme <- function(x, row.names = NULL, optional = FALSE, ...) {
  validate_age_scheme(x)
  g <- x$intervals
  out <- data.frame(scheme_id = x$id, group_index = seq_along(g),
                    label = names(g), start = ivs::iv_start(g),
                    end = ivs::iv_end(g), unit = get_unit(g),
                    row.names = row.names, optional = optional,
                    stringsAsFactors = FALSE)
  attr(out, "scheme_metadata") <- x[setdiff(names(x), "intervals")]
  out
}
