#' Construct a reusable age classification scheme
#'
#' A scheme contains an existing [age_group()] vector and scheme-level metadata.
#' It does not inherit from `age_group`. All intervals are right-open `[start,end)`.
#'
#' @param groups A nonempty `age_group` vector with an explicit time unit and
#'   unique, nonblank names for every category. Missing intervals are not allowed.
#' @param id Stable machine identifier, using letters, digits, underscores or
#'   hyphens and starting with a letter.
#' @param name Nonblank human-readable title.
#' @param type `"partition"` rejects overlap; `"classification"` permits it.
#' @param domain NULL or two numeric bounds specifying the intended right-open
#'   age domain, in the groups' unit. All groups must lie within this domain.
#' @param complete Logical coverage claim: NA (unknown), TRUE (complete), or FALSE
#'   (incomplete). TRUE/FALSE require a domain and must agree with actual coverage.
#' @param purpose,organization,source,reference,version,notes Optional nonblank
#'   character scalars describing intended use and provenance. `reference` can be
#'   a URL or citation. A version is an edition or source version, not a claim of
#'   current authority.
#' @param verified Logical scalar; TRUE requires source, reference and version.
#'   This records the caller's verification claim; the constructor cannot verify
#'   an external source. Legacy built-ins are unverified.
#' @return `age_scheme()` returns a validated S3 scheme. `is_age_scheme()` returns
#'   a logical scalar. `validate_age_scheme()` invisibly returns the valid object
#'   or errors. `scheme_groups()` returns its `age_group` vector.
#' @details Scheme units must be second, minute, hour, day, week, month or year.
#'   Reconstruct and revalidate a scheme after changing its groups. Transformed
#'   intervals do not automatically retain an official source identity. A
#'   partition need not cover the entire domain; disjointness and coverage are
#'   separate properties. No registry lookup is performed by this constructor.
#' @seealso [categorize_age()], [classify_age_scheme()], [get_age_scheme()]
#' @examples
#' g <- age_group(c(0, 18, 65), c(18, 65, Inf), unit = "year")
#' names(g) <- c("Children", "Adults", "Older adults")
#' s <- age_scheme(g, "example", "Example bands", domain = c(0, Inf),
#'                 complete = TRUE)
#' s
#' scheme_groups(s)
#' summary(s)
#' @export
age_scheme <- function(groups, id, name, type = c("partition", "classification"),
                       domain = NULL, complete = NA, purpose = NULL,
                       organization = NULL, source = NULL, reference = NULL,
                       version = NULL, verified = FALSE, notes = NULL) {
  type <- match.arg(type)
  x <- structure(list(groups = groups, id = id, name = name, type = type,
                      domain = domain, complete = complete, purpose = purpose,
                      organization = organization, source = source,
                      reference = reference, version = version,
                      verified = verified, notes = notes), class = "age_scheme")
  validate_age_scheme(x)
  x
}

#' @rdname age_scheme
#' @param x An object to identify, validate, or inspect.
#' @export
is_age_scheme <- function(x) inherits(x, "age_scheme")

#' @rdname age_scheme
#' @export
scheme_groups <- function(x) {
  validate_age_scheme(x)
  x$groups
}

#' @rdname age_scheme
#' @export
validate_age_scheme <- function(x) {
  required <- c("groups", "id", "name", "type", "domain", "complete", "purpose",
                "organization", "source", "reference", "version", "verified", "notes")
  if (!is_age_scheme(x) || !is.list(x) || !identical(names(x), required)) {
    stop("x must be an age_scheme with all required fields", call. = FALSE)
  }
  for (field in c("id", "name", "type", "purpose", "organization", "source",
                  "reference", "version", "notes")) {
    value <- x[[field]]
    optional <- !field %in% c("id", "name", "type")
    if (optional && is.null(value)) next
    if (!is.character(value) || length(value) != 1L || is.na(value) ||
        !nzchar(trimws(value))) {
      stop(field, " must be a nonblank character scalar", call. = FALSE)
    }
  }
  if (!grepl("^[A-Za-z][A-Za-z0-9_-]*$", x$id)) {
    stop("id must start with a letter and contain letters, digits, _ or -", call. = FALSE)
  }
  if (!x$type %in% c("partition", "classification")) {
    stop("type must be partition or classification", call. = FALSE)
  }
  if (!is.logical(x$complete) || length(x$complete) != 1L) {
    stop("complete must be TRUE, FALSE or NA", call. = FALSE)
  }
  if (!is.logical(x$verified) || length(x$verified) != 1L || is.na(x$verified)) {
    stop("verified must be TRUE or FALSE", call. = FALSE)
  }
  if (x$verified && any(vapply(x[c("source", "reference", "version")],
                               is.null, logical(1)))) {
    stop("verified schemes require source, reference and version", call. = FALSE)
  }
  g <- x$groups
  if (!is.age_group(g) || !length(g)) {
    stop("groups must be a nonempty age_group vector", call. = FALSE)
  }
  unit <- get_unit(g)
  if (!is.character(unit) || length(unit) != 1L || is.na(unit) ||
      !unit %in% c("second", "minute", "hour", "day", "week", "month", "year")) {
    stop("groups require an explicit supported time unit", call. = FALSE)
  }
  # Recheck endpoints even for objects altered after construction.
  new_age_group(ivs::iv_start(g), ivs::iv_end(g), unit = unit)
  if (anyNA(ivs::iv_start(g)) || anyNA(ivs::iv_end(g))) {
    stop("groups cannot contain missing intervals", call. = FALSE)
  }
  labels <- names(g)
  if (is.null(labels) || length(labels) != length(g) || anyNA(labels) ||
      any(!nzchar(trimws(labels))) || anyDuplicated(labels)) {
    stop("groups require unique nonblank names", call. = FALSE)
  }
  if (!is.null(x$domain)) {
    d <- x$domain
    if (!is.numeric(d) || is.object(d) || length(d) != 2L || anyNA(d) ||
        !is.finite(d[1]) || d[1] < 0 || d[2] <= d[1]) {
      stop("domain must be two numeric bounds with 0 <= start < end", call. = FALSE)
    }
    if (any(ivs::iv_start(g) < d[1] | ivs::iv_end(g) > d[2])) {
      stop("groups must lie within domain", call. = FALSE)
    }
  } else if (!is.na(x$complete)) {
    stop("a completeness claim requires an explicit domain", call. = FALSE)
  }
  coverage <- age_scheme_coverage(g, x$domain)
  if (x$type == "partition" && coverage$overlaps) {
    stop("partition groups must not overlap", call. = FALSE)
  }
  if (!is.na(x$complete) && x$complete != coverage$covered) {
    stop("complete does not agree with domain coverage", call. = FALSE)
  }
  invisible(x)
}
