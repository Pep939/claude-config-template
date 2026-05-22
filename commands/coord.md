---
name: coord
description: Set up a multi-session coordination bus for the current project
---

# /coord — Multi-session setup

You're setting up a coord bus so multiple Claude Code windows can work on this project together. Each window gets a role with hard rules so they don't step on each other.

## Step 1 — Detect the project
Run `pwd` and `basename "$PWD"`. The basename is the project slug (e.g. `myproject`).

## Step 2 — Check for an existing bus
ONLY check `~/.claude/<slug>-coord/` where `<slug>` is the EXACT basename of the current working directory. Do NOT offer to attach to a coord bus whose slug doesn't match.

If `~/.claude/<slug>-coord/` exists, ask the operator:
- (a) Attach this window to the existing bus (claim a free role)
- (b) Archive and rebuild (move existing bus to `~/.claude/.trash/`, spawn fresh)
- (c) Cancel

If the operator picks (b), run these commands in order:

**First — kill orphan tail processes holding the bus open (Windows file-lock workaround):**
```bash
powershell -Command "Get-CimInstance Win32_Process -Filter \"Name='tail.exe'\" | Where-Object { \$_.CommandLine -match '<slug>-coord' } | ForEach-Object { Write-Host ('Killing tail PID ' + \$_.ProcessId); Stop-Process -Id \$_.ProcessId -Force }"
```

These tails are leftover Monitors from previous coord-bus windows that are still open. Killing them stops those Monitors but leaves the Claude windows themselves intact (the operator can close them manually after). On Linux/macOS this step is a no-op (POSIX allows mv with open files).

**Then — the actual archive (auto-mode-safe mv, not rm):**
```bash
mkdir -p ~/.claude/.trash && mv ~/.claude/<slug>-coord ~/.claude/.trash/<slug>-coord-$(date +%s)
```

The old bus is preserved under `~/.claude/.trash/` and can be inspected or deleted later by the operator manually. Then proceed to spawn the fresh bus.

If the cwd basename doesn't have a matching coord dir, skip this step and go straight to setup.

## Step 3 — Ask how many sessions
Use AskUserQuestion. Header: "Session count". Options: 2, 3, 4, 5, 6.

## Step 4 — Ask which roles
List files in `~/.claude/coord-roles/` — each `.md` file is one selectable role. Skip `_bootstrap-protocol.md` and `README.md`; they are not roles. Use AskUserQuestion with multiSelect=true.

**Suggested defaults by count** (offer as first option, let the operator override):
- 2: coder, reviewer  — no coordinator; the two sessions work peer-to-peer
- 3: coordinator, coder, reviewer
- 4: + tester
- 5: + architect
- 6: + researcher

**Coordinator ordering.** The `coordinator` is the CEO of the bus — it delegates, verifies, and decides; it does not write code. The spawning session adopts it. Whenever `coordinator` is among the chosen roles it MUST be ordered first (`role[0]`), so the spawning session becomes the coordinator. A 2-session bus gets no coordinator (not enough team to run); 3+ sessions get one.

## Step 5 — Spawn the bus
Run: `~/.claude/coord-template/spawn.sh <slug> <role1> <role2> ...`

This creates `~/.claude/<slug>-coord/` with cli.py, per-role .sh wrappers, human.sh, inbox.jsonl.

## Step 6 — Drop bootstrap protocol + role files + PRE-CLAIM all slots
```bash
mkdir -p ~/.claude/<slug>-coord/roles ~/.claude/<slug>-coord/slots
# Copy the await-mode protocol (overrides role-specific instincts on first turn)
cp ~/.claude/coord-roles/_bootstrap-protocol.md ~/.claude/<slug>-coord/_bootstrap-protocol.md
```

Then for each chosen role:
```bash
sed "s/<slug>/<actual-slug>/g" ~/.claude/coord-roles/<role>.md > ~/.claude/<slug>-coord/roles/<role>.md
touch ~/.claude/<slug>-coord/slots/<role>.claimed   # PRE-CLAIMED — see Step 9 rationale
```

**Important — pre-claim, not unclaimed.** All slots are claimed BY THIS SESSION before any other window opens. Each new window's prompt explicitly tells it which role it is (no hook race). The hook then exits silently on new windows because all slots are already claimed.

Also write `~/.claude/<slug>-coord/agents.txt` with one role per line in order.

