# Global CLAUDE.md — TEMPLATE

<!--
  This is your global Claude Code instruction file. It loads into every session.
  Fill in each section below, then delete this comment and the placeholder notes.
  Keep it short and high-signal — Claude reads this every time.
-->

## Who I Am

<!-- Describe yourself: your name, your role, how you like Claude to work with you. -->

- I'm `<your name>` — `<role / what you do>`.
- I'm working on `<the kind of projects you build>`.

## Communication Style

<!-- Tell Claude how to talk to you: tone, length, what to avoid. -->

- Be concise. Lead with the answer, then the supporting detail.
- Use bullets and tables over long paragraphs.
- When uncertain, say so — don't guess.

## Default Stack

<!-- List the languages, frameworks, and tools you use most, so Claude defaults to them. -->

- Languages: `<e.g. Python, TypeScript>`
- Frameworks / tools: `<e.g. FastAPI, React, Postgres>`

## Core Behavior Rules

<!-- The non-negotiable rules for how Claude works on your projects. -->

- Plan before any multi-step task; stop and replan if something breaks.
- Verify before declaring done — cite a real signal, not just intent.
- Fix the task at hand; don't refactor adjacent code without asking.
- Match the existing conventions of whatever codebase you're in.

## Risk Tiers

<!-- Define your own tiers so Claude knows when to be careful vs. move fast. -->

- 🔴 **Production / customer-facing** — snapshot, verify, confirm before changing anything.
- 🟡 **Internal** — move fast, don't break the working thing.
- 🟢 **Experiments / sandbox** — break things freely.

<!--
  Optional sections you may want to add:
  - Active Projects (a table of what you're working on)
  - How To Get Things Done (when to use agents, skills, subagents)
  - Reference Files (@-includes loaded on demand)
  - Credentials (where keys live — never paste keys here)
-->
