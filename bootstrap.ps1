# bootstrap.ps1 - claude-config bootstrap (Windows / PowerShell 7+)
#
# Usage:
#   cd ~/.claude
#   pwsh -ExecutionPolicy Bypass -File ./bootstrap.ps1
#
# What it does (idempotent - safe to re-run):
#   1. Verifies prereqs (claude, git, node, optionally wt.exe, bash)
#   2. Installs all enabled plugins from settings.json
#   3. Bootstraps credentials/api-keys.json from template if missing
#   4. Verifies /coord prerequisites (wt.exe, claude on PATH, bash)
#   5. Prints a note about adding MCP servers
#
# Marketplaces declared in settings.json (extraKnownMarketplaces) register
# automatically on Claude Code startup - bootstrap does not touch them.
#
# Exit non-zero only on hard prereq failure. Soft warnings stay non-fatal.

[CmdletBinding()]
param(
    [switch]$SkipPlugins
)

$ErrorActionPreference = 'Stop'
$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }

function Write-Section($Text) {
    Write-Host ""
    Write-Host "=== $Text ===" -ForegroundColor Cyan
}
function Write-Ok($Text)   { Write-Host "  [OK]   $Text" -ForegroundColor Green }
function Write-Warn($Text) { Write-Host "  [WARN] $Text" -ForegroundColor Yellow }
function Write-Skip($Text) { Write-Host "  [SKIP] $Text" -ForegroundColor DarkGray }
function Write-Fail($Text) { Write-Host "  [FAIL] $Text" -ForegroundColor Red }

# -------------------------------------------------------------------
# 1. PREREQ CHECK
# -------------------------------------------------------------------
Write-Section "Prereq check"

$HardPrereqs = @{
    'claude' = 'Claude Code CLI - install: https://docs.claude.com/en/docs/claude-code/setup'
    'git'    = 'Git - install: https://git-scm.com/downloads'
    'node'   = 'Node.js >= 18 - install: https://nodejs.org/'
}
$SoftPrereqs = @{
    'wt.exe' = 'Windows Terminal - needed for /coord multi-window spawn (winget install Microsoft.WindowsTerminal)'
    'bash'   = 'Git Bash - needed for sync hooks and /coord (comes with Git for Windows)'
}

$Failed = @()
foreach ($cmd in $HardPrereqs.Keys) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Write-Ok "$cmd present"
    } else {
        Write-Fail "$cmd missing - $($HardPrereqs[$cmd])"
        $Failed += $cmd
    }
}
foreach ($cmd in $SoftPrereqs.Keys) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Write-Ok "$cmd present"
    } else {
        Write-Warn "$cmd missing - $($SoftPrereqs[$cmd])"
    }
}

if ($Failed.Count -gt 0) {
    Write-Host ""
    Write-Fail "Hard prereqs missing. Install them and re-run."
    exit 1
}

# -------------------------------------------------------------------
# 2. PARSE settings.json (marketplaces + enabled plugins)
# -------------------------------------------------------------------
Write-Section "Reading settings.json"

$SettingsPath = Join-Path $ClaudeDir "settings.json"
if (-not (Test-Path $SettingsPath)) {
    Write-Fail "settings.json not found at $SettingsPath"
    Write-Fail "Did you clone the repo into ~/.claude?"
    exit 1
}

$Settings = Get-Content -LiteralPath $SettingsPath -Raw | ConvertFrom-Json
$Marketplaces = @{}
if ($Settings.extraKnownMarketplaces) {
    $Settings.extraKnownMarketplaces.PSObject.Properties | ForEach-Object {
        $Marketplaces[$_.Name] = $_.Value
    }
}
$EnabledPlugins = @()
if ($Settings.enabledPlugins) {
    $Settings.enabledPlugins.PSObject.Properties | ForEach-Object {
        if ($_.Value -eq $true) { $EnabledPlugins += $_.Name }
    }
}
Write-Ok "$($Marketplaces.Count) marketplaces, $($EnabledPlugins.Count) plugins declared"