## Step 7 — This session adopts role[0] + follows bootstrap protocol
All slots were pre-claimed in Step 6, so role[0] is already yours. Read **BOTH files**, in this order:
1. `~/.claude/<slug>-coord/_bootstrap-protocol.md` (await-mode protocol — overrides everything)
2. `~/.claude/<slug>-coord/roles/<role[0]>.md` (your role's job description + hard rules)

Then on this turn — and ONLY this turn — do EXACTLY this (per the bootstrap protocol):
1. State your role to the operator in plain English: name + 3-bullet summary + hard rules
2. Start your Monitor (Step 8 below)
3. Announce "Standing by for explicit instructions from the operator."
4. STOP. Do NOT read STATE.md, git status, open issues, or any work queue. Do NOT pick up any work autonomously, even if you see uncommitted changes or open PRs. Wait for the operator's explicit task.

## Step 8 — Start the Monitor for this session
Use the Monitor tool with `persistent: true` and this command (substitute `<role[0]>` and `<slug>`):
```
tail -F -n +1 ~/.claude/<slug>-coord/inbox.jsonl | grep --line-buffered -E '"to": ?"(<role[0]>|all)"' | grep --line-buffered -vE '"from": ?"<role[0]>"'
```

## Step 9 — Launch new windows with role-aware prompts (NO semicolons, NO parens)

**CRITICAL — Windows Terminal command-line parsing:**
- `wt.exe` treats `;` as a new-tab separator. Any `;` inside your prompt will spawn a new garbage tab.
- Numbered lists like `(1) ... (2) ...` combined with `;` are exactly how this breaks.
- Use periods only. Imperative sentences. No semicolons. No parenthesized lists.

For each role NOT yet claimed (i.e. every role except role[0]), derive a Title Case display name and pick the role-specific color from this map:

| Role | Display name | Color |
|---|---|---|
| coordinator | Coordinator | purple |
| coder | Coder | blue |
| tester | Tester | red |
| reviewer | Reviewer | yellow |
| architect | Architect | cyan |
| designer | Designer | magenta |
| researcher | Researcher | green |
| (others) | (Title Case) | green or default |

**Resolve the Claude executable first — do NOT hard-code `claude.cmd`.** `wt.exe` resolves the command name in its own process context, and `claude.cmd` only exists on npm-global installs. Native-installer machines ship `claude.exe` with no `.cmd` shim, so a bare `claude.cmd` fails with `0x80070002` (file not found). Resolve the real path once and reuse it:

```bash
CLAUDE_BIN="$(cygpath -w "$(command -v claude)")"   # → C:\...\claude.exe
```
`cygpath -w` adds the `.exe` extension even though `command -v` reports the path without it. If `command -v claude` is empty, fall back to `"$(cygpath -w "$HOME/.local/bin/claude.exe")"` before giving up.

Then run (one `start` per remaining role, substituting `$CLAUDE_BIN`):

```bash
start "" wt.exe -d "$(pwd -W)" "$CLAUDE_BIN" -n "<DisplayName>" "You are the <role> on the <slug> coord bus. Read ~/.claude/<slug>-coord/_bootstrap-protocol.md and ~/.claude/<slug>-coord/roles/<role>.md. Follow the protocol exactly. Announce your role to the operator in plain English with a 3-bullet job summary and hard rules. Start your Monitor with the tail command for to:<role> or to:all messages. Tell the operator to run /color <color-from-map> in this window for visual distinction. Then say 'Standing by for explicit instructions from the operator.' and STOP. Do not read STATE.md. Do not scan git status. Do not browse open issues or PRs. Do not pick up work autonomously. Wait for the operator's direct task."
```

**Key points about this prompt:**
- The prompt names the role EXPLICITLY (`You are the <role>`) — no race with the SessionStart hook, the `-n` label always matches the announced role
- Periods only as separators. No semicolons. No parens with numbers.
- The hook fires but exits silently (all slots pre-claimed in Step 6) — bootstrap content comes from the prompt's file-reads instead of the hook injection

(One `start` per remaining role. If `wt.exe` is unavailable, escape carefully for `cmd /k`.)

Each new window will: read the two files, announce its role, start Monitor, stand by. No human "go ahead" needed. No work pickup. Stays in await mode until the operator gives a direct task.

## Step 10 — Report to the operator + rename this window
Print:
- Bus dir: `~/.claude/<slug>-coord/`
- This window's role: `<role[0]>`
- Other roles being claimed by new windows: `<remaining>` (each launches with `-n "<DisplayName>"` so they're labeled at the bottom-right)
- How to inject as human: `~/.claude/<slug>-coord/human.sh send all --needs-human "<message>"`
- How to inspect: `cat ~/.claude/<slug>-coord/inbox.jsonl`

Tell the operator to run TWO commands in THIS window:
- `/rename <DisplayName>` (e.g. `/rename Coder`) — the launcher window needs the manual rename since it's already running
- `/color <color>` from the color map (e.g. `/color blue` for coder) — visual distinction matching the other windows

**If `<role[0]>` is `coordinator`:** also tell the operator how to start the team — when ready, the operator gives the coordinator its objective with `/goal "<objective>"` in this window. `/goal` pins the objective and keeps the coordinator session driving until it is met. The coordinator then decomposes the goal, shows the operator the task breakdown, and dispatches to the workers only after the operator approves the plan.

**STOP HERE. Stand by for the operator's explicit task.** Do NOT pick up work autonomously. Bus messages from other roles are not task assignments — only the operator's direct instruction triggers work. "Go ahead" on a fresh session means "confirm you're armed," NOT "start working on whatever you find."
