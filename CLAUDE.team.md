# CLAUDE.md (팀 공용)

이 파일은 팀 표준 Claude Code 작업환경의 전역 지침입니다. 모든 세션에 자동 로드됩니다.
개별 저장소의 프로젝트별 `CLAUDE.md`가 여기보다 우선하지만, 이를 대체하지는 않습니다.

> 개인 환경 설정(특정 서버·계정·채널·봇 등)은 포함하지 않습니다. 팀 공통 규칙만 담습니다.

## 코딩 규칙은 rules/ 가 원본(source of truth)

`~/.claude/rules/common/` 아래 파일들이 시스템 프롬프트에 주입됩니다. 의문이 생기면 추측하지 말고 해당 규칙 파일을 직접 읽으세요:

- `coding-style.md` — 불변성 원칙(in-place 변경 금지), KISS/DRY/YAGNI, 파일 크기 한도(200–400줄 통상, 800 최대), 네이밍.
- `testing.md` — 커버리지 하한 80%, TDD(RED→GREEN→REFACTOR), AAA 구조.
- `security.md` — 커밋 전 체크리스트, 시크릿 정책(평문 금지).
- `code-review.md` — 심각도 등급(CRITICAL 차단 / HIGH 경고 / MEDIUM 안내 / LOW 참고).
- `development-workflow.md` — 리서치 순서(gh search → 벤더 문서 → 웹). 신규 작성보다 검증된 구현 채택 우선.
- `git-workflow.md` — 컨벤셔널 커밋(`feat|fix|refactor|docs|test|chore|perf|ci`).
- `agents.md`, `hooks.md`, `patterns.md`, `performance.md` — 에이전트 오케스트레이션, 훅, 디자인 패턴, 모델 티어.

언어 오버레이(`rules/{golang,python,typescript}/`)는 같은 파일명으로 공통 규칙을 확장합니다. 해당 언어로 작업할 때 공통+오버레이를 함께 읽으세요.

## 공통 관례

1. **응답 언어는 사용자에 맞춤** — 코드/식별자는 영어, 설명은 사용자가 쓰는 언어로. 한국어 답변은 전송 전 오타·맞춤법을 한 번 검수.
2. **커밋 트레일러**: 팀 정책에 따름. (기본: `Co-Authored-By` 등 자동 트레일러 비활성 권장 — `settings.json`에서 제어)
3. **복잡한 작업은 계획 먼저** — 사소하지 않은 기능은 코드 작성 전 `planner` 에이전트로 계획.
4. **독립 리뷰는 병렬 에이전트** — 보안·성능·타입 등은 동시에 디스패치. `rules/common/agents.md` 참조.
5. **커밋 전 보안 체크** — 하드코딩 시크릿 금지, 입력 검증, 에러 처리. `rules/common/security.md` 참조.

## 알림·터미널

- 승인/완료 시 OS 토스트 알림이 뜹니다(claude-notify-team). 차단형 대화상자 대신 알림센터/토스트로.
- 빈 `claude` 입력 시 최근 세션 메뉴가 뜹니다(claude-term-ux). 이어서 작업할 세션을 고를 수 있습니다.

## 스킬 추가/수정

- 팀 공용 스킬은 공개 GitHub 저장소 `mac-win-tailscale-remote` 에서 배포됩니다. 새 PC는 한 줄 부트스트랩으로 받아 `install.{sh,ps1}` 가 설치합니다.
- 개인용 스킬을 따로 만들면 `~/.claude/skills/` 에 두되, 팀 번들과 이름이 겹치지 않게 하세요.
