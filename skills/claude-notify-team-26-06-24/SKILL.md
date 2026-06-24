---
name: claude-notify-team-26-06-24
description: 팀 공용 Claude Code 알림 세팅. 승인/완료 이벤트를 차단형 대화상자 대신 OS 네이티브 토스트(맥 알림센터 / 윈도우 토스트)로 띄운다. 개인 토폴로지(원격 ssh 전달) 비의존 — 로컬 알림만. team-pc-setup 마스터가 호출하거나, "알림만 다시 세팅" 같은 단일 요청에 직접 사용. (cross-platform: setup.sh + setup.ps1)
---

> **[플랫폼]** 맥 ✅ / 윈도우 ✅ — 로컬 토스트 전용(원격 전달 없음, 팀 공용)

# claude-notify-team — 팀 공용 알림 세팅

Claude Code가 승인을 기다리거나 작업을 끝냈을 때, 차단형 메시지박스 대신 **OS 네이티브 토스트**로 알린다. 개인 `claude-notify-26-06-20`에서 원격(ssh peer 전달) 부분을 제거한 팀 공용본.

## 설치
- 맥: `bash "$HOME/.claude/skills/claude-notify-team-26-06-24/scripts/setup.sh"`
- 윈도우: `powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\skills\claude-notify-team-26-06-24\scripts\setup.ps1"`

## 동작
- 맥: `~/.claude/hooks/notify.sh` 배치 → `settings.json` 의 Stop/Notification 훅 배선 → `osascript` 로컬 토스트.
- 윈도우: `~/.claude/hooks/peer-notify.ps1`(UTF-8 BOM) 작성 → Stop/Notification 훅 배선 → Windows.UI.Notifications 네이티브 토스트(기본 AUMID `Anysphere.Cursor`).

## 규칙
- 멱등·비파괴: 이미 배선돼 있으면 안 건드림. 기존 훅 보존.
- 어떤 경우에도 세션을 막지 않음(실패해도 조용히 로그, 항상 exit 0).
