# age_group contract

An age_group is an integer ordered-factor subclass with classes
`c("age_group", "ordered", "factor")`. It stores assignments, not original
ages or scheme provenance. The intervals attribute contains one age_interval interval
per level, in chronological order; levels are unique nonblank labels. Observation
names are independent of category names. Missing and unmatched ages use NA.

## Agreed contracts

1. Subsetting preserves every level and definition. Explicit droplevels removes
   unused levels and corresponding intervals together.
2. Combining requires identical ordered bounds, labels and definition units.
   Conflicting cosmetic symbols normalize to age_interval defaults. Mixing with
   ordinary factors or character vectors requires explicit conversion.
3. Unique nonblank relabeling is allowed. Reordering, implicit merging and
   structural edits are rejected. New boundaries require reclassification from
   original ages; disconnected categories cannot become one interval.

Construct with age_group(x, intervals), where x is character labels or a factor.
Retrieve definitions with group_intervals(). Empty definitions and observations
are allowed. Definition intervals must be present. Duplicate identical intervals
with the same label are collapsed by categorize_age for legacy factor behavior;
identical intervals with distinct labels remain separate categories.

The legacy units attribute records original observation units, while intervals
stores definition units. Combining drops differing observation-unit attributes;
it never changes definition coordinates. Unitless input groups inherit the
observation unit. Interval output remains unchanged.

Base and vctrs slicing, repetition, concatenation and replacement preserve the
mapping. Use vctrs::vec_rbind for binding: base rbind.data.frame reconstructs
factors internally and may discard the subclass and metadata.
Explicit generics::as.factor/as.ordered conversion drops metadata; base
as.factor/as.ordered return existing factor subclasses unchanged.
Arbitrary attr/class mutation bypasses S3 validation and is unsupported.

Printing identifies the class, length and category-definition unit. vctrs full
type descriptions use `age_group [week]`, for example; abbreviated descriptions
use `aGrp-week`. Unitless definitions display `unspecified` in the full description, `unk` in the
abbreviation and `unknown` in the print header.

## Compatibility

categorize_age factor output gains this subclass and intervals metadata. Factor
codes, readable labels and ordered status remain. Exact class/attribute checks
and previously permissive factor combinations may require changes. age_cat_iv
retains its existing output. No interval matching algorithm changes.

## Reused class name and legacy objects

Before the naming refactor, age_group was an ivs interval record. Only the
integer ordered-factor representation is an assignment. is_age_group checks
that distinction without acting as a full metadata validator. Dispatched group
methods reject old ivs records with a message directing reconstruction through
age_interval(). Validation precedes proxy/prototype, coercion, slicing, binding,
comparison, replacement, formatting and print operations owned by this class.
The coercion/format methods forward valid assignments to ordinary factor methods.
No methods are added to bare ivs intervals. Not every inherited or base operation
can be intercepted; migrate old objects before using them. See the migration guide.
