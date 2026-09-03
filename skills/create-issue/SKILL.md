---
name: create-issue
description: Create a GitHub Issue following this project's Markdown issue templates with an English title and body. Use when the user asks to file an issue, 起票する, or turn a bug, idea, or task into a GitHub Issue.
---

# Create issue

## Task overview

Compose a GitHub Issue that matches one of the repository's Markdown issue templates and create it with the available GitHub integration or CLI.

## Convention

Follow `.claude/rules/git-workflow.md` — Issues (read it first):

- **Title**: the same Conventional Commits format as commits (`<type>: <description>`, scope optional) — write the title in **English**
- **Body**: written concisely in **English**, following the section structure of the matching template
- **Type**: choose the template whose purpose matches the task

## Issue templates (`.github/ISSUE_TEMPLATE/`)

List the directory and pick the template whose frontmatter `about` matches the task. Always read
the chosen template from the target branch before composing: the title prefix is its frontmatter
`title` (e.g. `chore: `), and the body reproduces its `##` headings verbatim with the content
written beneath them.

## Workflow

1. **Classify** — choose the matching template; confirm only when the type materially changes the task
2. **Study conventions** — inspect recent Issues and read the matching template from the target branch
3. **Compose** — write the title with the template prefix and the body under the template's `##` headings:
   - When investigation preceded the filing, the main body carries only its conclusions; append
     an `## Investigation` section at the end of the body so the recorded findings are visible,
     with the detail (evidence, measurements, file findings) collapsed beneath the heading in a
     `<details><summary>…</summary></details>` block
4. **Verify the premises** — when the Issue's justification rests on prior investigation — a
   root-cause analysis, a claim that something is missing or impossible, API or version
   availability, a statement of current behavior — do not file on the investigator's word:
   - Extract the load-bearing factual claims from the draft body.
   - Launch a fresh read-only agent given the draft alone — no investigation context, so it
     cannot inherit its assumptions — briefed to falsify each claim against primary evidence
     (the code as of `origin/main`, artifact contents, command output — never articles or
     recollection) and to return a verdict per claim with the evidence cited.
   - A refuted claim goes back to the user before anything is filed; a claim that could not be
     verified either way stays in the body labeled as an assumption, not a fact.
   Skip this step when the Issue has no investigative premise (typos, self-evident chores). For
   high-impact Issues, escalate to the project's cross-model review lane when one exists.
5. **Create** — create the Issue without adding assignees, labels, milestones, or projects unless requested

   ```bash
   gh issue create \
     --title "docs: update AI documentation" \
     --body "$(cat <<'EOF'
   ## Summary

   Evaluate and update the AI documentation after practical use.

   ## Target Documents

   - `AGENTS.md`
   - `CLAUDE.md`
   EOF
   )"
   ```

6. **Hand off or stop** — print the created issue URL, then by default continue straight into
   the autonomous flow: invoke `ship-issue <N>`, whose Dispatch step moves the work into its
   own dispatched worktree — never the current checkout's branch. When the request that led
   here settled the issue but not the implementation, put that hand-off as a single pick-one
   question (Claude Code: `AskUserQuestion`) instead of prose, so it costs one click to answer
   — never ask again once the user has already asked for the implementation. Stop with the
   report instead when the user asked to only record the issue (記録だけ / "file it for
   later") or for backlog or checklist batches

## Notes

- One issue = one responsibility; if the request bundles several concerns, propose splitting before creating
- Filing many findings at once, and how Issues map to PRs: follow `.claude/rules/git-workflow.md` — Issues
- The issue Type determines the branch prefix later — the mapping is canonical in `.claude/rules/git-workflow.md` — Branches

## Argument handling

| Argument | Behavior |
|----------|----------|
| Free-form description | Use as the source material for Type classification and body composition |
| (none) | Ask the user what the issue should cover |
