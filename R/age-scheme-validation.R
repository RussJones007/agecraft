# Compare sorted coordinates exactly for overlap; retain ivs for domain gaps.
age_scheme_coverage <- function(groups, domain) {
  starts <- ivs::iv_start(groups)
  ends <- ivs::iv_end(groups)
  bare <- ivs::iv(starts, ends)
  overlaps <- FALSE
  n <- length(starts)
  if (n > 1L) {
    index <- order(starts)
    # A running maximum also detects overlap with an earlier enclosing interval.
    overlaps <- any(starts[index][-1L] < cummax(ends[index])[-n])
  }
  gaps <- if (is.null(domain)) NULL else {
    ivs::iv_set_difference(ivs::iv(domain[1], domain[2]), bare)
  }
  list(overlaps = overlaps, gaps = gaps,
       covered = if (is.null(domain)) NA else length(gaps) == 0L)
}
