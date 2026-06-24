#!/usr/bin/env bash
# claude-term-ux 맥 세팅 (멱등). 세션 메뉴(zsh)를 설치한다.
#  - assets/claude-menu.zsh  ->  ~/.claude/claude-menu.zsh
#  - ~/.zshrc 에 claude() 함수 주입(마커 가드, 1회만)
# statusline 은 node 가 필요해 맥은 제외(윈도우 전용). 어떤 사용자명에서도 동작.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$SKILL_DIR/assets"
CLAUDE_DIR="$HOME/.claude"

echo ""
echo "claude-term-ux 맥 세팅 시작"
echo ""

mkdir -p "$CLAUDE_DIR" "$CLAUDE_DIR/.menu-cache"
cp "$ASSETS/claude-menu.zsh" "$CLAUDE_DIR/claude-menu.zsh"
chmod +x "$CLAUDE_DIR/claude-menu.zsh"
# 버전 마커 기록(asset VERSION 과 동기) → 첫 실행 때 불필요한 self-heal 재실행 방지
[ -f "$ASSETS/VERSION" ] && cp "$ASSETS/VERSION" "$CLAUDE_DIR/claude-menu.version"
echo "  세션 메뉴 배치: $CLAUDE_DIR/claude-menu.zsh (VERSION $( [ -f "$ASSETS/VERSION" ] && cat "$ASSETS/VERSION" || echo '?' ))"

ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"
MARK_START="# >>> claude-term-ux >>>"
MARK_END="# <<< claude-term-ux <<<"

# 기존 블록 있으면 제거(멱등 — 항상 최신 함수로 교체)
if grep -qF "$MARK_START" "$ZSHRC"; then
  tmp="$(mktemp)"
  awk -v s="$MARK_START" -v e="$MARK_END" '
    $0==s {skip=1}
    skip==0 {print}
    $0==e {skip=0}' "$ZSHRC" > "$tmp"
  mv "$tmp" "$ZSHRC"
fi

cat >> "$ZSHRC" <<'EOF'
# >>> claude-term-ux >>>
# 인자 없이 claude 치면 최근 세션 메뉴, 인자 있으면 진짜 claude 로 통과.
claude() {
  if [ $# -eq 0 ]; then
    "$HOME/.claude/claude-menu.zsh"
  elif [ -x "$HOME/.local/bin/claude" ]; then
    "$HOME/.local/bin/claude" "$@"
  else
    command claude "$@"
  fi
}
# <<< claude-term-ux <<<
EOF
echo "  ~/.zshrc 에 claude() 함수 주입"

echo ""
echo "완료."
echo "  - 세션 메뉴: 새 터미널(또는 'source ~/.zshrc') 부터 인자 없이 'claude' 입력 시 동작."
echo "  - statusline 은 맥 제외(node 필요) — 윈도우 전용."
echo ""