# -------------------------------------------------------------------
# 3. INSTALL ENABLED PLUGINS
# -------------------------------------------------------------------
# Marketplaces are deliberately NOT registered here. Claude Code auto-registers
# every marketplace declared in settings.json (extraKnownMarketplaces) on
# startup. Running `claude plugin marketplace add` would rewrite the portable
# "~/..." path in settings.json to a machine-specific absolute path - which
# then gets committed and synced, leaking the username and breaking the
# marketplace on every other machine. So marketplaces stay purely declarative.
if (-not $SkipPlugins) {
    Write-Section "Installing plugins"
    foreach ($plugin in $EnabledPlugins) {
        Write-Host "  Installing $plugin"
        # A native exe's non-zero exit does not throw in PowerShell, so check
        # $LASTEXITCODE rather than relying on try/catch.
        & claude plugin install $plugin --scope user 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "$plugin installed"
        } else {
            Write-Warn "$plugin install failed (may already be installed)"
        }
    }
    if ($EnabledPlugins.Count -eq 0) { Write-Skip "no plugins enabled in settings.json" }
} else {
    Write-Skip 'Plugin install skipped (-SkipPlugins)'
}

# -------------------------------------------------------------------
# 4. CREDENTIALS TEMPLATE
# -------------------------------------------------------------------
Write-Section "Credentials"
$CredDir  = Join-Path $ClaudeDir "credentials"
$CredFile = Join-Path $CredDir   "api-keys.json"
$CredTpl  = Join-Path $CredDir   "api-keys.template.json"

if (-not (Test-Path $CredDir)) { New-Item -ItemType Directory -Path $CredDir | Out-Null }

if (Test-Path $CredFile) {
    Write-Ok "credentials/api-keys.json already present"
} elseif (Test-Path $CredTpl) {
    Copy-Item -LiteralPath $CredTpl -Destination $CredFile
    Write-Warn "Copied template to credentials/api-keys.json - fill in real keys before using"
} else {
    $TplBody = @'
{
  "_comment": "Bootstrap template - fill in real keys. This file is gitignored (defense in depth: credentials/, *api-keys.json*, *credential*).",
  "example_service": { "api_key": "TODO", "api_base": "https://api.example.com" }
}
'@

    Set-Content -LiteralPath $CredFile -Value $TplBody -Encoding UTF8
    Write-Warn "Wrote credentials/api-keys.json TEMPLATE - fill in real keys before using"
}

# -------------------------------------------------------------------
# 5. /coord PREREQ VERIFY
# -------------------------------------------------------------------
Write-Section "/coord prereqs"
$CoordPrereqs = @('wt.exe','claude','bash')
foreach ($p in $CoordPrereqs) {
    if (Get-Command $p -ErrorAction SilentlyContinue) {
        Write-Ok "$p present"
    } else {
        Write-Warn "$p missing - /coord multi-window spawn will fail without it"
    }
}
$CoordTemplate = Join-Path $ClaudeDir "coord-template\spawn.sh"
if (Test-Path $CoordTemplate) {
    Write-Ok "coord-template/spawn.sh present (synced via repo)"
} else {
    Write-Warn "coord-template/spawn.sh missing - repo may be incomplete"
}

# -------------------------------------------------------------------
# 6. MCP SERVERS
# -------------------------------------------------------------------
Write-Section "MCP servers"
Write-Host "  Add any MCP servers your workflow needs after bootstrap."
Write-Host "  See the Claude Code MCP docs:"
Write-Host "    https://docs.claude.com/en/docs/claude-code/mcp"

# -------------------------------------------------------------------
# DONE
# -------------------------------------------------------------------
Write-Section "Bootstrap complete"
Write-Host "  Next steps:"
Write-Host "    1. Fill any TODO keys in credentials/api-keys.json"
Write-Host "    2. Add MCP servers your workflow needs (see Claude Code MCP docs)"
Write-Host "    3. Restart any open Claude Code windows so plugins load"
Write-Host ""
