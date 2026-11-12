# Age class naming implementation plan

Status: both naming phases implemented; phase-two validation is recorded in
CURRENT_STATE.md. Prepared 2026-11-12.
See CURRENT_STATE.md for the executed validation record.
Companion: [naming inventory](age_class_naming_inventory.md).
Baseline: main at e7cf2a27eea6a5439f3610259cd242401e3139e5,
version 0.1.0.9020. No implementation or fresh test results are claimed here.

## Scope and authorization

Approved naming direction: interval age_group becomes age_interval;
assignment age_category becomes age_group; age_group_presets becomes
age_interval_presets. Prepare the inventory and plan before modifying package
code. Target branch: refactor/age-class-names. Both implementation phases belong
on that branch and must each produce a coherent working checkpoint.

The user created refactor/age-class-names locally; the active branch was verified
on 2026-11-12. Planning documents and implementation are present on that branch.
Do not implement on main. Do not publish or merge an intermediate API. No remote
branch or PR has been created by this session.

## Invariants

This is a naming/schema migration. Preserve S3, ivs and vctrs representations;
left-closed/right-open boundaries; fractional values; optional interval names;
units and approximation safeguards; overlap resolution; interval comparisons;
ordered-factor codes, labels and unused levels; scheme policies and scientific
provenance; all preset numeric values; and optional mudnester semantics.
Do not optimize algorithms, add dependencies, change matching rules, broaden
accepted inputs or remove unrelated deprecated APIs during this work.

## Phase 0: review and establish baseline

1. Branch creation and status verification are complete. Commit the planning
   documents as a separate planning checkpoint when Git writes are available.
2. Naming review is complete; the inventory records recommended formal/field
   names, preset alias retention and saved-object reconstruction. These remain
   proposed implementation details, with no production edits yet.
3. Record an old-version API/export manifest and representative outputs. Run
   `devtools::test()` and `devtools::check(document = FALSE)` on the unchanged
   baseline; record actual results and environment without copying old counts.
4. Capture representative old objects before class-name reuse: intervals,
   age_category assignments and schemes, including nested metadata. Keep any
   fixtures small and reproducible. If using serialized fixtures, document their
   producing version and do not regenerate them with the new class definitions.
5. Review API_POLICY, architecture, class contracts and AGENTS instructions.
   Update preservation rules when implementation begins to explicitly authorize
   the new names while retaining semantic invariants. Historical records remain
   historical; a plan does not override the current implementation contract.

## Phase 1: vacate the interval age_group name

1. Rename interval class, constructor, predicate, coercion generic and every
   supporting method/helper according to the inventory. Rename source/test
   files. Use bounded identifier edits with semantic review, not global substring
   replacement. Adapt direct method calls and both sides of vctrs registrations.
2. Update all consumers: age calculations, classification, category definitions,
   scheme validation/updates, registry factories, imports and formatting bridges.
   Keep the assignment class named age_category throughout this phase.
3. Apply reviewed interval argument/field/accessor names consistently, including
   nested definition access and scheme replacement transactions. Preserve
   derivative provenance behavior and metadata equality after reconstruction.
4. Rename preset generation and canonical packaged data to age_interval_presets.
   Regenerate RDA contents. Preserve the old alias policy explicitly; verify
   `data()` loading in a private environment and registry access in an installed
   package. Update the installed migration script so it recommends the final
   dataset name while preserving preview, backups and token-aware safeguards.
5. Move the interval contract to docs/age_interval.md. Update roxygen examples,
   README, vignettes, pkgdown, API policy, architecture, current state, NEWS and
   contributor instructions. Keep age_category documentation accurate for this
   intermediate state. Do not pre-document the final factor class as available.
6. Regenerate help and NAMESPACE with `devtools::document()`. Remove stale
   generated topics after reviewing generator output. Run the validation gate.

Phase-1 acceptance: interval objects inherit age_interval and ivs_iv; no runtime
interval object inherits age_group; age_category remains an ordered factor with
age_interval definitions; both classification outputs work; scheme registry and
mudnester paths work; new dataset values equal the baseline. Old constructor
age_group is absent unless an explicit actionable migration error stub is chosen;
no functional interval alias may survive into phase 2.

Commit a working phase-1 checkpoint before beginning phase 2.

