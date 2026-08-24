# ai-docs

Shared AI-agent tooling for kei-1111's repositories: workflow skills, agent contracts, rule
cores, and helper scripts consumed by both Claude Code and the Codex CLI. "Shared" here means
**cross-repository** — one canonical source consumed by every project via git submodule (a
consuming repository may also use the word shared for in-repo module sharing; the two are
unrelated).

## Layout

```
skills/<name>/SKILL.md    workflow skills (Agent Skills format)
agents/<name>/SKILL.md    subagent contracts (consumed via thin per-product wrappers)
rules/*.md                project-agnostic rule cores (working-agreement, git-workflow)
scripts/*.sh              helper scripts the skills and agents invoke
install.sh                lays the consumer-side symlinks (--claude / --codex)
```

## Consuming from a project

```bash
git submodule add https://github.com/kei-1111/ai-docs.git ai-docs/shared
ai-docs/shared/install.sh --claude --codex
git add -A && git commit
```

Cloning a consumer then needs `git clone --recurse-submodules` (or `git submodule update --init`).

`install.sh` creates per-skill symlinks (`.claude/skills/<name>`, `.codex/skills/<name>` —
Claude-only skills are excluded from the Codex side), rule-core symlinks
(`.claude/rules/git-workflow.md`, `.claude/rules/working-agreement.md`), and script symlinks
(`scripts/*.sh`). Project-specific assets live outside the submodule, canonically at
`ai-docs/project/` in the consumer, with their own symlinks alongside the shared ones.

## Consumer contract

Shared content references project-specific facts only through these seams, which every
consuming repository provides:

- `.claude/rules/project-validation.md` — the per-change-type validation table and validation
  notes (fixed name, always defined)
- `.claude/rules/doc-surfaces.md` — the document-surface inventory read by `update-docs`
  (fixed name, always defined)
- Project rule overlays (`*.project.md`) for seams of the rule cores — commit scopes,
  test-suite mapping, hooks, project invariants
- Conditional references ("when the project defines one") — e.g. a TDD rule
  (`.claude/rules/tdd.md`), architecture documents, or a project `verify-app`-style skill
- Agent wrappers: `.claude/agents/<name>.md` (frontmatter + "read the canonical and follow
  it") and `.codex/agents/<snake_name>.toml`, pointing at
  `ai-docs/shared/agents/<name>/SKILL.md`

A shared document must not name any other project-specific file, module, or convention.

## Editing and updating

The canonical copy lives here — never edit the files through a consumer's symlinks without
pushing from the submodule. The flow is: commit and push in this repository (directly or via
the submodule checkout), then in each consumer run `git submodule update --remote ai-docs/shared`
and commit the pin bump. Consumers pin a commit, so an upstream change never applies silently.

Prerequisites for the `codex-*` skills and the `codex-implementer` agent: the `codex` CLI
installed and authenticated. They fail fast with a clear error when it is missing.

`scripts/check_structure.sh` (run by CI on every push and PR) verifies the structural
invariants — SKILL.md presence and frontmatter, resolvable internal symlinks, and executable
scripts.
