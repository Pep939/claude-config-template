#!/usr/bin/env bash
# bootstrap.sh — claude-config bootstrap (macOS / Linux / Git Bash)
#
# Usage:
#   cd ~/.claude
#   bash ./bootstrap.sh
#
# What it does (idempotent — safe to re-run):
#   1. Verifies prereqs (claude, git, node, optionally wt.exe, bash)
#   2. Installs all enabled plugins from settings.json
#   3. Bootstraps credentials/api-keys.json from template if missing
#   4. Verifies /coord prerequisites
#   5. Prints a note about adding MCP servers
#
# Marketplaces (extraKnownMarketplaces in settings.json) are handled by Claude
# Code itself, not by bootstrap. The template ships none — see README "Add a
# plugin + skill" for the supported way to add your own.
#
# Requires: bash >= 3.2 (runs on stock macOS bash), claude, git, node.

set -u
SKIP_PLUGINS=0
for arg in "$@"; do
    case "$arg" in
        --skip-plugins)    SKIP_PLUGINS=1 ;;
        -h|--help)
            grep '^#' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
    esac
done

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# ANSI colors (no-op if stdout not a tty)
if [ -t 1 ]; then
    C_CYAN=$'\e[36m'; C_GREEN=$'\e[32m'; C_YEL=$'\e[33m'
    C_RED=$'\e[31m'; C_GRAY=$'\e[90m'; C_RESET=$'\e[0m'
else
    C_CYAN=""; C_GREEN=""; C_YEL=""; C_RED=""; C_GRAY=""; C_RESET=""
fi
section() { printf '\n%s=== %s ===%s\n' "$C_CYAN" "$1" "$C_RESET"; }
ok()      { printf '  %s[OK]%s   %s\n'   "$C_GREEN" "$C_RESET" "$1"; }
warn()    { printf '  %s[WARN]%s %s\n'   "$C_YEL"   "$C_RESET" "$1"; }
skip()    { printf '  %s[SKIP]%s %s\n'   "$C_GRAY"  "$C_RESET" "$1"; }
fail()    { printf '  %s[FAIL]%s %s\n'   "$C_RED"   "$C_RESET" "$1"; }

# -------------------------------------------------------------------
# 1. PREREQ CHECK
# -------------------------------------------------------------------
section "Prereq check"

# Prereqs as "cmd|install-hint" strings — avoids bash 4 associative arrays so
# this runs on stock macOS bash 3.2.
HARD=(
    "claude|Claude Code CLI — install: https://docs.claude.com/en/docs/claude-code/setup"
    "git|Git — install: https://git-scm.com/downloads"
    "node|Node.js >= 18 — install: https://nodejs.org/"
)
SOFT=(
    "bash|bash — should already be present"
)
case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*) SOFT+=("wt.exe|Windows Terminal — needed for /coord (winget install Microsoft.WindowsTerminal)") ;;
esac

FAILED=()
for entry in "${HARD[@]}"; do
    cmd="${entry%%|*}"; hint="${entry#*|}"
    if command -v "$cmd" >/dev/null 2>&1; then
        ok "$cmd present"
    else
        fail "$cmd missing — $hint"
        FAILED+=("$cmd")
    fi
done
for entry in "${SOFT[@]}"; do
    cmd="${entry%%|*}"; hint="${entry#*|}"
    if command -v "$cmd" >/dev/null 2>&1; then
        ok "$cmd present"
    else
        warn "$cmd missing — $hint"
    fi
