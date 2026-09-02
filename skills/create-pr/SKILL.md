---
name: create-pr
description: Create a pull request via the GitHub CLI (gh) from the current branch's committed changes.
---

# Create pull request

## Task overview

Inspect the changes on the current branch and create a pull request using the GitHub CLI (gh).

## Convention

Follow `.claude/rules/git-workflow.md` — Pull Requests (read it first):

- PR title: the corresponding Issue title verbatim (Conventional Commits format, in English)
- Branch name: derive the Issue number from `<type>/#<issue-number>` (type mapping canonical in `.claude/rules/git-workflow.md` — Branches)
- Base branch: `main`

## Workflow

1. **Check the current state**
   - Run `git status` to review changes
   - Run `git log` to review recent commits
   - Confirm the current branch and base branch

2. **Analyze the changes**
   - Review every commit message
   - Inspect the modified files
   - Understand the purpose and scope of impact

3. **Compose the PR title and body**
   - Extract the Issue number from the branch name (format: `<type>/#<issue-number>`)
   - Run `gh issue view` to fetch Issue information and reuse the Issue title as the PR title
   - Build the body from `.github/PULL_REQUEST_TEMPLATE.md` (canonical): reproduce its
     headings and follow its inline comments for which optional sections apply
   - Verification shows up solely as the template's checklist states
   - For a user-visible UI change, capture Before and After images of the affected screens by
     driving the running product, reference the image files where the template places them, and
     pass each to the repeatable `--attach` flag (`gh pr create --attach <image>`) — gh uploads
     the files and rewrites the references in place

4. **Create the pull request**
   - Print the proposed title and body, then continue straight into creating the PR
   - Run `git push -u origin <branch-name>` if needed
   - Create the PR with `gh pr create`
   - Print the URL of the created PR

## Notes

- If there are uncommitted changes, prompt the user to commit them first
- Write the body and any GitHub comments in English

## Argument handling

When an argument is provided:

- Use the argument as supplemental context for the PR body

When no argument is provided:

- Generate the body by analyzing the commit messages
