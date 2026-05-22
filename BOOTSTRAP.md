# Bootstrap

This is a blank, shareable Claude Code configuration template. Clone it into
`~/.claude`, run the bootstrap script, and you have a working baseline you can
fill with your own agents, plugins, skills, and coordination roles.

The template ships only generic machinery — no personal content, no secrets.

## Quick start

`$HOME` is used instead of `~` — PowerShell does not expand `~` when passing
arguments to `git`, so `~` would create a literal folder named `~`. `$HOME`
works in both bash and PowerShell.

```bash
# 1. Back up any existing config (skip if you've never run Claude Code)
mv "$HOME/.claude" "$HOME/.claude.backup"

# 2. Clone the template into your Claude Code config directory
git clone https://github.com/Pep939/claude-config-template.git "$HOME/.claude"

# 3. Run the bootstrap script
cd "$HOME/.claude"
bash bootstrap.sh          # macOS / Linux / Git Bash
# or
pwsh -File bootstrap.ps1   # Windows PowerShell 7+
```

Bootstrap is idempotent — safe to re-run any time. Your old config is safe in
`~/.claude.backup` — copy anything you want to keep into the new tree.

## What bootstrap does

| Step | Action |
|------|--------|
| Prereq check | Verifies `claude`, `git`, `node` are installed (and warns on optional `bash` / `wt.exe`). |
| Read settings | Parses `settings.json` for the enabled plugins to install. |
| Plugins | Installs every enabled plugin with `--scope user`. |
| Credentials | Creates `credentials/api-keys.json` from a template if it does not exist. |
| /coord prereqs | Confirms the multi-session coordination bus can run. |
| MCP note | Reminds you to add any MCP servers your workflow needs. |

Marketplaces declared in `settings.json` (`extraKnownMarketplaces`) need no
bootstrap step — Claude Code registers them automatically on startup.

Flags: `--skip-plugins` / `-SkipPlugins` skips plugin install.

## What syncs vs. what doesn't

This directory is a git repo. Commit and push to keep machines in sync.

**Syncs (tracked):**
- `settings.json`, `bootstrap.*`, hooks, `coord-template/`, `coord-roles/`
- Your own `agents/*.md`, `commands/*.md`
- Your own marketplace under `plugins/marketplaces/my-plugins/`

**Does NOT sync (gitignored):**
- `credentials/` and anything matching `*credential*`, `*token*`, `*secret*`
- `settings.local.json` (machine-specific allow rules)
- Session artifacts, caches, history, per-project coord buses
- Auto-managed plugin state and third-party marketplaces

See `.gitignore` for the full deny/allow ruleset.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `settings.json not found` | Clone the repo into `~/.claude`, not a subfolder. |
| Plugin install fails | Often "already installed" — safe to ignore. Re-run bootstrap. |
| `/coord` does not spawn | Install `bash`; on Windows install Windows Terminal (`wt.exe`). |
| Hooks not firing | Confirm `hooks/*.sh` are executable and `settings.json` is valid JSON. |
| `claude` not found | Install Claude Code, ensure it is on PATH, restart your shell. |
