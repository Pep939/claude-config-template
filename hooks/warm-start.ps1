# warm-start.ps1 — Injects project state into Claude Code session context
# Windows PowerShell version

Write-Output "=== WARM START: Project State ==="
Write-Output ""

# --- Git State ---
Write-Output "## Git State"
$branch = git branch --show-current 2>$null
if ($branch) { Write-Output "- Branch: $branch" } else { Write-Output "- Branch: not a git repo" }

$lastCommit = git log -1 --format="%h %s" 2>$null
if ($lastCommit) { Write-Output "- Last commit: $lastCommit" } else { Write-Output "- Last commit: none" }

$uncommitted = (git status --porcelain 2>$null | Measure-Object -Line).Lines
Write-Output "- Uncommitted changes: $uncommitted files"

$stashCount = (git stash list 2>$null | Measure-Object -Line).Lines
Write-Output "- Stash count: $stashCount"
Write-Output ""

# --- Stack Detection ---
Write-Output "## Stack"
if (Test-Path "requirements.txt") {
    $pyVer = python --version 2>$null
    Write-Output "- Python: $pyVer"
    Write-Output "- Dependencies: requirements.txt"
    $framework = Select-String -Path "requirements.txt" -Pattern "^(fastapi|flask|django)" 2>$null | ForEach-Object { $_.Line } | Select-Object -First 5
    if ($framework) { Write-Output "- Framework: $($framework -join ', ')" }
}
if (Test-Path "Dockerfile") { Write-Output "- Docker: Dockerfile present" }
if (Test-Path "package.json") {
    $nodeVer = node --version 2>$null
    Write-Output "- Node: $nodeVer"
}
Write-Output ""

# --- Key Commands ---
Write-Output "## Key Commands"
if (Test-Path "requirements.txt") {
    Write-Output "- Run: python main.py"
    Write-Output "- Install: pip install -r requirements.txt"
}
if (Test-Path "Dockerfile") { Write-Output "- Docker build: docker build -t myapp ." }
Write-Output ""

# --- Project Structure ---
Write-Output "## Project Structure (agents)"
Get-ChildItem -Directory | Where-Object { $_.Name -notmatch "^(__pycache__|node_modules|\.claude|knowledge|\.git|assets)" } | ForEach-Object { Write-Output "  $($_.Name)/" } | Select-Object -First 20
Write-Output ""

# --- Recent Commits ---
Write-Output "## Recent Commits (last 5)"
git log --oneline -5 2>$null
Write-Output ""

# --- Knowledge System ---
Write-Output "## Knowledge System"
if (Test-Path "knowledge") {
    $domains = (Get-ChildItem "knowledge" -Directory).Count
    Write-Output "- Knowledge domains: $domains"
} else {
    Write-Output "- No knowledge directory found"
}
Write-Output ""
Write-Output "=== WARM START COMPLETE ==="
