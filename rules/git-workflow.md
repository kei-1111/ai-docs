# Git Workflow

Core Git/GitHub conventions, loaded in every session. Step-by-step procedures live in the
create-commit / create-issue / create-pr / triage-pr-reviews skills. Project-specific seams
(scopes, test-suite mapping, hooks) live in `.claude/rules/git-workflow.project.md`.

## Commits

- [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/), written entirely in English: `<type>: <description>` or `<type>(scope): <description>`
- Types: feat, fix, docs, refactor, perf, test, build, ci, chore — which suites `test` covers and the observed scopes are project-specific (see the project git rules)
- Description: imperative mood, one concise line, no trailing period
- Breaking changes: `feat!:` or a `BREAKING CHANGE:` footer
- Granularity: one self-contained logical change per commit, cherry-pickable without depending on later commits

## Branches

- Name: `<type>/#<issue-number>` where type derives from the Issue title's Conventional Commits type — `feat` → `feature`, every other type keeps its name (e.g. `feature/#18`, `fix/#20`, `chore/#43`)
- Keep branches short-lived and synced with `main`

## Issues

- Title in the same Conventional Commits format as commits (`<type>: <description>`, scope optional), the type being the chosen template's frontmatter prefix in `.github/ISSUE_TEMPLATE/`; title and body in English, mirroring that template's headings
- Bodies state what to do and its outcome; a past change appears only as the current state to fix — never as what introduced it, what it did not cause, or the review that found the item
- One responsibility per Issue; close when completed
- Filing many findings at once (audits, review sweeps): batch them into per-kind checklist Issues — never one Issue per finding
- One Issue maps to one PR — never split an Issue's items across PRs; when a change feels PR-splittable, split the Issue instead, and keep Issue bodies free of "separate PRs" phrasing
- When the implementation deviates from the Issue's stated approach, update the Issue body to match
- An Issue made obsolete by consolidation is deleted (`gh issue delete`), not closed — closing means completed; also remove references to it from the absorbing Issue

## Pull Requests

- Title: the corresponding Issue title verbatim; base branch is always `main`
- Body follows `.github/PULL_REQUEST_TEMPLATE.md` (canonical — its inline comments state which optional sections apply)
- Bodies stay at overview level: one bullet per aspect of the change and its impact — never enumerate what the diff already shows (files, symbols, renames), never restate the linked Issue; name a symbol only when the impact statement needs it
- Keep PRs reviewable (up to ~500 lines) and don't repeat information already in the Issue or diff
- Merge method: a merge commit — never switch to squash/rebase without an explicit user instruction

## Prohibited

- Direct push to the `main` branch
- Force push on shared branches
- Massive file changes in a single PR
- Meaningless commit messages
