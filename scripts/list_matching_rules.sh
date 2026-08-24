#!/usr/bin/env bash
# Lists the .claude/rules/*.md that apply to the given repo-relative file paths:
# always-loaded rules (no paths: frontmatter) plus every rule whose paths: glob
# matches an argument. Feeds the codex-implement brief and codex-review prompt
# so rule transfer is mechanical, not recalled.
set -u

cd "$(git rev-parse --show-toplevel)" || exit 1
[ $# -ge 1 ] || { echo 'usage: scripts/list_matching_rules.sh <repo-relative-file>...' >&2; exit 2; }
if ! command -v python3 >/dev/null 2>&1 || ! python3 -c 'import yaml' >/dev/null 2>&1; then
  echo 'ERROR: python3 with PyYAML is required (same dependency as check_ai_docs.sh)' >&2
  exit 1
fi

python3 - "$@" <<'PY'
import re
import sys
from pathlib import Path

import yaml


def glob_to_re(glob):
    out = ""
    i = 0
    while i < len(glob):
        if glob[i : i + 3] == "**/":
            out += "(?:.*/)?"
            i += 3
        elif glob[i : i + 2] == "**":
            out += ".*"
            i += 2
        elif glob[i] == "*":
            out += "[^/]*"
            i += 1
        elif glob[i] == "?":
            out += "[^/]"
            i += 1
        else:
            out += re.escape(glob[i])
            i += 1
    return re.compile("^" + out + "$")


targets = sys.argv[1:]
always, matched = [], {}
for rule in sorted(Path(".claude/rules").glob("*.md")):
    lines = rule.read_text(encoding="utf-8").splitlines()
    globs = []
    if lines and lines[0] == "---":
        try:
            closing = lines.index("---", 1)
            frontmatter = yaml.safe_load("\n".join(lines[1:closing])) or {}
            globs = [g for g in frontmatter.get("paths", []) if isinstance(g, str)]
        except (ValueError, yaml.YAMLError):
            globs = []
    if not globs:
        always.append(rule)
        continue
    patterns = [glob_to_re(g) for g in globs]
    hits = [t for t in targets if any(p.match(t) for p in patterns)]
    if hits:
        matched[rule] = hits

print("== always loaded")
for rule in always:
    print(rule)
print("== matched by paths")
if not matched:
    print("(none)")
for rule, hits in matched.items():
    print(f"{rule}: {', '.join(hits)}")
PY
