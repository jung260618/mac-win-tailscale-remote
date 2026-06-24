#!/usr/bin/env bash
# setup.sh  (file-manager-view — 맥: Finder 정렬 "생성일순 자동 유지" 고정)
# install.sh가 설치 후 인자 없이 자동 실행 → 변경하지 않고 계획만 출력하고 exit 0.
# 규칙: 멱등 · 전제조건(없으면 번들에서 설치) · $HOME 상대경로 · 요약 출력 · 성공 exit 0.
set -euo pipefail
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"   # 스킬 루트
TOOL="$HOME/.local/bin/finder-sort-datecreated"
BUNDLED="$SKILL_DIR/assets/finder-sort-datecreated"

ensure_tool() {
  # 전제조건: finder-sort-datecreated 가 있어야 함. 없으면 번들본을 ~/.local/bin 에 설치(자체완결).
  if [ ! -x "$TOOL" ]; then
    if [ -f "$BUNDLED" ]; then
      mkdir -p "$HOME/.local/bin"
      cp "$BUNDLED" "$TOOL"
      chmod +x "$TOOL"
      echo "  finder-sort-datecreated 설치: $TOOL (번들에서)"
    else
      echo "❌ finder-sort-datecreated 도구를 찾을 수 없고 번들도 없습니다."
      echo "   $BUNDLED 를 확인하세요."
      exit 0   # install 자동실행을 깨지 않도록 비치명 종료
    fi
  fi
}

SCOPE="${1:-}"

if [ -z "$SCOPE" ]; then
  # 인자 없이 실행(=install 자동실행): 변경하지 않고 계획만 안내 후 정상 종료.
  echo "file-manager-view (맥): Finder 정렬을 생성일순 자동 유지로 고정"
  echo "  실행 전 SKILL.md(## 맥)의 인터뷰로 범위를 확인하세요. 그 다음:"
  echo "    내 맥 전체:   bash setup.sh home"
  echo "    특정 폴더:    bash setup.sh <폴더경로>   (예: ~/Desktop/<폴더>)"
  echo "  ⚠️ .DS_Store 초기화는 창 크기·아이콘 위치도 리셋합니다(정렬 자동화 비용)."
  exit 0
fi

ensure_tool

case "$SCOPE" in
  home)
    echo "  내 맥 전체(홈) 생성일순 적용..."
    "$TOOL"
    ;;
  *)
    # 경로로 간주: 해당 폴더에만 적용
    echo "  대상 폴더 적용: $SCOPE"
    "$TOOL" "$SCOPE"
    ;;
esac

echo "✅ file-manager-view 맥 세팅 완료 (Finder 생성일순)."
