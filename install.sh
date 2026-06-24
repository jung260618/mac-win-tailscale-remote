#!/usr/bin/env bash
# install.sh — 팀 공용 Claude 작업환경 부트스트랩 (맥).
# GitHub 번들(skills/ rules/ CLAUDE.team.md)을 ~/.claude 로 설치하고,
# 알림 토스트 + 터미널 세션메뉴를 배선한다. 멱등 · 비파괴 · 항상 친절한 요약 후 exit.
# 개인정보(특정 IP·계정·서버·채널·봇) 없음. 파일관리자 보기 설정은 이후 Claude가 가이드.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
CLAUDE="$HOME/.claude"
SKILLS="$CLAUDE/skills"
say(){ printf "%s\n" "$1"; }

say "=== 팀 PC 세팅 설치 시작 (맥) ==="
say "번들: $HERE"

command -v rsync >/dev/null 2>&1 || { say "❌ rsync 필요(맥 기본). 중단."; exit 1; }
mkdir -p "$SKILLS"

# --- 1) 스킬 복사 (.venv/__pycache__ 제외) ---
if [ -d "$HERE/skills" ]; then
  for d in "$HERE"/skills/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    # 비파괴 overlay(--delete 안 씀): 대상 스킬 폴더의 다른 파일을 지우지 않음.
    rsync -a --exclude '.DS_Store' --exclude '.venv' --exclude '__pycache__' --exclude '*.pyc' "$d" "$SKILLS/$name/" \
      && say "  ✅ skill: $name" || say "  ⚠️  skill 복사 실패: $name"
  done
else
  say "  ⚠️  skills/ 없음 — 건너뜀"
fi

# --- 2) rules 복사 (기존 위에 병합) ---
if [ -d "$HERE/rules" ]; then
  rsync -a --exclude '.DS_Store' "$HERE/rules/" "$CLAUDE/rules/" \
    && say "  ✅ rules/ 설치" || say "  ⚠️  rules/ 복사 실패"
fi

# --- 3) CLAUDE.md (기존 보존: 있으면 .team.md 로 두고 안내) ---
if [ -f "$HERE/CLAUDE.team.md" ]; then
  if [ -f "$CLAUDE/CLAUDE.md" ]; then
    cp "$HERE/CLAUDE.team.md" "$CLAUDE/CLAUDE.team.md"
    say "  ℹ️  기존 CLAUDE.md 보존 → 팀 표준본은 $CLAUDE/CLAUDE.team.md 에 둠(필요 시 직접 병합)"
  else
    cp "$HERE/CLAUDE.team.md" "$CLAUDE/CLAUDE.md"
    say "  ✅ CLAUDE.md(팀 표준) 설치"
  fi
fi

# --- 4) 부품 스킬 세팅 실행 (멱등) ---
NOTIFY="$SKILLS/claude-notify-team-26-06-24/scripts/setup.sh"
TERMUX="$SKILLS/claude-term-ux/scripts/setup.sh"
[ -f "$NOTIFY" ] && { say "— 알림 세팅"; bash "$NOTIFY" || say "  ⚠️  알림 세팅 경고(계속)"; }
[ -f "$TERMUX" ] && { say "— 터미널 세션메뉴 세팅"; bash "$TERMUX" || say "  ⚠️  터미널 세팅 경고(계속)"; }

say ""
say "=== 설치 완료 ==="
say "다음: Claude 가 파일관리자(파인더) 보기/정렬 설정을 이어서 도와줍니다."
say "터미널 세션메뉴는 새 터미널 창부터 적용됩니다(source ~/.zshrc 또는 창 새로 열기)."
exit 0
