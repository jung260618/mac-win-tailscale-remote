#!/bin/zsh
# setup-mac-server.zsh — 맥을 "조종석에서 부릴 작업서버"로 켠다.
#   원격로그인(SSH 22) + 파일공유(SMB 445) 활성화 + ~/.ssh 권한 보장.
# 멱등: 이미 켜져 있으면 sudo 없이 통과. 실제 토글이 필요할 때만 sudo 비번을 묻는다.
# 사용: 맥 Terminal.app 에서  zsh setup-mac-server.zsh   (필요 시 비번 1회)
#   ! sudo 는 TTY가 없어 비번을 못 받으므로 반드시 실제 터미널에서 실행할 것.
set -u

ok()   { print -P "%F{green}OK  $1%f"; }
warn() { print -P "%F{yellow}!!  $1%f"; }
info() { print -P "  - $1"; }

is_listening() { netstat -an 2>/dev/null | grep LISTEN | grep -q "\.$1 "; }

print -P "%F{cyan}== 맥 작업서버 세팅 (remote-link-team) ==%f"

# 1) 원격 로그인 (SSH 서버, 22)
if is_listening 22; then
  ok "원격 로그인 이미 ON (22 LISTEN)"
else
  info "원격 로그인 켜는 중 (sudo 비번 입력)..."
  sudo systemsetup -setremotelogin on
  sleep 1
  is_listening 22 && ok "원격 로그인 ON" || warn "22 미확인 - 시스템설정>일반>공유>원격 로그인 수동 확인"
fi

# 2) 파일 공유 (SMB, 445)
if is_listening 445; then
  ok "파일 공유 이미 ON (445 LISTEN)"
else
  info "파일 공유(SMB) 켜는 중 (sudo 비번 입력)..."
  sudo launchctl enable system/com.apple.smbd 2>/dev/null
  sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null
  sleep 1
  if is_listening 445; then
    ok "파일 공유 ON"
  else
    warn "445 미확인 - 시스템설정>일반>공유>파일 공유 를 수동으로 켜라 (macOS 버전 따라 CLI가 막힐 수 있음)"
  fi
fi

# 3) ~/.ssh 권한 (sshd StrictModes - 느슨하면 키 거부)
umask 077
mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
ok "~/.ssh 권한 정상 (700 / authorized_keys 600)"

# 4) 방화벽 상태 (켜져 있으면 sshd/smbd 허용 필요할 수 있음)
fw=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null)
case "$fw" in
  *disabled*|*"State = 0"*) info "방화벽 꺼짐 - 포트 막힘 없음" ;;
  *) warn "방화벽 켜짐 - 막히면 ssh/smb 앱 허용 필요: $fw" ;;
esac

# 5) 접속 정보 출력 (새 PC 부트스트랩에 넘길 값)
myip=$(tailscale ip -4 2>/dev/null | head -1)
[[ -z "$myip" ]] && myip=$(/Applications/Tailscale.app/Contents/MacOS/Tailscale ip -4 2>/dev/null | head -1)
print -P "%F{cyan}-- 새 PC에 넘길 값 --%f"
echo "  맥 사용자(MacUser): $(whoami)"
echo "  맥 Tailscale IP(MacIp): ${myip:-(Tailscale 미로그인?)}"
print -r -- "  맥 공유 경로: \\\\${myip:-맥IP}\\$(whoami)  (맥 홈 폴더)"
print -P "%F{yellow}※ 445가 켜졌어도 윈도우 마운트가 실패하면: 시스템 설정>일반>공유>'파일 공유'를 켜고%f"
print -P "%F{yellow}   '$(whoami)' 의 홈 폴더가 공유 목록에 있는지, (옵션>SMB로 공유 + 사용자 체크) 를 확인하세요.%f"
print -P "%F{green}맥 준비 완료. 새 PC에서 bootstrap-cockpit-to-mac.ps1 -MacIp <위 IP> -MacUser <위 사용자> 를 돌리세요.%f"
