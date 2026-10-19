# Public interface and compatibility

The main workflow uses calculate_age(), categorize_age(), age_group(),
as.age_group(), is.age_group(), and age_auto_unit(). Registered S3 methods
remain infrastructure. age_group_to_char() and valid_age_group_symbol() stay
exported for compatibility; use as.character() and as.age_group() in new code.

age_cat() warns once per session. calc_age() and age.cat() retain their
once-per-session messages and direct users to the primary functions.
All three remain available through the next non-development release. Removal
requires a later announced breaking release; no removal date is set.

The existing as.character.ivs_iv() and summary.ivs_iv() registrations are
retained for compatibility. New features operate on age_group explicitly and
will not add methods to the bare ivs class.

Age-group bounds are nonnegative whole numbers with Inf allowed only as an
upper bound. Intervals are lower inclusive and upper exclusive: [1,5) is
labelled 1-4. Fractional bounds are rejected.
