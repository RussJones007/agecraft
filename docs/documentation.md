# Instructions for writing R package documentation

Use these instructions whenever you create or revise documentation in this package: roxygen2 help, class references, vignettes, README content, and other guides. Write for someone who knows R but has not read the source. Help that person choose an approach, use it correctly, and understand the result. Sections 1–8 retain the detailed function and roxygen guidance; sections 9–14 extend it to classes, longer narratives, and the documentation ecosystem.

These instructions apply to help topics, argument descriptions, examples, and related package documentation. Follow established package terminology and genuine API contracts. Do not change function behavior merely to make a documentation example work.

## 1. Write for the person using the function

Explain what the reader can do, what they must supply, and what they receive. Give enough detail to use the function without tracing its implementation. Concision is useful only when it preserves that information.

- Start with the task or result. Prefer concrete verbs such as select, combine, count, convert, read, and write.
- Use ordinary sentences and familiar R terms: vector, list, data frame, tibble, column, row, named vector, factor, missing value, and class.
- Address the reader directly when giving instructions: “Use `NULL` to keep all columns.” Avoid repeating “the user.”
- Explain package-specific concepts before relying on them. Do not explain basic R syntax unless it is needed to prevent a likely mistake.
- Describe observable behavior precisely. “Rows remain in their original order” is more useful than “The function preserves data integrity.”
- Let the length follow the function's complexity. A short wrapper may need little explanation; a function with grouping, recycling, or interval rules may need several sections.

Sound like a knowledgeable colleague explaining a useful function. Avoid promotional claims, generic introductions, mechanical repetition, and inflated words such as “seamlessly,” “robust,” “powerful,” and “leverages.” Do not add conversational filler to make prose sound human.

For example:

**Weak:** “This utility facilitates flexible processing of input objects.”

**Better:** “Combine monthly observations into one row per year.”

**Too compact:** “`weights`: Weights.”

**Useful:** “A numeric vector with one weight per observation. Weights must be non-negative. Use `NULL` to give each observation equal weight.”

The better wording is appropriate only if those constraints match the actual function.

## 2. Establish the contract before writing

Read the function signature, existing help, relevant tests, and enough source to establish behavior. Inspect related functions to keep terminology consistent. Prefer the project's code discovery tools when available.

Determine which of the following matter:

- Accepted types, classes, lengths, names, and dimensions.
- Meaning of defaults, `NULL`, empty inputs, and missing values.
- Whether arguments use ordinary evaluation, data masking, or tidy selection.
- Output type, size, names, ordering, grouping, and attributes.
- Matching, sorting, duplicate handling, recycling, and coercion rules.
- Warnings, errors, side effects, and external requirements.

Do not infer a public guarantee from one successful example or an incidental implementation detail. If tests, code, and existing help disagree, resolve the discrepancy before documenting a confident claim. If it cannot be resolved, identify the specific uncertainty to the maintainer; do not bury it in polished prose.

## 3. Keep implementation history out of reference help

Reference documentation should explain the current function. It should not read like a description of the latest patch.

Apply this test to every technical detail: **Would knowing this change how someone calls the function, interprets its result, or handles a limitation?** If yes, explain its practical consequence. Otherwise, put it in an implementation comment, developer documentation, commit message, or pull request description.

| Detail discovered while editing | Appropriate treatment |
| --- | --- |
| An internal helper was replaced | Omit from user help unless behavior changes. |
| A join strategy changed but results are equivalent | Keep in developer notes. |
| Unmatched identifiers produce missing output values | Explain the matching rule and its consequence. |
| Duplicate keys now trigger an error | Document the current restriction; describe migration in NEWS if relevant. |
| A cache changes freshness or writes local files | Explain freshness, location, and controls that affect users. |
| An algorithm has a meaningful accuracy limitation | Explain the limitation and when it matters. |

**Implementation-focused:** “The function now delegates interval matching to a vectorized helper.”

**User-focused:** “An observation on a boundary belongs to the interval that starts at that boundary.”

Use the second statement only when it describes the real boundary rule. Do not invent an observable effect to justify mentioning a refactor.

Avoid “now,” “previously,” “updated,” “refactored,” and “fixed” in ordinary reference prose. Use NEWS for release history. Retain explicit deprecation and migration guidance when readers need it, including the replacement and any consequential differences.

