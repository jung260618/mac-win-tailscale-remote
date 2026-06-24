#!/bin/zsh
# bootstrap-cockpit-to-mac.zsh — 이 맥(조종석)에서 다른 맥(서버)으로 비번없는 ssh + 폴더 마운트.
# (윈도우 조종석 → 맥 서버는 mac-remote 의 .ps1 또는 references/windows-to-mac-ssh-smb.md 참조)
# 사용: zsh bootstrap-cockpit-to-mac.zsh <서버맥IP> <서버맥USER> [별칭=macsrv] [마운트포인트=~/mnt/<별칭>]
# 멱등: 키/config/마운트 있으면 재사용. 서버맥은 먼저 setup-mac-server.zsh 로 켜져 있어야 함.
set -u
SRV_IP="${1:?서버 맥 Tailscale IP를 줘라}"
SRV_USER="${2:?서버 맥 사용자명을 줘라}"
ALIAS="${3:-macsrv}"
MNT="${4:-$HOME/mnt/$ALIAS}"
KEY="$HOME/.ssh/id_ed25519_$ALIAS"
ok(){ print -P "%F{green}OK  $1%f"; }; warn(){ print -P "%F{yellow}!!  $1%f"; }; step(){ print -P "%F{cyan}== $1 ==%f"; }

mkdir -p ~/.ssh; chmod 700 ~/.ssh

step "서버 맥 도달 확인 ($SRV_IP port 22)"
nc -z -G 3 "$SRV_IP" 22 2>/dev/null && ok "도달 가능" || { warn "22 못 닿음 — Tailscale/서버 setup 확인"; exit 1; }

step "SSH 키"
[[ -f "$KEY" ]] && ok "기존 키 재사용" || { ssh-keygen -t ed25519 -f "$KEY" -N "" -C "$(scutil --get LocalHostName)-to-$ALIAS" >/dev/null; ok "키 생성"; }

step "ssh config ($ALIAS)"
cfg=~/.ssh/config; touch "$cfg"
[[ -s "$cfg" ]] && cp "$cfg" "$cfg.bak.$(date +%s)" && ok "config 백업: $cfg.bak.*"
# 기존 Host <ALIAS> 블록 제거 후 재작성 (멱등)
awk -v a="$ALIAS" 'BEGIN{skip=0} /^[[:space:]]*Host /{skip=($2==a)} skip==0{print}' "$cfg" > "$cfg.tmp" 2>/dev/null || cp "$cfg" "$cfg.tmp"
{ cat "$cfg.tmp"; print -- "Host $ALIAS"; print -- "    HostName $SRV_IP"; print -- "    User $SRV_USER"; print -- "    IdentityFile $KEY"; print -- "    IdentitiesOnly yes"; print -- "    StrictHostKeyChecking accept-new"; print -- "    ServerAliveInterval 30"; print -- "    ServerAliveCountMax 3"; } > "$cfg"
rm -f "$cfg.tmp"; chmod 600 "$cfg"; ok "Host $ALIAS 기록 (ssh $ALIAS 로 접속)"

step "서버 맥에 공개키 등록 (서버 맥 비번 1회)"
pub="$(<"$KEY.pub")"
ssh -o StrictHostKeyChecking=accept-new "$SRV_USER@$SRV_IP" \
  "umask 077; mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; grep -qxF '$pub' ~/.ssh/authorized_keys || printf '%s\n' '$pub' >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys; echo REGISTERED" \
  | grep -q REGISTERED && ok "공개키 등록" || warn "등록 확인 안 됨"

step "무비번 검증"
h=$(ssh -o BatchMode=yes "$ALIAS" "hostname" 2>/dev/null) && ok "ssh $ALIAS OK -> $h" || warn "아직 비번 물음 — 키/권한 확인"

step "서버 맥 홈폴더 마운트 ($MNT)"
mkdir -p "$MNT"
if mount | grep -q " $MNT "; then ok "이미 마운트됨"
else
  print "  서버 맥 비번 입력(파일공유용, SMB가 켜져 있어야 함):"
  mount_smbfs "//$SRV_USER@$SRV_IP/$SRV_USER" "$MNT" 2>/dev/null && ok "마운트됨: $MNT (맥 홈 폴더)" || warn "마운트 실패 — 서버 맥 파일공유(SMB) 켜졌는지 / SMB-NT 해시 확인(references 함정 6)"
fi

step "완료"
echo "  접속: ssh $ALIAS   /   파일: $MNT"
