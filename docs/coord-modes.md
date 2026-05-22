# Coord Bus — Topology Modes (design notes)

Status: **roadmap** — design captured 2026-05-22. Not built yet; to be done
after the template's first release.

These notes capture a design discussion about evolving the `/coord` command so
it can spin up more than one *shape* of multi-session setup.

## The decision

`/coord` should ask the topology **first** — before "how many sessions?" — then
branch. Two modes:

| Mode | Shape | Talk to each other? |
|------|-------|---------------------|
| **Team** | coordinator + distinct specialists (coder, reviewer, tester, architect…) | yes — they collaborate and depend on each other |
| **Hub**  | one hub + N identical workers | no — workers are independent, only report *up* to the hub |

Flow:

```
/coord → "Team or Hub?"
  Team → ask which roles (as today)
  Hub  → ask "how many workers?" + "what's their job?"
```

Same underlying machinery for both — the JSONL message bus + per-session
Monitors. The two modes are just different topologies on top of it.

## Team mode

What exists today. A coordinator (the CEO of the bus) decomposes a goal,
dispatches single-owner tasks to specialists, verifies, and reports. Specialists
collaborate and depend on each other (coder waits on architect, reviewer waits
on coder). Good for a bounded task that needs a few different skills.

## Hub mode

One **hub** + N **workers**. Workers are independent — each owns its own slice of
work, none of them talk to each other. Each worker only posts status *up* to the
hub. The hub collects those statuses and shows them in one place, so a human
running N parallel sessions has a single pane of glass instead of N windows.

It is a **fan-in** pattern, not a coordination pattern — that is why it scales
where Team mode would not: no worker ever blocks on another worker.

**What makes a hub worker "special" — three traits, all required:**

1. **Identical** — every worker runs the *same* role file. Interchangeable capability.
2. **Siloed** — workers never message each other. They only report up to the hub.
   That silo is what keeps coordination overhead at zero.
3. **Lane-locked** — each worker owns *one* bounded slice. No shared files, no
   overlapping scope. The worker role file enforces "stay in your lane."

Break any of the three and you are back to coordination overhead.

**The hub must stay passive.** It is a status board, not a boss — it collects,
displays, and flags. If the hub starts actively reasoning across all N work
streams, its context window fills and the hub itself becomes the bottleneck.

**Max workers.** No hard cap, but the useful range is small:

- Sweet spot **5–8**. 10 is pushing it. 20 is past the point of usefulness.
- Why it falls off: the hub is a single session, so N workers' status fills its
  context; a human cannot absorb 20 workers' status even aggregated; N workers =
  N model sessions = N× cost; N windows spawn on the desktop.
- Build it so the menu offers up to ~8, with "type a number" for more behind a
  plain warning about the falloff. Do not hard-block — just be honest in the UX.

## Multi-hub

Running several hubs at once — each a "department" on one project (one hub of
frontend workers, one of backend, one of tests, say).

**Mechanically:** fine. Each hub is its own independent bus; run several side by
side.

**Whether it actually helps:** depends entirely on the project, not the tool.
Multi-hub only pays off if the project splits into genuinely *independent* areas
— areas where a worker in one hub never needs to touch a file, or wait on a
decision, that another hub owns.

Most real software does **not** split that cleanly. Frontend / backend / tests on
one codebase share the API contract, shared models, shared types — workers in
different hubs end up editing the same files, collide, and then need to
coordinate. Coordination is the overhead trap again.

**The test before running multi-hub:** name the areas, and say with a straight
face "a worker in this area will never need another area's files or decisions."
If yes → multi-hub is great. If you hesitate → the work does not split; fewer
agents on it wins.

## God Mode — rejected

The idea: ~5 buses of ~5 sessions each, plus one "god" session orchestrating all
of them — ~25 agents on one goal.

**Not building this.** Reasons:

- Coordination overhead dominates past a small number of agents (Brooks's Law:
  past a point, adding people to a software project makes it slower).
- Evidence from the 2026-05-22 test run: a 5-agent Team bus built a trivial
  number-guessing game (~30 lines) in *minutes* of dispatch / ack / monitor
  round-trips. One agent does that in ~30 seconds. The overhead is fixed cost
  per agent, per message, and it scales badly.
- In a 25-agent setup, 1 god + 5 coordinators = 6 agents whose entire job is
  messaging; they produce zero output.
- Software does not decompose into 25 clean independent lanes — you get merge
  conflicts and integration hell.
- Cost: 25 model sessions per run, most of it spent on coordination chatter.

**Hard rule:** hubs stay independent. Never wire hubs up to a super-hub — a
hub-of-hubs *is* God Mode.

## The principle underneath all of it

The bottleneck is always the **decomposability of the work** — not the agent
count, and not the tooling. More structure (more hubs, a god layer) cannot make
entangled work parallel. A few focused agents on well-bounded work beats many
agents on entangled work, every time.

## Implementation sketch (for when this gets built)

- Reuse the existing coord bus — JSONL inbox + per-session Monitors. No new
  transport.
- Add two role files: `hub.md` (passive aggregator) and a generic `worker.md`
  (identical / siloed / lane-locked).
- Extend `/coord`: ask "Team or Hub?" up front; the Hub path asks for a worker
  count and a worker job, then spawns `hub` + N sessions all sharing `worker.md`.
- `spawn.sh` already accepts arbitrary session IDs, so
  `spawn.sh <slug> hub worker-1 worker-2 …` works today — the change is mostly
  in the `/coord` command's questions plus the two new role files.
