# Syncing `agent-skill` With `claude-code`

This fork keeps two long-lived branches:

- `claude-code`: upstream-style branch for the Claude-oriented plugin layout
- `agent-skill`: derived branch that reapplies the Agent Skills refactor

The goal of this document is to make the refactor replayable after upstream
changes land on `claude-code`.

## Invariants To Preserve

Keep these deltas on `agent-skill` unless the Agent Skills standard changes:

- `plugins/lean4/skills/lean4/scripts` exists and is a symlink to `../../lib/scripts`
- `plugins/lean4/skills/lean4/SKILL.md` and the portable reference tree use
  relative `scripts/...` paths instead of `LEAN4_SCRIPTS`
- repo-local Codex install wiring exists:
  - `.agents/skills/lean4 -> ../../plugins/lean4/skills/lean4`
  - `.codex/config.toml` enables
    `/Users/yuekai/codex-lean4-workflows/plugins/lean4/skills/lean4/SKILL.md`
- root install docs describe the portable skill tree and the repo-local Codex
  install path
- `plugins/lean4/tools/lint_docs.sh` accepts `scripts/...` in the portable
  skill tree and checks the skill-local symlink

## Replay Workflow

1. Update `claude-code`.
   ```bash
   git checkout claude-code
   git pull --ff-only origin claude-code
   ```

2. Recreate `agent-skill` from the updated source branch.
   If you want a throwaway replay branch first:
   ```bash
   git checkout -b agent-skill-refresh claude-code
   ```
   If you are updating the long-lived branch directly:
   ```bash
   git checkout agent-skill
   git rebase claude-code
   ```

3. Reapply the known refactor surfaces.
   Search for the old contract first:
   ```bash
   rg -n "LEAN4_SCRIPTS|LEAN4_REFS|LEAN4_PLUGIN_ROOT" \
     plugins/lean4/skills/lean4 README.md INSTALLATION.md plugins/lean4/README.md plugins/lean4/MIGRATION.md
   ```
   Then restore the expected state:
   - recreate `plugins/lean4/skills/lean4/scripts -> ../../lib/scripts` if it drifted
   - convert portable skill-tree references back to `scripts/...`
   - keep Claude-only env vars limited to Claude adapter internals
   - keep `.agents/skills/lean4` and `.codex/config.toml` aligned with the repo path
   - update `SYNC.md` if the replay procedure itself changes

4. Re-run the focused verification suite.
   ```bash
   bash plugins/lean4/tests/test_agent_skill_structure.sh
   bash plugins/lean4/tests/test_codex_install_layout.sh
   bash plugins/lean4/tests/test_lint_bash_compat.sh
   bash plugins/lean4/tests/test_guardrails.sh
   bash plugins/lean4/tools/lint_docs.sh
   ```

5. Re-run Codex discovery checks from the repo root.
   ```bash
   codex debug prompt-input "Edit a Lean 4 proof" | rg "lean4|plugins/lean4/skills/lean4/SKILL.md"
   ```
   Confirm that the fresh prompt input includes the `lean4` skill from this
   repo checkout.

6. Re-run the subagent check.
   In a fresh session, dispatch a bounded child task that reads:
   - `.agents/skills/lean4/SKILL.md`
   - `.agents/skills/lean4/scripts`
   The child should report the same repo-local skill path and see relative
   `scripts/...` references in the portable skill tree.

7. Fast-forward or merge back into `agent-skill`, then push.

## Files Most Likely To Drift

- `plugins/lean4/skills/lean4/SKILL.md`
- `plugins/lean4/skills/lean4/references/`
- `plugins/lean4/tools/lint_docs.sh`
- `README.md`
- `INSTALLATION.md`
- `plugins/lean4/README.md`
- `plugins/lean4/MIGRATION.md`
- `.agents/skills/lean4`
- `.codex/config.toml`

## Acceptance Criteria

Treat the sync as complete only if all of these are true:

- `plugins/lean4/tests/test_agent_skill_structure.sh` passes
- `plugins/lean4/tests/test_codex_install_layout.sh` passes
- the selected shell regression tests still pass
- fresh `codex debug prompt-input` shows the `lean4` skill from this repo
- a spawned child task can read the same repo-local skill install
- the portable skill tree no longer contains `LEAN4_SCRIPTS`
