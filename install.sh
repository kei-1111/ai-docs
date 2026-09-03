#!/usr/bin/env bash
# Lays the consumer-side symlinks for this shared AI-tooling repository.
# Run from the consuming repository root after adding the submodule, e.g.:
#   git submodule add https://github.com/kei-1111/ai-docs.git ai-docs/shared
#   ai-docs/shared/install.sh --claude --codex
#
# Flags (at least one required):
#   --claude  link .claude/skills/<name>, .claude/rules/<core>.md, scripts/<sc>.sh
#   --codex   link .codex/skills/<name> for the skills Codex uses while implementing
#
# After installing, the consumer still provides by hand:
#   - the fixed-name profile rules .claude/rules/project-validation.md and
#     .claude/rules/doc-surfaces.md (see README.md — Consumer contract)
#   - agent wrappers (.claude/agents/*.md / .codex/agents/*.toml) pointing at
#     <shared>/agents/<name>/SKILL.md
#
# On a name collision with an existing real file the script stops at that link;
# move the file aside and re-run — link() is idempotent, so completed links are
# recreated harmlessly.
set -u

CODEX_SKILLS='tdd'

die() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

shared_dir=$(dirname "$0")
case "$shared_dir" in
  /*) die 'run this script via its path relative to the consuming repository root (e.g. ai-docs/shared/install.sh)' ;;
esac
shared_dir=${shared_dir#./}
[ -d "$shared_dir/skills" ] || die "cannot locate the shared skills directory from $shared_dir"
[ -e .git ] || die 'run from the consuming repository root (no .git here)'

do_claude='' do_codex=''
for arg in "$@"; do
  case "$arg" in
    --claude) do_claude=1 ;;
    --codex) do_codex=1 ;;
    *) die "unknown flag: $arg (use --claude and/or --codex)" ;;
  esac
done
[ -n "$do_claude$do_codex" ] || die 'pass --claude and/or --codex'

# depth = number of path segments in $1; prints the ../ chain that climbs out of it
updirs() {
  printf '%s' "$1" | awk -F/ '{ for (i = 1; i <= NF; i++) printf "../" }'
}

link() { # link <link-path> <target-dir-relative-to-repo-root>
  link_path=$1 target=$2
  link_parent=$(dirname "$link_path")
  mkdir -p "$link_parent"
  rel=$(updirs "$link_parent")$target
  if [ -L "$link_path" ]; then
    [ "$(readlink "$link_path")" = "$rel" ] || { rm "$link_path" && ln -s "$rel" "$link_path"; }
  elif [ -e "$link_path" ]; then
    die "$link_path exists and is not a symlink; move it aside first"
  else
    ln -s "$rel" "$link_path"
  fi
  printf 'linked %s -> %s\n' "$link_path" "$rel"
}

for skill_dir in "$shared_dir"/skills/*/; do
  name=$(basename "$skill_dir")
  [ -n "$do_claude" ] && link ".claude/skills/$name" "$shared_dir/skills/$name"
  if [ -n "$do_codex" ]; then
    case " $CODEX_SKILLS " in
      *" $name "*) link ".codex/skills/$name" "$shared_dir/skills/$name" ;;
    esac
  fi
done

if [ -n "$do_claude" ]; then
  for rule in "$shared_dir"/rules/*.md; do
    link ".claude/rules/$(basename "$rule")" "$shared_dir/rules/$(basename "$rule")"
  done
  for sc in "$shared_dir"/scripts/*.sh; do
    case "$(basename "$sc")" in check_structure.sh) continue ;; esac
    link "scripts/$(basename "$sc")" "$shared_dir/scripts/$(basename "$sc")"
  done
fi

printf '\nDone. Remaining manual steps: profile rules (project-validation.md, doc-surfaces.md) and agent wrappers — see %s/README.md\n' "$shared_dir"
