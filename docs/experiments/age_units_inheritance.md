# Should age inherit from units?

Experiment branch: `experiment/units-inheritance`. Production baseline:
`7e732d4` (agecraft 0.1.0.9022). Conducted November 18, 2026.

## Recommendation: Retain

Retain the production `age` representation for now. Using the vctrs framework
can substantially reduce the vector-method adapters a `units` subclass needs,
but inheritance does not provide the restricted conversion/arithmetic contract
Agecraft requires. The current package already delegates conversion factors to
`units`; subclassing does not replace a duplicated conversion engine.

A future revision could use vctrs-first inheritance, explicit conversion setters,
and a deliberate solution for mixed `age`/`units` operator dispatch. That would
need another full compatibility study before adoption. This experiment is not a
production migration. Nothing under `R/`, `NAMESPACE`, or the public help was changed.

## Current representation and conversion policy

[`R/age-class.R`](../../R/age-class.R) constructs double vectors with
`vctrs::new_vctr()`, classes `age`, `vctrs_vctr`, `double`, and a normalized
character `unit` attribute. Finite nonnegative values and missing values are
valid. Names survive vector operations. Display floors values; numeric extraction
retains fractions. Constructors, restoration, casts and arithmetic validate results.

`as_age()` remains the explicit conversion interface. The shared helpers
`age_cat_iv_convert_values()` and `age_cat_iv_is_approx_conversion()` in
[`R/age-interval-classify.R`](../../R/age-interval-classify.R) provide conversion
and permission checks. The former constructs a `units` object, asks `units` to
convert it, then extracts numbers: eight source lines, not an independent
conversion engine. Intervals and classification also use these helpers, so they
would still be needed after an age-only migration.

All directed conversions between second, minute, hour, day and week are exact
in the measurement-policy sense, subject to floating-point rounding. Factors
include 60 seconds/minute, 24 hours/day, 7 days/week, 604800 seconds/week.
Every change involving month or year, including month/year, requires
`allow_approx = TRUE`. Same-unit conversion requires no permission. Fixed factors
do not recover birthday or month-anniversary coordinates from original dates.

The installed UDUNITS database defines one year as 365.24219878125 days and
one month as 30.4368498984375 days (year/12). `units` permits these conversions
without Agecraft's calendar-consent policy. All 49 directed factors, policy
flags and numerical results are recorded in the baseline/prototype conversion
CSVs under [`results`](../../experiments/units-inheritance/results/).

[`R/age-arithmetic.R`](../../R/age-arithmetic.R) permits numeric offsets,
left-unit age addition with guarded conversion, and selected summaries. It
rejects negative results, age subtraction, products, division and sums.
Comparisons, common types, casts and concatenation require matching age units.

## Installed APIs and unguarded inheritance

The inspected versions are units 1.0-1 and vctrs 0.7.3 on R 4.6.2, Linux Mint
22.1. The recorded session files identify all loaded dependencies.
A `units` value has class `units`, underlying double storage, and a
`units` attribute of class `symbolic_units` containing numerator and denominator
vectors. It does not inherit from vctrs_vctr. See the reproducible
[`audit.R`](../../experiments/units-inheritance/audit.R) and its full
[`installed API transcript`](../../experiments/units-inheritance/results/installed-api-audit.txt),
including installed method bodies and local help text.

Observed behavior when adding `age` to a valid units object without adapters:

- `set_units()` and `units<-` convert year to day/month without consent and
  return ordinary `units`, dropping `age`.
- `Ops.units` converts comparisons automatically, permits squared units and
  negative subtraction, and rejects the plain numeric offsets Agecraft supports.
- The existing `vec_restore.age` reconstructs the production class, losing the
  units subclass. Merely adding a class tag is insufficient.
- `units` already supplies vctrs proxy/restore/common-type/cast methods, but its
  common types and casts allow dimensionally convertible units, which is broader
  than Agecraft's matching-unit contract.
