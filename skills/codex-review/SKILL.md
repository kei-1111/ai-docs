---
name: codex-review
description: Have the OpenAI Codex CLI review code changes (working tree, branch diff, or a PR) as an independent second reviewer. Use when the user asks for a Codex review or "Codexにレビューしてもらって" — a single second opinion from Codex alone; for both models' reconciled review use cross-review.
allowed-tools: Bash(scripts/codex_review.sh:*), Bash(./scripts/codex_review.sh:*), Bash(git:*), Bash(gh:*), Read(*)
---

# Review by Codex

## Task overview

Run `codex exec` in non-interactive mode to get an independent code review of the current changes, verify every finding against the actual code, and report the verified result to the user. This skill never edits code — Codex's review is advisory input.

## Workflow

### 1. Determine the review target

- Argument is a PR number/URL → that PR (`gh pr view <n>`, `gh pr diff <n>`)
- No argument → uncommitted changes if any — `git status --porcelain` / `git diff HEAD` plus untracked files (`git ls-files --others --exclude-standard`; their full contents are part of the target, not just the diff) — otherwise the current branch vs `main`: fetch first and diff against the remote-tracking ref (`git fetch origin main`, then `git diff origin/main...HEAD`); the local `main` ref may be stale

State the chosen target explicitly in the final report.

### 2. Run the review harness

```bash
scripts/codex_review.sh [-p <PR-number>] [-f "<focus>"]
```

The script owns composition and invocation: it determines the target (given PR, else
uncommitted changes, else branch vs `origin/main`), enumerates the applicable rules with
`scripts/list_matching_rules.sh`, writes a self-contained prompt telling Codex to inspect the
diff itself and verify claims before reporting (with "no findings" explicitly allowed), and
runs `codex exec --sandbox read-only` with the prompt passed via stdin — reviews never get
workspace-write. `--dry-run` prints the composed prompt without calling Codex.

- Use a generous finite timeout. If the command times out or fails, report that rather than
  retrying blindly.
- Add caller context that the script cannot know (e.g. what was adjudicated in earlier rounds) via `-f`.

### 3. Verify before relaying

Codex is an LLM reviewer — every finding is a hypothesis until verified (same discipline as `triage-pr-reviews`):

- Read the cited code; line numbers and quoted snippets can be stale or misread
- Check whether a suggestion conflicts with `.claude/rules/*.md` or a pattern the project has deliberately established — a "fix" that undoes a sanctioned project decision is a rejection, not a finding
- A claim that does not survive verification is reported as rejected, with the verification result as the reason

### 4. Present to the user

- **検証済みの指摘**: severity 順、`file:line` 付き
- **棄却した指摘**: 棄却理由(検証結果)付き
- **自身の見解**: Codex が見落とした点や同意/不同意
- **推奨アクション**: 修正する / しない / 別 Issue 化

When the user invoked this skill directly, also publish the report as an HTML Artifact; as an
inner step of another skill (e.g. a cross-review loop), skip it — the outermost report owns the
HTML.

Wait for the user's decision. Do not modify code based on the review without explicit approval.

## Notes

- **No secret leakage**: the prompt is sent to Codex's backend — never include credentials or tokens

## Argument handling

| Argument | Behavior |
|----------|----------|
| PR number / URL | Review that PR |
| Free-form focus (e.g. "パフォーマンス観点で") | Add as a review focus in the prompt |
| (none) | Review uncommitted changes, else current branch vs origin/main |
