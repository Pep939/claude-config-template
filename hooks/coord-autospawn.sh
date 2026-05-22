#!/usr/bin/env bash
# coord-autospawn.sh — SessionStart hook for the coord bus.
#
# If the current working directory is in a project that has an active coord bus
# (~/.claude/<slug>-coord/ exists with a slots/ dir), this hook:
#   1. Atomically claims the next free role slot
#   2. Prints the role's instructions to stdout (lands in Claude's session context)
#   3. Prints the Monitor command for the claimed role
#
# If no coord bus is active for this project, exits silently with no overhead.
#
# The /coord slash command sets up the bus. This hook only auto-attaches new
# windows that open into a coord-active project folder.

set -uo pipefail

# Detect project slug = basename of cwd
SLUG="$(basename "$PWD")"
COORD_DIR="$HOME/.claude/${SLUG}-coord"

# Silent exit if no coord bus for this project
[ -d "$COORD_DIR/slots" ] || exit 0

# Find the first unclaimed role — atomic claim via mv
CLAIMED_ROLE=""
for slot in "$COORD_DIR"/slots/*.unclaimed; do
  [ -e "$slot" ] || continue
  new_name="${slot%.unclaimed}.claimed"
  if mv "$slot" "$new_name" 2>/dev/null; then
    CLAIMED_ROLE="$(basename "$new_name" .claimed)"
    # Stamp claim with PID + timestamp for future cleanup heuristics
    echo "pid=$$" > "$new_name"
    echo "claimed_at=$(date -Iseconds)" >> "$new_name"
    break
  fi
done

# No free role? All slots taken — exit silently (window stays unattached)
[ -n "$CLAIMED_ROLE" ] || exit 0

# Emit role instructions + Monitor command to stdout
# Claude Code injects hook stdout as additional context.
cat <<EOF
=== COORD BUS AUTO-ATTACHED ===

This Claude Code window has been auto-claimed for the **${CLAIMED_ROLE}** role on the \`${SLUG}\` coord bus.

Bus directory: ${COORD_DIR}

EOF

# Inject the bootstrap protocol FIRST — it overrides any role-specific instincts
# and enforces await-mode behavior on first turn.
if [ -f "$COORD_DIR/_bootstrap-protocol.md" ]; then
  cat "$COORD_DIR/_bootstrap-protocol.md"
  echo ""
  echo "---"
  echo ""
fi

# Inject the role file's content
if [ -f "$COORD_DIR/roles/${CLAIMED_ROLE}.md" ]; then
  cat "$COORD_DIR/roles/${CLAIMED_ROLE}.md"
else
  echo "WARNING: role file missing at $COORD_DIR/roles/${CLAIMED_ROLE}.md"
fi

cat <<EOF

=== START THE MONITOR ===

Start the Monitor tool with persistent: true and this exact command:

tail -F -n +1 $COORD_DIR/inbox.jsonl | grep --line-buffered -E '"to": ?"(${CLAIMED_ROLE}|all)"' | grep --line-buffered -vE '"from": ?"${CLAIMED_ROLE}"'

This will surface messages addressed to ${CLAIMED_ROLE} or broadcast to "all", skipping echoes of your own sends.

=== HOW TO SEND ===

To message another role:
  $COORD_DIR/${CLAIMED_ROLE}.sh send <other-role> "<message>" --thread <topic>

To broadcast:
  $COORD_DIR/${CLAIMED_ROLE}.sh send all "<message>"

=== END COORD CONTEXT ===
EOF
