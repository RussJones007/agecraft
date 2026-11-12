# Age class naming inventory

Status: both naming phases implemented on the development branch. Prepared 2026-11-12. Baseline tables below retain old names
for migration review. See CURRENT_STATE.md for validation results.
Baseline: main, e7cf2a27eea6a5439f3610259cd242401e3139e5, version 0.1.0.9020.
Active branch: refactor/age-class-names, verified 2026-11-12 after the user
created it locally. These planning documents do not amend current API policy.

## Target vocabulary

| Concept | Current | Target | Phase |
| --- | --- | --- | --- |
| ivs interval vector | age_group | age_interval | 1 |
| ordered-factor assignments | age_category | age_group | 2 |
| reusable classification definition | age_scheme | age_scheme | unchanged |
| numeric cut-point dataset | age_group_presets | age_interval_presets | 1 |

The user explicitly selected the preset rename. Presets remain numeric lists,
not interval vectors; preserve all eight entries, names, values and ordering.
Other mappings below are implementation proposals for review.

## Public names

| Current | Target | Notes |
| --- | --- | --- |
| age_group(start, end, ...) | age_interval(start, end, ...) | Phase 1; vacates constructor name |
| as.age_group() | as_age_interval() | Phase 1; preserve S3 dispatch and coercion semantics |
| is.age_group() | is_age_interval() | Phase 1 |
| compare_age_groups() | compare_age_intervals() | Phase 1; preserve operations/result columns |
| age_group_to_char() | age_interval_to_char() | Phase 1; retain role; prefer as.character() |
| valid_age_group_symbol() | valid_age_interval_symbol() | Phase 1; preserve parser rules |
| age_group_presets | age_interval_presets | Phase 1; data(), help and data generation |
| age_category(x, groups) | age_group(x, intervals) | Phase 2; explicitly changed formal name |
| is_age_category() | is_age_group() | Phase 2 |
| category_groups() | category_intervals() → group_intervals() | Phase 1 then phase 2; returns level-aligned intervals |
| scheme_groups() | scheme_intervals() | Phase 1; interval accessor |
| age_scheme(groups, ...) | age_scheme(intervals, ...) | Proposed phase 1 formal rename |
| age_cat_iv(age, age_group, ...) | age_cat_iv(age, intervals, ...) | Proposed phase 1 formal rename; retain generic name |

Retain calculate_age(), age(), as_age(), is_age(), age_auto_unit(),
categorize_age(), classify_age_scheme(), age_scheme(), is_age_scheme(),
validate_age_scheme(), get_age_scheme(), list_age_schemes(),
import_mudnester_scheme(), mudnester_catalogue() and toBibtex.age_scheme().
Retain categorize_age() arguments, including by, output and conversion controls.
Retain output = "factor" and "interval"; document the renamed return classes.
Retain legacy age_cat(), calc_age(), age.cat(), and age.groups through the
currently promised release window. Propose retaining age_group_presets as a
nonconflicting deprecated data alias during that window, with all new examples
using age_interval_presets. Decide this explicitly before implementing aliases.

## Methods and internal identifiers

Phase 1: rename every interval class suffix in S3 and vctrs methods, including
both sides of vec_cast/vec_ptype2 pairs, iv_restore, proxy/restore, formatting,
names replacement, coercion, and age_cat_iv.age_group. The coercion generic's
methods become as_age_interval.<input-class>; its interval self-method becomes
as_age_interval.age_interval. Preserve generic dispatch strings and roxygen
registrations consistently. Rename new_age_group, validate_age_group,
age_group_common_unit, age_group_labels, and age_group_locations to interval
counterparts. Rename remaining interval-specific local identifiers by meaning.

Phase 2: rename age_category suffixes in slicing/replacement, levels replacement,
Ops, c, rep, droplevels, factor conversion, reorder/relevel, print, vctrs casts,
proxies/restoration and both sides of mixed-type methods. Rename private
new_age_category, validate_age_category and age_category_common to age_group
counterparts. Do not overwrite phase-1 interval methods with factor methods.
Regenerate NAMESPACE from roxygen; never edit generated registrations by hand.

Update errors, print headers and full/abbreviated type descriptions. Proposed
abbreviations: aInt for intervals and aGrp for assignments, retaining existing
unit conventions. Printed labels and numeric/factor values do not change.

## Stored fields and arguments: semantic decisions