- Its installed `ud_convert()` uses `mapply()` over numeric values. Large-vector
  conversions retain this cost regardless of subclassing.

These are ordinary dispatched APIs, not deliberate `attr()` mutation or direct
calls to private methods. Unsupported direct class/attribute mutation remains
outside the class safety contract in either design.

## Isolated prototype

[`prototype.R`](../../experiments/units-inheritance/prototype.R) creates a valid
units object first, then adds `age`, producing exactly `c("age", "units")`.
It retains a character `unit` compatibility attribute for existing Agecraft
consumers; symbolic units remain authoritative. It defines explicit proxies,
restoration, same-unit common types/casts, numeric extraction, display, setters,
operators, summaries, replacement and selected base vector adapters.

`as_age()` is the public conversion interface, registered to prototype methods
for age, units and numeric inputs. The constructor is named `p_age()` to isolate
it from the production constructor. No public constructor or package namespace
binding is patched. S3 registrations are process-local and deliberately replace
registered methods only inside the experiment's fresh R processes. Do not source
this script into an analysis session containing production age objects.

Supported conversions and vector operations return validated age objects;
comparisons return logical; explicit numeric extraction and `drop_units()` return
numeric. Setters may perform exact conversions but reject calendar conversion
without consent: callers must use `as_age(..., allow_approx = TRUE)`.
Unsupported mathematics and mixed casts error. `diff()` explicitly errors rather
than inheriting a silent ordinary-units return. Replacement requires same-unit
ages. These restrictions are prototypes, not additions to the published API.

This implementation deliberately exposes its remaining failures in a separate
safety suite. Base `as.data.frame()` and `as.list()` lose the subclass. The tibble
column header inherits units display (`[d]`), rather than Agecraft's `<age-day>`.
The numerical and type-retention tests for the tested tibble/dplyr workflows pass;
that does not establish complete display or ecosystem compatibility.

## Does vctrs construction solve class loss?

The follow-up [`hybrid-audit.R`](../../experiments/units-inheritance/hybrid-audit.R)
constructs two separate trial classes with `vctrs::new_vctr()`, starting from
valid units objects, with explicit proxy, restore, common-type and cast methods.
No conversion/setter/base vector adapters are installed for these trial classes.

| Class order after trial class | Vector/coercion probes retaining subclass |
| --- | ---: |
| units, vctrs_vctr, double | 3 of 8 |
| vctrs_vctr, units, double | 8 of 8 |

The eight probes are base slicing, vec_slice, base concatenation, vec_c,
repetition, unique, data-frame coercion, and list-element coercion. The script
asserts these benefits and records 24 total probes in
[`hybrid-audit.csv`](../../experiments/units-inheritance/results/hybrid-audit.csv).
This supplies concrete evidence for using the vctrs framework if inheritance is
revisited, rather than adding vctrs_vctr speculatively.

**Neither ordering preserves the subclass through units conversion or unit
replacement.** Those methods construct new objects without calling the trial
restorer. Vctrs-first also retains the mixed operator-dispatch problem described
below. Units-first rejects the tested mixed addition but loses more ordinary
vector operations. Numeric offsets require explicit arithmetic methods in either
case. Class order changes which library owns a generic; it is a design decision,
not a general guarantee of safe inheritance.

The class-order trial was not benchmarked. Following that trial, a second
mode of the production-shaped prototype constructs `c("age", "vctrs_vctr",
"units", "double")` and removes the explicit slicing, replacement,
concatenation, repetition and unique adapters. The shared contract suite passes
for this hybrid mode. Its separate safety suite passes both data-frame/list
checks and still fails the two mixed-arithmetic checks. See the hybrid test and
safety CSVs/log. Hybrid performance was not benchmarked; the performance tables
compare the baseline with the original two-class prototype.

## Safety failures and compatibility limits

The desired-safety suite intentionally remains failing:

1. Prototype age plus ordinary units fails to reject a calendar offset.
2. Ordinary units plus prototype age fails to reject a calendar offset.
3. Base data-frame coercion loses age.
4. Base list coercion loses age.

For the first two, R warns that `Ops.age` and `Ops.units` are incompatible, then
falls through to raw numeric addition. One year plus one month yields 2 in the
left representation. A warning is not adequate protection for this invariant.

**The mixed-operator issue also exists in the baseline**, where
`+.vctrs_vctr` conflicts with `Ops.units`; it is not introduced by this experiment.
See [`baseline-mixed-ops.txt`](../../experiments/units-inheritance/results/baseline-mixed-ops.txt).
It merits an independent production bug fix outside this experiment's
production-preservation scope. The data-frame/list losses are prototype
regressions; the baseline retains age there. Inheritance offers no demonstrated
solution to the existing mixed-operator issue.

The failed assertions and two operator warnings are preserved in
[`prototype-safety.log`](../../experiments/units-inheritance/results/prototype-safety.log).
The safety runner exits nonzero, so these failures cannot be mistaken for a
passing adoption gate. Normal contract tests do not claim to cover every R generic.

## Validation and benchmarks

Production validation:

| Check | Pass | Fail | Warnings | Skips/notes |
| --- | ---: | ---: | ---: | --- |
| Full production `devtools::test()` | 3424 | 0 | 0 | 1 optional mudnester skip |
| Baseline experiment contract | 283 | 0 | 0 | 2 prototype-only skips |
| Two-class prototype contract | 348 | 0 | 0 | 0 |
| Vctrs-first hybrid contract | 348 | 0 | 0 | 0 |
| Two-class desired-safety audit | 0 | 4 | 2 | Intentional nonzero exit |
| Hybrid desired-safety audit | 2 | 2 | 2 | Intentional nonzero exit |

`devtools::check(document = FALSE)` completed with 0 errors, 0 warnings and one
note identifying the nonstandard top-level `experiments` directory. Installed
production tests, examples and rebuilt vignettes passed. This checks the unchanged
production implementation, not an installed migration of the prototype. The
prototype and hybrid were checked separately in isolated source-loaded sessions;
the full production test suite was not redirected through either constructor.
Results and command summaries are in
[`production-validation.txt`](../../experiments/units-inheritance/results/production-validation.txt).
No roxygen regeneration was needed: public documentation and exports are unchanged.

The shared suite covers values, names, missing values, zero-length vectors,
constructor rejection, all 49 conversion pairs and round trips, approximation
consent, invalid dimensions (also empty/missing inputs), exact setter conversion,
calendar-setter rejection, offsets, comparisons, concatenation, slicing,
restoration and casting, selected summaries, and tibble/dplyr mutation, binding,
ordering and aggregation. It compares a captured baseline of numeric/display and
classification results, including `age_interval`, `age_group`, scheme membership,
matched interval output, and both directions of classification-time conversion.
Original category definitions remain in `group_intervals()` even when matching
converts boundaries internally. No floating-point tolerance is introduced into
production matching.

### Performance measurements

Identical deterministic vectors of 1, 1,000, 100,000 and 1,000,000 values
(repeating 1.25, 2.5 and NA) were used in separate baseline/prototype processes.
Each workload had three warm-up calls and seven measured iterations with
`bench::mark(check = FALSE, filter_gc = FALSE)`. Garbage-collecting iterations are
included. Allocation is measured R allocation per evaluated call, not peak
resident memory or all native-library allocations. Tiny-vector zero allocations
mean zero recorded allocations, not zero object cost. Preparation of inputs is
excluded except in the construction workload. Modes were measured sequentially
on this desktop, without CPU isolation; short validation processes and ordinary
background work may affect timing. These are exploratory measurements, not
performance acceptance thresholds.