## 4. Organize roxygen2 topics consistently

Use this general order, adapting it to the existing package style:

1. A short title.
2. A description of purpose and central behavior.
3. Argument documentation.
4. Return value.
5. Details or named sections where needed.
6. Related functions and examples.
7. Package metadata tags such as `@export`, where appropriate.

Roxygen tags determine rendered sections; their source order is primarily for maintainability. Do not add empty sections or repeat the same explanation under several tags.

Use roxygen Markdown when enabled by the package, commonly through `Roxygen: list(markdown = TRUE)` in DESCRIPTION. Check the existing setup before introducing Markdown-dependent markup. Do not hand-edit generated `man/*.Rd` files when their source is roxygen comments.

### Title

Use a brief sentence-case phrase describing the task, without a final period. Avoid “A function to …” and titles that merely repeat the function name.

```r
#' Convert counts to proportions
```

### `@description`

Answer “What does this do, and when would I use it?” State the main transformation or result and any central constraint needed to choose the function. Do not begin with a tour of internal steps.

A single introductory paragraph can supply the description without an explicit tag. Use `@description` when multiple paragraphs or a list make the boundary clearer.

```r
#' Convert counts to proportions
#'
#' @description
#' Divide each count by the total count. Use this to express category counts
#' as shares of the whole.
#'
#' Missing counts remain missing. Set `na.rm = TRUE` to calculate the total
#' from the observed counts.
```

Do not compress all argument rules into the description. Put each rule where a reader will look for it, and use a short pointer if a crucial caveat needs to appear early.

### `@param`

Document every argument, including `...`. Describe the accepted input first, then its meaning and important constraints. Explain the effect of the default when it is not obvious from the signature.

Cover only relevant properties, but do not leave readers guessing about:

- Whether an input is a scalar or vector, and how its length relates to other inputs.
- Accepted values, ranges, units, classes, and required columns.
- The difference between `NULL`, `NA`, an empty vector, and an omitted argument.
- Whether column names are supplied as strings, bare names, or selection expressions.
- Whether a path names a file or directory, and whether existing files are overwritten.

Write complete sentences with punctuation. Match argument names exactly. Explain related arguments together only when each meaning remains clear. Use `@inheritParams` for genuinely identical contracts, checking the inherited text in its new context.

```r
#' @param x An unclassed integer or double vector of counts. Values must
#'   be non-negative and finite, apart from missing values (`NA` or `NaN`).
#' @param na.rm A single logical value. If `TRUE`, omit missing counts when
#'   calculating the total. Missing elements of `x` remain missing in the
#'   result.
```

For tidy evaluation, state the actual interface. These are alternative patterns for different APIs, not interchangeable descriptions:

```r
#' @param value <[`data-masking`][dplyr::dplyr_data_masking]> An expression
#'   that evaluates to a numeric vector in `data`.
#' @param cols <[`tidy-select`][dplyr::dplyr_tidy_select]> Columns to include.
#' @param column A single string giving the name of a column in `data`.
```

Check that links resolve and that any referenced package is appropriate for the package's documentation dependencies. Do not label a character argument as tidy selection just because it identifies columns.

For `...`, name the receiving function and relevant restrictions when arguments are forwarded. If dots are reserved and must be empty, say so. “Additional arguments” alone is rarely enough.

### `@return`

Describe the object the caller receives, not just the calculation. State its class or type and its length or dimensions where meaningful. Include names, ordering, grouping, attributes, and missing-value behavior when they affect subsequent work.

For data frames, explain the unit represented by a row and identify newly created columns. State whether inputs are retained or replaced. For lists, describe named components and their types. For functions called for side effects, explain the side effect and any invisible return value.

```r
#' @return A double vector with the same length and names as `x`. Each
#'   non-missing count is divided by the total. If `na.rm = FALSE` and `x`
#'   contains a missing value, every element of the result is `NA`.
```

Avoid vague text such as “The processed data” or “An object containing results.” Do not claim a tibble, preserved attributes, or an invisible return without checking.

### `@details` and `@section`

Use details for behavior readers need beyond the basic call. Good topics include boundary rules, group handling, zero denominators, matching policies, interpretation, and practical limitations.

