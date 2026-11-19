# Comparison performance in the existing age class

Investigated November 18, 2026 on `experiment/units-inheritance`, following the
units-inheritance benchmark. Production sources and `main` are unchanged.

## Finding

The baseline comparisons already use vectorized vctrs operations. The large
cost comes from same-class casts reconstructing and validating both operands,
not from an R loop comparing individual ages. A cheaper validation reduction
improves comparison performance without introducing units inheritance or
removing the nonnegative/finite/missing-value safeguards.

The profile of 50 equality comparisons of million-element age vectors attributed
85.1% of sampled time to `vec_cast.age.age()` and 85.5% to `new_age()` (inclusive,
not additive). See `baseline-profile.csv`. Sampling interval was 10 milliseconds;
these percentages are approximate and this run profiled equality only.

The path is:

1. `==.vctrs_vctr()` delegates to `vctrs::vec_equal()`.
2. Common-type handling casts the two age operands.
3. `R/age-class.R`'s `vec_cast.age.age()` calls `new_age()` for each.
4. `new_age()` checks values using several length-n logical expressions:
   `!is.na(x) & (!is.finite(x) | x < 0)`.

Those checks allocate temporary vectors and trigger further garbage collection.
The final comparison is already vectorized.

## Candidate

`candidate.R` supplies a session-only replacement for `vec_cast.age.age()`.
It retains matching-unit enforcement, unit validation, names, class and values.
For value validation it computes minimum and maximum with `na.rm = TRUE` and
explicit Inf/-Inf sentinels, using compiled scalar reductions rather than
length-n logical temporaries. It handles empty/all-missing inputs separately,
rejects negative or infinite present values, and permits NA/NaN like the baseline.
It still constructs a validated age vector and uses the existing vctrs comparison
implementation. No direct comparison operator is added.

For an eventual production implementation, prefer a shared private validation
helper used by the constructor and casts, rather than duplicating construction
logic. This candidate isolates the performance hypothesis; it is not installed
or adopted by the package.

## Measurements

Same-class, same-unit ages with deterministic values repeating 0, 1.25, 2.5,
NA and NaN were compared against a reversed copy. Each case used three warm-ups
and 15 measured iterations with `bench::mark(filter_gc = FALSE)`. Timings include
GC iterations; allocation is recorded R allocation per call, not peak memory.
Baseline and candidate ran in the same process, sequentially. No timing threshold
was added to tests. The desktop was not CPU-isolated. See `benchmarks.csv` for
all four vector sizes, allocation totals, iteration counts and GC counts.

| Size | Operation | Baseline ms | Candidate ms | Speedup | Baseline MiB | Candidate MiB |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | `==` | 0.867 | 0.866 | 1.00× | 0.000 | 0.000 |
| 1 | `<` | 0.922 | 0.897 | 1.03× | 0.000 | 0.000 |
| 1,000 | `==` | 0.905 | 0.865 | 1.05× | 0.104 | 0.050 |
| 1,000 | `<` | 0.976 | 0.933 | 1.05× | 0.108 | 0.054 |
| 100,000 | `==` | 4.367 | 1.867 | 2.34× | 10.301 | 4.960 |
| 100,000 | `<` | 4.513 | 2.090 | 2.16× | 10.683 | 5.341 |
| 1,000,000 | `==` | 84.238 | 19.282 | 4.37× | 102.998 | 49.592 |
| 1,000,000 | `<` | 45.852 | 13.764 | 3.33× | 106.813 | 53.407 |

The million-element equality baseline is slower here than in the original
inheritance experiment (84 versus 46 ms). These workloads also differ: this
follow-up includes zeros and NaNs and compares a distinct reversed vector,
whereas the original benchmark compared a vector with itself. Timing and garbage
collection also vary. Use the fresh paired comparison, not a ratio across the
two experiments. Tiny-vector performance is essentially unchanged. The candidate
reduces large-vector allocation by about half, and the observed speedup is
substantial without changing representation. These results do not establish that
every operation or platform would improve by the same amount.

## Validation

Focused checks passed 60 assertions. They compared all six comparison operators
against the original outputs, including names, fractional values, NA, NaN,
scalar recycling, empty vectors and incompatible sizes. They also checked unit
mismatches, comparisons with bare numeric values, exact cast representation,
very large finite values, and rejection of deliberately invalid negative/infinite
or invalid-unit age objects.

The existing package suite also passed with the candidate cast active: 3,424
assertions, zero failures, zero warnings and one optional mudnester skip.
The runner verified the candidate registration was still installed after the
suite. The command and final output are preserved in `validation.txt`.

No `R CMD check` was run for this session-only replacement, which cannot be
validated as an installed production change without a source implementation.
The earlier production checks for the inheritance experiment remain separate.

## Reproduce

From the repository root, in fresh R processes:

```sh
Rscript experiments/comparison-performance/investigate.R
Rscript experiments/comparison-performance/check.R
```

The first script records focused checks, benchmarks and a baseline profile. The
second temporarily mocks the cast method in the loaded namespace and S3 table
so existing mock-based tests cannot silently reset it, runs the existing package
suite, and verifies that the candidate registration is still active afterward.
Neither script changes the package files on disk.
