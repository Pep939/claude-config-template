#!/bin/bash
# Auto-commit any ~/.claude/ changes and push to origin on SessionEnd.
# Fails soft (echoes error) so it never blocks session shutdown.

cd ~/.claude || exit 0

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "git-sync-push: ~/.claude is not a git repo, skipping"
  exit 0
fi

# Guard: settings.json must never hardcode a machine-specific user path.
# "~" expands per-machine; an absolute "C:/Users/<name>/" or "/Users/<name>/"
# path breaks on every other box AND leaks the username into a public repo.
# Scans the whole file — catches hook commands and marketplace paths alike.
if grep -nE '[Uu]sers[/\\]' settings.json 2>/dev/null; then
  echo ""
  echo "  git-sync-push: ABORT — settings.json has a hardcoded user path (above)."
  echo "  Fix: replace the absolute C:/Users/<name>/... path with a ~/ path,"
  echo "  then end a session to sync."
  echo ""
  exit 0
fi

if [[ -n "$(git status --porcelain)" ]]; then
  git add -A
  git commit -m "sync: $(date +%Y-%m-%d) from $(hostname)" 2>&1 || true
fi

git push 2>&1 || echo "git-sync-push: push failed (offline or auth — investigate)"
