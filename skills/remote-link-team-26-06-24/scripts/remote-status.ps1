<#
  remote-status.ps1 — "지금 이 윈도우 PC가 누구한테 서버이고, 누구의 조종석인가"를 한눈에.
  읽기 전용. 아무것도 바꾸지 않는다.  사용: powershell -ep bypass -f remote-status.ps1
#>
function B($m){ Write-Host $m -ForegroundColor Cyan }
function Ok($m){ Write-Host "  $m" -ForegroundColor Green }
function Dim($m){ Write-Host "  $m" -ForegroundColor DarkGray }
$ErrorActionPreference = "SilentlyContinue"

Write-Host "========== 원격 상태판 (remote-link) ==========" -ForegroundColor Cyan

# --- 이 기계 ---
$ts = Join-Path $env:ProgramFiles "Tailscale\tailscale.exe"
$ip = if (Test-Path $ts) { & $ts ip -4 2>$null | Select-Object -First 1 } else { (tailscale ip -4 2>$null | Select-Object -First 1) }
B "[이 기계]"
Write-Host "  OS: Windows  /  이름: $env:COMPUTERNAME  /  사용자: $env:USERNAME"
Write-Host "  Tailscale IP: $(if($ip){$ip}else{'(미로그인)'})"

# --- 서버 역할 (남이 나한테 들어옴) ---
function Listening($p){ (Get-NetTCPConnection -State Listen -LocalPort $p -EA SilentlyContinue) -ne $null }
B "[서버 역할 — 남이 이 PC에 들어올 수 있나]"
if (Listening 22) {
  Ok "OpenSSH 서버(22) ON  → 이 PC는 '서버'로 동작 중"
  $ak = "$env:USERPROFILE\.ssh\authorized_keys"
  $adminak = "$env:ProgramData\ssh\administrators_authorized_keys"
  foreach($f in @($ak,$adminak)){
    if(Test-Path $f){
      Write-Host "  $(Split-Path $f -Leaf) 의 키:"
      Get-Content $f | Where-Object {$_ -match 'ssh-'} | ForEach-Object { "    - " + ($_ -split '\s+')[-1] } | Write-Host
    }
  }
} else { Dim "OpenSSH 서버(22) OFF — 이 PC는 지금 '서버'가 아님" }
$share = Get-SmbShare | Where-Object { $_.Name -notmatch '\$$' }
if($share){ Ok "SMB 공유 중인 폴더:"; $share | ForEach-Object { "    \\$env:COMPUTERNAME\$($_.Name)  ($($_.Path))" } | Write-Host }
else { Dim "공유 중인 폴더 없음(관리공유 제외)" }

# --- 조종석 역할 (내가 남한테 나감) ---
B "[조종석 역할 — 이 PC가 누구를 부리나]"
$cfg = "$env:USERPROFILE\.ssh\config"
if(Test-Path $cfg){
  $host_ = $null
  Get-Content $cfg | ForEach-Object {
    if($_ -match '^\s*Host\s+(\S+)'){ $host_ = $Matches[1] }
    elseif($_ -match '^\s*HostName\s+(\S+)' -and $host_){ Write-Host "    ssh $host_  ->  $($Matches[1])" }
  }
} else { Dim "~/.ssh/config 없음 — 부리는 상대 없음" }

# --- 마운트된 원격 드라이브 ---
B "[마운트된 네트워크 드라이브]"
$map = Get-SmbMapping
if($map){ $map | ForEach-Object { "    $($_.LocalPath)  ->  $($_.RemotePath)  [$($_.Status)]" } | Write-Host }
else { Dim "네트워크 드라이브 없음" }

# --- Tailscale 피어 ---
B "[같은 테일넷 기기들]"
if(Test-Path $ts){ & $ts status 2>$null | ForEach-Object { "    $_" } | Write-Host } else { Dim "tailscale status 불가" }

# --- 결론 ---
Write-Host "---------- 한 줄 결론 ----------" -ForegroundColor Cyan
$role = @()
if(Listening 22){ $role += "서버" }
if((Test-Path $cfg) -and (Select-String -Path $cfg -Pattern '^\s*Host\s' -Quiet)){ $role += "조종석" }
$roleStr = if($role){ $role -join " + " } else { "아직 원격 미설정" }
Write-Host "  이 PC의 현재 역할: $roleStr" -ForegroundColor Green
Write-Host "  (남이 나한테 들어오면 '서버', 내가 ssh로 나가면 '조종석'. 둘 다일 수 있음)"
