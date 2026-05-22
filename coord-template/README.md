# Cross-session coordination bus — reusable scaffolder

When you have **two or more Claude Code windows** working on the same project and you want them to coordinate without copy-pasting through you, run this scaffolder once and they talk peer-to-peer over an append-only JSONL inbox.

## Spawn a bus for a new project

```bash
~/.claude/coord-template/spawn.sh <project-slug> <agent-id-1> <agent-id-2> [agent-id-3] ...
```

Examples:

```bash
# Two-session pair
~/.claude/coord-template/spawn.sh myproject coder reviewer

# Three-session split on a frontend project
~/.claude/coord-template/spawn.sh webapp backend frontend reviewer

# Research team
~/.claude/coord-template/spawn.sh research scout skeptic synthesizer
```

Creates `~/.claude/<project-slug>-coord/` with:

- `cli.py` — the chat tool (file-locked JSONL append, read-by tracking, sender-kind override)
- `<agent>.sh` — one wrapper per agent, stamps `CLAUDE_AGENT_ID`
- `human.sh` — human override wrapper, auto-tags `sender_kind="human"`
- `inbox.jsonl` — empty, ready for first message

The script prints **the exact Monitor command each session should run** when it starts — copy-paste into the right Claude Code window.

## How sessions talk

```bash
# From session 'backend':
~/.claude/webapp-coord/backend.sh send frontend "message" --thread feature-X

# Session 'frontend' sees a Monitor event with the JSON line.
# To respond:
~/.claude/webapp-coord/frontend.sh send backend "reply" --thread feature-X
```

## How you (the human) inject

```bash
~/.claude/webapp-coord/human.sh send all "scope change — pause everything" --human --needs-human
```

`--needs-human` tags the message as urgent. Every session is expected to halt and re-read.

## How sessions watch (Monitor)

Each session, when it starts, runs ONE `Monitor` task with `persistent: true`:

```
tail -F -n +1 ~/.claude/<project>-coord/inbox.jsonl | grep --line-buffered -E '"to": ?"(<my-id>|all)"' | grep --line-buffered -vE '"from": ?"<my-id>"'
```

The grep filters fire only on lines addressed to that agent (or broadcast to `all`), and skip echoes of the agent's own sends. Each matching line becomes a notification in the Claude Code session.

## Why JSONL + file locks

- **Append-only JSONL** — every message persists; never overwritten. Cheap audit trail.
- **File locks** (O_EXCL create) — prevent concurrent-write corruption when two sessions send at the same exact moment.
- **read_by[]** field — each agent marks messages as read so you don't see them twice.
- **Outside the project repo** — `~/.claude/<project>-coord/` is in your home, never tracked by git. Neither branch carries the bus state.

## Cleanup

When the project is done, just `rm -rf ~/.claude/<project>-coord/`. No git state to manage. To audit later, the inbox.jsonl is plain JSON Lines.
