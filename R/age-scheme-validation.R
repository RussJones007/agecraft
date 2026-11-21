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
  inferred <- is.null(domain)
  if (inferred) {
    span <- ivs::iv_span(bare)
    domain <- c(ivs::iv_start(span), ivs::iv_end(span))
  }
  gaps <- ivs::iv_set_difference(ivs::iv(domain[1], domain[2]), bare)
  list(overlaps = overlaps, gaps = gaps,
       covered = length(gaps) == 0L, domain = domain, domain_inferred = inferred)
}
