#' Construct a reusable age classification scheme
#'
#' A scheme contains an existing [age_group()] vector and scheme-level metadata.
#' It does not inherit from `age_group`. All intervals are right-open `[start,end)`.
#'
#' @param groups A nonempty `age_group` vector with an explicit time unit and
#'   unique, nonblank names for every category. Missing intervals are not allowed.
#' @param id Stable machine identifier, using letters, digits, underscores or
#'   hyphens and starting with a letter.
#' @param name Nonblank human-readable title. For `$<-`, the exact field name
#'   to replace; changing the title field `name` is descriptive, not substantive.
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
#'   or errors. `scheme_groups()` returns its `age_group` vector. Replacement
#'   methods return the validated updated scheme.
#' @details Scheme units must be second, minute, hour, day, week, month or year.
#'   Validation checks the complete stored `age_group` representation, including
#'   interval fields, bounds, units, category names and the actual `below`, `sep`
#'   and `above` display symbols. Malformed metadata is rejected without repair
#'   or substitution of defaults. Custom scalar-string display symbols remain
#'   valid. Structural validation does not independently verify external sources.
#'   Ordinary replacement validates the completed candidate; invalid edits error
#'   without changing the original. A
#'   partition need not cover the entire domain; disjointness and coverage are
#'   separate properties. No registry lookup is performed by this constructor.
#' @section Editing local copies:
#' Schemes are independent R value objects. Copy with `modified <- original`,
#' then edit using `$<-`, `[[<-` or batch `[<-` replacement. Substantive changes
#' to bounds, units, ordered category labels, category order, type, domain or
#' completeness create a derivative. Display symbols, title, purpose and notes
#' are descriptive/cosmetic; valid changes to these preserve status. Identical
#' definition assignments do not create derivatives or reset verification.
#'
#' New objects have `derived_from = NULL`. The first substantive edit records
#' the parent's `id`, `version`, `source`, `organization` and `reference` there,
#' assigns an `_derived` ID, clears the current version and sets `verified = FALSE`.
#' Subsequent edits retain that first ancestry and do not restore verification,
#' even when reverting the definition. Generated IDs are predictable local names,
#' not globally unique. An explicitly supplied distinct ID or version in a batch
#' is retained. Source, organization, reference, ID or version changes also create
#' ancestry on first change and clear verification. Inherited source/citation
#' fields remain attribution, not verification of the derivative. A later explicit
#' `verified = TRUE` remains a caller's claim requiring source, reference and version;
#' substantive or asserted-source changes always clear it, even in a batch that
#' also assigns TRUE.
#'
#' `derived_from` is protected from ordinary replacement. Use one exact field name
#' or position for `[[<-`; recursive indices are rejected. Use a list of values
#' for atomic batch edits, for example `x[c("groups", "complete")] <- list(g, FALSE)`.
#' Each completed assignment must be valid; batch related policy/interval changes
#' rather than relying on an invalid intermediate object. Optional fields can be
#' cleared with NULL without deleting schema fields.
#'
#' Older serialized schemes without `derived_from` remain readable and valid.
#' Their first tracked edit records their then-current metadata, not an invented
#' historical lineage. Deliberate class removal, `unclass()` or reconstruction
#' bypasses tracking. No definition snapshots or change histories are stored;
#' validation checks structure and ancestry shape, not historical authenticity.
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
                      verified = verified, notes = notes, derived_from = NULL), class = "age_scheme")
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
  if (!is_age_scheme(x) || !is.list(x) || !(identical(names(x), required) ||
        identical(names(x), c(required, "derived_from")))) {
    stop("x must be an age_scheme with all required fields", call. = FALSE)
  }
  ancestry <- x$derived_from
  if (!is.null(ancestry)) {
    if (!is.list(ancestry) || is.object(ancestry) ||
        !identical(names(ancestry), c("id", "version", "source", "organization", "reference"))) {
      stop("derived_from must contain id, version, source, organization and reference", call. = FALSE)
    }
    for (field in names(ancestry)) {
      value <- ancestry[[field]]
      if (field != "id" && is.null(value)) next
      if (!is.character(value) || length(value) != 1L || is.na(value) ||
          !nzchar(trimws(value))) {
        stop("derived_from ", field, " must be a nonblank character scalar or optional NULL",
             call. = FALSE)
      }
    }
    if (!grepl("^[A-Za-z][A-Za-z0-9_-]*$", ancestry$id) || identical(x$id, ancestry$id)) {
      stop("a derivative requires a valid ancestor id distinct from its current id", call. = FALSE)
    }
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
  if (!is.age_group(g)) {
    stop("groups must be a nonempty age_group vector", call. = FALSE)
  }
  validate_age_group(g)
  if (!length(g)) {
    stop("groups must be a nonempty age_group vector", call. = FALSE)
  }
  unit <- get_unit(g)
  if (!is.character(unit) || length(unit) != 1L || is.na(unit) ||
      !unit %in% c("second", "minute", "hour", "day", "week", "month", "year")) {
    stop("groups require an explicit supported time unit", call. = FALSE)
  }
  if (anyNA(ivs::iv_start(g)) || anyNA(ivs::iv_end(g))) {
    stop("groups cannot contain missing intervals", call. = FALSE)
  }
  labels <- attr(g, "group_names", exact = TRUE)
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
