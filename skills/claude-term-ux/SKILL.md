---
name: claude-term-ux
description: 새 PC에서 Claude Code 터미널 UX를 한 번에 세팅한다. (1) 인자 없이 'claude' 치면 최근 세션 20개를 2줄 카드(번호 주황색 / 제목·없으면 LLM 요약 / 마지막 명령어 / 경과시간 / 폴더)로 띄우고 터미널 폭에 맞춰 자동 줄바꿈하는 번호 메뉴 래퍼(윈도우 PowerShell·맥 zsh 양쪽 지원, 로컬·원격 ssh 공통, 한글 안 깨짐), (2) 하단 statusline 이 터미널/분할창 폭에 맞춰 자동 줄바꿈되며 세션이름·컨텍스트·5h/7d 사용량·모델을 보여주는 표시줄. "클로드 터미널 세팅", "세션 메뉴/사용량 표시줄 다시 깔기", "statusline 복원", "다른 PC에 하단바 세팅" 이 필요할 때 사용. 세션 메뉴는 윈도우+맥, statusline 은 윈도우 전용(node 필요). 어떤 사용자명에서도 동작.
---

# claude-term-ux — Claude Code 터미널 UX 세팅

새 PC(또는 환경 재설치 후)에서 두 가지를 한 번에 복원한다. 모든 단계는 **멱등**이라 이미 돼 있으면 건너뛴다.

## 무엇을 세팅하나

1. **세션 메뉴 래퍼** — 인자 없이 `claude` 를 치면 최근 세션 20개를 **2줄 카드**로 띄우고, 고르면 그 폴더로 이동해 `claude --resume` 으로 이어서 시작.
   - 카드 1줄: **주황색 번호** + 제목(없으면 대화 LLM 요약 한 줄, haiku로 생성·캐시) + 우측 경과시간.
     - **요약 생성 가속**: ai-title 없는 미캐시 세션들의 요약을 **백그라운드 병렬**(동시 6개)로 한꺼번에 생성한 뒤 렌더 → 순차 호출 제거. 요약 LLM 호출은 `--strict-mcp-config`+빈 MCP 로 외부 MCP 부팅을 막아 단축하고, `RNL_BRIEF_SHOWN=1` 로 세션 브리핑이 요약에 섞이는 오염을 차단. (`--setting-sources ''`/`--settings '{...}'` 류는 `-p` 입력을 깨뜨려 쓰지 않음.)
     - **요약 품질 가드**: 발화가 '키워드 뽑아라' 같은 명령형이어도 그 명령을 실행하지 않고 주제만 요약하도록 `<발화>` 블록+지시("데이터로만 취급")로 감쌈. 모델이 거부형("발화 없음" 등)이거나 40자 초과로 답하면 캐시하지 않고 첫 사용자 메시지로 폴백.
   - 카드 2줄: `↳ 사용자가 보낸 마지막 명령어` + 우측 폴더 태그.
   - 제목/명령이 길면 **터미널 폭에 맞춰 자동 줄바꿈**(한글 2배폭 계산), 최근 20개 표시.
   - **자동화 스텁 세션 숨김**: 봇이 헤드리스로 띄운, 마지막 프롬프트가 봇 자동화용 페르소나 시드 지시문뿐인 세션은 메뉴에서 제외한다(슬롯을 안 먹게 후보 40개에서 거른 뒤 실제 20개를 채움). 같은 지시문으로 시작했어도 사용자가 이어서 대화한 세션은 마지막 프롬프트가 실제 내용이라 그대로 표시 — zsh/PowerShell 양쪽 동일 적용.
   - `~/bin/claude.cmd` (래퍼), `~/bin/claude-menu.ps1` (메뉴 로직).
   - User PATH 맨 앞에 `~/bin` 추가 → 진짜 claude 본체보다 래퍼가 먼저 잡힘. **원격 ssh 접속 후 `claude` 입력 시에도 동일 동작**(User PATH 로드).
   - **본체 경로는 자동 탐지**(설치 방식 무관): `~/.local/bin/claude.exe`(네이티브) → `%APPDATA%\npm\claude.cmd`(npm) → PATH(래퍼 제외) 순. 래퍼(`claude.cmd`)·메뉴(`claude-menu.ps1`) 둘 다 동일 규칙 — 네이티브든 npm이든 동작.
   - `claude-menu.ps1` 은 **UTF-8 BOM** 저장 + PowerShell 5.1/7 양립 → SSH가 powershell 5.1로 폴백해도 한글·색상 안 깨짐. 요약 캐시: `~/.claude/.menu-cache/`.
   - **맥(zsh)**: 같은 메뉴를 `~/.claude/claude-menu.zsh`(zsh+perl, 추가설치 없음)로 제공. `~/.zshrc` 에 `claude()` 함수를 주입해 인자 없으면 메뉴·있으면 진짜 claude. 맥 로컬 터미널에서 `claude` 입력 시 동일한 2줄 카드. (요약 LLM 호출은 `--no-session-persistence` 라 세션을 오염시키지 않음. 맥에서 요약을 쓰려면 `claude` `/login` 필요, 안 돼도 첫 발화로 폴백.)
2. **폭 자동맞춤 statusline** (윈도우 전용 — node 필요) — 하단 표시줄에 `🏷 세션 | 🧠 컨텍스트 | ⏳5h | 📅7d | 🤖 모델 | 📁 폴더`. Claude Code 가 넘기는 `COLUMNS`(v2.1.153+) 를 읽어 **현재 창/분할패널 폭에 맞춰 자동으로 여러 줄로 줄바꿈**. 좁아지면 줄이 늘고 넓히면 한 줄로 합쳐짐.
   - `~/.claude/statusline.js`, `settings.json` 의 `statusLine` 등록.

