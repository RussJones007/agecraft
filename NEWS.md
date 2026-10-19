# Development changes

- Validate whole-number, nonnegative age-group endpoints and metadata. A scalar
  upper endpoint is recycled to the number of starts; other size mismatches fail.
- Handle empty and scalar numeric constructors; reject unordered, fractional,
  duplicate, and missing cut points.
- Preserve missing character, factor, and interval observations and existing
  age-group display metadata; format missing values without adding unit text.
- Include units in full vector type names and accept the documented `plus` suffix.
- Keep unit-conversion matching intervals separate from whole-number age groups,
  preserving original labels without rounding converted boundaries.

# agecraft 0.1.0.9010

* Rename the original rage package to agecraft; require R >= 4.1.0.
* Retain age_group class, units, and display metadata through vector operations.
  Incompatible units and implicit mixing with bare intervals/numbers now fail.
* Preserve observation order during factor conversion; order only factor levels.
* Reject end dates before start dates. Calendar years use March 1 for leap
  birthdays in non-leap years; month anniversaries use the last day of shorter
  months. Document time-zone and daylight-saving behavior.
* Select automatic units with non-overlapping rules: days through day 30,
  then completed calendar years, completed calendar months, or days.
* Fix runnable examples, dependency declarations, partial argument matching,
  and once-per-session deprecation messages. Keep legacy wrappers documented.
* Add regression tests, a public-health vignette, data provenance, portable
  build/release instructions, and an R CMD check CI matrix.
