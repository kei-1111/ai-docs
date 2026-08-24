---
name: create-commit
description: Create a git commit from the staged changes, with a message following the project's Conventional Commits format. Use only when the user explicitly asks for a commit — never commit unprompted.
---

# Create commit

Inspect the staged changes, generate a commit message that follows the project convention, and run the commit.

## Convention

Read `.claude/rules/git-workflow.md` — Commits first: the Conventional Commits format, allowed
types and scopes, real examples, and the concise-imperative-English language rule all live
there; do not work from memory.

## Workflow

1. Run `git status` to review the changes
2. Run `git diff --staged` to inspect the staged contents
3. Run `scripts/list_added_comments.sh` (a language-aware candidate scan) to surface comment lines the staged diff adds, and pass each through `.claude/rules/working-agreement.md` — Comments: keep only an individually justifiable constraint the code cannot express; delete the rest, re-stage, and re-run the script before continuing
4. Run `git log --oneline -5` to see the recent commit style
5. Generate a message that follows the convention
6. After confirming with the user, run `git commit`
