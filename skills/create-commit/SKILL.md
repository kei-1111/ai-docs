---
name: create-commit
description: Create a git commit from the staged changes, with a message following the project's Conventional Commits format. Invoke at each completed logical unit of work.
---

# Create commit

Inspect the staged changes, generate a commit message that follows the project convention, and run the commit.

## Convention

Read `.claude/rules/git-workflow.md` — Commits first: the Conventional Commits format,
allowed types, and the concise-imperative-English language rule live there; the observed
scopes and real examples are project-specific (the project git overlay it points to). Do not
work from memory.

## Workflow

1. Run `git status` to review the changes
2. Run `git diff --staged` to inspect the staged contents
3. Run `scripts/list_added_comments.sh` (a language-aware candidate scan) to surface comment lines the staged diff adds, and pass each through `.claude/rules/working-agreement.md` — Comments: keep only an individually justifiable constraint the code cannot express; delete the rest, re-stage, and re-run the script before continuing
4. Run `git log --oneline -5` to see the recent commit style
5. Generate a message that follows the convention
6. Run `git commit`
