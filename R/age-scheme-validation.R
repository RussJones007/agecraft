# The ivs engine determines overlap and uncovered domain; do not round bounds.
age_scheme_coverage <- function(groups, domain) {
  bare <- ivs::iv(ivs::iv_start(groups), ivs::iv_end(groups))
  locations <- ivs::iv_locate_overlaps(bare, bare)
  overlaps <- any(locations$needles < locations$haystack, na.rm = TRUE)
  gaps <- if (is.null(domain)) NULL else {
    ivs::iv_set_difference(ivs::iv(domain[1], domain[2]), bare)
  }
  list(overlaps = overlaps, gaps = gaps,
       covered = if (is.null(domain)) NA else length(gaps) == 0L)
}
