# install.ps1 — team Claude work-environment bootstrap (Windows).
# Copies bundle (skills/ rules/ CLAUDE.team.md) into %USERPROFILE%\.claude,
# then wires notification toasts + terminal session menu. Idempotent, non-destructive.
# No personal data. File-manager view is guided afterwards by Claude.
$ErrorActionPreference = "Stop"
$here   = $PSScriptRoot
$claude = Join-Path $env:USERPROFILE ".claude"
$skills = Join-Path $claude "skills"

Write-Host "=== Team PC setup install (Windows) ===" -ForegroundColor Cyan
Write-Host "bundle: $here"

New-Item -ItemType Directory -Force -Path $skills | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $claude "rules") | Out-Null

# Prefer PowerShell 7 (pwsh) for sub-setups; fall back to Windows PowerShell.
# Notification setup REQUIRES pwsh 7 (uses ConvertFrom-Json -AsHashtable, absent in PS 5.1).
# Terminal setup works on 5.1 (plain ConvertFrom-Json), so it can use the fallback.
$pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
$hasPwsh = [bool]$pwshCmd
$pwshExe = if ($pwshCmd) { $pwshCmd.Source } else { "powershell" }

# --- 1) Copy skills ---
$srcSkills = Join-Path $here "skills"
if (Test-Path $srcSkills) {
  Get-ChildItem -Path $srcSkills -Directory | ForEach-Object {
    $dst = Join-Path $skills $_.Name
    # Non-destructive overlay: copy CONTENTS into existing dir (no Remove-Item,
    # and copy '*' to avoid the nested-folder gotcha when $dst already exists).
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Copy-Item (Join-Path $_.FullName '*') $dst -Recurse -Force
    Write-Host "  [ok] skill: $($_.Name)" -ForegroundColor Green
  }
} else { Write-Host "  [warn] skills/ not found - skipped" -ForegroundColor Yellow }

# --- 2) Copy rules (merge over existing) ---
$srcRules = Join-Path $here "rules"
if ((Test-Path $srcRules) -and (Get-ChildItem $srcRules -Force -ErrorAction SilentlyContinue)) {
  Copy-Item (Join-Path $srcRules "*") (Join-Path $claude "rules") -Recurse -Force
  Write-Host "  [ok] rules/ installed" -ForegroundColor Green
}

# --- 3) CLAUDE.md (preserve existing) ---
$srcClaude = Join-Path $here "CLAUDE.team.md"
if (Test-Path $srcClaude) {
  $dstClaude = Join-Path $claude "CLAUDE.md"
  if (Test-Path $dstClaude) {
    Copy-Item $srcClaude (Join-Path $claude "CLAUDE.team.md") -Force
    Write-Host "  [info] existing CLAUDE.md kept; team version saved as CLAUDE.team.md (merge manually if needed)" -ForegroundColor DarkGray
  } else {
    Copy-Item $srcClaude $dstClaude -Force
    Write-Host "  [ok] CLAUDE.md (team standard) installed" -ForegroundColor Green
  }
}

# --- 4) Run part-skill setups (idempotent) ---
$notify = Join-Path $skills "claude-notify-team-26-06-24\scripts\setup.ps1"
$termux = Join-Path $skills "claude-term-ux\scripts\setup.ps1"
if (Test-Path $notify) {
  if ($hasPwsh) {
    Write-Host "- notification setup"
    & $pwshExe -NoProfile -ExecutionPolicy Bypass -File $notify
  } else {
    Write-Host "  [skip] notification setup needs PowerShell 7 (pwsh). Skills/rules/CLAUDE.md are installed." -ForegroundColor Yellow
    Write-Host "         Install pwsh, then run:  pwsh -NoProfile -ExecutionPolicy Bypass -File `"$notify`"" -ForegroundColor Yellow
  }
}
if (Test-Path $termux) {
  Write-Host "- terminal session-menu setup"
  & $pwshExe -NoProfile -ExecutionPolicy Bypass -File $termux
}

Write-Host ""
Write-Host "=== Install complete ===" -ForegroundColor Cyan
Write-Host "Next: Claude will guide Explorer view/sort setup (file-manager-view)."
Write-Host "Session menu & statusline apply to NEW terminal windows."
exit 0
