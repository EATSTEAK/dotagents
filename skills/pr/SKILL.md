---
name: pr
description: Prepare and create a GitHub pull request from the current branch. Use when the user asks to open a PR, create a pull request, or requests `/pr`, including an optional base branch argument.
---

# GitHub Pull Request

Use this workflow when the user wants a PR created from the current branch.

## Base Branch

- Use the user-provided base branch when present.
- Default to `main` when no base branch is provided.

## Workflow

1. Identify the current branch with `git branch --show-current`.
2. Stop if the current branch is the base branch.
3. Inspect commits with `git log origin/<base>..HEAD --oneline`.
4. Inspect changed files with `git diff origin/<base>...HEAD --name-status`.
5. Inspect the full branch diff with `git diff origin/<base>...HEAD`.
6. Check whether the branch is pushed and whether an open PR already exists.
7. Summarize the changes by feature additions, structural changes, refactors, tests, and docs.
8. Draft a PR title and body that match existing repository style.
9. Push the current branch if needed.
10. Create the PR with the available GitHub tooling, preferring `gh pr create` when available.
11. Return the PR URL.

## PR Body Shape

Prefer a concise body like:

```md
## Summary
- ...

## Testing
- ...
```

Mention tests that were not run.

## Safety

- Do not create a PR from `main` or the selected base branch.
- Do not force-push unless the user explicitly requests it.
- If an open PR already exists for the branch, return that PR instead of creating a duplicate.
