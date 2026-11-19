# Session-only candidate for the existing age class; no units inheritance.
# Preserve validation while avoiding length-n logical temporary vectors.
range_cast <- function(x, to, ...) {
  values <- vctrs::vec_data(x)
  unit <- agecraft:::validate_age_unit(agecraft:::age_common_unit(x, to))
  low <- min(values, Inf, na.rm = TRUE)
  high <- max(values, -Inf, na.rm = TRUE)
  all_missing <- low == Inf && high == -Inf
  if (!all_missing && (low < 0 || !is.finite(high))) {
    stop("Ages must be nonnegative and finite, or missing", call. = FALSE)
  }
  vctrs::new_vctr(values, unit = unit, class = "age", inherit_base_type = TRUE)
}
