# age_category contract

An age_category is an integer ordered-factor subclass with classes
`c("age_category", "ordered", "factor")`. It stores assignments, not original
ages or scheme provenance. The groups attribute contains one age_group interval
per level, in chronological order; levels are unique nonblank labels. Observation
names are independent of category names. Missing and unmatched ages use NA.

## Agreed contracts

1. Subsetting preserves every level and definition. Explicit droplevels removes
   unused levels and corresponding intervals together.
2. Combining requires identical ordered bounds, labels and definition units.
   Conflicting cosmetic symbols normalize to age_group defaults. Mixing with
   ordinary factors or character vectors requires explicit conversion.
3. Unique nonblank relabeling is allowed. Reordering, implicit merging and
   structural edits are rejected. New boundaries require reclassification from
   original ages; disconnected categories cannot become one interval.

Construct with age_category(x, groups), where x is character labels or a factor.
Retrieve definitions with category_groups(). Empty definitions and observations
are allowed. Definition intervals must be present. Duplicate identical intervals
with the same label are collapsed by categorize_age for legacy factor behavior;
identical intervals with distinct labels remain separate categories.

The legacy units attribute records original observation units, while groups
stores definition units. Combining drops differing observation-unit attributes;
it never changes definition coordinates. Unitless input groups inherit the
observation unit. Interval output remains unchanged.

Base and vctrs slicing, repetition, concatenation and replacement preserve the
mapping. Use vctrs::vec_rbind for binding: base rbind.data.frame reconstructs
factors internally and may discard the subclass and metadata.
Explicit generics::as.factor/as.ordered conversion drops metadata; base
as.factor/as.ordered return existing factor subclasses unchanged.
Arbitrary attr/class mutation bypasses S3 validation and is unsupported.

## Compatibility

categorize_age factor output gains this subclass and groups metadata. Factor
codes, readable labels and ordered status remain. Exact class/attribute checks
and previously permissive factor combinations may require changes. age_cat_iv
retains its existing output. No interval matching algorithm changes.
