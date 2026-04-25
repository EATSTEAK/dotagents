---
name: commit
description: Analyze staged git changes and create one or more well-scoped commits. Use when the user asks to commit, split staged changes into logical commits, or requests `/commit`-style smart committing, including single-commit mode.
---

# Smart Staged Commit

Use this workflow when the user wants staged changes committed.

## Arguments

- `--single` or `-s`: commit all staged changes as one commit.
- No argument: analyze staged changes and split them into logical commits when useful.

## Workflow

1. Inspect staged files with `git diff --cached --name-status`.
2. If nothing is staged, show `git status` and stop without creating an empty commit.
3. Review the full staged diff with `git diff --cached`.
4. Check recent commit style with `git log --oneline -20`.
5. Classify changes by intent: `feat`, `fix`, `refactor`, `docs`, `test`, `style`, or `chore`.
6. Group changes by feature, module, dependency, and reviewability.
7. Before committing, show the user a concise commit plan and ask for confirmation unless the surrounding agent instructions explicitly allow committing without another confirmation.
8. Commit each group in dependency order.

## Grouping Rules

- Prefer feature-level groups when one feature spans multiple files.
- Keep implementation and directly related tests together.
- Keep unrelated documentation, formatting, and configuration changes separate when that improves reviewability.
- Avoid overly tiny commits that do not stand on their own.
- Avoid overly broad commits that mix unrelated behavior changes.

## Message Format

Use the repository's existing style. If there is no stronger local convention, use Conventional Commits:

```text
<type>(<scope>): <subject>

<body>
```

- Keep the subject concise, lowercase, and without a trailing period.
- Add a body only when it explains important context or motivation.

## Single Commit Mode

When `--single` or `-s` is requested:

1. Analyze all staged changes together.
2. Draft one message that covers the full intent.
3. Create one commit after confirmation.

## Safety

- Do not commit files that likely contain secrets, credentials, or local-only configuration.
- Do not amend, force-push, reset hard, or discard changes unless explicitly requested.
- If a hook fails, fix the issue and create a new commit rather than amending a failed attempt.
