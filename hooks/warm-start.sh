#!/bin/bash
# warm-start.sh — Injects project state into Claude Code session context
# Fires on SessionStart and after compaction (PreCompact)
# Inspired by @chiefofautism's warm-start hook

echo "=== WARM START: Project State ==="
echo ""

# --- Git State ---
echo "## Git State"
BRANCH=$(git branch --show-current 2>/dev/null || echo "not a git repo")
echo "- Branch: $BRANCH"

LAST_COMMIT=$(git log -1 --format="%h %s" 2>/dev/null || echo "no commits")
echo "- Last commit: $LAST_COMMIT"

UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
echo "- Uncommitted changes: $UNCOMMITTED files"

UPSTREAM=$(git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null || echo "no upstream")
echo "- Upstream sync: $UPSTREAM"

STASH_COUNT=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
echo "- Stash count: $STASH_COUNT"
echo ""

# --- Stack Detection ---
echo "## Stack"
if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  PYTHON_VER=$(python --version 2>/dev/null || python3 --version 2>/dev/null || echo "not found")
  echo "- Python: $PYTHON_VER"
fi

if [ -f "requirements.txt" ]; then
  echo "- Dependencies: requirements.txt"
  FRAMEWORK=$(grep -E "^(fastapi|flask|django)" requirements.txt 2>/dev/null | head -5)
  if [ -n "$FRAMEWORK" ]; then
    echo "- Framework: $FRAMEWORK"
  fi
fi

if [ -f "package.json" ]; then
  NODE_VER=$(node --version 2>/dev/null || echo "not found")
  echo "- Node: $NODE_VER"
  # Detect package manager
  if [ -f "pnpm-lock.yaml" ]; then echo "- Package manager: pnpm"
  elif [ -f "yarn.lock" ]; then echo "- Package manager: yarn"
  elif [ -f "package-lock.json" ]; then echo "- Package manager: npm"
  fi
fi

if [ -f "Dockerfile" ]; then
  echo "- Docker: Dockerfile present"
fi
echo ""

# --- Key Commands ---
echo "## Key Commands"
if [ -f "requirements.txt" ]; then
  echo "- Run: python main.py"
  echo "- Install: pip install -r requirements.txt"
fi
if [ -f "Dockerfile" ]; then
  echo "- Docker build: docker build -t myapp ."
fi
if [ -f "pyproject.toml" ]; then
  echo "- Test: pytest (if configured)"
fi
echo ""

# --- Project Structure ---
echo "## Project Structure (agents)"
ls -d */ 2>/dev/null | grep -v __pycache__ | grep -v node_modules | grep -v .claude | grep -v knowledge | head -20
echo ""

# --- Recent Activity ---
echo "## Recent Commits (last 5)"
git log --oneline -5 2>/dev/null || echo "no git history"
echo ""

# --- Open PRs ---
echo "## Open PRs"
git log --oneline origin/main..HEAD 2>/dev/null | head -5 || echo "none or no remote"
echo ""

# --- Knowledge System Status ---
echo "## Knowledge System"
if [ -d "knowledge" ]; then
  RULE_COUNT=$(find knowledge -name "rules.md" -exec grep -c "^##\|^-" {} + 2>/dev/null | awk -F: '{sum+=$2} END {print sum}')
  echo "- Knowledge domains: $(ls knowledge/ | grep -v INDEX | wc -l | tr -d ' ')"
  echo "- Total rules/patterns: ~$RULE_COUNT"
else
  echo "- No knowledge directory found"
fi
echo ""
echo "=== WARM START COMPLETE ==="
