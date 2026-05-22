#!/bin/bash
# Auto-commit any ~/.claude/ changes and push to origin on SessionEnd.
# Fails soft (echoes error) so it never blocks session shutdown.

cd ~/.claude || exit 0

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "git-sync-push: ~/.claude is not a git repo, skipping"
  exit 0
fi

# Guard: a synced settings.json hook command must never hardcode a machine-specific
# user path. "~" expands per-machine; "C:/Users/<name>/" breaks on every other box.
if grep -nE '"command".*[Uu]sers[/\\]' settings.json 2>/dev/null; then
  echo ""
  echo "  git-sync-push: ABORT — settings.json hook command has a hardcoded user path (above)."
  echo "  Fix: replace the C:/Users/<name>/ path with ~/  then end a session to sync."
  echo ""
  exit 0
fi

if [[ -n "$(git status --porcelain)" ]]; then
  git add -A
  git commit -m "sync: $(date +%Y-%m-%d) from $(hostname)" 2>&1 || true
fi

git push 2>&1 || echo "git-sync-push: push failed (offline or auth — investigate)"