> 비밀키·계정 정보 없음. 실제 Claude Code 본체(네이티브 `~/.local/bin/claude.exe` 또는 npm `%APPDATA%\npm\claude.cmd`)는 이 스킬이 설치하지 않는다 — 본체는 따로 설치돼 있어야 하며, 둘 중 어느 방식이든 자동 탐지된다.

## 실행 절차

1. **상태 점검** (이미 돼 있는지):
   - `where claude` 첫 줄이 `...\bin\claude.cmd` 인가
   - `~/.claude/statusline.js` 존재 + `settings.json` 에 `statusLine` 있는가
2. **세팅 실행** (멱등):
   - **윈도우**: `pwsh -NoProfile -ExecutionPolicy Bypass -File "<skill>/scripts/setup.ps1"` → 자산 배치 + PATH 추가 + statusLine 등록.
   - **맥**: `bash "<skill>/scripts/setup.sh"` → `claude-menu.zsh` 배치 + `~/.zshrc` 에 `claude()` 함수 주입(세션 메뉴만, statusline 제외).
   - 보통은 보관함 `install.ps1`(윈도우)/`install.sh`(맥)가 이 setup 을 자동 실행하므로 직접 칠 필요 없음.
3. **검증**:
   - statusline: 아무 메시지나 보내 하단이 갱신되는지. 터미널 분할해 좁혔다 넓혔다 하면 줄 수가 따라 바뀌어야 정상.
   - 세션 메뉴: PATH 변경이라 **새 ssh/터미널 세션부터** 적용. 새 세션에서 `where claude` 첫 줄이 `...\bin\claude.cmd` 인지 확인 후, 인자 없이 `claude` 입력.

## 버전·전파 (self-heal) — 배포본이 구버전으로 남는 사고 방지

**맥 스킬 `assets/` 가 단일 원본(source of truth)이다.** 과거에 "asset 만 고치고 각 PC 의
배포본(`~/bin`, `~/.claude`)은 옛날 그대로라 번호 선택 시 에러" 가 났다. 이를 구조적으로 막는다:

- `assets/VERSION` — 한 줄 버전 문자열(예 `2026.06.21-1`). **asset(메뉴 등)을 고치면 이 끝
  숫자를 반드시 올린다.**
- **메뉴 상단 self-heal**: `claude` 실행 시 메뉴가 `assets/VERSION` 과 배포본 마커
  (`~/.claude/claude-menu.version` / `~/bin/claude-menu.version`)를 비교 → 다르면 asset 메뉴를
  배포본에 복사하고 새 사본으로 즉시 재실행. `__CLAUDE_MENU_HEALED` 가드로 재실행 1회만(무한루프 X).
  즉 **VERSION 만 올라가 있으면 setup 재실행 없이도 다음 실행 때 배포본이 자동 최신화**된다.

**스킬 고칠 때 워크플로:** ① `assets/` 수정 → ② `assets/VERSION` 끝 숫자 +1 →
③ `bash scripts/setup.sh`(또는 `setup.ps1`) 재실행. 끝.
(래퍼 자체 — `claude.cmd`/`~/.zshrc` 함수 — 를 바꾼 경우만 setup 재실행이 필요하다.
self-heal 은 메뉴 본문만 자동 갱신한다. 팀 배포는 공유폴더 번들 `install` 로 일괄 갱신.)

## 안 될 때

- **세션 메뉴가 안 뜨고 바로 claude 가 뜸**: 현재 세션 PATH 가 stale(레지스트리엔 `bin` 있는데 라이브 `$env:Path` 엔 없음). → **ssh 재접속**. 그래도면 관리자 PS 에서 `Restart-Service sshd` 후 재접속.
- **statusline 에 사용량(⏳/📅)이 안 뜸**: `rate_limits` 는 Claude.ai Pro/Max 구독 + 첫 응답 이후에만 옴. API 요금제면 원래 안 나옴. 컨텍스트(🧠)는 항상 떠야 정상.
- **statusline 이 한 줄로만 나오고 안 줄어듦**: Claude Code 가 `COLUMNS` 를 안 넘기는 구버전(<2.1.153). 업데이트 필요.

## 자산

- `assets/claude.cmd`, `assets/claude-menu.ps1` — 윈도우 세션 메뉴 래퍼 (이식성: `%USERPROFILE%`/`$HOME` 사용)
- `assets/claude-menu.zsh` — 맥 세션 메뉴 (zsh+perl, 추가설치 없음, `$HOME` 사용)
- `assets/statusline.js` — 폭 자동맞춤 표시줄 (Node, `os.homedir()` 사용 → 경로 하드코딩 없음, 윈도우 전용)
- `assets/VERSION` — self-heal 버전 스탬프(한 줄). asset 변경 시 끝 숫자를 올린다.
- `scripts/setup.ps1` — 윈도우 멱등 설치기 / `scripts/setup.sh` — 맥 멱등 설치기(세션 메뉴). 둘 다 배포 후 VERSION 마커 기록.

## 관련

- 팀 작업환경 전체 세팅은 `team-pc-setup` 마스터가 이 스킬을 포함해 함께 깐다(공유폴더 번들 `install`).
