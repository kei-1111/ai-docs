#!/usr/bin/env bash
# Review harness for the codex-review skill: determines the review target,
# enumerates the applicable rules via list_matching_rules.sh, composes the
# self-contained prompt, and runs `codex exec --sandbox read-only` with the
# prompt passed via stdin (an inline argument can hang the CLI at startup).
# Verifying the findings stays with the caller.
# Usage: scripts/codex_review.sh [-p <PR-number>] [-f <focus>] [--dry-run]
set -u -o pipefail

die() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

cd "$(git rev-parse --show-toplevel)" || exit 1

pr='' focus='' dry_run=0
while [ $# -gt 0 ]; do
  case "$1" in
    -p) shift; pr=${1:-}; [ -n "$pr" ] || die '-p needs a PR number' ;;
    -f) shift; focus=${1:-}; [ -n "$focus" ] || die '-f needs focus text' ;;
    --dry-run) dry_run=1 ;;
    *) die "unknown argument: $1" ;;
  esac
  shift
done
command -v codex >/dev/null 2>&1 || die 'codex CLI not found on PATH'

# --- Determine the target and its changed files -------------------------------
pr_files_unknown=0
if [ -n "$pr" ]; then
  target_desc="PR #$pr — inspect it yourself with: gh pr view $pr, gh pr diff $pr"
  changed=$(gh pr diff "$pr" --name-only 2>/dev/null) ||
    { echo 'WARNING: gh pr diff failed; rule enumeration skipped' >&2; changed=''; pr_files_unknown=1; }
elif [ -n "$(git status --porcelain)" ]; then
  target_desc='the UNCOMMITTED working-tree changes — inspect them yourself with: git status --porcelain, git diff HEAD, and read untracked files in full (git ls-files --others --exclude-standard)'
  changed=$(
    git diff HEAD --name-only
    git ls-files --others --exclude-standard
  )
else
  git fetch origin main -q || die 'git fetch origin main failed'
  target_desc='the current branch vs origin/main — inspect it yourself with: git diff origin/main...HEAD'
  changed=$(git diff origin/main...HEAD --name-only)
fi
[ -n "$changed" ] || [ "$pr_files_unknown" -eq 1 ] || die 'nothing to review for the chosen target'

# --- Compose the prompt -------------------------------------------------------
rules=$(printf '%s\n' "$changed" | xargs ./scripts/list_matching_rules.sh) || {
  echo 'WARNING: rule enumeration failed — the prompt will tell Codex to enumerate the rules itself' >&2
  rules='(rule enumeration unavailable — enumerate and read the applicable .claude/rules/*.md yourself)'
}
prompt=$(mktemp "${TMPDIR:-/tmp}/codex-review-prompt.XXXXXX") || die 'mktemp failed'
{
  echo 'You are an independent code reviewer for this repository (you are in the repo root).'
  echo
  echo "Review target: $target_desc"
  [ -n "$focus" ] && { echo; echo "Additional review focus from the caller: $focus"; }
  echo
  echo 'Review against the project conventions: read AGENTS.md and every rule file listed below (the list was produced mechanically from the changed paths).'
  echo
  echo "$rules"
  echo
  echo 'Output format, per finding: severity (high/medium/low) / file:line / problem / why it matters / suggested fix.'
  echo 'Read the cited code and verify each claim before reporting it. Do NOT invent findings — "no findings" is a valid outcome. End with a one-paragraph overall verdict.'
} > "$prompt"

if [ "$dry_run" -eq 1 ]; then
  echo "--- prompt ($prompt) ---"
  cat "$prompt"
  exit 0
fi

log=$(mktemp "${TMPDIR:-/tmp}/codex-review-out.XXXXXX") || die 'mktemp failed'
codex exec --sandbox read-only - < "$prompt" 2>&1 | tee "$log"
rc=$?
echo
echo "prompt: $prompt"
echo "log: $log"
exit "$rc"
