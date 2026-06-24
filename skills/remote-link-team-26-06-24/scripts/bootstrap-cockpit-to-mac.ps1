<#
  bootstrap-cockpit-to-mac.ps1 — 새 윈도우 PC를 "맥 조종석"으로 한 방에 세팅.
  맥(작업서버)으로: 비번없는 ssh(mac) + 맥폴더 M: 마운트 + (역방향) 이 PC 폴더를 맥에 마운트.
  키 등록 후엔 이 스크립트가 ssh mac 으로 맥까지 직접 조작하므로 맥 터미널로 돌아갈 일 없음.

  전제: 이 PC와 맥이 같은 Tailscale 계정에 로그인돼 있고, 맥에서 setup-mac-server.zsh 를 1회 돌렸음.
  사용(관리자 PowerShell):
    .\bootstrap-cockpit-to-mac.ps1                        # (MacIp/MacUser 필수: 맥에서 setup-mac-server.zsh 가 출력)
    .\bootstrap-cockpit-to-mac.ps1 -MacIp <IP> -MacUser <user>
    .\bootstrap-cockpit-to-mac.ps1 -NoReverse            # 역방향(PC->맥) 공유 생략
  멱등: 키/config/공유/방화벽/마운트 모두 있으면 재사용.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$MacIp,
  [Parameter(Mandatory)][string]$MacUser,
  [string]$DriveLetter  = "M",
  [string]$PcShareName  = "PCShare",
  [string]$PcSharePath  = "C:\PC공유",
  [switch]$NoReverse
)
$ErrorActionPreference = "Stop"
function Ok($m){ Write-Host "OK  $m" -ForegroundColor Green }
function Info($m){ Write-Host "  - $m" }
function Warn($m){ Write-Host "!!  $m" -ForegroundColor Yellow }
function Step($m){ Write-Host "`n== $m ==" -ForegroundColor Cyan }

$ssh    = "$env:USERPROFILE\.ssh"
$key    = "$ssh\id_ed25519_mac"
$cfg    = "$ssh\config"
if(!(Test-Path $ssh)){ New-Item -ItemType Directory -Path $ssh | Out-Null }

# 1) 맥 도달 확인 (Tailscale)
Step "맥 연결 확인 ($MacIp port 22)"
if(-not (Test-NetConnection -ComputerName $MacIp -Port 22 -WarningAction SilentlyContinue).TcpTestSucceeded){
  Warn "맥 22번에 못 닿음. Tailscale 로그인(같은 계정) 됐는지 / 맥에서 setup-mac-server.zsh 돌렸는지 확인."
  Warn "Tailscale: 트레이 로그인 또는 'tailscale up' (본인 Tailscale 계정)"
  return
}
Ok "맥 도달 가능"

# 2) SSH 키 생성 (없으면)
Step "SSH 키"
if(Test-Path $key){ Ok "기존 키 재사용 ($key)" }
else {
  ssh-keygen -t ed25519 -f $key -C "$env:COMPUTERNAME-to-mac" -N '""' | Out-Null
  # PowerShell의 -N '""' 는 빈 패스프레이즈가 아니라 글자 ""를 넣음 → BatchMode 키인증 깨짐. 벗겨낸다.
  ssh-keygen -p -f $key -P '""' -N '' | Out-Null
  Ok "키 생성됨(패스프레이즈 제거)"
}

# 3) ~/.ssh/config 의 Host mac 블록 (멱등: 기존 블록 제거 후 재작성)
Step "ssh config (Host mac)"
$block = @"
Host mac
    HostName $MacIp
    User $MacUser
    IdentityFile ~/.ssh/id_ed25519_mac
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    ServerAliveInterval 30
    ServerAliveCountMax 3
"@
$existing = ""
if(Test-Path $cfg){
  # "Host mac" 블록만 들어내고 나머지 보존
  $lines = Get-Content $cfg
  $keep = New-Object System.Collections.Generic.List[string]
  $skip = $false
  foreach($l in $lines){
    if($l -match '^\s*Host\s'){ $skip = ($l -match '^\s*Host\s+mac\s*$') }
    if(-not $skip){ $keep.Add($l) }
  }
  $existing = ($keep -join "`n").TrimEnd() + "`n"
}
Set-Content -Path $cfg -Value ($existing + $block) -Encoding ascii
Ok "Host mac 블록 기록 (ssh mac 별칭 활성)"

# 4) 공개키를 맥 authorized_keys 에 등록 (ssh-copy-id 대체, 맥 비번 1회)
Step "맥에 공개키 등록 (맥 비번 1회 입력)"
$pub = (Get-Content "$key.pub" -Raw).Trim()
$remote = "umask 077; mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; grep -qxF '$pub' ~/.ssh/authorized_keys || printf '%s\n' '$pub' >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys; echo REGISTERED"
$r = ssh -o StrictHostKeyChecking=accept-new "$MacUser@$MacIp" $remote
if($r -match "REGISTERED"){ Ok "공개키 등록 완료" } else { Warn "등록 응답 불명확: $r" }

# 5) 무비번 접속 검증
$sshOk = $false; $mountOk = $false
Step "ssh mac 무비번 검증"
$h = ssh -o BatchMode=yes mac "hostname" 2>$null
if($LASTEXITCODE -eq 0 -and $h){ $sshOk = $true; Ok "ssh mac OK -> $h" }
else { Warn "아직 비번 없이 안 됨. 'ssh -i $key $MacUser@$MacIp hostname' 로 키 단독 테스트해보라." }

