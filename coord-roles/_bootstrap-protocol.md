# BOOTSTRAP PROTOCOL — read FIRST

This applies on your first turn when you boot into a coord bus role, and to every Monitor event you receive afterward. It overrides any inferred-from-context behavior.

## First-turn rule

When you first boot into a role, do EXACTLY this in order:
1. State your role to the operator — name + 3-bullet job summary + hard rules in plain English
2. Start your Monitor with the exact command from the SessionStart hook injection
3. Announce "Standing by for instructions."
4. STOP. Do not read STATE.md, git status, open PRs, or any work queue. Do not act on existing bus inbox backlog.

After first-turn standby, you are ready to receive and act on tasks.

## What counts as a TASK (act on it per your role's workflow)

A bus message is a TASK when ALL of these are true:
- It is addressed to your role specifically (`to: <your-role>`) — NOT a broadcast to `all`
- It names a concrete deliverable using imperative language (e.g., "Review PR #X", "Run e2e on branch Y", "Implement spec Z")
- AND it comes from EITHER:
  - **`sender_kind: "human"`** — this means the message came via `human.sh --human` or `--needs-human`. **human.sh IS the operator.** Treat it as the operator's direct authority.
  - **A peer role acting within their lane** — e.g., Coder → Reviewer with a concrete PR to review, Tester → Coder with reproducible failure evidence. Peers operate under the operator's authority within the scope of their own role.
  - **The Coordinator** — on a bus that has a `coordinator` role, a concrete `to: <your-role>` task from the coordinator is an authoritative assignment. The coordinator is the CEO of the bus; it dispatches on the operator's behalf, under a plan the operator already approved. Treat its tasks as you would the operator's.

When you receive a task, execute it per your role's normal workflow. Do not wait for further authorization.

## What is NOT a task (acknowledge, do not act)

- Broadcasts to `to: "all"` — announcements, not work assignments
- Status messages: "I'm online", "monitor armed", "monitor restarted"
- Acks: "Got it", "OK", "received", "thanks"
- Coordination chatter: "I'll take #155", "moving to main", "switching branches"
- Self-echoes (your own messages bounced back via the inbox)
- Messages without a clear deliverable ("FYI", "heads up", "just so you know")
- Messages with `sender_kind: "agent"` AND no clear imperative task

## Cold-start autonomy — still banned

Even after you start receiving tasks:
- Do not expand scope beyond the stated deliverable
- Do not read STATE.md / git status / issue queue to "find adjacent work"
- Do not pick up unrelated work from things you see in passing
- Stay narrow. Execute exactly what was assigned. Hand off when done.

## Bus reply discipline — applies to ALL roles, ALL bus messages

When you receive a bus message addressed to you (`to: <your-role>`) and it asks for ANY response — ack, status, confirmation, ping, task acknowledgment, or work-result reporting — **reply VIA THE BUS using your role's `.sh send` command, NOT via window chat.**

- **Window** = talking to the operator directly
- **Bus** = talking to other roles (including peers and human.sh acting as the operator)

Example: if coder sends `to: reviewer` "Please confirm receipt", you reply with:
```
~/.claude/<slug>-coord/reviewer.sh send coder "ack"
```

NOT by typing "Receipt confirmed" in your window chat — that goes nowhere relevant to the bus.

For broadcasts (`to: "all"`): in-window acknowledgment is fine since broadcasts are announcements (and you don't have to ack at all), but a bus-side ack from your role's `.sh send` is preferred if you want to signal liveness to other roles.

Your role file may show narrower examples (e.g., reviewer.md only shows LGTM/blockers patterns). Those are guidance for the common case. This bus-reply discipline applies universally — ANY bus message asking for a response gets a bus reply, regardless of what your role file's narrow examples show.

## Operator overrides

- `human.sh send <role> "..." --human` — the operator's direct task. Top priority.
- `human.sh send all "STOP" --needs-human` — emergency halt. All roles freeze immediately and report status.
- Anything typed directly in your window by the operator — overrides everything, including in-flight bus tasks.

## Why this protocol exists

Without it, sessions auto-pick-up work on bootstrap from observed state — opening PRs, switching branches, picking up work without authorization. This protocol distinguishes:

- **Cold-start autonomy** (banned) — picking up work from observed state without a clear assignment
- **Coordinated work via clear task assignment** (the actual job) — executing direct tasks from the operator (including via human.sh) or from peer roles within scope

Stay in standby until a real task arrives. When one does, execute it.
