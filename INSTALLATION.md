# Installation Guide

## Portable Skill Layout

The portable entrypoint is the skill directory itself:

```text
plugins/lean4/skills/lean4/
├── SKILL.md
├── references/
└── scripts -> ../../lib/scripts
```

Non-Claude hosts should point the agent at `SKILL.md` and preserve that bundled
`scripts/` + `references/` layout. Claude Code still exports adapter-specific
environment variables internally, but the portable skill contract no longer
depends on them.

## Claude Code (Native Plugin)

```bash
/plugin marketplace add cameronfreer/lean4-skills
/plugin install lean4
```

That's it! The skill activates automatically when working with `.lean` files.

### Verify

```
/lean4:doctor
```

### Platform Notes

#### Windows

**Option 1: VSCode Extension (recommended)**
- Install [Claude Code for VS Code](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code)
- No Bash required

**Option 2: Git Bash**
- Install [Git for Windows](https://git-scm.com/download/win)
- Use Git Bash for Claude Code CLI

#### macOS / Linux

No special setup required.

### Troubleshooting

#### Plugin Not Loading

1. Check installation: `/plugin list`
2. Restart Claude Code
3. Run `/lean4:doctor`

#### LSP Server Not Working

1. Verify installation: https://github.com/oOo0oOo/lean-lsp-mcp
2. Run `lake build` in your project first (avoids timeouts). If fresh clone/worktree or after `lake clean`, prime cache first: `lake cache get` or `lake exe cache get`.
3. Restart Claude Code
4. Test: try `lean_goal` on a `.lean` file

#### Bootstrap Variables Missing

Claude Code sets its internal Lean 4 adapter variables from the bootstrap hook.
If `/lean4:doctor` reports them missing:
1. Restart Claude Code session
2. Check `/lean4:doctor env`

#### Scripts Not Executable

```bash
chmod +x ~/.claude/plugins/lean4/lib/scripts/*.sh ~/.claude/plugins/lean4/lib/scripts/*.py
```

## OpenAI Codex CLI

Create a repo-local discovery symlink so parent sessions and spawned subagents
see the same skill tree:

```bash
mkdir -p .agents/skills
ln -s /path/to/lean4-skills/plugins/lean4/skills/lean4 .agents/skills/lean4
```

Optionally add workspace-local Codex config:

```toml
[[skills.config]]
path = "/path/to/lean4-skills/plugins/lean4/skills/lean4/SKILL.md"
enabled = true
```

Add to your project's `AGENTS.md` (model context):

```markdown
## Lean 4 Workflows

See /path/to/lean4-skills/plugins/lean4/skills/lean4/SKILL.md for proving workflows.
```

Codex MCP setup remains separate:

```bash
codex mcp add lean-lsp -- npx lean-lsp-mcp --project /path/to/lean/project
```

### Verify

```bash
readlink .agents/skills/lean4
python3 .agents/skills/lean4/scripts/sorry_analyzer.py . --format=summary --report-only
codex debug prompt-input "Use the lean4 skill if available." >/tmp/lean4-prompt.json
# If MCP configured: test `lean_goal` in a fresh Codex session
```

## Gemini CLI

Add to your project's `GEMINI.md` (or global `~/.gemini/GEMINI.md`).

**If your Gemini CLI version supports file includes:**

```markdown
## Lean 4 Workflows
@./lean4-skills/plugins/lean4/skills/lean4/SKILL.md
```

**Manual fallback:** Copy relevant sections of SKILL.md into your GEMINI.md,
or instruct Gemini to read the file:

```markdown
## Lean 4 Workflows
Read ./lean4-skills/plugins/lean4/skills/lean4/SKILL.md for proving workflows.
```

### Verify

```bash
python3 /path/to/lean4-skills/plugins/lean4/skills/lean4/scripts/sorry_analyzer.py . --format=summary --report-only
```

## Cursor

> These are documented setup patterns, not CI-verified adapters.

Create `.cursor/rules/lean4.mdc` in your project:

```yaml
---
description: Lean 4 theorem proving workflows
globs: ["**/*.lean"]
---
```

Then paste the content of `plugins/lean4/skills/lean4/SKILL.md` into the rule body,
or keep it concise and reference the file path for the agent to read.

### Verify

Open a `.lean` file, ask the agent to run:

```bash
python3 /path/to/lean4-skills/plugins/lean4/skills/lean4/scripts/sorry_analyzer.py . --format=summary --report-only
```

## Windsurf

> These are documented setup patterns, not CI-verified adapters.

Windsurf uses its own rules format. Adapt the Cursor pattern above to
Windsurf's rule system — see [Windsurf docs](https://docs.windsurf.com/windsurf/getting-started)
for the current config format. The core setup is the same: point the agent at
`SKILL.md` and keep the bundled `scripts/` directory intact.

## OpenCode

> These are documented setup patterns, not CI-verified adapters.

If using [oh-my-opencode](https://github.com/nicobailon/oh-my-opencode) or
your OpenCode setup supports skill discovery, place the skill where it can be found.
Replace `/path/to` with the actual location of your clone:

```bash
# Option A: project-level (copies SKILL.md + references/)
mkdir -p .opencode/skills
cp -r "/path/to/lean4-skills/plugins/lean4/skills/lean4" .opencode/skills/

# Option B: global
mkdir -p ~/.config/opencode/skills
cp -r "/path/to/lean4-skills/plugins/lean4/skills/lean4" ~/.config/opencode/skills/
```

**Without oh-my-opencode:** Point OpenCode at SKILL.md via its instructions
file or paste relevant sections into your project's configuration.

OpenCode supports MCP servers — see [OpenCode docs](https://opencode.ai/docs/)
for current MCP setup commands.

### Verify

```bash
python3 /path/to/lean4-skills/plugins/lean4/skills/lean4/scripts/sorry_analyzer.py . --format=summary --report-only
```

## Any Agent (Generic)

Any LLM coding agent that can read markdown and run shell commands can use this pack:

1. Clone the repo
2. Point your agent at `plugins/lean4/skills/lean4/SKILL.md` as system context
3. Scripts work standalone from the skill root — no adapter needed:
   ```bash
   python3 plugins/lean4/skills/lean4/scripts/sorry_analyzer.py . --format=summary --report-only
   bash plugins/lean4/skills/lean4/scripts/check_axioms_inline.sh path/to/YourFile.lean --report-only
   bash plugins/lean4/skills/lean4/scripts/search_mathlib.sh "continuous" name
   ```
4. If your agent supports MCP, add lean-lsp-mcp for faster mathlib search and sub-second feedback

**Optional — skill auto-discovery:** Some setups may support discovering
skills at `.agents/skills/<name>/SKILL.md`. This is host-dependent — check
your agent's docs for supported discovery paths. If supported:

```bash
# Unix/macOS — symlink
mkdir -p .agents/skills
ln -s "/path/to/lean4-skills/plugins/lean4/skills/lean4" .agents/skills/lean4

# Windows (Git Bash)
mkdir -p .agents/skills
cp -R "/path/to/lean4-skills/plugins/lean4/skills/lean4" .agents/skills/lean4

# Windows (PowerShell)
New-Item -ItemType Directory -Force -Path .agents\skills
Copy-Item -Recurse "path\to\lean4-skills\plugins\lean4\skills\lean4" .agents\skills\lean4
```

### Verify

```bash
readlink .agents/skills/lean4
ls .agents/skills/lean4/scripts/sorry_analyzer.py
python3 .agents/skills/lean4/scripts/sorry_analyzer.py . --format=summary --report-only
```

## Lean LSP MCP Server (All Hosts)

[lean-lsp-mcp](https://github.com/oOo0oOo/lean-lsp-mcp) provides faster mathlib
search and sub-second feedback. Works with any MCP-capable host. Setup: a few minutes.

**What you get:**
- `lean_goal(file, line)` — See exact goal at cursor
- `lean_local_search("keyword")` — Fast local + mathlib (unlimited)
- `lean_leanfinder("goal or query")` — Semantic, goal-aware (rate-limited)
- `lean_leansearch("natural language")` — Semantic search (rate-limited)
- `lean_loogle("?a → ?b → _")` — Type-pattern (rate-limited)
- `lean_hammer_premise(file, line, col)` — Premise suggestions for simp/aesop/grind (rate-limited)
- `lean_multi_attempt(file, line, snippets=[...])` — Test multiple tactics
- `lean_diagnostic_messages(file)` — Per-file error/warning check without a full `lake build`
- …and more (hover info, goal-conditioned search, state inspection, etc.)

**One-time setup:** ~5 minutes. Highly recommended.

Per-host MCP configuration (check each host's latest docs for current syntax):
- **Claude Code** (run from your Lean project root): `claude mcp add --transport stdio --scope user lean-lsp -- uvx lean-lsp-mcp`
- **Codex CLI:** Check [Codex docs](https://developers.openai.com/codex/) for MCP setup
- **Gemini CLI:** Check [Gemini CLI docs](https://github.com/google-gemini/gemini-cli) for MCP setup
- **OpenCode:** Check [OpenCode docs](https://opencode.ai/docs/) for MCP setup
- **Other hosts:** `npx lean-lsp-mcp --project /path/to/lean/project` — connect via your agent's MCP configuration

## Optional: ripgrep

Install `ripgrep` for faster searches:

```bash
# macOS
brew install ripgrep

# Linux
sudo apt install ripgrep

# Windows
winget install BurntSushi.ripgrep.MSVC
```

The workflows and scripts work without it, but searches are slower.

## Migrating from V3 (Claude Code Only)

If you have the old 3-plugin system:

```bash
# Uninstall old plugins
/plugin uninstall lean4-theorem-proving
/plugin uninstall lean4-memories
/plugin uninstall lean4-subagents

# Install unified plugin
/plugin install lean4

# Verify
/lean4:doctor
```

### What Changed

| V3 | V4 |
|----|-----|
| 3 plugins | 1 unified plugin |
| `/lean4-theorem-proving:*` | `/lean4:*` |
| `.claude/tools/lean4/` scripts | `skills/lean4/scripts/` |
| Memory integration | Removed (didn't work) |

### Legacy Access

```bash
# Pin to legacy tag
/plugin marketplace add cameronfreer/lean4-skills@v3.4.2-legacy

# Or use legacy branch
/plugin marketplace add cameronfreer/lean4-skills#legacy-marketplace
```

## Getting Help

- **Plugin diagnostics (Claude Code):** `/lean4:doctor` — checks environment, plugin, and project
- **Issues:** https://github.com/cameronfreer/lean4-skills/issues
- **LSP server:** https://github.com/oOo0oOo/lean-lsp-mcp/issues
- **Claude Code:** `/help`
