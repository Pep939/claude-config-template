# claude-config-template

A ready-to-fork foundation for your **global Claude Code setup** — the `~/.claude`
directory that follows you across every project and machine. Clone it, run one
bootstrap script, and you have an organized, portable baseline to fill with your
own agents, plugins, skills, and coordination roles.

Most people grow their `~/.claude` ad hoc — an agent here, a plugin there, settings
scattered over time. This gives you a clean, structured starting point instead:
the directory layout, the install tooling, cross-machine sync, and a multi-session
coordination system are already wired up. You add the content.

It ships **only generic machinery — zero personal content, zero secrets** — so you
can fork it, make it yours, and even keep your fork public without leaking anything.

## What you get

- **One-command setup on any machine.** `bootstrap.sh` / `bootstrap.ps1` installs
  every enabled plugin declared in `settings.json` — a fresh `git clone` becomes a
  working Claude Code config in a single step. (Marketplaces need no setup step:
  Claude Code registers the ones declared in `settings.json` automatically.)
- **A multi-session coordination bus.** The included `/coord` command launches
  several Claude Code windows that work one project as a team — a **coordinator**
  that decomposes the goal and delegates, plus **coder / reviewer / tester /
  architect** and other roles that talk to each other over a shared message bus.
  13 generic roles are included and ready to use.
- **A home for everything you build.** Organized folders for subagents, slash
  commands, plugins, skills, and coordination roles — each with a worked example
  showing the exact file format to copy.
- **Cross-machine sync, built in.** SessionStart / SessionEnd git hooks auto-pull
  and auto-push, so your config stays identical on every machine you work from.
- **Secret-safe by default.** A hardened `.gitignore` keeps credentials, tokens,
  caches, and session logs out of git.

## What's in here

| Path | What it is |
|------|------------|
| `settings.json` | Global Claude Code settings (permissions, hooks, plugins). |
| `bootstrap.sh` / `bootstrap.ps1` | One-shot setup: installs plugins, sets up credentials. |
| `CLAUDE.md` | Fill-in-the-blanks global instruction file. |
| `agents/` | Your subagents — one `.md` per agent. Includes `example-agent.md`. |
| `commands/` | Your slash commands. Includes the `/coord` command. |
| `coord-roles/` | Role definitions for the multi-session coordination bus. |
| `coord-template/` | The coordination-bus scaffolder (`spawn.sh`). |
| `hooks/` | SessionStart / SessionEnd shell hooks (git sync, warm start). |
| `plugins/marketplaces/my-plugins/` | Your own plugin marketplace. Includes `example-plugin`. |

## Quick start

> **Already using Claude Code?** You already have a `~/.claude` directory, and
> this template *becomes* your new one. Move the old one aside first (step 1) —
> nothing is deleted, and you can copy your own agents, commands, and settings
> back in afterward.
>
> Commands below use `$HOME`, not `~` — PowerShell does not expand `~` for
> `git`, so `~` would clone into a literal folder named `~`. `$HOME` works in
> bash and PowerShell alike.

```bash
# 1. Back up any existing config (skip if you've never run Claude Code)
mv "$HOME/.claude" "$HOME/.claude.backup"

# 2. Clone the template into your Claude Code config directory
git clone https://github.com/Pep939/claude-config-template.git "$HOME/.claude"

# 3. Run bootstrap
cd "$HOME/.claude"
bash bootstrap.sh          # macOS / Linux / Git Bash
pwsh -File bootstrap.ps1   # Windows PowerShell 7+

# 4. Point the git remote at YOUR own repo
git remote set-url origin <your-repo-url>
```

See `BOOTSTRAP.md` for what bootstrap does and what syncs.

## Make it yours

### Add an agent

Drop a `.md` file into `agents/`. Each file is YAML frontmatter
(`name`, `description`, `model`, `color`) plus a system-prompt body.
Copy `agents/example-agent.md` as a starting point.

### Add a plugin + skill

Your plugins live under `plugins/marketplaces/my-plugins/plugins/`.
Each plugin has a `.claude-plugin/plugin.json` manifest and can contain
`skills/`, `commands/`, `agents/`, and `hooks/`. A skill is a folder with a
`SKILL.md` (frontmatter `name` + `description`, then the workflow body).
See `plugins/marketplaces/my-plugins/plugins/example-plugin/` for a worked
example. Register the plugin by adding it to `enabledPlugins` in
`settings.json`, then re-run bootstrap.

### Add a coordination role

Drop a `.md` file into `coord-roles/`. It describes one role on the `/coord`
bus (its job, hard rules, how it coordinates). The generic roles
(`coder`, `reviewer`, `tester`, etc.) are already included and ready to use.

### Add a slash command

Drop a `.md` file into `commands/`. The filename becomes the command name
(`commands/foo.md` → `/foo`). The body is the prompt that runs.

## Coordination bus

The generic `coord-roles/` and the `/coord` command are included and ready to
use out of the box. `/coord` spins up a multi-window coordination bus so
several Claude Code sessions can collaborate on one project. See
`coord-template/README.md` for details.
