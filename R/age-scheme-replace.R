# Ephemeral comparison key: labels and order are definition content, while display
# symbols and unrelated attributes are cosmetic. No snapshot is stored.
age_scheme_definition <- function(x) {
  g <- x$intervals
  validate_age_interval(g)
  list(start = unname(ivs::iv_start(g)), end = unname(ivs::iv_end(g)),
       unit = get_unit(g), labels = unname(names(g)), type = unname(x$type),
       domain = if (is.null(x$domain)) NULL else as.double(x$domain),
       complete = unname(x$complete))
}

# All public replacement forms commit one fully validated candidate. Raw list
# writes avoid recursive dispatch and preserve NULL-valued schema fields.
age_scheme_update <- function(x, fields, values) {
  validate_age_scheme(x)
  editable <- setdiff(names(x), "derived_from")
  if (anyNA(fields) || any(!fields %in% editable) || anyDuplicated(fields)) {
    stop("Replace known scheme fields exactly once; derived_from is protected", call. = FALSE)
  }
  before <- unclass(x)
  candidate <- before
  candidate[fields] <- values
  if (identical(candidate, before)) return(x)
  if (!"derived_from" %in% names(candidate)) candidate["derived_from"] <- list(NULL)
  substantive <- !identical(age_scheme_definition(before), age_scheme_definition(candidate))
  identity_fields <- c("id", "version", "source", "organization", "reference")
  source_changed <- !identical(before[identity_fields], candidate[identity_fields])
  if (substantive || source_changed) {
    if (is.null(candidate$derived_from)) {
      candidate["derived_from"] <- list(before[identity_fields])
      if (!"id" %in% fields || identical(candidate$id, before$id)) {
        candidate$id <- paste0(before$id, "_derived")
      }
    }
    candidate$verified <- FALSE
    # The ancestor's edition does not describe a changed definition. An explicit
    # replacement version is a caller-supplied local/source claim, not inferred.
    if (!"version" %in% fields) candidate["version"] <- list(NULL)
  }
  class(candidate) <- class(x)
  validate_age_scheme(candidate)
  candidate
}

#' @rdname age_scheme
#' @param value Replacement value; use a list of values for batch `[` replacement.
#' @export
`$<-.age_scheme` <- function(x, name, value) {
  age_scheme_update(x, name, list(value))
}

#' @rdname age_scheme
#' @param ... For `[[<-`, one exact field name or positive field position.
#'   Recursive indices and multidimensional replacement are not supported.
#' @export
`[[<-.age_scheme` <- function(x, ..., value) {
  indices <- list(...)
  if (length(indices) != 1L || length(indices[[1]]) != 1L || is.list(indices[[1]])) {
    stop("Use one exact scheme field; recursive [[<- indices are not supported", call. = FALSE)
  }
  index <- indices[[1]]
  if (is.numeric(index)) {
    if (is.na(index) || !is.finite(index) || index != trunc(index) || index < 1 || index > length(x)) {
      stop("Invalid scheme field position", call. = FALSE)
    }
    index <- names(x)[index]
  }
  if (!is.character(index)) stop("Use an exact field name or position", call. = FALSE)
  age_scheme_update(x, index, list(value))
}

#' @rdname age_scheme
#' @param i Fields to replace, using exact names, numeric positions or logical indices.
#' @export
`[<-.age_scheme` <- function(x, i, ..., value) {
  if (length(list(...))) stop("Scheme replacement has one field dimension", call. = FALSE)
  positions <- stats::setNames(seq_along(x), names(x))
  if (!missing(i)) {
    if (!(is.character(i) || is.numeric(i) || is.logical(i)) ||
        (is.numeric(i) && any(!is.finite(i) | i != trunc(i)))) {
      stop("Invalid scheme field indices", call. = FALSE)
    }
    positions <- positions[i]
  }
  if (anyNA(positions)) stop("Unknown or missing scheme field indices", call. = FALSE)
  fields <- names(x)[unname(positions)]
  if (is_age_interval(value) || is_age_scheme(value)) {
    stop("Use a list of replacement values, such as list(new_groups)", call. = FALSE)
  }
  values <- if (is.null(value)) rep(list(NULL), length(fields)) else as.list(value)
  if (length(values) != length(fields)) {
    stop("Supply one replacement value per selected scheme field", call. = FALSE)
  }
  age_scheme_update(x, fields, values)
}
