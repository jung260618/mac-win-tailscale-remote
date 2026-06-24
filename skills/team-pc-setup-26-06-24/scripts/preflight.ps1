# preflight.ps1 (team-pc-setup) — Windows read-only diagnostics. No mutation, always exit 0.
$ErrorActionPreference = "SilentlyContinue"
$skills = Join-Path $env:USERPROFILE ".claude\skills"
function L($k,$v){ "{0,-26}: {1}" -f $k,$v }

"=== team-pc-setup preflight (Windows) ==="
L "OS" ("Windows ({0})" -f $env:COMPUTERNAME)

# Install source comes from the GitHub bootstrap (Invoke-WebRequest). Override with $env:TEAM_BUNDLE.
$bundle = if ($env:TEAM_BUNDLE) { $env:TEAM_BUNDLE } else { "" }
if ($bundle -and (Test-Path (Join-Path $bundle "install.ps1"))) { L "bundle" "OK ($bundle)" } else { L "bundle" "(GitHub bootstrap - no fixed path)" }

foreach ($s in @("claude-term-ux","claude-notify-team-26-06-24","file-manager-view-26-06-21","remote-link-team-26-06-24","team-pc-setup-26-06-24")) {
  if (Test-Path (Join-Path $skills $s)) { L "skill:$s" "installed" } else { L "skill:$s" "MISSING" }
}

if (Test-Path (Join-Path $env:USERPROFILE ".claude\rules")) { L "rules/" "present" } else { L "rules/" "MISSING" }
if (Test-Path (Join-Path $env:USERPROFILE ".claude\CLAUDE.md")) { L "CLAUDE.md" "present" } else { L "CLAUDE.md" "absent" }

$settings = Join-Path $env:USERPROFILE ".claude\settings.json"
if ((Test-Path $settings) -and (Select-String -Path $settings -Pattern "peer-notify.ps1" -Quiet)) { L "notify hook" "wired" } else { L "notify hook" "not wired" }

"(read-only - nothing changed)"
exit 0
