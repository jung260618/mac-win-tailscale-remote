#!/bin/bash
# notify.sh (team) — Claude Code 맥 로컬 알림만. 원격(ssh) 전달 없음(팀 공용·개인 토폴로지 비의존).
#   인자: stop  → 작업 완료
#         notify→ 승인/입력 필요. 메시지는 stdin JSON(.message).
# 어떤 경우에도 세션을 막지 않는다(|| true, 항상 exit 0).
mode="${1:-notify}"
title="Claude Code"
if [ "$mode" = "stop" ]; then
  body="작업이 완료되었습니다"; sub="명령한 일을 끝냈어요"; sound="Glass"
else
  msg=$(cat 2>/dev/null | jq -r '.message // "입력이 필요합니다"' 2>/dev/null | tr -d '"')
  body="${msg:-입력이 필요합니다}"; sub="확인이 필요해요"; sound="Ping"
fi

# AppleScript 문자열 안전화: 역슬래시·큰따옴표를 이스케이프(메시지에 섞여도 알림이 안 깨지게).
esc(){ printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
body="$(esc "$body")"; sub="$(esc "$sub")"; title="$(esc "$title")"

# 맥 로컬 알림센터 토스트
osascript -e "display notification \"$body\" with title \"$title\" subtitle \"$sub\" sound name \"$sound\"" 2>/dev/null || true
exit 0