Prefer an explanation followed by a small example to a dense list of implementation steps. Use named sections when several topics would otherwise form a long paragraph.

```r
#' @details
#' The total must be greater than zero. A vector of zero counts produces
#' an error because proportions are undefined when the total is zero.
```

Do not create a details section simply to repeat arguments. Include mathematical notation or algorithms when they help interpret the output, establish a necessary assumption, or explain a consequential tradeoff. Keep helper names and control flow in source comments.

### `@examples`

Teach the common call first, then one or two important variations. Examples should answer questions a reader is likely to have.

- Use small built-in, package-provided, or locally constructed data.
- Show enough setup for a reader to run the example as written.
- Use meaningful names and short comments that explain intent.
- Make grouping, missing values, or a non-obvious default visible when relevant.
- Keep examples deterministic, quick, and independent of the reader's machine.
- Avoid network access, credentials, interactive prompts, permanent option changes, and writes to personal files.
- For file examples, use temporary paths and clean up only files created by the example. Restore changed options or other session state.
- Set a seed when randomness is necessary to the lesson.

Do not wrap ordinary examples in `\dontrun{}` to hide failures. Use it only for examples that genuinely cannot run automatically, with a reason. Use `@examplesIf` for a justified executable condition, such as an optional dependency being installed. Do not assume `\donttest{}` is a guarantee that code will never execute during checks.

Avoid intentional errors in runnable examples unless handled deliberately and transparently; explain invalid inputs in prose when that is clearer. Do not turn examples into an exhaustive test suite.

## 5. Complete worked example

The following is an original, self-contained teaching example. Its implementation is included so the documented contract can be checked. Adapt the pattern to the actual package API; do not copy its behavior into an unrelated function.

```r
#' Convert counts to proportions
#'
#' Divide each count by the total count. Use this to express category counts
#' as shares of the whole.
#'
#' @param x An unclassed integer or double vector of counts. Values must
#'   be non-negative and finite, apart from missing values (`NA` or `NaN`).
#' @param na.rm A single non-missing logical value. If `TRUE`, omit missing
#'   counts when calculating the total. Missing elements remain missing in
#'   the result.
#'
#' @return A double vector with the same length and names as `x`. If
#'   `na.rm = FALSE` and `x` contains a missing value, every element of the
#'   result is `NA`. An empty input returns an empty double vector.
#'
#' @details
#' The total must be greater than zero. Zero counts and, when
#' `na.rm = TRUE`, inputs containing only missing values produce an error.
#' An error also occurs if the total exceeds the finite numeric range.
#'
#' @examples
#' counts <- c(north = 12, south = 8, west = 5)
#' count_proportions(counts)
#'
#' # Calculate shares using the observed counts.
#' count_proportions(c(north = 12, south = NA, west = 8), na.rm = TRUE)
#'
#' @export
count_proportions <- function(x, na.rm = FALSE) {
  if (!is.numeric(x) || !is.null(dim(x)) || is.object(x)) {
    stop("`x` must be an unclassed numeric vector.", call. = FALSE)
  }
  if (!is.logical(na.rm) || length(na.rm) != 1L || is.na(na.rm)) {
    stop("`na.rm` must be a single non-missing logical value.", call. = FALSE)
  }
  observed <- x[!is.na(x)]
  if (any(!is.finite(observed)) || any(observed < 0)) {
    stop("Counts must be finite and non-negative.", call. = FALSE)
  }
  out <- as.double(x)
  names(out) <- names(x)
  if (length(out) == 0L) return(out)
  if (!na.rm && anyNA(out)) {
    out[] <- NA_real_
    return(out)
  }
  total <- sum(out, na.rm = na.rm)
  if (!is.finite(total) || total <= 0) {
    stop("The total must be finite and greater than zero.", call. = FALSE)
  }
  out / total
}
```

The example states the accepted numeric types and treats both `NA` and `NaN` as missing. Review these distinctions for each actual API instead of assuming that “numeric” conveys every constraint.

## 6. Formatting, links, and shared topics

