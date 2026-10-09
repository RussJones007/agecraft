# agecraft review resolution — 2026-10-09

All six review priorities have been implemented in development version 0.1.0.9010.

| Original finding | Resolution |
| --- | --- |
| Broken runnable examples and incomplete documentation | Corrected examples; documented legacy age.cat and validator; reconciled method arguments; regenerated man pages and NAMESPACE. |
| Missing dependencies and code notes | Declared/imported generics, qualified stats::na.omit, removed partial difftime argument matching, and replaced broad namespace imports with targeted imports. |
| Age-group metadata loss | Added prototype/finalisation/cast methods; identical normalized units are retained; incompatible or missing units are rejected; differing display symbols use canonical formatting. Regression tests include slicing, casts, concatenation, missing observations, and data-frame binding. |
| Calendar boundary ambiguity | Retained days through day 30; use completed calendar years then months; reject reversed dates. Documented March 1 leap birthdays, month-end anniversaries, time zones, daylight-saving behavior, empty/missing vectors, and recycling; added exact-output tests. |
| README/API mismatch | Corrected local installation, documented deprecated wrappers, interval matching, overlap controls, unit conversion, and calendar conventions. |
| Release/data infrastructure | Added NEWS, migration update, public-health vignette, provenance for all eight definitions, portable build/release scripts, pkgdown configuration, and cross-platform CI. Official source editions remain explicitly unknown; data is unchanged. |

Additional fixes preserve factor observation order, format missing intervals, and
persist once-per-session deprecation messages. Validation is now **138 passing
test expectations and R CMD check: 0 errors, 0 warnings, 0 notes** on Linux.

See CURRENT_STATE.md for the current release limitations and scripts/validation/
for logs. The original rage project remains unchanged. The GitHub workflow is
configured locally and can run after repository creation and push.
