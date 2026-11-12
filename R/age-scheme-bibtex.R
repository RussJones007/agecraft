#' Export an age scheme as BibTeX
#'
#' Export the scheme actually used, together with its recorded source and
#' ancestry, using the standard [utils::toBibtex()] generic.
#'
#' @param object An `age_scheme`, validated before export.
#' @param ... Additional arguments passed to [utils::toBibtex()] for the
#'   constructed `bibentry`.
#' @return A character vector of class `Bibtex` containing one `@Misc` entry.
#' @details
#' The entry key is the scheme ID and its title is the scheme name. Source and
#' organization are recorded in `howpublished`; reference, version, verification
#' claim, purpose, notes and any `derived_from` metadata are recorded in `note`.
#' An HTTP(S) reference is also included as `url`. No author or publication year
#' is inferred from the organization, version, package release or current date.
#' Unknown source, reference and version are explicitly identified in the note.
#' A derivative is identified as adapted from its recorded ancestor; exporting
#' does not claim the modified scheme is the original published definition.
#' This exports recorded metadata, without verifying or fetching external sources.
#' Use [summary()] to inspect all scheme metadata and coverage programmatically.
#' @seealso [age_scheme()], [age_scheme_methods], [utils::bibentry()]
#' @examples
#' s <- get_age_scheme("legacy_ili")
#' summary(s)
#' utils::toBibtex(s)
#' @importFrom utils toBibtex
#' @export
toBibtex.age_scheme <- function(object, ...) {
  validate_age_scheme(object)
  known <- function(x) x %||% "unknown"
  note <- c(paste0("Scheme ID: ", object$id),
            paste0("Source: ", known(object$source)),
            paste0("Reference: ", known(object$reference)),
            paste0("Version: ", known(object$version)),
            paste0("Source verification claimed: ", object$verified))
  for (field in c("purpose", "notes")) {
    if (!is.null(object[[field]])) {
      note <- c(note, paste0(field, ": ", object[[field]]))
    }
  }
  if (!is.null(object$derived_from)) {
    ancestor <- object$derived_from
    note <- c(note, paste0("Adapted from scheme: ", ancestor$id))
    for (field in c("version", "source", "organization", "reference")) {
      note <- c(note, paste0("Ancestor ", field, ": ", known(ancestor[[field]])))
    }
  }
  published <- c(object$organization, object$source)
  reference <- object$reference
  url <- if (!is.null(reference) && grepl("^https?://", reference)) reference
  entry <- utils::bibentry(
    bibtype = "Misc", key = object$id, title = object$name,
    howpublished = if (length(published)) paste(published, collapse = ": "),
    url = url, note = paste(note, collapse = "; ")
  )
  utils::toBibtex(entry, ...)
}
