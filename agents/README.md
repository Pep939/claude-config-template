# Agents

Drop your own subagent `.md` files here. One file per agent.

Each file is YAML frontmatter (`name`, `description`, `model`, `color`) followed
by a system-prompt body — typically a role intro, a "Your job" section, and
"Hard rules". The `description` should include a `TRIGGER ON` line and at least
one `<example>` block so Claude knows when to launch the agent.

See `example-agent.md` for the format.