| Surface | Proposed treatment |
| --- | --- |
| Interval group_names attribute | Retain; these are optional group labels, not a class tag |
| Scheme groups field | Rename to intervals in phase 1, including validation and replacement transactions |
| Assignment groups attribute | Rename to intervals in phase 1 while class remains age_category |
| Assignment groups constructor formal | Rename to intervals in phase 1; phase 2 changes constructor name only |
| Scheme domain, source, reference, derived_from | Preserve shape and meaning |
| Classification result category indices/labels | Retain: category is still valid semantic vocabulary |
| Comparison result column names | Retain unless inventory reveals an actual class-name dependency |
| Registry IDs, source editions, upstream mudnester IDs | Preserve exactly |
| Interval unit / legacy observation units attributes | Preserve distinction and behavior |

Field renames are additional explicit compatibility breaks, not incidental text
replacement. Their implementation must update scheme replacement validation and
provenance comparisons without falsely marking a schema migration as a changed
scientific definition. Do not rename external upstream dataset fields.

## Files and packaged surfaces

| Surface | Planned work |
| --- | --- |
| R/agegroup-{class,coerce,compare,print}.r | Rename to R/age-interval-{class,coerce,compare,print}.R |
| R/agegroup-methods.r | Rename to R/age-interval-classify.R; matching engine remains shared |
| R/age-category.R | Keep in phase 1; rename to R/age-group.R in phase 2 |
| R/Age_calculation.r, R/age-class.R | Update classification calls and dispatch |
| R/age-scheme-*.R | Update interval validation, access, registry, import and replacement paths |
| R/misc.r, R/utils.r | Update data help, formatting bridges and interval consumers |
| data-raw/DATASET.R | Generate new canonical dataset and explicitly retained aliases |
| data/*.rda | Regenerate with correctly named contained objects; renaming files alone is insufficient |
| inst/tools/migrate-age-groups.R | Extend/replace with reviewed token-aware preset migration to final name |
| inst/extdata/age-group-provenance.csv | Retain path initially; source provenance describes reporting groups |
| tests/testthat/test-agegroup*.R | Rename to test-age-interval*.R and update interval expectations |
| tests/testthat/test-age-category.R | Update definitions in phase 1; rename to test-age-group.R in phase 2 |
| Other tests, snapshots and fixtures | Review all references; preserve independent behavioral assertions |
| docs/age_group.md | Move interval contract to docs/age_interval.md in phase 1 |
| docs/age_category.md | Update interval terminology in phase 1; move to docs/age_group.md in phase 2 |
| AGENTS.md and docs/coding_guidelines.md | Update required paths and class-preservation rules with implementation |
| docs/architecture.md, age_scheme.md, API_POLICY.md, CURRENT_STATE.md | Describe each completed phase accurately |
| Existing implementation plans and dated validation records | Preserve historical facts; annotate superseded names rather than rewrite history |
| vignettes/age-and-age-group.Rmd | Propose age-and-age-interval.Rmd; update title and links |
| vignettes/age-categories.Rmd | Propose age-groups.Rmd in phase 2 |
| All other vignettes, README.md, DESCRIPTION | Update examples, return types, references and terminology |
| _pkgdown.yml | Update reference topics and article paths |
| man/*.Rd, NAMESPACE | Regenerate and remove obsolete generated topics deliberately |
| scripts/*.r and scripts/release.md | Update executable examples and release instructions |
| scripts/validation/* | Preserve historical logs; do not rewrite old evidence |

## Collision and compatibility inventory

The old interval class and new factor class share the spelling age_group.
Do not retain old interval constructor or S3 class aliases under age_group.
In particular, do not subclass age_interval with age_group: new factor methods
would dispatch on interval records. inherits(x, "age_group") alone cannot safely
identify old serialized objects after phase 2. New factor entry points must
validate actual representation before operating.

Old saved schemes and category objects also contain nested interval objects and
old field names. Automatic readRDS dispatch cannot be assumed. Recommended
initial migration: reconstruct intervals from verified old bounds/units/names
using a separately installed old package, then reconstruct schemes/assignments
with the new constructors. Decide whether a dedicated structural migration
helper is worthwhile; no automatic class reassignment or lossy conversion.

## Naming review — 2026-11-12

Review completed against current constructors, assignment metadata, scheme
replacement transactions, registration manifest and packaged data generation.
The following are recommended implementation choices; production code remains
unchanged. The three class/dataset renames above are user-selected; these details
are recommendations within that direction, not additional user approvals.

- Use snake_case for the public interval coercer and predicate. This deliberately
  changes both the spelling and the S3 generic name of as.age_group; changing
  method suffixes alone is insufficient.
- Use intervals for constructor arguments, the scheme field and assignment
  metadata. This matches scheme_intervals()/group_intervals() and makes the
  stored definition's type evident. Preserve interval group_names because those
  are labels for reporting groups. Do not mechanically rename every groups local.
- In phase 1, category_groups becomes category_intervals; in phase 2 it becomes
  group_intervals. This keeps the intermediate API consistent with age_category
  rather than introducing group_intervals before the factor is called age_group.
- Retain age_cat_iv as a legacy generic and retain its return behavior. Its name
  is awkward but renaming that generic is a separate API expansion; the public
  categorize_age workflow already supplies clear factor/interval output modes.
- Retain conversion option values age_to_group/group_to_age, the by argument,
  result category-index columns and group labels. These describe operations and
  classification concepts rather than a concrete class identifier.
- Retain age.groups and age_group_presets as documented data aliases through the
  existing compatibility window. They must equal age_interval_presets exactly;
  data aliases do not imply an interval class alias. Describe aliases as legacy
  in help rather than promise access-time warnings for ordinary lazy datasets.
- Do not introduce new aliases for old interval functions or age_category APIs.
  Provide a migration map instead. Existing unrelated deprecated wrappers retain
  their current promises. This keeps the final API vocabulary unambiguous.
- Document reconstruction of old saved objects first; do not add a new migration
  API in this refactor. Reject old interval records under the reused age_group
  tag at operational entry points. is_age_group should at least distinguish
  factor assignments from ivs records, rather than use inherits alone. Test its
  result on an old interval object without implying it is a full validator.
- Migration reconstruction must preserve optional display symbols, labels,
  units, missing intervals, unused factor levels and scheme metadata. Export
  primitive components in an old-version session; avoid calling new methods on
  old objects. Do not run reconstruction through ordinary scheme replacement
  setters, which can incorrectly create derivative ancestry.

Implementation acceptance must distinguish method safety from arbitrary base R
operations: the package cannot guarantee interception of every inherited/base
operation on an old serialized object. Documentation must require migration
before use, and package entry points/methods must fail clearly where dispatched.

## Observed function/method inventory

Source locations are baseline references and will move during implementation.
This table includes affected naming families and the shared age_cat_iv family;
unchanged unit helpers still require a consumer review.

| Identifier | Baseline source |
| --- | --- |
| `age_category` | `R/age-category.R:24` |
| `new_age_category` | `R/age-category.R:39` |
| `validate_age_category` | `R/age-category.R:44` |
| `is_age_category` | `R/age-category.R:63` |
| `category_groups` | `R/age-category.R:67` |
| `[.age_category` | `R/age-category.R:73` |
| `[[.age_category` | `R/age-category.R:83` |
| `droplevels.age_category` | `R/age-category.R:86` |
| `levels<-.age_category` | `R/age-category.R:99` |
| `as.factor.age_category` | `R/age-category.R:114` |
| `as.ordered.age_category` | `R/age-category.R:122` |
| `rep.age_category` | `R/age-category.R:129` |
| `[<-.age_category` | `R/age-category.R:135` |
| `age_category_common` | `R/age-category.R:149` |
| `c.age_category` | `R/age-category.R:168` |
| `vec_proxy.age_category` | `R/age-category.R:185` |
| `vec_restore.age_category` | `R/age-category.R:192` |
| `vec_ptype2.age_category.age_category` | `R/age-category.R:200` |
| `vec_cast.age_category.age_category` | `R/age-category.R:203` |
| `[[<-.age_category` | `R/age-category.R:211` |
| `Ops.age_category` | `R/age-category.R:217` |
| `vec_ptype2.age_category.factor` | `R/age-category.R:226` |
| `vec_ptype2.factor.age_category` | `R/age-category.R:230` |
| `vec_ptype2.age_category.ordered` | `R/age-category.R:232` |
| `vec_ptype2.ordered.age_category` | `R/age-category.R:234` |
| `vec_ptype2.age_category.character` | `R/age-category.R:236` |
| `vec_ptype2.character.age_category` | `R/age-category.R:238` |
| `vec_ptype_full.age_category` | `R/age-category.R:241` |
| `vec_ptype_abbr.age_category` | `R/age-category.R:248` |
| `print.age_category` | `R/age-category.R:255` |
| `reorder.age_category` | `R/age-category.R:265` |
| `relevel.age_category` | `R/age-category.R:270` |
| `age_cat_iv.age` | `R/age-class.R:210` |
| `scheme_groups` | `R/age-scheme-class.R:108` |
| `new_age_group` | `R/agegroup-class.r:51` |
| `validate_age_group` | `R/agegroup-class.r:84` |
| `is.age_group` | `R/agegroup-class.r:118` |
| `vec_ptype_abbr.age_group` | `R/agegroup-class.r:122` |
| `vec_ptype_full.age_group` | `R/agegroup-class.r:126` |
| `vec_restore.age_group` | `R/agegroup-class.r:135` |
| `iv_restore.age_group` | `R/agegroup-class.r:145` |
| `valid_age_group_symbol` | `R/agegroup-class.r:166` |
| `age_group` | `R/agegroup-class.r:210` |
| `names.age_group` | `R/agegroup-class.r:219` |
| `names<-.age_group` | `R/agegroup-class.r:222` |
| `vec_proxy.age_group` | `R/agegroup-class.r:233` |
| `vec_proxy_equal.age_group` | `R/agegroup-class.r:242` |
| `vec_proxy_compare.age_group` | `R/agegroup-class.r:248` |
| `age_group_common_unit` | `R/agegroup-coerce.r:7` |
| `vec_ptype.age_group` | `R/agegroup-coerce.r:17` |
| `vec_ptype_finalise.age_group` | `R/agegroup-coerce.r:22` |
| `vec_ptype2.age_group.age_group` | `R/agegroup-coerce.r:27` |
| `vec_cast.age_group.age_group` | `R/agegroup-coerce.r:35` |
| `vec_ptype2.age_group.double` | `R/agegroup-coerce.r:43` |
| `vec_ptype2.double.age_group` | `R/agegroup-coerce.r:48` |
| `vec_ptype2.age_group.ivs_iv` | `R/agegroup-coerce.r:53` |
| `vec_ptype2.ivs_iv.age_group` | `R/agegroup-coerce.r:58` |
| `vec_cast.ivs_iv.age_group` | `R/agegroup-coerce.r:64` |
| `vec_cast.age_group.ivs_iv` | `R/agegroup-coerce.r:69` |
| `as.integer.age_group` | `R/agegroup-coerce.r:76` |
| `as.age_group` | `R/agegroup-coerce.r:157` |
| `as.age_group.factor` | `R/agegroup-coerce.r:163` |
| `as.age_group.character` | `R/agegroup-coerce.r:170` |
| `as.age_group.integer` | `R/agegroup-coerce.r:234` |
| `as.age_group.double` | `R/agegroup-coerce.r:241` |
| `as.age_group.ivs_iv` | `R/agegroup-coerce.r:273` |
| `as.age_group.age_group` | `R/agegroup-coerce.r:281` |
| `compare_age_groups` | `R/agegroup-compare.r:45` |
| `age_cat_iv` | `R/agegroup-methods.r:47` |
| `age_cat_iv_haystack` | `R/agegroup-methods.r:55` |
| `age_cat_iv_age_unit` | `R/agegroup-methods.r:100` |
| `age_cat_iv_convert_values` | `R/agegroup-methods.r:112` |
| `age_cat_iv_is_approx_conversion` | `R/agegroup-methods.r:121` |
| `age_cat_iv_align_units` | `R/agegroup-methods.r:129` |
| `age_cat_iv_to_factor` | `R/agegroup-methods.r:204` |
| `age_cat_iv.default` | `R/agegroup-methods.r:213` |
| `age_cat_iv.numeric` | `R/agegroup-methods.r:221` |
| `age_cat_iv.integer` | `R/agegroup-methods.r:238` |
| `age_cat_iv.units` | `R/agegroup-methods.r:247` |
| `age_cat_iv.age_group` | `R/agegroup-methods.r:264` |
| `age_cat_iv.ivs_iv` | `R/agegroup-methods.r:285` |
| `age_cat_iv.double` | `R/agegroup-methods.r:294` |
| `age_cat_iv.POSIXct` | `R/agegroup-methods.r:303` |
| `age_cat_iv.Date` | `R/agegroup-methods.r:311` |
| `age_group_labels` | `R/agegroup-methods.r:319` |
| `age_group_locations` | `R/agegroup-methods.r:338` |
| `format.age_group` | `R/agegroup-print.r:8` |
| `print.age_group` | `R/agegroup-print.r:13` |
| `age_group_to_char` | `R/agegroup-print.r:35` |
| `as.character.age_group` | `R/agegroup-print.r:89` |
| `as.factor.age_group` | `R/agegroup-print.r:111` |
| `as.ordered.age_group` | `R/agegroup-print.r:122` |