- Put one space after `#'`. Indent wrapped argument text by two additional spaces. Follow the package's line-width convention, usually about 80 characters.
- Use backticks for argument names, literal values, column names, classes, and short R expressions. Include parentheses when referring to a function in prose: `sum()`.
- Use roxygen links such as `[related_function()]` and `[otherpkg::function()]` when a help link would be useful. Check links in rendered help.
- Use sentence case for headings. Use periods for descriptive sentences; omit the final period in a short title.
- Prefer bullets for parallel options or output components. Use prose for explanations that build on one another.
- Use `@seealso` to help readers choose a related function; explain the relationship instead of supplying an unexplained list.
- Use `@family`, `@rdname`, and inheritance where they improve navigation and maintainability. Shared pages must still explain differences between functions.
- Add lifecycle guidance only when the package has adopted that status. Do not invent experimental or deprecated labels.
- Keep internal-function documentation useful to maintainers without exposing it as a public API by accident. Use the package's established `@noRd` or internal-topic conventions; `@keywords internal` does not itself prevent export.

## 7. Revision and verification workflow

1. Establish the current behavior and intended audience.
2. Read neighboring help topics for vocabulary and conventions.
3. Draft the purpose, inputs, and output before adding optional details.
4. Check every factual claim against the implementation and relevant tests.
5. Read the prose as someone encountering the function for the first time. Replace vague statements with concrete information and remove patch history.
6. Run runnable examples and regenerate documentation using the package's usual process, commonly `devtools::document()`.
7. Inspect generated help for broken links, malformed lists, missing arguments, and misplaced text. Use `help()` or preview the pkgdown page when available.
8. Run documentation checks and the relevant package checks appropriate to the change. Review generated diffs for unintended namespace or unrelated documentation changes.

Do not claim to have run a check that was unavailable. Report the specific unverified part. Documentation-only work should not introduce unrelated API or dependency changes.

## 8. Documentation quality checklist

### Purpose and voice

- [ ] The title names a concrete task or result.
- [ ] The opening explains when and why someone would use the function.
- [ ] The prose sounds natural when read aloud and uses consistent R terminology.
- [ ] The explanation is detailed enough to use without reading source code.
- [ ] There is no filler, promotion, unexplained jargon, or repetitive scaffolding.

### Inputs and output

- [ ] Every argument, including `...`, is documented accurately.
- [ ] Types, lengths, units, defaults, and required structure are clear where relevant.
- [ ] Ordinary evaluation, data masking, and tidy selection are distinguished correctly.
- [ ] Relevant `NULL`, `NA`, `NaN`, empty-input, duplicate, and boundary behavior is covered.
- [ ] The return type, shape, names, ordering, and important attributes are specified.
- [ ] Side effects, external requirements, warnings, and errors are described when needed for correct use.

### User-facing scope

- [ ] Details explain decisions or interpretation that matter to callers.
- [ ] Internal helper names, refactoring narratives, and release-history prose are absent.
- [ ] Necessary migration guidance explains what readers should do.
- [ ] Every stated guarantee is supported; incidental behavior is not promoted into a contract.

### Examples and rendered help

- [ ] The first example shows the common use with minimal setup.
- [ ] Further examples teach important variations without becoming tests.
- [ ] Runnable examples work and do not depend on private files or credentials.
- [ ] Conditional or non-running examples have a concrete justification.
- [ ] Roxygen tags, Markdown, inheritance, and links render correctly.
- [ ] Generated documentation matches its source, and relevant checks have been reviewed.

## 9. Give each part of the documentation a clear job

Documentation should work as a connected system. A reader should be able to move
from discovering the package to learning a workflow, understanding its concepts,
and checking an exact contract without encountering contradictory explanations.

| Document | Main question it answers |
| --- | --- |
| README or package overview | What problem does this solve, and where should I start? |
| Function or method reference | How do I call this operation, and what does it guarantee? |
| Class reference | What does this object mean, and which properties and operations can I rely on? |
| Tutorial vignette | How do I accomplish a first useful task with guidance? |
| Conceptual vignette | How should I understand these ideas and their consequences? |
| Workflow vignette | How do I make and justify decisions across a realistic task? |
| NEWS and migration guide | What changed, and what must I adapt? |
| Developer design documents | Why is the implementation organized this way, and what is proposed? |

