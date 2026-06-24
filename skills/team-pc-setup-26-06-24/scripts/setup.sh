#!/usr/bin/env bash
# setup.sh (team-pc-setup) — 얇은 진입점. install 이 인자 없이 자동 실행 → 변경 없이
# 계획 + 읽기전용 preflight 만 출력하고 exit 0. 실제 세팅은 번들 install.{sh,ps1} + Claude(SKILL.md).
set +e
here="$(cd "$(dirname "$0")" && pwd)"

if [ "${1:-}" != "--preflight" ]; then
  echo "team-pc-setup — 팀 공용 작업환경 세팅 마스터 (가이드형, 개인정보 없음)"
  echo "단계:"
  echo "  0) 프리플라이트  OS/번들도달/부품설치 진단"
  echo "  1) 환경설치      번들 install 실행 (스킬·rules·CLAUDE.md + term-ux/notify)"
  echo "  2) 파일관리자    file-manager-view  Explorer 보기 / Finder 정렬"
  echo "Claude 가 SKILL.md 절차대로 단계마다 확인받으며 진행합니다."
  echo ""
fi

bash "$here/preflight.sh"
exit 0
