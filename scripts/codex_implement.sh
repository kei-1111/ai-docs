#!/usr/bin/env bash
# Delegation harness for the codex-implementer agent
# (ai-docs/shared/agents/codex-implementer/SKILL.md). Snapshots the working
# tree, streams the director's brief to `codex exec` (model pinned below), optionally
# verifies the result and feeds failures back into the same Codex session, then
# prints a delta report so the caller can attribute exactly what Sol changed.
#
# Usage: scripts/codex_implement.sh -b <brief-file> [-v <verify-command>] [-r <max-fix-rounds>] [-s <session-id>]
#   -b  implementation brief (initial run) or delta instruction (with -s)
#   -v  narrowest verification command proving the change builds/passes, run
#       with `sh -c`, e.g. './gradlew :<module>:<compile-task>'
#       (select it from the project's validation profile,
#       .claude/rules/project-validation.md). Runs on the host, NOT in the
#       sandbox: in-sandbox Gradle was measured (2026-07-18) to need full
#       sandbox network access for its file-lock contention socket, which
#       would drop the sandbox's network isolation.
#       The gradlew-specific JAVA_HOME setup and dry-run preflight below are
#       fast paths that no-op for non-Gradle verify commands.
#   -r  max automatic fix rounds fed back via `codex exec resume` (default 2)
#   -s  resume this Codex session instead of starting a fresh one (delta briefs)
set -u -o pipefail

usage() {
  echo 'usage: scripts/codex_implement.sh -b <brief-file> [-v <verify-command>] [-r <max-fix-rounds>] [-s <session-id>]' >&2
  exit 2
}
die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

brief='' verify_cmd='' max_rounds=2 sid=''
while getopts 'b:v:r:s:' opt; do
  case "$opt" in
    b) brief=$OPTARG ;;
    v) verify_cmd=$OPTARG ;;
    r) max_rounds=$OPTARG ;;
    s) sid=$OPTARG ;;
    *) usage ;;
  esac
done
[ -n "$brief" ] || usage
[ -f "$brief" ] || die "brief file not found: $brief"
case "$verify_cmd" in
  :*) die "-v takes a full command since the generalization; prepend the runner: -v './gradlew $verify_cmd'" ;;
esac
case "$max_rounds" in
  ''|*[!0-9]*) die "-r must be a non-negative integer: $max_rounds" ;;
esac
command -v codex >/dev/null 2>&1 || die 'codex CLI not found on PATH'
repo=$(git rev-parse --show-toplevel 2>/dev/null) || die 'not inside a git repository'
cd "$repo" || die "cannot cd to $repo"

# Gradle-specific host setup, applied only when the verify command uses gradlew.
# A stale JAVA_HOME (e.g. pointing into a moved Android Studio) breaks ./gradlew.
# /usr/libexec/java_home is macOS-only; elsewhere fall back to java on PATH.
case "$verify_cmd" in
  *gradlew*)
    if [ -z "${JAVA_HOME:-}" ] || [ ! -x "${JAVA_HOME}/bin/java" ]; then
      if [ -x /usr/libexec/java_home ] && JAVA_HOME=$(/usr/libexec/java_home -v 21 2>/dev/null); then
        export JAVA_HOME
      elif command -v java >/dev/null 2>&1; then
        unset JAVA_HOME
      else
        die 'no usable JDK for -v: export JAVA_HOME or install a JDK'
      fi
    fi
    ;;
esac

# Gradle preflight before spending Codex rounds: --dry-run configures the
# task graph (wrapper, plugins, dependency resolution) without executing, so it
# succeeds even when the code does not compile yet — a failure here is
# infrastructure or a mistyped task, never Sol's code. Non-Gradle verify
# commands have no equivalent cheap preflight and skip this.
case "$verify_cmd" in
  ./gradlew\ *)
    rest=${verify_cmd#./gradlew }
    case "$rest" in
      *'&'*|*';'*|*'|'*|*'$'*|*'>'*|*'<'*) ;;
      *)
        sh -c "./gradlew --dry-run $rest" > /dev/null 2>&1 ||
          die "-v preflight failed (infra not ready or unknown task): run ./gradlew --dry-run $rest"
        ;;
    esac
    ;;
esac

# --- Pre-delegation snapshot, kept outside the repository ---------------------
# The post-run comparison must isolate Sol's changes even on a dirty tree,
# including edits inside pre-existing untracked files, so untracked contents
# are copied in full rather than listed or hashed.
snap=$(mktemp -d "${TMPDIR:-/tmp}/codex-implement.XXXXXX") || die 'mktemp failed'
git status --porcelain=v1 > "$snap/status-before.txt" || die 'snapshot failed: git status'
git diff HEAD --binary > "$snap/diff-before.patch" || die 'snapshot failed: git diff'
mkdir "$snap/untracked" || die 'snapshot failed: mkdir'
git ls-files --others --exclude-standard -z |
  ( while IFS= read -r -d '' f; do
      mkdir -p -- "$snap/untracked/$(dirname "$f")" && cp -pRP -- "$f" "$snap/untracked/$f" || exit 1
    done ) || die 'snapshot failed: untracked file copy'

