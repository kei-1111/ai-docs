---
name: ship-issue
description: Take a GitHub Issue all the way to an opened pull request — implement, update docs, commit, and create the PR in one flow. The default entry point for handling an Issue (「対応して」, 「PRまで対応して」, 「最後まで対応して」, ship this Issue); only an explicitly PR-less implementation-only request falls to the internal implement-issue step instead.
---

# Ship issue

## Task overview

Thin orchestrator chaining `implement-issue` → `update-docs` → `create-commit` → `create-pr` and
folding each inner skill's report into one final report. This skill owns only the ordering and the
confirmation points between steps — it never reimplements an inner skill's logic. When an inner
skill needs a decision (plan approval, commit approval, PR body confirmation), surface that
question directly and pause the chain there.

## Workflow

0. **Dispatch (Orca-first)** — decide where the chain runs before starting it:
   - Already on the target Issue's branch (canonical `<type>/#<N>` or its Orca-sanitized form
     `<type>-<N>`): run the chain here.
   - Otherwise, when the Orca CLI is available (`command -v orca`): hand the Issue to its own
     Orca-managed worktree instead of implementing in place —
     derive the workspaces root from an existing `orca worktree list --json` path, pre-trust
     the predictable new path for the launched agent (Claude Code: set
     `projects["<path>"].hasTrustDialogAccepted: true` in `~/.claude.json`), then
     `orca worktree create --repo path:<repo-root> --name '<type>/#<N>' --issue <N>
     --no-parent --agent claude --prompt "/ship-issue <N>" --json`, report the created
     worktree and agent handle, and end — the dispatched agent runs this same skill inside
     the worktree, and progress is monitored in the Orca app.
   - Without Orca: fall back to `implement-issue`'s branch precondition (confirm the branch
     with the user).

1. **Implement** — run `implement-issue` with the given arguments (Issue number/URL, size
   override, `no-review`); its branch precondition, plan approval, validation, and full review
   loop all apply as written
2. **Update docs** — run `update-docs` over the resulting change
3. **Commit** — present the final diff and get the user's confirmation; stop and ask if
   unrelated staged changes already exist. Then per logical unit: stage only that unit's files,
   confirm `git diff --staged` matches the reviewed diff, and run `create-commit` — repeat until
   everything reviewed is committed
4. **Create PR** — run `create-pr`; any deviation from the Issue goes into the PR body's
   Summary — reviewers need it there, not in the report
5. **Report** — one consolidated report, in three parts:
   - Text: open with a prose overview of what was changed and why, then changed files,
     validation results, review rounds with fixed/rejected findings, docs updated,
     commits created, and the PR URL
   - HTML: render from `references/report-template.html` (shared with `implement-issue`; its
     fixed sections carry only what opening the PR does not give), filled per the template's
     own header contract, and share it (Claude Code: publish it as an Artifact; a product
     without artifact publishing writes the HTML file and reports its path)
   - Attach: a one-line `gh pr comment` on the PR from step 4 with exactly this text:
     `Execution report for this batch (session artifact, private by default — share from the
     page menu if needed): <report URL>` — only when no published URL exists, carry the
     report's overview instead — so the execution context lives with the PR, not only in the
     session

6. **Watch** — the step-5 report never waits for CI: deliver it as soon as the push is up, then
   keep tracking the PR in the background (Claude Code: scheduled wakeups; a product without
   scheduling checks at each next opportunity) until every check is green and the branch is
   conflict-free, reporting follow-up results as they land. This watch covers CI and conflicts
   only; PR review comments always enter through `triage-pr-reviews`:
   - CI failure: check it first. A known infra flake (per the project CI rule, when one
     exists) is rerun; a code-caused failure is investigated and reported with the failing output
   - Conflict with `main`: merge `main`, resolve, re-run the narrowest relevant validation
     (plus the project's app-verification skill, when one exists and code changed), and push. A conflict needing more than a mechanical
     merge — semantic choices between both sides — is escalated to the user
     (`.claude/rules/working-agreement.md` — While Editing, escalate when stuck)

If an inner step fails or the user stops the chain, report what completed and what remains.

## Argument handling

| Argument | Behavior |
|---|---|
| Issue number / URL | Passed through to `implement-issue` |
| `small` / `medium` / `large` / `no-review` | Passed through to `implement-issue` (size override / skip its review step) |
| (none) | `implement-issue` derives `#<N>` from the current branch name `<type>/#<N>` |
