#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_ROOT="$PLUGIN_ROOT/skills/lean4"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

echo "Checking agent-skill structure..."

if [[ ! -L "$SKILL_ROOT/scripts" ]]; then
  fail "missing skill-local scripts symlink at skills/lean4/scripts"
fi

skill_scripts_target="$(readlink "$SKILL_ROOT/scripts")"
if [[ "$skill_scripts_target" != "../../lib/scripts" ]]; then
  fail "skills/lean4/scripts points to '$skill_scripts_target' (expected ../../lib/scripts)"
fi

if rg -n "LEAN4_SCRIPTS" "$SKILL_ROOT" >/dev/null; then
  fail "portable skill tree still references LEAN4_SCRIPTS"
fi

echo "PASS: agent-skill structure looks correct"