# --- Baseline validation on a dirty tree --------------------------------------
# If pre-existing changes already break the verify command, the fix loop would
# push Sol into repairing code outside the brief; refuse to delegate instead.
if [ -n "$verify_cmd" ] && [ -s "$snap/status-before.txt" ]; then
  sh -c "$verify_cmd" > "$snap/baseline-verify.log" 2>&1 ||
    die "baseline validation failed before delegating: the dirty tree already fails '$verify_cmd' (log: $snap/baseline-verify.log)"
fi

# --- Delegate -----------------------------------------------------------------
# The trailer is appended with printf, not a heredoc: a brief line matching a
# heredoc delimiter would silently truncate the brief.
trailer='Leave all changes uncommitted in the working tree. Do not create branches or commits. Do not run build, test, or other verification commands - the harness verifies after you finish and sends any failure back into this session. Do not run git commands that update the index (git mv, git add, git rm) - rename or delete with plain file operations instead; this sandbox cannot write the worktree index and the command hangs forever. Change only what the brief requires; if something outside its stated scope blocks you, stop and report it instead of fixing it.'
if [ -n "$sid" ]; then
  { cat "$brief"; printf '\n%s\n' "$trailer"; } |
    codex exec resume "$sid" -c 'sandbox_mode="workspace-write"' - 2>&1 |
    tee "$snap/codex-round-0.log"
else
  { cat "$brief"; printf '\n%s\n' "$trailer"; } |
    codex exec -m gpt-5.6-sol -c model_reasoning_effort=high --sandbox workspace-write - 2>&1 |
    tee "$snap/codex-round-0.log"
fi
rc=$?
[ "$rc" -eq 0 ] || die "codex exec failed with status $rc (log: $snap/codex-round-0.log)"
if [ -z "$sid" ]; then
  sid=$(sed -n 's/^session id: //p' "$snap/codex-round-0.log" | head -1)
  [ -n "$sid" ] ||
    printf 'WARNING: no "session id:" line in codex output (CLI banner changed?); fix rounds and delta resume are unavailable\n' >&2
fi

# --- Verify on the host, feeding failures back into the same session ----------
verify_result=skipped
rounds_used=0
if [ -n "$verify_cmd" ]; then
  while :; do
    if sh -c "$verify_cmd" > "$snap/verify-round-$rounds_used.log" 2>&1; then
      verify_result=pass
      break
    fi
    if [ "$rounds_used" -ge "$max_rounds" ] || [ -z "$sid" ]; then
      verify_result=fail
      break
    fi
    rounds_used=$((rounds_used + 1))
    # Constraints are restated because Sol may act on this message alone.
    { printf '%s\n\n' "The verification command failed. Fix the cause in the same working tree. Same constraints: leave changes uncommitted, no branches or commits, do not run build or test commands, no index-updating git commands (git mv, git add, git rm) - the harness re-verifies after you finish. If the cause lies outside the brief's target files (pre-existing or unrelated code), do not modify anything - report the cause instead."
      printf -- '---- %s output (tail) ----\n' "$verify_cmd"
      tail -n 80 "$snap/verify-round-$((rounds_used - 1)).log"
    } | codex exec resume "$sid" -c 'sandbox_mode="workspace-write"' - 2>&1 |
      tee "$snap/codex-round-$rounds_used.log"
    [ $? -eq 0 ] || { verify_result=fail; break; }
  done
fi

# --- Delta report -------------------------------------------------------------
git status --porcelain=v1 > "$snap/status-after.txt" || die 'post-run snapshot failed: git status'
git diff HEAD --binary > "$snap/diff-after.patch" || die 'post-run snapshot failed: git diff'
echo
echo '=== codex-implement delta report ==='
echo "session id: ${sid:-unknown (not found in codex output)}"
if [ -n "$verify_cmd" ]; then
  echo "verify: $verify_result ($verify_cmd, $rounds_used fix round(s))"
else
  echo "verify: skipped"
fi
echo 'status delta since snapshot (< before / > after):'
# diff exits 1 when files differ, which pipefail would misread as a failure,
# so capture the delta instead of testing the pipeline status.
status_delta=$(diff "$snap/status-before.txt" "$snap/status-after.txt" | grep '^[<>]')
if [ -n "$status_delta" ]; then
  printf '%s\n' "$status_delta"
else
  echo '  (no status-line change)'
fi
echo "snapshot kept at: $snap"
echo '  attribute content changes by comparing diff-before.patch / diff-after.patch'
echo '  and pre-existing untracked contents under untracked/'
[ "$verify_result" != fail ] || exit 1