Time ratio is prototype/baseline: below 1 is faster. Allocation is in MiB.
Full times, allocation ratios, iterations and GC counts are in
[`benchmark-comparison.csv`](../../experiments/units-inheritance/results/benchmark-comparison.csv).

| N | Operation | Baseline ms | Prototype ms | Time ratio | Baseline MiB | Prototype MiB |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | approximate conversion | 1.045 | 0.922 | 0.88 | 0.000 | 0.000 |
| 1 | arithmetic | 0.155 | 0.450 | 2.90 | 0.000 | 0.000 |
| 1 | comparison | 0.912 | 0.459 | 0.50 | 0.000 | 0.000 |
| 1 | concatenation | 1.061 | 5.892 | 5.55 | 0.000 | 0.000 |
| 1 | construction | 0.083 | 0.299 | 3.61 | 0.000 | 0.000 |
| 1 | exact conversion | 1.026 | 0.904 | 0.88 | 0.000 | 0.000 |
| 1 | subsetting | 0.116 | 0.491 | 4.24 | 0.000 | 0.000 |
| 1000 | approximate conversion | 8.504 | 9.431 | 1.11 | 0.081 | 0.073 |
| 1000 | arithmetic | 0.236 | 0.702 | 2.98 | 0.073 | 0.050 |
| 1000 | comparison | 0.990 | 0.458 | 0.46 | 0.104 | 0.019 |
| 1000 | concatenation | 1.271 | 7.159 | 5.63 | 0.315 | 0.269 |
| 1000 | construction | 0.103 | 0.334 | 3.23 | 0.042 | 0.027 |
| 1000 | exact conversion | 9.506 | 8.712 | 0.92 | 0.081 | 0.073 |
| 1000 | subsetting | 0.139 | 0.487 | 3.49 | 0.054 | 0.039 |
| 100000 | approximate conversion | 1193.563 | 1137.582 | 0.95 | 8.249 | 7.486 |
| 100000 | arithmetic | 2.045 | 4.476 | 2.19 | 7.249 | 4.960 |
| 100000 | comparison | 4.183 | 1.718 | 0.41 | 10.301 | 1.908 |
| 100000 | concatenation | 14.932 | 19.483 | 1.30 | 31.283 | 26.705 |
| 100000 | construction | 3.766 | 3.069 | 0.81 | 4.197 | 2.671 |
| 100000 | exact conversion | 1307.403 | 1175.882 | 0.90 | 8.249 | 7.486 |
| 100000 | subsetting | 1.900 | 1.777 | 0.94 | 5.341 | 3.815 |
| 1000000 | approximate conversion | 12969.244 | 12815.703 | 0.99 | 80.480 | 72.850 |
| 1000000 | arithmetic | 22.096 | 26.365 | 1.19 | 72.480 | 49.592 |
| 1000000 | comparison | 46.179 | 3.305 | 0.07 | 102.998 | 19.074 |
| 1000000 | concatenation | 182.660 | 181.428 | 0.99 | 312.807 | 267.031 |
| 1000000 | construction | 23.088 | 17.559 | 0.76 | 41.962 | 26.703 |
| 1000000 | exact conversion | 13025.397 | 12715.638 | 0.98 | 80.480 | 72.850 |
| 1000000 | subsetting | 21.009 | 13.215 | 0.63 | 53.406 | 38.147 |

At one million elements, exact conversion took 13.025 seconds in the baseline
and 12.716 seconds in the two-class prototype; approximate conversion took
12.969 and 12.816 seconds. This does not establish a meaningful conversion-engine
improvement: both run through the same installed units conversion loop.
Construction and slicing were faster at that size, and comparison was markedly
faster with substantially less measured allocation. Arithmetic was 19% slower;
concatenation was effectively similar. At small sizes, construction, arithmetic,
slicing and concatenation incurred substantially more overhead. These mixed
results do not support a blanket speed claim. The hybrid was not benchmarked,
so neither the gains nor the overheads should be attributed to it.

