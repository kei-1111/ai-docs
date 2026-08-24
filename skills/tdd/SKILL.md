---
name: tdd
description: Drive implementation of new or changed logic through the red-green-refactor TDD cycle — one failing test at a time, minimal code to green, refactor kept green. Use when implementing logic in a testable layer (business logic, data access, serialization, server endpoints — the project's TDD rule defines the exact set), whether the user asks for TDD directly or the work arrives via implement-issue, so tests are written first instead of after the fact.
user-invocable: false
---

# TDD

## Task overview

Execute the project's test-first process as a concrete workflow. Applicability and the
prohibitions are canonical in the project's TDD rule (`.claude/rules/tdd.md`) when the project
defines one; the suite conventions for the touched layer are named in
`.claude/rules/project-validation.md`. This skill is canonical for the execution sequence —
where it and a rule's constraints disagree, the rule wins.

## Preconditions

- The change adds or modifies logic in a testable layer — the project's TDD rule defines the
  exact set (this project: `.claude/rules/tdd.md`); business logic, data access, and
  serialization are typical. Pure UI rendering has no test-first assertion — end-to-end tests
  and visual judgment cover it (the project's UI-testing rule, when one exists).
- The test can actually be written first. In a layer whose suite does not exist yet, the
  first test introduces the suite itself per the TDD rule — that is not a blocker. If the test still cannot be written first (an untestable seam, missing
  infrastructure with no bootstrap path), STOP and surface that as the finding instead of
  silently skipping TDD.

## Workflow

1. **Test list** — from the requirement, write the list of expected behaviors including edge
   cases, implementing none of them. Behaviors discovered mid-cycle go onto the list, not
   straight into code.
2. **Red** — turn exactly ONE list item into a test (conventions per the suite rule for the
   layer). Run the narrowest test task and observe the failure; confirm it fails for the
   intended behavioral reason — a compile failure counts, a broken fixture or unrelated error
   does not.
3. **Green** — write the minimum production code that makes the new test and all previous
   tests pass; re-run the same task.
4. **Refactor** — clean up with everything kept green; re-run after refactoring.
5. Repeat 2–4 until the test list is empty.
6. **Final validation** — run the change-type validation from
   `.claude/rules/project-validation.md` after the cycle is green.

Derive the narrowest test task from the same validation table and the touched module's suite rule.

## Guardrails

The prohibitions are canonical in the project's TDD rule (`.claude/rules/tdd.md` — Process
Anti-Patterns) when the project defines one; they bind every cycle here. In particular, when
red persists the production code is what changes — never edit the test to force a pass.

## Model routing

Test authoring and the red/green judgment (why a test fails, whether green is genuine) stay with
the directing agent. Where the product has a delegated implementation lane (Claude Code: `CLAUDE.md` — Working
Principles, model routing), the Green step may be delegated with the failing test as the contract —
the delegate makes the test pass and never edits it.
