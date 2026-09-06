---
name: triage-pr-reviews
description: "Use whenever a pull request has review comments and the user wants them handled, however casually phrased (\"look at the reviews on my PR\", 「レビュー来てたので確認して対応して」). Fetches every comment, verifies each claim against the code, classifies it as fix / won't fix / separate issue, and applies the fixes. Not for reviewing code yourself, reviewing local working-tree changes, or replying to Issue comments."
---

# PR Review Triage

## Overview

Fetch every review comment on a PR, verify each one, sort it into "fix" / "won't fix" / "separate issue", and fix what needs fixing.

## Workflow

### 1. Identify the target PR

The PR number / URL argument, otherwise the PR attached to the current branch:

```bash
gh pr view [<number>] --json number,title,url,state,headRefName,baseRefName
```

If no PR is found, ask the user which PR to target.

### 2. Fetch review comments

Fetch every comment source and thread-resolution state per `references/github-review-comments.md`
(canonical for the endpoints and commands). GraphQL enriches the REST inline-comment records
rather than adding a source: match a GraphQL comment `id` to the REST `node_id`, count the
comment once, and apply the containing thread's `isResolved` to it. Group comments that hit the
same file or repeat the same point.

### 3. Verify, then classify

Every comment is a hypothesis until verified — LLM bot reviewers (Copilot, claude[bot],
gemini-code-assist[bot], and any account ending in `[bot]`) frequently raise plausible but
incorrect concerns:

- Read the cited code, docs, or API; line numbers and quoted snippets can be stale or misread.
- Cross-check claims about external behavior (GitHub API, library semantics, language features) against current upstream documentation.
- Check whether the suggestion conflicts with the applicable `.claude/rules/*.md` or an established pattern in the repository — a "fix" that undoes a sanctioned decision is a rejection.
- Distinguish "actually wrong" from "could be phrased more precisely" — the latter is a stylistic preference, not a defect.

| Bucket | Criteria |
|--------|----------|
| **Fix** | The cited problem exists after verification: bug, code-quality issue, rule violation, typo |
| **Won't fix** | Verification did not confirm the problem / out of scope / an existing pattern or already-chosen alternative takes precedence |
| **Separate issue** | Verified, but too large or a different concern from this PR |

### 4. Report the classification

In one response, in Japanese: the count breakdown, each "won't fix" with its verification
result, each "separate issue" candidate with a proposed English title (`<type>: <description>`),
and each "fix" with what will change and where.

### 5. Apply the fixes

Implement every "fix" through the product's implementation lane, validate per
`.claude/rules/project-validation.md`, and commit per logical unit. Filing the "separate issue"
candidates and replying to review threads are separate asks — never do either unprompted.
Finish by reporting the commits created and any deviation from the classification.

## Notes

- Resolved threads are included by default so the user can re-confirm them; drop them only when the user says so ("skip resolved").

## Arguments

| Argument | Example | Behavior |
|----------|---------|----------|
| PR number | `432` | Target that PR |
| PR URL | `https://github.com/<owner>/<repo>/pull/432` | Extract the number from the URL |
| (none) | — | Use the PR attached to the current branch |
| Free-form instruction | "skip resolved", "bots only", "only file X" | Apply as a filter on fetch / classification |
