# Read session defaults without modifying the caller's options.
get_option <- function(name, default, choices = NULL) {
  value <- getOption(name, default)
  valid <- if (is.null(choices)) {
    is.logical(value) && length(value) == 1L && !is.na(value)
  } else {
    is.character(value) && length(value) == 1L && !is.na(value) &&
      value %in% choices
  }
  if (!valid) {
    expected <- if (is.null(choices)) "TRUE or FALSE" else
      paste(sprintf('"%s"', choices), collapse = ", ")
    stop("Option `", name, "` must be ", expected, ".", call. = FALSE)
  }
  value
}

# Mask once before calendar or elapsed calculation, including automatic units.
age_end_before_start <- function(start, end) {
  policy <- get_option("agecraft.end_before_start", "warn", c("warn", "error"))
  reversed <- !is.na(start) & !is.na(end) & end < start
  count <- sum(reversed)
  if (count) {
    text <- if (policy == "error") {
      "end must not precede start when calculating age"
    } else {
      sprintf(ngettext(count,
                       "Produced NA for %d entry where `end` occurs before `start`.",
                       "Produced NA for %d entries where `end` occurs before `start`."), count)
    }
    if (policy == "error") stop(text, call. = FALSE)
    warning(text, call. = FALSE)
    end[reversed] <- NA
  }
  end
}

# Count observations rather than membership rows; missing input is not unmatched.
age_check_unmatched <- function(ages, locations) {
  policy <- get_option("agecraft.classify.unmatched", "allow",
                       c("allow", "warn", "error"))
  if (policy == "allow") return(invisible(NULL))
  missing <- if (inherits(ages, "ivs_iv")) {
    is.na(ivs::iv_start(ages)) | is.na(ivs::iv_end(ages))
  } else {
    is.na(as.numeric(ages))
  }
  matched <- locations$needles[!is.na(locations$haystack)]
  count <- sum(!missing[setdiff(seq_along(ages), matched)])
  if (count) {
    text <- sprintf(ngettext(count,
                             "%d non-missing age observation has no matching category.",
                             "%d non-missing age observations have no matching category."), count)
    if (policy == "error") stop(text, call. = FALSE)
    warning(text, call. = FALSE)
  }
  invisible(NULL)
}
