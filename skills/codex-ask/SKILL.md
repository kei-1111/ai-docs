---
name: codex-ask
description: Ask the OpenAI Codex CLI for a second opinion on the current discussion — implementation approach, written code, or design decision. Use when the user asks for "Codex's opinion", "second opinion", "look at this from another angle", another agent's take (「別エージェントにも聞いてほしい」), or otherwise wants Codex's perspective on the current topic.
allowed-tools: Bash(codex:*), Read(*), Write
---

# Ask Codex

## Task overview

Forward the current question or topic to the OpenAI Codex CLI in non-interactive mode, then surface Codex's view to the user along with Claude's own view so the user can make the call. This skill never edits code — Codex's response is treated as advisory input.

## Workflow

### 1. Compose the question for Codex

Build a self-contained prompt for Codex (`codex exec` opens a fresh session that does not see this conversation). Include only what's needed:

- **Background**: what is being designed / built / discussed
- **Concrete subject**: the implementation idea, the file/diff under review, or the open question
- **What kind of input is wanted**: e.g. "are there pitfalls?", "would another approach be cleaner?", "review this diff"
- **Constraints**: relevant project rules (`CLAUDE.md`, `.claude/rules/*`, `AGENTS.md`) when material to the question

If Codex needs to read specific files, name them by path in the prompt (e.g. `src/feature/.../SomeScreen.kt`). Codex can read the workspace itself; do not paste large file contents into the prompt.

### 2. Run codex exec

Write the prompt to a file and pass it on stdin — a long inline argument can hang the CLI at
startup, and a file avoids shell-quoting issues. Opinions are read-only by design; never grant
workspace-write here:

```bash
codex exec --sandbox read-only - < <prompt-file>
```

- The prompt is the only argument forwarded; the skill does not auto-attach diffs, file contents, or other context. If the user wants a diff reviewed, they should mention it in their request and Codex will run `git diff` itself.
- Use a generous finite Bash timeout. If `codex exec` times out or fails, report that rather than
  retrying blindly.
- Large outputs may be persisted by the Bash tool to a file — read it back if needed.

### 3. Summarize and compare

After Codex returns:

- **Verify before relaying.** Codex is an LLM; its claims may be plausible-sounding but wrong. Cross-check any concrete assertion (API behavior, file contents, line numbers) before presenting it as fact.
- Distill Codex's view into a short summary — key recommendations, risks raised, alternatives suggested.
- Compare it with Claude's own view: agreements, disagreements, points Codex missed.

### 4. Present to the user

Report in this shape:

- **Codex's view**: 3–5 bullets
- **Claude's view**: 3–5 bullets (or "agrees with Codex" if so)
- **Suggested next action**: what to do (apply / discuss further / ignore)

Wait for the user's decision. Do not modify code based on Codex's response without explicit user approval.

## Notes

- **Boundary**: this skill relays a free-form question; for a structured review of code changes (working tree, branch, or PR) use `codex-review` instead.
- **No secret leakage.** Before passing a prompt to `codex exec`, confirm it contains no credentials, API keys, or other secrets. The prompt is sent to Codex's backend.

## Arguments

| Argument | Example | Behavior |
|----------|---------|----------|
| Free-form question | `Is this MVI design OK?` | Forward verbatim to `codex exec` after composing background context |
| Free-form with file references | `Look at SomeScreen.kt in src/feature and suggest improvements` | Codex reads the named files itself |
| (none) | — | Ask the user what they want Codex's opinion on |
