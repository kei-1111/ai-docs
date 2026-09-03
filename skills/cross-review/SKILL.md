---
name: cross-review
description: Run Claude's own review and an independent Codex review over the same change, then reconcile both into a single report (agreements, conflicts, findings unique to each). Use when the user wants both models' review, a two-reviewer double check, or 「ClaudeとCodexの両方でレビューして」. For a single second opinion from Codex alone, use codex-review.
---

# Cross review

## Task overview

Review the same change through two independent lanes — the product's independent review lane and a
Codex review — and reconcile the verified findings into one report. Keep the lanes independent: never
feed one lane's findings into the other's prompt. This skill never edits code.

## Workflow

### 1. Determine the review target

Same resolution as `codex-review`: a PR number/URL argument → that PR; no argument → uncommitted
changes if any, otherwise the current branch vs `origin/main` (fetch first — the local `main` ref
may be stale). State the chosen target in the report.

### 2. Claude lane

Run the product's independent review lane over the target diff — the model-routing rule maps it.

### 3. Codex lane

Follow `ai-docs/shared/skills/codex-review/SKILL.md` steps 2–3 for the same target: run
`scripts/codex_review.sh`, then verify every finding against the actual code. Do not
present the Codex result standalone — it feeds the reconciliation below.

### 4. Reconcile

Verify both lanes' findings (each is a hypothesis until checked against the code and
`.claude/rules/*.md`), then bucket them:

- **一致** — both lanes report it (highest confidence)
- **相違** — the lanes assess the same code differently; investigate and take a position
- **Claude のみ** / **Codex のみ** — verified findings unique to one lane

### 5. Present to the user

Report per bucket, severity-ordered with `file:line`; include rejected findings with their
verification result, plus 推奨アクション (修正する / しない / 別 Issue 化). Wait for the
user's decision — do not modify code without explicit approval.

## Notes

- **No secret leakage**: the Codex-lane prompt is sent to Codex's backend — never include credentials or tokens

## Argument handling

| Argument | Behavior |
|---|---|
| PR number / URL | Review that PR |
| Free-form focus (e.g. "パフォーマンス観点で") | Add as a review focus to both lanes |
| (none) | Review uncommitted changes, else current branch vs origin/main |
