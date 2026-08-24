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
3. **Compose** — write the title with the template prefix and the body under the template's `##` headings
4. **Create** — create the Issue without adding assignees, labels, milestones, or projects unless requested

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

5. **Report and stop** — print the created issue URL and end there: filing an issue is not a signal to start implementing — no branch creation, no implementation reconnaissance — until the user explicitly asks (e.g. via `implement-issue` / `ship-issue`)

## Notes

- One issue = one responsibility; if the request bundles several concerns, propose splitting before creating
- Filing many findings at once, and how Issues map to PRs: follow `.claude/rules/git-workflow.md` — Issues
- The issue Type determines the branch prefix later — the mapping is canonical in `.claude/rules/git-workflow.md` — Branches

## Argument handling

| Argument | Behavior |
|----------|----------|
| Free-form description | Use as the source material for Type classification and body composition |
| (none) | Ask the user what the issue should cover |
