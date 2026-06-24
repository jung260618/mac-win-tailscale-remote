---
name: team-pc-setup-26-06-24
description: 팀원 새 PC(윈도우/맥)에 '팀 공용 Claude 작업환경'을 한 번에 까는 마스터 오케스트레이터(가이드형). 개인 정보(특정 IP·계정·서버·채널·봇)는 일절 없음. "팀 PC 세팅", "팀원 환경 세팅", "team pc setup", "회사 PC 클로드 환경 세팅", "팀원 테일스케일 세팅", "팀 원격연결(맥-윈도우)", "테일스케일로 팀 세팅" 같은 요청에 트리거. 공개 GitHub 저장소의 번들을 ~/.claude 로 설치(스킬·rules·CLAUDE.md)하고, 알림 토스트·터미널 세션메뉴를 배선한 뒤, 파일관리자 보기 설정을 가이드한다. 소유자 개인 PC와의 SSH 연결·데이터 이전·텔레그램은 포함하지 않는다(그건 개인용 new-pc-setup 소관). (cross-platform: setup.sh + setup.ps1, 가이드형)
---

> **[플랫폼]** 맥 ✅ / 윈도우 ✅ — 팀원 공용(개인 토폴로지·데이터 비포함)

# team-pc-setup — 팀 공용 작업환경 세팅 마스터

팀원의 새 PC에 **팀 표준 Claude 작업환경**을 까는 단일 진입점. GitHub 저장소의 번들을 설치하고, 가이드형으로 마무리 설정을 돕는다. 개인용 `new-pc-setup-26-06-21`(개인 서버 연결·데이터 이전·텔레그램 포함)과 달리, 이 스킬은 **개인정보가 전혀 없는 팀원 공용 환경만** 세팅한다.

## 무엇을 까나
| 항목 | 내용 | 개인정보 |
|------|------|----------|
| rules/ | 팀 코딩 표준(common + 언어 오버레이) | 없음 |
| CLAUDE.md | 팀 공용 일반본(개인 채널·서버·봇 제거) | 없음 |
| claude-term-ux | 터미널 세션메뉴 + statusline | 없음 |
| claude-notify-team | 승인/완료 OS 토스트(로컬만) | 없음 |
| file-manager-view | 탐색기 보기 / 파인더 정렬 고정 | 없음 |
| remote-link-team | (선택) 본인 PC↔본인 맥 ssh+M: 연결, 본인 Tailscale | 없음(본인 값) |

**포함하지 않음(의도적):** claude-env-clone(소유자→peer 푸시 도구), migrate-mainserver(개인 데이터), telegram-bot-deploy(개인 봇). ※ remote-link 는 개인판(특정 개인 IP 하드코딩) 대신 **de-personalized `remote-link-team`** 을 선택 단계로 포함(팀원 본인 Tailscale·본인 맥).

## 실행 흐름 (팀원이 Claude에 프롬프트 한 줄 붙여넣기)
팀원은 README의 프롬프트를 Claude(커서 터미널)에 붙여넣는다. 그러면 Claude가:

### 0단계 — 프리플라이트 (읽기전용)
- 맥: `bash "$HOME/.claude/skills/team-pc-setup-26-06-24/scripts/preflight.sh"`
- 윈도우: `powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\skills\team-pc-setup-26-06-24\scripts\preflight.ps1"`

OS·번들 도달 여부·이미 설치된 부품을 보고 계획을 확인받는다.

### 1단계 — 환경설치 (번들 install 실행)
한 줄 부트스트랩(curl/irm)이 GitHub 저장소를 받아 그 폴더의 install 스크립트를 실행한다(스킬·rules·CLAUDE.md 복사 + term-ux/notify 세팅 + 테스트 토스트).
- 맥: 부트스트랩이 받은 폴더의 `install.sh` 실행
- 윈도우: 부트스트랩이 받은 폴더의 `install.ps1` 실행

**검증 게이트**: `~/.claude/skills/claude-term-ux` 존재 **AND** `~/.claude/skills/claude-notify-team-26-06-24` 존재 **AND** `settings.json` 에 Stop/Notification 훅 배선됨 **AND** 테스트 토스트가 실제로 한 번 떴는지 사용자에게 확인.

### 2단계 — 파일관리자 보기/정렬 (가이드)
`file-manager-view-26-06-21` 절차대로:
- **윈도우**: 팀원이 한 폴더에 원하는 보기를 직접 설정 → `scripts\setup.ps1 -Backup` → `-FindUserBag` → `-Apply -SourceKey '<경로>'`.
- **맥**: 적용 범위를 물어본 뒤 → `bash scripts/setup.sh home`(또는 폴더경로).

**검증 게이트**: 폴더 몇 개 열어 지정한 보기/정렬로 나오는지 **사용자 눈으로 확인**.

### 3단계 — 원격연결 (선택, 본인 PC↔본인 맥)
끝에 **물어보고만** 진행한다(Tailscale·두 기기·비번이 필요해 강제 안 함):
> "본인 윈도우 PC에서 본인 맥에 `ssh mac` + `M:` 드라이브로 붙는 원격연결도 세팅할까요? (본인 맥+윈도우가 같은 Tailscale 계정에 로그인돼 있어야 함)"

원하면 `remote-link-team-26-06-24` 절차대로 **2대로 나눠** 진행한다:
- **맥에서 먼저**: `zsh "$HOME/.claude/skills/remote-link-team-26-06-24/scripts/setup-mac-server.zsh"` → 출력된 `MacUser`/`MacIp` 확보.
- **윈도우에서**: `powershell ... \remote-link-team-26-06-24\scripts\bootstrap-cockpit-to-mac.ps1 -MacIp <맥IP> -MacUser <맥사용자>`(관리자).

**검증 게이트**: 윈도우에서 `ssh -o BatchMode=yes mac hostname` 무비번 성공 **AND** `Test-Path M:\` 참.
(개인판 remote-link 와 달리 IP·계정 하드코딩 없음 — 전부 팀원 본인 값.)

### 완료 요약
설치된 항목·다음 할 일(있으면)을 한국어로 정리. 끝.

## 게이트 규약 (매 단계)
1. **설명** 먼저(이 단계가 뭘 하는지 한국어로).
2. **스킵 확인**: preflight상 이미 됐으면 "건너뛸까요?".
3. **진행**: 사용자 확인 후 위 경로의 스크립트 실행.
4. **검증**: 위 게이트 통과해야 다음 단계. 실패하면 그 자리에서 해당 부품 스킬로 해결.

## 자체 스크립트 (얇음)
- `scripts/setup.{sh,ps1}` — install이 인자 없이 자동 실행해도 **아무것도 바꾸지 않고** 계획 + preflight만 출력 후 exit 0. 실제 오케스트레이션은 Claude가 이 SKILL.md대로 수행.
- `scripts/preflight.{sh,ps1}` — 읽기전용 진단(OS·번들도달·부품설치·훅배선).
