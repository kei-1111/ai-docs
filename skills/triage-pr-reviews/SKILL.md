---
name: triage-pr-reviews
description: "Use whenever a pull request has review comments and the user wants them handled — checked, addressed, fixed, planned, or responded to — no matter how casually phrased (e.g. \"look at the reviews on my PR and fix them\", 「レビュー来てたので確認して対応して」). This is the mandatory first step for acting on PR review feedback, even when the end goal is fixing the code: it fetches every comment (inline reviews, review summaries, issue comments, bot reviews), verifies each claim against the actual code, classifies each as fix / won't fix / split into separate issue, and produces the concrete fix plan that subsequent code edits follow — then, once the user approves that plan, continues in the same flow through implementing and committing the fixes. Not for performing a code review yourself, reviewing local working-tree changes, explaining what a single comment means, replying to comments on an Issue, or other PR chores."
---

# PR Review Triage

## Overview

Fetch every review comment on a PR, classify each into "fix" / "won't fix" / "split into separate issue" with a one- to two-line rationale, and produce a concrete fix plan for the ones marked "fix".

## Workflow

### 1. Identify the target PR

If the user passes a PR number / PR URL as argument, use it. Otherwise, resolve the PR attached to the current branch.

```bash
# With argument
gh pr view <number> --json number,title,url,state,headRefName,baseRefName

# Without argument (current branch)
gh pr view --json number,title,url,state,headRefName,baseRefName
```

If no PR is found, ask the user which PR to target.

### 2. Fetch review comments

Fetch every comment source and thread-resolution state using
`references/github-review-comments.md`; that reference is canonical for the endpoints and commands.

### 3. Organize the comments

Track each comment by:

- Comment ID
- Author (human vs. bot — treat accounts ending in `[bot]`, e.g. `gemini-code-assist[bot]`, as bots)
- Target file / line (inline review comments only)
- Body (summarized)
- Resolved flag (when fetched via GraphQL)
- Thread linkage (`in_reply_to_id` groups replies into a single thread)

GraphQL enriches the REST inline-comment records; it is not an additional comment source. Match a
GraphQL comment `id` to the REST record's `node_id`, keep the REST numeric `id` for reporting, and
count the comment once. Apply the containing GraphQL thread's `isResolved` value to the merged
records.

Group comments that hit the same file or repeat the same point.

### 4. Verify each comment, then classify

Comments — especially from LLM-based bot reviewers (Copilot, claude[bot], gemini-code-assist[bot], etc.) — frequently surface plausible-sounding but incorrect concerns. Treat every claim as a hypothesis until verified.

**Verify before classifying as "Fix"**:

- Read the cited code, docs, or API. Line numbers and quoted snippets can be stale or misread.
- Cross-check claims about external behavior (GitHub API, library semantics, language features) against current upstream documentation.
- Check whether the suggestion conflicts with the applicable `.claude/rules/*.md` or established patterns in this repo.
- Distinguish "the document/code is actually wrong" from "the wording could be slightly more precise" — the latter is a stylistic preference, not a defect.
- For bot reviewers, treat low-effort or generic suggestions as especially likely to be off-base.

A claim that does not survive verification → **Won't fix**, with the verification result as the rationale.

Then sort each comment (or comment group) into the buckets below, with a short rationale that
includes what was verified:

| Bucket | Typical criteria |
|--------|------------------|
| **Fix** | The cited problem actually exists after verification: real bug, real code-quality issue, real project-rule violation, typo |
| **Won't fix** | Verification did not confirm the problem (cited code is fine, API behaves differently than claimed, wording is descriptively correct) / out-of-scope improvement / existing pattern takes precedence / alternative already chosen |
| **Split into separate issue** | Verified concern, but scope is too large / different concern from this PR / better handled in a follow-up PR |

### 5. Build the fix plan

For every "Fix" comment (or group), write:

```markdown
### Fix Plan #<n> — <short title>

- **Target comments**: #<id> by <author> — `<path>:<line>` (when applicable)
- **Issue**: <summary>
- **Approach**: <what to change, in which file, how>
- **Impact**: <other files affected, manual verification steps>
- **Commit shape**: <single commit / split into N commits, with proposed commit message(s)>
```

When several comments collapse into one fix, list all their IDs under `Target comments`.

### 6. Present and get approval

Deliver everything in a single response and wait for the user's call:

1. **Summary** — total comments fetched, breakdown (Fix N / Won't fix M / Split L)
2. **Won't-fix list** — comment IDs with the rejection rationale
3. **Split-out candidates** — proposed English issue titles (`<type>: <description>`) and short descriptions
4. **Fix plans** — numbered using the format above
5. **Next-step decisions**:
   - Proceed with the fix plan?
   - Open the split-out issues now?
   - Reply to any "Won't fix" comments?

### 7. Implement approved fixes

Only when the user approves the fix plan in step 6 — a bare "look at the reviews" request still
stops at step 6. Execute each approved Fix Plan's Approach faithfully through the product's
implementation lane, commit per its Commit shape (the step-6 approval is the explicit go-ahead
for those commits), and validate per its Impact notes before moving to the next plan. Never reply to review threads on GitHub — that stays a separate, explicit ask.
Finish by reporting the commits created and any deviation from the approved plans.

## Notes

- **Read-only until the user approves the fix plan in step 6.** Only that approval triggers the
  implementation step; partial approval ("only plans 1 and 3") limits it to the approved plans.
- **Bot reviews count.** Mechanical or out-of-scope bot suggestions tend to land in "Won't fix", but evaluate on content — don't auto-reject them.
- **Resolved threads** are included by default so the user can re-confirm them. Drop them only when the user says so in plain language (e.g., "skip resolved").
- **Large comment sets**: group by file or by repeated issue so the user can scan the picture
  quickly.
- **Language**: write the classification report and fix plans in Japanese (this is the user-facing output and matches the rest of the project's review workflow).
- **Project-rule alignment**: when shaping a fix, check it against the applicable `.claude/rules/*.md` and the current source. If a review comment conflicts with a project rule, surface that conflict explicitly.
- **Post-PR boundary**: `ship-issue`'s Watch step monitors CI and conflicts only; review comments on a PR created by that flow still use this skill.

## Arguments

| Argument | Example | Behavior |
|----------|---------|----------|
| PR number | `432` | Target that PR |
| PR URL | `https://github.com/<owner>/<repo>/pull/432` | Extract the number from the URL |
| (none) | — | Use the PR attached to the current branch |
| Free-form instruction | "skip resolved", "bots only", "only file X" | Apply as a natural-language filter on fetch / classification |