Keep the authoritative explanation of a contract in reference help. Vignettes
should develop its meaning through use and link to the precise rules. A README
should offer a manageable entry point rather than reproduce every vignette.
Cross-links should describe why to follow them: “See the interval reference for
boundary and missing-value rules” is more helpful than “See also.”

Distinguish implemented behavior from proposals and historical descriptions.
Resolve disagreements using the current API policy, implementation, and tests;
do not copy a design proposal into user documentation as an available feature.
When a contract changes, review every affected reference, vignette, README
example, and migration note for consistency.

## 10. Document classes separately from their constructors

A constructor explains how to create an object. A class reference explains what
the object represents and how it behaves throughout its use. A class vignette
teaches the reasoning behind that model and follows objects through meaningful
operations. These are distinct responsibilities even when a small API shares a
help topic for its constructor and class.

### Class reference and public invariants

Provide a discoverable class topic for a substantive public S3 or S4 class. If it
shares a constructor page, give class behavior explicit sections and suitable
aliases so readers can find it without knowing the constructor's name. Use the
package's roxygen conventions for class topics and verify the generated help
aliases; a heading alone does not make a class searchable through help.

Cover the following where they form part of the public contract:

- Meaning: what one element or one object represents, and why the class exists.
- Public invariants: valid values, lengths, dimensions, units, missingness,
  boundary rules, and required relationships among components.
- Creation and validation: supported constructors, coercions, predicates, and
  validators, including what each actually checks. A class predicate need not
  establish that an object is valid.
- Inspection: supported accessors and the meaning of printed or summarized
  output. Distinguish display from stored values when they differ.
- Operations: subsetting, combining, comparison, arithmetic, replacement, and
  coercion where supported. State what is preserved, changed, or rejected.
- Relationships: inheritance, containment, conversion, and association with
  related classes. Do not describe containment as inheritance or imply that
  conversion is lossless without evidence.
- Limits: unsupported operations and information lost on conversion or export,
  where knowing this prevents misuse.

For S3, explain supported generic behavior and accessors rather than teaching
readers to construct arbitrary lists or alter attributes directly. For S4,
document relevant formal inheritance, public slots if they are an intended
interface, validity requirements, and supported accessors. Do not expose private
storage merely because it is visible in source. Document subclass extension
contracts only when extension is supported; distinguish instructions for class
authors from ordinary use. General S4 guidance here does not imply that Agecraft
has S4 classes or needs them.

Describe important methods near the class overview and link to their detailed
help. A method reference should explain how its behavior differs from the generic
and which arguments, return properties, or restrictions are class-specific.
Readers should be able to find the behavior through both the generic and class
navigation without maintaining duplicate, diverging contracts.

### Constructors and class vignettes

Keep constructor reference focused on accepted inputs, defaults, validation,
normalization, and the returned class. Link to the class contract for later
operations. Explain any distinction between a public constructor and an internal
low-level constructor; do not recommend bypassing validation for routine use.

A class vignette should introduce the problem the representation solves, create
an object, inspect it, use relevant operations, and explain consequences. It
should not simply expand the constructor's argument list into prose or catalogue
every method. Link to reference help for the full operation inventory.

For Agecraft, distinguish age values, interval definitions, categorical
assignments, and schemes. An `age_scheme` contains `age_interval` definitions;
an `age_group` represents categorical assignments with associated interval
definitions. Explain how these roles connect without suggesting they are
interchangeable. Check current class contracts before supplying detailed examples,
particularly after naming migrations. A useful class explanation might contrast
printed completed ages with stored fractional values, then show why the stored
value matters for classification.

## 11. Choose a vignette's teaching purpose

Choose the primary audience, starting knowledge, and learning outcome before
writing code. A vignette needs a reason to exist beyond demonstrating functions.
State the reader's task or question early, identify necessary prerequisites, and
make the intended result clear without a long administrative preamble.

| Type | Teaching purpose | Appropriate progression |
| --- | --- | --- |
| Tutorial | Guide a reader through a first successful task | Establish a small problem, supply data, guide essential steps, inspect the result, and suggest a next task. |
| Conceptual | Develop a mental model and explain consequential distinctions | Pose a question, introduce ideas in dependency order, use focused examples, and explain implications and limits. |
| Workflow | Show decisions and connected operations in a realistic setting | Establish the analytical objective, inspect inputs, justify choices, carry results forward, and assess the final result. |
| Hybrid | Combine conceptual understanding with a guided task or workflow | Keep one primary purpose and introduce supporting concepts where the task makes them necessary. |