done
if [ ${#FAILED[@]} -gt 0 ]; then
    fail "Hard prereqs missing. Install them and re-run."
    exit 1
fi

# -------------------------------------------------------------------
# 2. PARSE settings.json
# -------------------------------------------------------------------
section "Reading settings.json"
SETTINGS="$CLAUDE_DIR/settings.json"
if [ ! -f "$SETTINGS" ]; then
    fail "settings.json not found at $SETTINGS"
    fail "Did you clone the repo into ~/.claude?"
    exit 1
fi

# Parse settings.json via Node (no jq dependency — node is a hard prereq).
# Read into arrays with a while-loop, not `mapfile` — mapfile is bash 4 only.
ENABLED_PLUGINS=()
while IFS= read -r line; do
    [ -n "$line" ] && ENABLED_PLUGINS+=("$line")
done < <(node -e "
const s = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
for (const [k, v] of Object.entries(s.enabledPlugins || {})) if (v === true) console.log(k);
" "$SETTINGS")
MARKETPLACE_NAMES=()
while IFS= read -r line; do
    [ -n "$line" ] && MARKETPLACE_NAMES+=("$line")
done < <(node -e "
const s = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
for (const k of Object.keys(s.extraKnownMarketplaces || {})) console.log(k);
" "$SETTINGS")
ok "${#MARKETPLACE_NAMES[@]} marketplaces, ${#ENABLED_PLUGINS[@]} plugins declared"

# -------------------------------------------------------------------
# 3. INSTALL ENABLED PLUGINS
# -------------------------------------------------------------------
# Marketplaces are deliberately NOT registered here. Claude Code auto-registers
# every marketplace declared in settings.json (extraKnownMarketplaces) on
# startup. Running `claude plugin marketplace add` would rewrite the portable
# "~/..." path in settings.json to a machine-specific absolute path — which
# then gets committed and synced, leaking the username and breaking the
# marketplace on every other machine. So marketplaces stay purely declarative.
if [ "$SKIP_PLUGINS" -eq 0 ]; then
    section "Installing plugins"
    # ${arr[@]+"${arr[@]}"} = bash 3.2-safe expansion of a possibly-empty array
    # under `set -u` (plain "${arr[@]}" errors as unbound on empty arrays there).
    for plugin in ${ENABLED_PLUGINS[@]+"${ENABLED_PLUGINS[@]}"}; do
        echo "  Installing $plugin"
        if claude plugin install "$plugin" --scope user >/dev/null 2>&1; then
            ok "$plugin installed"
        else
            warn "$plugin install failed (may already be installed)"
        fi
    done
    [ ${#ENABLED_PLUGINS[@]} -eq 0 ] && skip "no plugins enabled in settings.json"
else
    skip "Plugin install skipped (--skip-plugins)"
fi

# -------------------------------------------------------------------
# 4. CREDENTIALS TEMPLATE
# -------------------------------------------------------------------
section "Credentials"
CRED_DIR="$CLAUDE_DIR/credentials"
CRED_FILE="$CRED_DIR/api-keys.json"
CRED_TPL="$CRED_DIR/api-keys.template.json"
mkdir -p "$CRED_DIR"

if [ -f "$CRED_FILE" ]; then
    ok "credentials/api-keys.json already present"
elif [ -f "$CRED_TPL" ]; then
    cp "$CRED_TPL" "$CRED_FILE"
    warn "Copied template to credentials/api-keys.json — fill in real keys before using"
else
    cat > "$CRED_FILE" <<'EOF'
{
  "_comment": "Bootstrap template — fill in real keys. Gitignored (credentials/, *api-keys.json*, *credential*).",
  "example_service": { "api_key": "TODO", "api_base": "https://api.example.com" }
}
EOF
    warn "Wrote credentials/api-keys.json TEMPLATE — fill in real keys before using"
fi

# -------------------------------------------------------------------
# 5. /coord PREREQ VERIFY
# -------------------------------------------------------------------
section "/coord prereqs"
for p in claude bash; do
    if command -v "$p" >/dev/null 2>&1; then ok "$p present"; else warn "$p missing — /coord will fail without it"; fi
done
case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*)
        if command -v wt.exe >/dev/null 2>&1; then ok "wt.exe present"; else warn "wt.exe missing — install Windows Terminal"; fi
        ;;
esac
if [ -f "$CLAUDE_DIR/coord-template/spawn.sh" ]; then
    ok "coord-template/spawn.sh present (synced via repo)"
else
    warn "coord-template/spawn.sh missing — repo may be incomplete"
fi

# -------------------------------------------------------------------
# 6. MCP SERVERS
# -------------------------------------------------------------------
section "MCP servers"
cat <<'EOF'
  Add any MCP servers your workflow needs after bootstrap.
  See the Claude Code MCP docs:
    https://docs.claude.com/en/docs/claude-code/mcp
EOF

# -------------------------------------------------------------------
# DONE
# -------------------------------------------------------------------
section "Bootstrap complete"
cat <<EOF
  Next steps:
    1. Fill any TODO keys in credentials/api-keys.json
    2. Add MCP servers your workflow needs (see Claude Code MCP docs)
    3. Restart any open Claude Code windows so plugins load
EOF
