# mac-win-tailscale-remote — 팀 Claude 작업환경 + (선택) Mac↔Win 원격연결

새 PC(윈도우/맥)에 **팀 표준 Claude 작업환경**을 한 줄로 까는 공개 번들입니다.
개인정보(특정 IP·계정·서버·채널·봇) 없음. 공유폴더/VPN 필요 없이 **인터넷만 있으면** 됩니다.

## 준비물
- PC에 **Claude Code** + **Cursor** 설치
- 인터넷 연결 (그게 전부)

## 사용법 — Cursor 터미널에서 `claude` 실행 후, 본인 OS 프롬프트 한 줄 붙여넣기

### 🪟 윈도우
```
새 PC 팀 환경을 세팅해줘. 먼저 이 한 줄을 실행해서 GitHub에서 받아 설치해줘: powershell -NoProfile -ExecutionPolicy Bypass -Command "$z=\"$env:TEMP\mwtr.zip\"; Invoke-WebRequest 'https://github.com/jung260618/mac-win-tailscale-remote/archive/refs/heads/main.zip' -OutFile $z; Expand-Archive $z \"$env:TEMP\mwtr\" -Force; & \"$env:TEMP\mwtr\mac-win-tailscale-remote-main\install.ps1\"" ; 끝나면 %USERPROFILE%\.claude\skills\team-pc-setup-26-06-24\SKILL.md 를 읽고 그 절차대로 탐색기 보기 설정과 (윈도우+맥이면) 원격연결까지 단계별로 도와줘.
```

### 🍎 맥
```
새 PC 팀 환경을 세팅해줘. 먼저 이 한 줄을 실행해서 GitHub에서 받아 설치해줘: curl -fsSL https://github.com/jung260618/mac-win-tailscale-remote/archive/refs/heads/main.tar.gz | tar -xz -C /tmp && bash /tmp/mac-win-tailscale-remote-main/install.sh ; 끝나면 ~/.claude/skills/team-pc-setup-26-06-24/SKILL.md 를 읽고 그 절차대로 파인더 보기 설정까지 단계별로 도와줘.
```

> Claude 없이 터미널에서 직접 돌려도 됩니다 — 위 프롬프트의 `:` 와 `;` 사이 명령만 그대로 붙여넣으면 설치까지 진행됩니다. 파일관리자 보기 설정만 이후 Claude에게 부탁하세요.

## 설치되는 것
- 팀 코딩 규칙 `rules/` + 팀 공용 `CLAUDE.md` (기존 CLAUDE.md 있으면 덮지 않고 `CLAUDE.team.md`로 보존)
- 터미널 세션 메뉴 (빈 `claude` 입력 시 최근 작업 목록) + statusline
- 승인/완료 OS 토스트 알림
- 탐색기·파인더 보기/정렬 고정 (Claude가 보기를 같이 정해 적용)
- (선택) **본인 PC↔본인 맥 원격연결** — 아래 참고

## (선택) 본인 Windows PC ↔ 본인 Mac 원격연결 (Tailscale)
윈도우+맥 둘 다 쓰면 설치 끝에 Claude가 "원격연결도 할까요?" 묻습니다. 하면:
- `ssh mac` → 본인 맥에 터미널로 바로 접속
- `M:` 드라이브 → 본인 맥 파일을 윈도우에서 봄 (+ 역방향: PC 폴더를 맥에서)

전제: 본인 **맥 + 윈도우가 같은 Tailscale 계정**에 로그인. 순서:
1. **맥에서**: `setup-mac-server.zsh` 실행 → 화면에 뜬 `MacUser` / `MacIp` 확인
2. **윈도우에서**: `bootstrap-cockpit-to-mac.ps1 -MacIp <맥IP> -MacUser <맥사용자>`

(IP·계정은 전부 팀원 본인 값 — 하드코딩 없음)

## 폴더 구성
```
install.sh / install.ps1     부트스트랩이 받아 실행하는 설치기
CLAUDE.team.md               개인내용 없는 팀 표준 CLAUDE.md
rules/                       팀 코딩 규칙
skills/                      team-pc-setup · claude-term-ux · claude-notify-team
                             · file-manager-view · remote-link-team
```

## 안 될 때
- 다운로드 실패 → 인터넷/방화벽 확인 (회사망이 github.com codeload 를 막는지)
- 윈도우 알림 세팅 경고 → PowerShell 7(pwsh) 설치 후 재실행 권장 (없어도 나머지는 설치됨)
- 그 외 → 그냥 Claude에게 "안 돼"라고 하면 진단/수정해 줍니다