These are editorial choices, not mandatory labels or rigid templates. A tutorial
can explain concepts; a workflow can pause to teach a new operation. A hybrid
needs a coherent path rather than alternating unrelated mini-tutorials. Split a
vignette when audiences or prerequisites diverge enough that one group must read
substantial material unrelated to its task.

A useful learning outcome names what the reader can decide or accomplish:
“Choose age boundaries and explain how boundary observations are classified” is
more informative than “Learn about age intervals.” Keep reference-level edge
cases in linked help unless they are central to that outcome.

## 12. Build a narrative that advances the reader's reasoning

Plan the progression of ideas before arranging code chunks. Each section should
answer a question raised by the preceding material or prepare a decision needed
later. Introduce concepts before relying on them, then deepen the explanation
when the reader has a concrete reason to care.

For example, a reporting workflow could develop from “What age does each record
represent?” to “Which boundaries match the reporting purpose?”, then “How are
records assigned?” and finally “What do these counts support?” This connects age
calculation, units, interval definitions, classification, and interpretation
through a single analytical objective. It is an editorial outline, not a promise
that every possible reporting operation is provided by Agecraft.

### Use transitions to connect decisions

Explain why the next step follows. Prefer a sentence tied to the result or an
unresolved choice over “Next, we use another function.” For example:

> The counts depend on where the boundaries fall. Before summarizing the
> records, we need to decide which interval includes an observation exactly at
> a boundary.

A transition can introduce a limitation, compare alternatives, or carry a result
into a new question. It need not recap everything the reader has just seen.
Headings should express meaningful questions, tasks, or concepts rather than
repeat function names unless the function itself is the subject.

### Vary the form to match the explanation

Do not repeat an introduction–code–explanation pattern mechanically for every
chunk. Sometimes a short question and a result are enough; sometimes several
chunks belong inside one developing argument. Use prose without code for a
conceptual distinction, a compact table for alternatives, or an annotated result
when the reader needs help interpreting it. Place explanation before code when
it establishes a necessary choice, and after code when it interprets evidence.

Keep code subordinate to the learning purpose. Remove chunks that merely prove a
function exists or repeat an already established pattern. Do not add filler,
forced anecdotes, artificial suspense, or conversational questions solely to vary
the rhythm. Read adjacent sections together: each should leave the reader better
prepared for the next, without an identical opening and closing formula.

End with what the example established, the limits of that result, and a useful
next destination. Avoid a generic list of every function mentioned.

## 13. Use connected examples and interpret their results

Use a realistic, manageable scenario whose objects and decisions persist across
sections. Establish what each row represents, where values come from, relevant
units and dates, and the question being answered. Synthetic data are welcome;
label them as such and give them plausible relationships. Do not imply that a
teaching dataset is representative or an externally validated standard.

Carry intermediate objects forward with stable, meaningful names. Avoid
recreating unrelated datasets for each function or silently changing assumptions
midway through the narrative. Introduce one meaningful complication at a time,
such as a missing birth date, a boundary age, or incomplete interval coverage.
Show why it matters to the task rather than collecting edge cases for their own
sake. A small independent example is appropriate when it makes a difficult rule
clearer; explain its connection to the main scenario before returning to it.

For an Agecraft reporting example, use synthetic birth and reference dates,
choose an explicit age unit, define reporting intervals for a stated purpose,
and retain the assignments when examining counts. Include a boundary observation
if the lesson concerns interval membership. If a missing assignment appears,
explain whether it reflects missing input or an unmatched value according to the
actual API; do not assume these cases are interchangeable. Describe reporting
bands as illustrative unless their source and edition have been verified.

### Explain meaning, not just output syntax

After a consequential result, explain what the reader should notice and how it
affects the next decision. “The result is a data frame” identifies a structure;
it does not explain what a row means or what the result establishes. Select the
output needed for the lesson and make important columns, units, levels, or
boundary cases visible without printing pages of incidental output.

Distinguish the following when relevant:

