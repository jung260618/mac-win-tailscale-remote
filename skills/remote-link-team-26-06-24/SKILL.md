---
name: remote-link-team-26-06-24
description: 팀원이 '본인 윈도우 PC ↔ 본인 맥'을 본인 Tailscale 계정으로 묶는 원격연결 세팅(개인정보 없음). 윈도우(조종석)에서 ssh mac + M: 드라이브로 본인 맥(작업서버)에 무비번 접속. IP·계정은 전부 팀원 본인 값(맥에서 자동 출력→윈도우에 입력). 특정 개인 IP·계정·이메일 하드코딩 없음. team-pc-setup 마스터의 옵션 단계로 호출하거나, 테일스케일·원격연결 얘기에 직접 사용 — "테일스케일", "tailscale", "테일스케일로 맥 윈도우 연결", "테일스케일 폴더공유", "테일스케일로 ssh mac", "팀원 테일스케일 세팅", "맥 윈도우 원격연결", "원격연결만", "ssh mac 다시" 같은 요청. (cross-platform: 맥 zsh + 윈도우 ps1, 가이드형·2대 필요)
---

> **[플랫폼]** 맥(작업서버) + 윈도우(조종석) — 팀원 **본인 두 기기**를 **본인 Tailscale**로 묶음. 개인정보 없음.

# remote-link-team — 팀원 본인 PC↔맥 원격연결

팀원이 자기 윈도우 PC에서 자기 맥에 `ssh mac` + `M:` 드라이브로 붙는 세팅. 남의 맥에 붙는 게 아니라 **각자 본인 맥**에 붙는다. 모든 값(IP·계정)은 팀원 본인 것이며, 하드코딩이 없다.

## 전제
1. 팀원의 **맥과 윈도우 PC가 같은 Tailscale 계정**에 로그인돼 있을 것(본인 계정).
2. 두 기기 다 켜져 있고 같은 tailnet.

## 2대로 나눠 진행 (순서 중요)

### A. 맥에서 (작업서버 켜기) — 먼저
```
zsh "$HOME/.claude/skills/remote-link-team-26-06-24/scripts/setup-mac-server.zsh"
```
- 원격 로그인(SSH 22) + 파일 공유(SMB 445) 켜고, `~/.ssh` 권한 보장.
- 끝에 **새 PC에 넘길 값**을 출력한다 → `MacUser`(맥 사용자), `MacIp`(맥 Tailscale IP). 이 두 값을 받아 적는다.
- (sudo 비번을 물을 수 있어 **실제 맥 터미널**에서 실행. Claude가 맥에서 돌고 있으면 출력값을 그대로 읽어 B로 넘긴다.)

### B. 윈도우에서 (조종석 세팅) — A의 값으로
**관리자 PowerShell**에서:
```
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\skills\remote-link-team-26-06-24\scripts\bootstrap-cockpit-to-mac.ps1" -MacIp <맥IP> -MacUser <맥사용자>
```
- `-MacIp`/`-MacUser` **필수**(A에서 받은 값). 비우면 PowerShell이 물어본다.
- 하는 일: SSH 키 생성 → `~/.ssh/config`의 `Host mac` 기록 → 맥에 공개키 등록(맥 비번 1회) → 무비번 검증 → 맥 홈을 `M:` 드라이브로 마운트(맥 비번 1회) → (역방향) 이 PC 폴더를 맥에서 보게 공유.
- 결과: `ssh mac` 으로 접속, `M:` 에서 맥 파일. `-NoReverse` 주면 역방향 생략.

### (참고) 맥↔맥인 경우
조종석도 맥이면 B 대신: `zsh scripts/bootstrap-cockpit-to-mac.zsh <맥IP> <맥USER> [별칭] [마운트포인트]` (이미 파라미터화됨).

## 상태 점검 (읽기전용)
- 윈도우: `powershell ... scripts\remote-status.ps1`
- 맥: `zsh scripts/remote-status.zsh`

## 검증 게이트 (마스터가 확인)
- 윈도우: `ssh -o BatchMode=yes mac hostname` 무비번 성공 **AND** `Test-Path M:\` 참.

## 안 될 때 (자주 나오는 함정)
- **맥 22 못 닿음**: 두 기기 같은 Tailscale 계정인지, A(setup-mac-server)를 돌렸는지.
- **마운트 실패**: 맥 SMB 비번(=맥 로그인 비번) 재확인. `cmdkey /delete:<맥IP>`로 캐시 자격증명 지우고 재시도.
- **키인증 안 됨(비번 계속 물음)**: 맥 `~/.ssh` 권한(700 / authorized_keys 600) — A가 보장하지만 재확인.
