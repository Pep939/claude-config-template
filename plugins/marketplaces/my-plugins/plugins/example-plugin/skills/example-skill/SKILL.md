---
name: example-skill
description: Use when you want to see how a Claude Code skill is structured, or as a starting point for writing your own. This is a placeholder skill — replace it with a real one.
---

# Example Skill

This skill exists to demonstrate the skill format. Once you understand the
layout, delete this skill and write your own.

## What a skill is

A skill is a folder containing a `SKILL.md` file. The YAML frontmatter has two
required fields:

- **`name`** — a short, lowercase, hyphenated identifier.
- **`description`** — a "Use when..." sentence that tells Claude when to
  trigger the skill. Make the triggers concrete; this is what Claude matches on.

Everything below the frontmatter is the skill body — instructions Claude reads
once the skill is triggered.

## A simple workflow

When this skill triggers, follow these steps:

1. **Confirm the goal.** Restate what the user is trying to accomplish in one
   sentence so there is no ambiguity.
2. **Do the work.** Carry out the task using the instructions in this body.
3. **Report back.** Summarize what was done and any follow-ups.

## Writing your own skill

To replace this example:

1. Create a new folder under `skills/` named after your skill.
2. Add a `SKILL.md` with `name` and a sharp `description`.
3. Write the body: keep it focused on one capability.
4. Add supporting files (scripts, references) alongside `SKILL.md` if needed.

Keep skills small and single-purpose. If a skill grows several unrelated
workflows, split it into separate skills.