- A displayed value from the underlying stored value.
- A valid object from a definition appropriate for a particular analysis.
- Missing observations from observations outside the chosen coverage.
- A computational match from evidence supporting an analytical conclusion.
- Observed counts from rates that require compatible population denominators.

For example, interval overlap can establish possible membership without
justifying allocation of aggregate counts to finer bands. A successful validation
can establish structural or coverage properties without certifying the clinical
or institutional authority of a reporting scheme. Explain such limits at the
point where a reader might otherwise draw the unsupported conclusion.

Vignette examples should run in order from a clean session using only declared
packages and available data. Apply section 4's reproducibility and side-effect
rules to the whole narrative. Do not rely on hidden interactive objects or let
cached output conceal stale results. Keep reference examples short and
independent; connected vignette examples serve a different teaching purpose.

## 14. Make craftsmanship visible through editorial care

Agecraft's identity should come through in accurate boundaries, explicit choices,
well-chosen examples, and explanations that respect the reader's reasoning.
Ages and classifications involve decisions about measurement, representation,
and purpose. Show the consequences of those decisions rather than making broad
claims about the package's elegance or care.

Use the idea of craftsmanship as an editorial standard, not a recurring metaphor.
Avoid workshop imagery, craft-themed headings, slogans, and decorative stories
that compete with the subject. A brief framing sentence can be useful when it
introduces a real analytical choice; it should earn its place by helping the
reader understand the work. Precision, restraint, and a coherent progression
should carry the voice across help topics and vignettes.

### Review the document and the ecosystem

Review in separate passes so local sentence polishing does not conceal a weak
structure or an incorrect claim:

1. **Contract and scope:** Check claims, terminology, class relationships, and
   implemented versus proposed behavior against their authoritative sources.
2. **Learning path:** Read headings and transitions without code. Check that
   prerequisites arrive before use, questions develop naturally, and the ending
   delivers the promised learning outcome.
3. **Examples and interpretation:** Follow the connected scenario from a clean
   session. Check that every consequential output is explained and that limits
   appear before a misleading conclusion becomes likely.
4. **Voice and economy:** Read the prose aloud. Remove mechanical scaffolding,
   repeated definitions, promotional language, and metaphors that do no work.
   Retain explanation needed to understand a decision.
5. **Navigation and consistency:** Follow links between overview, vignettes,
   class topics, constructors, and methods. Check that shared concepts use the
   same names and that no page contradicts or needlessly duplicates another.
6. **Rendered result:** Inspect the applicable rendered help or article for
   broken links, heading structure, tables, code, and readable output. Report
   what was actually run and inspected.

For a policy-only Markdown edit, inspect its structure and diff; regenerating
roxygen help or running the package test suite is unnecessary unless executable
examples, roxygen sources, or behavior also change. For actual help or vignette
changes, use section 7 and render the affected documents. Scale checks to the
changed material and do not present a prose review as executable validation.

### Reuse the guidance across packages

The general rules here apply beyond Agecraft: establish public contracts,
distinguish reference from teaching, choose a vignette's purpose, connect
examples, interpret results, and review the documentation as a system. When
adapting this guide, replace Agecraft-specific concepts, examples, source-of-truth
paths, and workflows with the receiving package's actual domain and tooling.
Do not transplant interval semantics, class relationships, provenance claims,
lifecycle status, or validation guarantees into a package where they do not
apply. Keep a stable shared editorial core and clearly identified package-specific
rules, so improvements can be reused without erasing local contracts.

## 15. Style references

Use these primary references for conventions and representative help structure. The rules above combine those conventions with this package owner's preference for fuller explanations directed at readers; they are not a verbatim reproduction of a tidyverse policy.

- [Tidyverse style guide: Documentation](https://style.tidyverse.org/documentation.html): roxygen formatting and documentation style.
- [roxygen2: Documenting functions](https://roxygen2.r-lib.org/articles/rd.html): topic structure and tag behavior.
- [dplyr: filter reference](https://dplyr.tidyverse.org/reference/filter.html): an example of connecting arguments, return properties, missing values, and examples.

When borrowing a structural pattern, write original explanations grounded in this package's behavior. Do not copy another function's promises, terminology, or limitations without checking that they apply.
