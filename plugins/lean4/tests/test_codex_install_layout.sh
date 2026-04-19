#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SKILL_LINK="$REPO_ROOT/.agents/skills/lean4"
CONFIG_FILE="$REPO_ROOT/.codex/config.toml"
EXPECTED_SKILL_PATH="$REPO_ROOT/plugins/lean4/skills/lean4/SKILL.md"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

echo "Checking repo-local Codex install layout..."

if [[ ! -L "$SKILL_LINK" ]]; then
  fail "missing repo-local .agents/skills/lean4 symlink"
fi

skill_link_target="$(readlink "$SKILL_LINK")"
if [[ "$skill_link_target" != "../../plugins/lean4/skills/lean4" ]]; then
  fail ".agents/skills/lean4 points to '$skill_link_target' (expected ../../plugins/lean4/skills/lean4)"
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  fail "missing workspace .codex/config.toml"
fi

if ! rg -F "path = \"$EXPECTED_SKILL_PATH\"" "$CONFIG_FILE" >/dev/null; then
  fail ".codex/config.toml does not enable $EXPECTED_SKILL_PATH"
fi

echo "PASS: repo-local Codex install layout looks correct"
