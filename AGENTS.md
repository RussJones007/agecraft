# Codex Instructions for Agecraft

## Project overview

Agecraft is an R package for representing ages,
age intervals, and age classification schemes.

## Required design documents

Before modifying relevant code, consult:

- `docs/architecture.md`
- `docs/age_group.md`
- `docs/age_scheme.md`
- `docs/coding_guidelines.md`
- `docs/API_POLICY.md`
- `docs/CURRENT_STATE.md`

## Core requirements

- Preserve the existing S3 `age_group` class.
- Use the `ivs` package for interval representation.
- Age intervals are left-closed and right-open: [start, end).
- Maintain compatibility with existing public functions.
- Use roxygen2 for documentation.
- Add testthat tests for new functionality.
- Do not change public APIs without identifying
  compatibility implications.