## Phase 2: assign age_group to categorical assignments

1. Rename age_category constructor, predicate, validators and complete method
   family to age_group. Update group_intervals() access and consumers. Ensure
   interval operations still dispatch only to age_interval methods.
2. Update categorize_age() default return documentation and expectations; retain
   output option names and interval output. Retain underlying integer factor
   values and label-to-interval mappings.
3. Rename the factor contract and source/test files to age_group names, now that
   the interval documentation path is free. Update final vocabulary throughout
   live documentation, examples and pkgdown. Preserve ordinary use of the words
   group/category where they describe concepts rather than obsolete identifiers.
4. Add focused old-object collision regressions. New methods must reject legacy
   interval records encountered under the age_group tag with an actionable error;
   method-name reuse must never silently interpret endpoint records as factors.
   Check any default/inherited method paths that could bypass validation.
5. Regenerate documentation and run the validation gate. Commit a working
   phase-2 checkpoint.

Phase-2 acceptance: class hierarchy is c("age_group", "ordered", "factor") for
assignments and the existing ivs hierarchy with age_interval for ranges.
Categorization, manual construction, slicing, replacement, droplevels, c/rep,
validated binding, coercion, comparisons and incompatible-type rejection retain
baseline semantics. Definitions remain aligned after unused-level removal.

## Validation gate for each implementation phase

- Run focused interval, factor, scheme, preset and classification tests while
  editing. Preserve their behavioral assertions rather than merely changing
  expected class strings until tests pass.
- Run `devtools::document()`, full `devtools::test()` and
  `devtools::check(document = FALSE)` with vignette rebuilding and examples.
- Check an installed package in a fresh R session for S3 dispatch, exports,
  dataset loading, canonical preset contents and renamed classification results.
- Exercise optional mudnester with and without the dependency where feasible;
  record unavailable configurations rather than claim they were tested.
- Check generated NAMESPACE against the naming map, duplicate methods, old help
  aliases, pkgdown topic references and outdated script output.
- Run `git diff --check`; inspect diff and residual old-name matches. Allow only
  explicitly retained aliases, historical evidence and migration examples.
- Record commands, pass/failure outcomes and limitations in CURRENT_STATE.
  Fix new failures before the phase checkpoint. Timing claims are out of scope.

Cross-cutting regression coverage includes zero length, missing/unmatched ages,
fractional and exact endpoints, touching/gapped/overlapping ranges, Inf, duplicate
labels/bounds, unit mismatches, conversion direction, mixed-type binding,
formatting, scheme mutation/provenance and registry stability.

## Final migration and integration review

Write a migration guide with old/new constructor calls, coercion/predicate names,
preset references, accessors, named arguments, stored-field access and downstream
changes. Include a concrete warning that identical age_group spelling now means
a different representation, and instructions for rebuilding old saved objects.
Review tarr.pop and external scripts separately; do not edit other repositories
as part of this package-only scope.

Select the release/development version deliberately and label the transition as
breaking; do not infer a release number solely from package version 0.1.0.9020.
Review the final export manifest, run full checks on the final candidate and
complete normal release/CI review before merging. Keep main unchanged until the
complete branch is accepted; do not merge only phase 1 as the final feature.

## Recommended decisions after naming review

The inventory now records a coherent recommendation for each open naming issue:
interval arguments/metadata use intervals; public accessors identify their owning
class; old preset names remain data aliases; no new function aliases or automatic
saved-object upgrader are introduced. Existing deprecation commitments remain.
The phase-1 category accessor is category_intervals(); phase 2 renames it to
group_intervals(). Neither intermediate API is published independently.

The user approved these recommendations for phase one. Baseline validation and
old-object capture preceded implementation. Phase two was subsequently authorized by the user.
See CURRENT_STATE.md for phase-one validation and any checkpoint limitations.

## Checkpoint status

Phase one was committed as e25155c on refactor/age-class-names. Phase two was
started from that clean checkpoint after explicit user authorization. Both
phases' behavior and validation are recorded in CURRENT_STATE.md. No merge,
push or publication is authorized for this task.

Phase-two validation is complete. Staging the checkpoint was blocked by the
current session's read-only Git metadata; phase two remains in the working tree.
The phase-one commit e25155c is intact. Record the phase-two commit from a session
with Git write permission before integration or release work.
