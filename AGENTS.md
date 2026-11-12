# Codex Instructions for Agecraft

## Project overview

Agecraft is an R package for representing ages,
age intervals, and age classification schemes.

## Required design documents

Before modifying relevant code, consult:

- `docs/architecture.md`
- `docs/age_interval.md`
- `docs/age_group.md`
- `docs/age_scheme.md`
- `docs/coding_guidelines.md`
- `docs/API_POLICY.md`
- `docs/CURRENT_STATE.md`

## Documentation guidance

Before writing or revising roxygen documentation, help topics,
vignettes, README content, or other user-facing documentation,
read and follow `docs/documentation.md`.

## Core requirements

- Preserve the existing S3 `age_interval` class.
- Use the `ivs` package for interval representation.
- Age intervals are left-closed and right-open: [start, end).
- Maintain compatibility with existing public functions.
- Use roxygen2 for documentation.
- Add testthat tests for new functionality.
- Do not change public APIs without identifying
  compatibility implications.
