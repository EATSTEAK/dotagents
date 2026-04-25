---
name: review
description: Perform a code review for a branch diff, staged diff, or specific file. Use when the user asks for review, code review, `/review`, staged review, branch review, or review of a named file.
---

# Selective Code Review

Use this workflow when the user wants review findings rather than implementation.

## Review Targets

- No argument or `branch`: review the current branch against `origin/main...HEAD`.
- `staged`: review the staged diff.
- `file <path>`: review the full target file and relevant references.

If the target is ambiguous or `file` has no path, ask one short clarifying question.

## Workflow

1. Resolve the review target.
2. For `branch`, inspect current branch, commits, changed files, and full diff against `origin/main...HEAD`.
3. For `staged`, inspect `git diff --cached --name-status` and `git diff --cached`.
4. For `file`, verify the file exists, read it, and inspect nearby references when needed.
5. Check whether the reviewed changes fit the surrounding codebase patterns.
6. Run available static checks only when they are cheap and clearly relevant.
7. Report findings first, ordered by severity, with file and line references.

## Review Criteria

- Correctness, soundness, edge cases, and regressions.
- Avoidable duplicate implementation where existing project utilities or dependencies fit.
- Error handling, nullability, and invalid input behavior.
- Security risks including secret exposure, validation, authentication, and authorization.
- Performance risks such as repeated expensive work, N+1 queries, or memory leaks.
- Documentation gaps only when they create maintenance or usage risk.

## Output Format

Use this structure:

```md
## Findings
- [severity] path:line - issue and impact

## Open Questions
- ...

## Notes
- ...
```

If no findings are found, state that explicitly and mention residual risks or testing gaps.
