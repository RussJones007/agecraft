# Instructions for writing R package documentation

Use these instructions whenever you create or revise roxygen2 documentation in this package. Write for someone who knows R but has not read the function's source. Help that person decide whether the function fits their task, call it correctly, and understand the result.

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

## 9. Style references

Use these primary references for conventions and representative help structure. The rules above combine those conventions with this package owner's preference for fuller explanations directed at readers; they are not a verbatim reproduction of a tidyverse policy.

- [Tidyverse style guide: Documentation](https://style.tidyverse.org/documentation.html): roxygen formatting and documentation style.
- [roxygen2: Documenting functions](https://roxygen2.r-lib.org/articles/rd.html): topic structure and tag behavior.
- [dplyr: filter reference](https://dplyr.tidyverse.org/reference/filter.html): an example of connecting arguments, return properties, missing values, and examples.

When borrowing a structural pattern, write original explanations grounded in this package's behavior. Do not copy another function's promises, terminology, or limitations without checking that they apply.
