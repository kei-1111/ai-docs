#!/usr/bin/env bash
# Lists comment lines ADDED by the staged diff, with language-aware patterns,
# for the create-commit comment-policy pass. Pure listing — the keep/delete
# judgment stays with the caller.
set -u

cd "$(git rev-parse --show-toplevel)" || exit 1

found=0
while IFS= read -r file; do
  case "$file" in
    *.kt|*.kts|*.java|*.js|*.ts) pattern='(^|[^:])//|/\*|^[[:space:]]*\*' ;;
    *.css) pattern='/\*' ;;
    *.sh|*.yml|*.yaml|*.py|*.toml|*.properties) pattern='(^|[[:space:]])#' ;;
    *.html|*.md|*.xml) pattern='<!--' ;;
    *.sql) pattern='(^|[[:space:]])--' ;;
    *) continue ;;
  esac
  matches=$(git diff --staged -U0 -- "$file" | grep -E '^\+' | grep -Ev '^\+\+\+ ' | sed 's/^+//' | grep -E "$pattern" | grep -Ev '^#!')
  if [ -n "$matches" ]; then
    found=1
    printf '== %s\n' "$file"
    printf '%s\n' "$matches"
  fi
done < <(git diff --staged --name-only --diff-filter=ACMR)

[ "$found" -eq 0 ] && echo "no added comment lines detected"
exit 0
