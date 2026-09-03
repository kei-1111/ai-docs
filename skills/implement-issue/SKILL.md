---
name: implement-issue
description: Internal step of the ship-issue chain — implement a GitHub Issue on the current branch, from reading the issue to a validated working-tree change reviewed until no findings remain. Invoked from ship-issue, never directly.
user-invocable: false
---

# Implement issue

## Task overview

Take a GitHub Issue from number to a validated working-tree change on the current branch.
Committing and the PR are separate steps (`create-commit` / `create-pr`).

## Branch precondition

Work happens on the Issue's branch `<type>/#<issue-number>`, inside the Orca-managed worktree
created by `ship-issue`'s dispatch step.

## Workflow

1. **Fetch the issue** — `gh issue view <N>` for the title, body, and type
2. **Investigate impact** — locate the affected modules/files and every usage of what will change;
   read the nearest analogous implementation
3. **Read conventions** — the applicable `.claude/rules/*.md` (via `scripts/list_matching_rules.sh`) and the docs applicable to the touched areas
4. **Plan** — settle target files, approach, validation, and the change size (see below) before
   editing, then present the plan and continue straight from it, still asking where the Issue
   leaves something genuinely unsettled: a short prose summary for Small/Medium;
   for a Large change, an HTML page rendered from
   `references/plan-template.html` per that template's own header contract (Claude Code:
   publish it as an Artifact; a product without artifact publishing writes the HTML file and
   reports its path)
5. **Implement** — delegate execution to the product's default implementation lane with the
   concrete plan (contract: `ai-docs/shared/agents/implementer/SKILL.md`; when the project's `CLAUDE.md`
   defines model routing — e.g. a delegated Codex lane — follow it, judgment-heavy
   edits staying on `implementer`), then review the diff yourself;
   a Small change may instead be edited directly without delegation. When the change adds or
   modifies logic in a testable layer, run this step through the `tdd` skill's red-green-refactor
   workflow instead of implementing first and testing after
6. **Validate** — run every applicable row from `.claude/rules/project-validation.md`
7. **Review** — the same loop at every change size, ending only when a round produces zero
   actionable findings. Every round runs the independent review lane and, where the product has
   one, the cross-model reviewer in parallel on the same diff (lanes kept independent; a change
   implemented through the Codex lane gets its cross-model check from the Claude lane).
   Per round: fix verified findings and re-validate,
   record rejected ones with their verification result, and put judgment calls to the user.
   When findings stop converging across rounds, stop and consult instead of looping further
8. **Report** — as text: open with a prose overview of what was changed and why, then changed
   files, validation results, review rounds with fixed/rejected findings, and any deviation
   from the Issue with its reason. The HTML report belongs to the outermost `ship-issue`
   report (`references/report-template.html`) — this step never renders one

## Change size

Classify during Plan; when in doubt, pick the larger tier. The user's explicit override always wins.

| Size | Criteria |
|---|---|
| Small | The diff is explainable in one sentence — single file or equivalently narrow, no cross-module or wiring impact |
| Medium | Multi-file change contained in one module/feature, established patterns, low risk |
| Large | Cross-module, DI/navigation/build wiring, release-impacting, or the Issue leaves real ambiguity |

## Notes

- Make the smallest coherent change; if the Issue bundles several concerns, propose splitting first
- If investigation contradicts the Issue's premise, report instead of improvising
- `references/plan-template.html` and `references/report-template.html` are one design family
  sharing the same CSS tokens (also used by `ship-issue` via a `references` symlink) — edit the
  two files together, never one alone

## Argument handling

| Argument | Behavior |
|---|---|
| Issue number / URL | Target that Issue |
| `small` / `medium` / `large` | Override the change-size classification |
| `no-review` | Skip the Review step regardless of size |
| (none) | Derive `#<N>` from the current branch name `<type>/#<N>` |
