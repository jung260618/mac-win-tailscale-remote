#!/usr/bin/env bash
# preflight.sh (team-pc-setup) — 맥용 읽기전용 진단. 변경 없음, 항상 exit 0.
set +e
skills="$HOME/.claude/skills"
L(){ printf "%-26s: %s\n" "$1" "$2"; }

echo "=== team-pc-setup preflight (Mac) ==="
L "OS" "macOS ($(scutil --get LocalHostName 2>/dev/null))"

# 설치 소스: GitHub 부트스트랩(curl)으로 받은 폴더에서 install 실행. 별도 지정 시 TEAM_BUNDLE.
BUNDLE="${TEAM_BUNDLE:-}"
if [ -n "$BUNDLE" ] && [ -f "$BUNDLE/install.sh" ]; then L "bundle" "OK ($BUNDLE)"; else L "bundle" "(GitHub 부트스트랩 사용 — 고정 경로 없음)"; fi

# 부품 스킬 설치 여부
for s in claude-term-ux claude-notify-team-26-06-24 file-manager-view-26-06-21 remote-link-team-26-06-24 team-pc-setup-26-06-24; do
  if [ -d "$skills/$s" ]; then L "skill:$s" "installed"; else L "skill:$s" "MISSING"; fi
done

# rules / CLAUDE.md
[ -d "$HOME/.claude/rules" ] && L "rules/" "present" || L "rules/" "MISSING"
[ -f "$HOME/.claude/CLAUDE.md" ] && L "CLAUDE.md" "present" || L "CLAUDE.md" "absent"

# 알림 훅 배선 여부(가벼운 grep)
if [ -f "$HOME/.claude/settings.json" ] && grep -q "notify.sh" "$HOME/.claude/settings.json" 2>/dev/null; then
  L "notify hook" "wired"; else L "notify hook" "not wired"; fi

echo "(읽기전용 — 아무것도 바꾸지 않음)"
exit 0
