# Working Agreement

Canonical working rules for every coding agent in this repository. Claude Code loads this rule
in every session; Codex reaches it through `AGENTS.md`, which summarizes and points here. When
they drift, this file wins. Project-specific seams of this agreement live in
`.claude/rules/working-agreement.project.md`.

## Instruction Priority

When guidance conflicts, use this order:

1. The user's current request
2. The closest applicable agent guidance (this file and the other `.claude/rules/*.md`; for Codex, the closest `AGENTS.md`)
3. Current source code and build configuration
4. The project's architecture overview documents, when present (the project rules name them)

Treat source code as authoritative when generated documentation, examples, or copied patterns
have drifted. This source-over-document rule does not override applicable agent guidance in
`.claude/rules/*.md`. Preserve the project's established structure, conventions, and validation
approach; project-specific invariants are stated in the project rules.

## Before Editing

- Inspect the files being changed and their nearest analogous implementation.
- Check `git status`; preserve user changes and avoid unrelated cleanup.
- Verify referenced APIs, tasks, modules, and paths in the current checkout instead of relying on documentation alone.
- For a non-trivial change, define verifiable success criteria first — the narrowest validation that must pass and, for user-visible UI changes, what to confirm in the running product — and validate against them before reporting completion.

## While Editing

- Make the smallest coherent change that satisfies the request.
- Follow existing module boundaries and naming before introducing a new abstraction.
- Keep refactors separate from behavior changes unless the refactor is required.
- Do not edit generated files or build output.
- Keep documentation concise and proportional; prefer one clear instruction over repeated wording, exhaustive safeguards, or speculative edge cases.
- Volatile facts that would need synchronized edits — commands, flags, versions, thresholds, module/task enumerations — have one canonical source, preferably the code or configuration itself; other documents point to it and add only why or when it matters. When pointing at a canonical, do not append a breakdown — a parenthetical example list is still an enumeration and drifts. Entrypoints may restate stable safety invariants, and checklists state completion outcomes, not implementation details.
- Escalate when stuck: after a few failed attempts without a confirmed root cause, stop and consult the user instead of applying speculative fixes.

## Comments

- Comments are exceptional: the default for agent-written code is no comments at all.
- The only admissible comment states a constraint the code cannot express — a workaround pinned to an external bug, a non-obvious invariant — and must be individually justifiable. Anything else, including correct-but-derivable rationale, is deleted.
- A comment lives in the file it describes; never describe another file or module from elsewhere.
- A stale comment is deleted or trimmed to its non-derivable part, never rewritten into a cross-reference.

## Scope Of A Request

- Filing an issue defaults to continuing into the dispatched autonomous flow (`ship-issue` — Dispatch): the work starts in its own dispatched worktree, never on the current checkout's branch. Stop after the completion report instead when the user asks to only record the issue, for backlog or checklist batches, or when no dispatch lane exists on this host.
- Asking for an opinion is not a signal to start implementing; consultative phrasing requests an opinion, not execution.
- A problem report or wish phrased as 「〜したい」 defaults to confirming whether to file an Issue, not to starting the implementation.
- A consultation ends when the user settles the question it was about: that answer is the go-ahead. Continue from it into filing the Issue and the dispatched flow instead of asking for a separate confirmation on top of a decision already made.
- Do not commit, push, create an Issue, or open a PR unless the user asks for that action.

## Build And Validation

- Prefer the narrowest command that covers the change. The per-change-type validation table and
  the project's validation notes are canonical in `.claude/rules/project-validation.md` — a
  fixed-name rule defined by every project.
- New logic in testable layers follows TDD (the `tdd` skill); which suites and conventions apply
  is part of the same validation profile.
- Do not claim runtime behavior was verified when only compilation or static analysis was run.

## Before Handing Off

- Review the final diff for accidental or unrelated changes.
- Verify before asserting: check API existence and behavior against the resolved dependency version or official sources; confirm the running build actually contains the change before diagnosing from runtime observations; distinguish live data from fallbacks before declaring end-to-end success; separate observation from speculation when reporting.
- When a skill step names the independent review lane, it maps to the `rules-reviewer` and `code-reviewer` agents run independently (Codex wrappers: `rules_reviewer` / `code_reviewer`); a cross-model reviewer exists only on Claude Code (the `codex-review` skill).
- Run the narrowest relevant validation, expanding to broader checks for cross-module or release-impacting changes. Narrowest applies to validation commands only — review depth never scales down: the review loop runs until a round yields no actionable findings.
- Report what changed, what was validated, and anything not validated.

## Safety And Maintenance

- Never expose secrets, credentials, tokens, signing material, or machine-specific configuration.
- Do not add heavy dependencies without approval.
- Do not rewrite large areas, rename public APIs, or move code across modules unless the task requires it.
- Never discard or overwrite unrelated working-tree changes.
- When generated templates or docs disagree with current source code, the source wins (subject to Instruction Priority above).
- Keep `AGENTS.md` and this file updated together when agent-level instructions change.
