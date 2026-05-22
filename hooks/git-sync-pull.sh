#!/bin/bash
# Pull latest ~/.claude/ config from origin on SessionStart.
# Fails soft (echoes error) so it never blocks session start.

cd ~/.claude || exit 0

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "git-sync-pull: ~/.claude is not a git repo, skipping"
  exit 0
fi

git pull --ff-only 2>&1 || echo "git-sync-pull: pull failed (offline or non-fast-forward — investigate)"
