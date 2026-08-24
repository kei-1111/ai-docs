#!/usr/bin/env bash
# Structural invariants for this repository, run by CI on every push and PR.
set -u

fail=0
err() { printf 'ERROR: %s\n' "$1" >&2; fail=1; }

cd "$(dirname "$0")/.." || { echo 'cannot cd to repo root' >&2; exit 1; }

for kind in skills agents; do
  [ -d "$kind" ] || { err "missing directory: $kind"; continue; }
  for dir in "$kind"/*/; do
    name=$(basename "$dir")
    md="$dir/SKILL.md"
    [ -f "$md" ] || { err "$kind/$name lacks SKILL.md"; continue; }
    head -1 "$md" | grep -qx -- '---' || err "$md lacks frontmatter"
    grep -q '^name: ' "$md" || err "$md frontmatter lacks name:"
    grep -q '^description: ' "$md" || err "$md frontmatter lacks description:"
    grep -q "^name: $name$" "$md" || err "$md frontmatter name does not match directory $name"
  done
done

for core in rules/git-workflow.md rules/working-agreement.md; do
  [ -f "$core" ] || err "missing rule core: $core"
done

for sc in scripts/*.sh install.sh; do
  [ -x "$sc" ] || err "$sc is not executable"
done

while IFS= read -r l; do
  [ -e "$l" ] || err "dangling symlink: $l -> $(readlink "$l")"
done <<EOF
$(find skills agents -type l)
EOF

if grep -rn 'kei-1111\.github\.io\|io\.github\.kei_1111' skills agents rules --include='*.md' | grep -v 'github.com/kei-1111/ai-docs'; then
  err 'project-specific identifier leaked into shared content (above)'
fi

[ "$fail" -eq 0 ] && echo 'structure check passed'
exit "$fail"