The machine was an AMD Ryzen 5 1600 (six cores, twelve hardware threads), x86_64.
CPU, package-version and session records are included in the results directory.
Conversion calls, rather than the numeric vector operations, dominated runtime.

## Dependency and maintenance assessment

`units` is already an Imports dependency of agecraft, so this experiment adds
no installation dependency. The [CRAN metadata](https://cran.r-project.org/package=units)
identifies compiled code, Rcpp and UDUNITS2 requirements, and supplies Windows
and macOS binaries. Binary availability is not proof that source installation
works on every platform. For source installation, the
[upstream installation guide](https://r-quantities.github.io/units/) lists
`libudunits2-dev` on Debian/Ubuntu, `udunits2-devel` on Fedora, and Homebrew
`udunits` on macOS. Windows source builds require the matching build toolchain
and UDUNITS2 setup; that was not tested here. No macOS, Windows, CRAN submission,
or multi-version dependency tests were run. Existing reliance on these system
libraries remains unchanged by subclassing.

A reproducible nonblank, non-comment line count gives 92 lines in age-class.R
and 25 in age-arithmetic.R, versus 169 in the shared two-mode prototype (including
registration scaffolding and the hybrid option). Even replacing all 117 existing
lines would increase this rough count by 52; in practice the prototype reuses existing validators,
classification, type-label helpers and conversion-policy helpers, so 117 is an
overestimate of removable code. The shared eight-line conversion adapter still
serves intervals. The prototype adds no conversion engine and removes none.
These are source-line estimates, not a complete migration diff or a promise of
52 net added production lines. Test and report code is excluded.

The hybrid trial shows that vctrs-first order could remove several explicit base
adapters, but guard setters, arithmetic rules, same-unit casts, display and
validation would remain. Requiring two representations of unit metadata adds
synchronization risk until consumers migrate. Ongoing costs include S3 dispatch
across two vector libraries, inherited methods returning new superclass objects,
upstream method changes, explicit mixed-type policies, and saved-object/class
compatibility. Inheritance alone does not justify these costs at present.

## Reproducing the experiment

Run these from the repository root in separate fresh R processes:

```sh
Rscript experiments/units-inheritance/audit.R
Rscript experiments/units-inheritance/baseline-mixed-ops.R
Rscript experiments/units-inheritance/run.R baseline
Rscript experiments/units-inheritance/run.R prototype
Rscript experiments/units-inheritance/hybrid-audit.R
Rscript experiments/units-inheritance/run.R hybrid
Rscript experiments/units-inheritance/safety-audit.R
Rscript experiments/units-inheritance/safety-audit.R hybrid
Rscript experiments/units-inheritance/summarize.R
```

Run each command independently; the two safety commands are expected to exit 1,
with four and two failed
assertions respectively. Add `--tests-only` to the baseline/prototype runner to
repeat validation without rerunning slow conversion benchmarks. Baseline and
prototype benchmark runs must be sequential and on an otherwise idle machine.
The runner requires the existing development dependencies and bench for allocation
measurement; dplyr is optional and was available here. Results are observations
on this machine, not cross-platform performance guarantees.

Production remains on the existing vctrs representation pending a go/no-go decision.

## Follow-up: faster comparisons without units inheritance

A separate [baseline comparison investigation](../../experiments/comparison-performance/report.md)
found that casting and repeated value validation dominate equality comparisons.
A session-only same-class cast candidate uses scalar minimum/maximum reductions
to preserve validation while reducing temporary allocations. Fresh paired
million-element measurements showed equality improving from 84 to 19 ms and
ordering from 46 to 14 ms, with roughly half the allocation. The workloads differ
from the original inheritance benchmark; see that report for limits. The existing
3,424-assertion package suite passed with the candidate active. No production
source was changed. This provides a route to improving the existing class
without adopting units inheritance.
