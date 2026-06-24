#!/bin/zsh
# remote-status.zsh — "지금 이 맥이 누구한테 서버이고, 누구의 조종석인가"를 한눈에.
# 읽기 전용. 아무것도 바꾸지 않는다.
set -u
b() { print -P "%F{cyan}$1%f"; }
ok() { print -P "  %F{green}$1%f"; }
dim() { print -P "  %F{244}$1%f"; }

print -P "%F{cyan}========== 원격 상태판 (remote-link) ==========%f"

# --- 이 기계 ---
ip=$(tailscale ip -4 2>/dev/null | head -1)
[[ -z "$ip" ]] && ip=$(/Applications/Tailscale.app/Contents/MacOS/Tailscale ip -4 2>/dev/null | head -1)
b "[이 기계]"
echo "  OS: macOS  /  이름: $(scutil --get LocalHostName 2>/dev/null)  /  사용자: $(whoami)"
echo "  Tailscale IP: ${ip:-(미로그인)}"

# --- 서버 역할 (남이 나한테 들어옴) ---
listen() { netstat -an 2>/dev/null | grep LISTEN | grep -q "\.$1 "; }
b "[서버 역할 — 남이 이 맥에 들어올 수 있나]"
if listen 22; then
  ok "원격로그인(SSH 22) ON  → 이 맥은 '서버'로 동작 중"
  if [[ -f ~/.ssh/authorized_keys ]]; then
    n=$(grep -c . ~/.ssh/authorized_keys 2>/dev/null)
    echo "  들어올 수 있는 키 ${n}개:"
    awk '{print "    - "$3}' ~/.ssh/authorized_keys 2>/dev/null
  fi
  if listen 445; then
    ok "파일공유(SMB 445) ON  → 폴더 공유 중"
    print -r -- "    공유 경로: \\\\${ip}\\${USER}  (맥 홈 폴더)"
  else
    dim "파일공유(445) OFF — 폴더공유는 꺼짐"
  fi
else
  dim "원격로그인(22) OFF — 이 맥은 지금 '서버'가 아님"
fi

# --- 조종석 역할 (내가 남한테 나감) ---
b "[조종석 역할 — 이 맥이 누구를 부리나]"
if [[ -f ~/.ssh/config ]]; then
  awk '
    /^[Hh]ost /{host=$2; next}
    /^[[:space:]]*[Hh]ost[Nn]ame/{print "    ssh "host"  ->  "$2}
  ' ~/.ssh/config
  [[ $(grep -cE '^[Hh]ost ' ~/.ssh/config) -eq 0 ]] && dim "ssh config에 Host 별칭 없음 — 부리는 상대 없음"
else
  dim "~/.ssh/config 없음 — 부리는 상대 없음"
fi

# --- 마운트된 원격 폴더 ---
b "[마운트된 원격 폴더]"
m=$(mount 2>/dev/null | grep -iE 'smbfs|@')
[[ -n "$m" ]] && echo "$m" | sed 's/^/    /' || dim "SMB 마운트 없음"
for x in ~/mnt/*/(N); do print -r -- "    (mnt) $x"; done

# --- Tailscale 피어 ---
b "[같은 테일넷 기기들]"
tailscale status 2>/dev/null | awk '{printf "    %-16s %-14s %s\n", $1, $2, $4}' || dim "tailscale status 불가"

# --- 결론 ---
print -P "%F{cyan}---------- 한 줄 결론 ----------%f"
role=""
listen 22 && role="서버"
if [[ -f ~/.ssh/config ]] && grep -qE '^[Hh]ost ' ~/.ssh/config; then
  [[ -n "$role" ]] && role="$role + 조종석" || role="조종석"
fi
[[ -z "$role" ]] && role="아직 원격 미설정"
print -P "  이 맥의 현재 역할: %F{green}${role}%f"
echo "  (헷갈리면: 남이 나한테 들어오면 '서버', 내가 ssh로 나가면 '조종석'. 둘 다일 수 있음)"
