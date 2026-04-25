---
name: summary
description: Summarize current branch changes against a base branch. Use when the user asks for a branch summary, change summary, release-style summary, or `/summary` with an optional base branch.
---

# Branch Change Summary

Use this workflow when the user wants a factual summary of branch changes.

## Base Branch

- Use the user-provided base branch when present.
- Default to `main` when no base branch is provided.

## Workflow

1. Identify the current branch with `git branch --show-current`.
2. Inspect commits with `git log origin/<base>..HEAD --oneline`.
3. Inspect changed files with `git diff origin/<base>...HEAD --name-status`.
4. Inspect the full diff with `git diff origin/<base>...HEAD`.
5. Check the surrounding codebase when needed to understand how the changes fit.
6. Produce a concise summary focused on user-visible behavior, structural changes, refactors, tests, and docs.

## Output Format

Prefer this shape:

```md
## Summary
- ...

## Major Changes
- ...

## Testing
- ...
```

If the diff is empty, say so directly.
