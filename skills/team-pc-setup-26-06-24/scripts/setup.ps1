# setup.ps1 (team-pc-setup) — thin entry. ASCII/English only.
# install auto-runs this with NO args: it must NOT mutate anything.
# It only prints the plan + a read-only preflight, then exit 0.
# Real setup = bundle install.ps1 + Claude (per SKILL.md, guided).
param([switch]$Preflight)
$here = $PSScriptRoot

if (-not $Preflight) {
  "team-pc-setup — team Claude work-environment master (guided, no personal data)"
  "Phases:"
  "  0) Preflight  OS / bundle-reachable / parts-installed"
  "  1) Install    run bundle installer (skills, rules, CLAUDE.md + term-ux/notify)"
  "  2) Files      file-manager-view  Explorer view / Finder sort"
  "Claude runs these step-by-step per SKILL.md, confirming before each phase."
  ""
}

& powershell -NoProfile -ExecutionPolicy Bypass -File "$here\preflight.ps1"
exit 0
