---
name: update-docs
description: Internal documentation-maintenance step — update project documents made stale by an implementation before handoff. Invoked by implementation workflows such as ship-issue and create-destination, not directly by the user.
user-invocable: false
---

# Update docs

## Task overview

Find every project document the current change has made stale and bring it up to date with the
smallest natural edit. Run after the code change is complete and before its handoff, commit, or PR.

## Document surfaces

The project's surface inventory is canonical in `.claude/rules/doc-surfaces.md` — a fixed-name
rule defined by every project. Read it and check each listed surface against the change.

## Workflow

1. **Scope the change** — review `git fetch origin main` then `git diff origin/main...HEAD` (and the working tree) for what actually changed; the local `main` ref may be stale
2. **Collect candidates** — search the surfaces above for the changed symbols, paths, and concepts
3. **Verify against code** — current source is authoritative; touch only statements that are now wrong
4. **Edit minimally** — fix the existing sentence in place rather than adding new sections
5. **Re-read** — read each edited document start to finish and confirm it reads naturally as a whole
6. **Report** — list updated docs and checked-but-current docs; "no updates needed" is a valid outcome

## Writing constraints

- Docs describe the current state — never narrate the change or its history; retain only rationale
  that explains a non-obvious current rule or constraint
- Keep each edit proportional: one clear sentence over repeated wording or speculative safeguards
- Do not let rule documents grow when the change only warrants adjusting a line

## Argument handling

| Argument | Behavior |
|---|---|
| Free-form context | Treat as a hint about where the change's impact lies |
| (none) | Derive the scope from the branch diff |
