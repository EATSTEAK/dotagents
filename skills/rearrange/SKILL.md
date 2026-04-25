---
name: rearrange
description: Analyze and reorganize current branch commits for easier review. Use when the user asks to rearrange, reorder, split, squash, or clean up commits, or requests `/rearrange` with an optional base branch.
---

# Commit Rearrangement

Use this workflow when the user wants branch commits reorganized for reviewability.

## Base Branch

- Use the user-provided base branch when present.
- Default to `main` when no base branch is provided.

## Analysis

1. Inspect commits since the base branch:

```bash
git log --oneline <base>..HEAD
git log --oneline --name-status <base>..HEAD
git log -p <base>..HEAD
```

2. Inspect recent project commit style with `git log --oneline -20`.
3. Identify commits that should be reordered, split, squashed, or renamed.
4. Preserve dependency order and keep tests with the implementation they verify.
5. Confirm that the final branch diff should remain behaviorally equivalent unless the user explicitly wants content changes.

## Plan

Before rewriting history, show a plan containing:

- Current commits.
- Proposed operations: `reorder`, `split`, `squash`, or `edit`.
- Expected final commit structure.
- Risks, especially if the branch has already been pushed.

Ask for explicit confirmation before any history rewrite.

## Execution

- Prefer non-interactive commands where possible.
- Avoid interactive git modes unless the environment supports them and the user approved the rewrite.
- Create a backup branch before rewriting when the branch has meaningful local work.
- After rearranging, verify `git log --oneline <base>..HEAD` and compare the final diff against the original intended diff.

## Safety

- Do not force-push unless explicitly requested.
- Do not discard changes.
- If conflicts occur, stop and explain the safest next step.