# 6) 맥 폴더 -> 이 PC (M: 드라이브)  — 비파괴: 같은 드라이브가 '다른 대상'에 매핑돼 있으면 건드리지 않음
Step "맥 폴더 마운트 (${DriveLetter}: from \\$MacIp\$MacUser)"
$target = "\\$MacIp\$MacUser"
$existing = Get-SmbMapping -LocalPath "${DriveLetter}:" -ErrorAction SilentlyContinue
if($existing -and $existing.RemotePath -and ($existing.RemotePath -ne $target)){
  Warn "${DriveLetter}: 가 이미 다른 곳($($existing.RemotePath))에 매핑돼 있어 비파괴를 위해 건너뜀."
  Warn "다른 드라이브 문자를 쓰려면 -DriveLetter <문자> 로 다시 실행하세요."
} else {
  cmd /c "net use ${DriveLetter}: /delete /y" 2>$null | Out-Null   # 같은 대상의 절반 연결만 정리(다른 대상은 위에서 차단)
  cmdkey /delete:$MacIp 2>$null | Out-Null                         # 캐시된 잘못된 자격증명 제거(흔한 함정)
  Info "맥 SMB 비번(=맥 로그인 비번)을 물으면 입력. 'net use'가 기억함."
  net use "${DriveLetter}:" "$target" /user:$MacUser /persistent:yes
  if($LASTEXITCODE -eq 0){ $mountOk = $true; Ok "${DriveLetter}: 마운트됨 (맥 홈 폴더)" }
  else { Warn "마운트 실패 - 맥에서 파일 공유(시스템 설정>일반>공유>파일 공유)와 본인 계정 SMB가 켜졌는지 / 비번·사용자명($MacUser) 재확인" }
}

# 7) (역방향) 이 PC 폴더 -> 맥
if(-not $NoReverse){
  Step "역방향: 이 PC 폴더를 맥에서 보기"
  New-Item -ItemType Directory -Force -Path $PcSharePath | Out-Null
  if(-not (Get-SmbShare -Name $PcShareName -ErrorAction SilentlyContinue)){
    try { New-SmbShare -Name $PcShareName -Path $PcSharePath -FullAccess "$env:USERNAME" | Out-Null; Ok "SMB 공유 생성 ($PcShareName from $PcSharePath)" }
    catch { Warn "공유 생성 실패(관리자 권한 필요): $_" }
  } else { Ok "SMB 공유 이미 있음 ($PcShareName)" }

  if(-not (Get-NetFirewallRule -DisplayName "SMB from Tailscale" -ErrorAction SilentlyContinue)){
    try { New-NetFirewallRule -DisplayName "SMB from Tailscale" -Direction Inbound -Protocol TCP -LocalPort 445 -RemoteAddress 100.64.0.0/10 -Action Allow | Out-Null; Ok "방화벽 허용 규칙 추가(Tailscale 대역 445)" }
    catch { Warn "방화벽 규칙 실패(관리자 권한 필요): $_" }
  } else { Ok "방화벽 규칙 이미 있음" }

  $pcIp = (tailscale ip -4 2>$null | Select-Object -First 1)
  if($pcIp){
    Info "맥이 이 PC($pcIp)에 인증하려면 이 PC 계정($env:USERNAME)에 '비번'이 있어야 한다(PIN만이면 전용 표준계정 권장)."
    # 보안: 비번을 명령줄/URL(smb://user:pass@)에 넣지 않는다(프로세스목록 노출·특수문자 깨짐).
    # 맥에서 Finder로 한 번 연결해 키체인에 저장하는 방식으로 마운트한다.
    ssh -o BatchMode=yes mac "mkdir -p ~/mnt/$PcShareName" 2>$null | Out-Null
    Ok "PC 공유 준비 완료. 맥에서 아래로 마운트(비번은 키체인에 저장):"
    Write-Host "    Finder > 이동 > 서버에 연결(Cmd-K) > smb://$env:USERNAME@$pcIp/$PcShareName  (키체인에 저장 체크)"
    Write-Host "    또는 맥에서: open 'smb://$env:USERNAME@$pcIp/$PcShareName'"
  } else { Warn "이 PC Tailscale IP 확인 불가 - Tailscale 로그인 확인" }
}

Step "완료"
if($sshOk){
  Write-Host "조종석 사용법:" -ForegroundColor Green
  Write-Host "  - 맥 명령:   ssh mac        (들어가서 claude 실행 가능)"
  if($mountOk){ Write-Host "  - 맥 파일:   ${DriveLetter}: 드라이브 (맥 홈 폴더)" }
  else { Write-Host "  - 맥 파일:   (${DriveLetter}: 마운트 미완 — 위 마운트 경고 참고)" -ForegroundColor Yellow }
  if(-not $NoReverse){ Write-Host "  - PC 파일(맥에서):  ~/mnt/$PcShareName" }
} else {
  Warn "ssh mac 무비번 접속이 아직 안 됩니다. 위 경고(키 등록/맥 SSH)부터 해결한 뒤 다시 실행하세요."
}
