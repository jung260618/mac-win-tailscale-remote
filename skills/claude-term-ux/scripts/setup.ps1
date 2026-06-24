<#
  claude-term-ux 세팅 (멱등).
  - 폭 자동맞춤 statusline.js 배치 + settings.json 의 statusLine 등록
  - 인자 없이 'claude' 치면 최근 세션 메뉴 뜨는 래퍼(claude.cmd + claude-menu.ps1) 배치
  - User PATH 맨 앞에 %USERPROFILE%\bin 추가 (래퍼가 진짜 claude.exe 보다 먼저 잡히게)
  이미 돼 있으면 건너뛴다. 어떤 Windows 사용자명에서도 동작.
#>
$ErrorActionPreference = 'Stop'

$HomeDir   = $env:USERPROFILE
$Assets    = Join-Path $PSScriptRoot '..\assets' | Resolve-Path | Select-Object -ExpandProperty Path
$BinDir    = Join-Path $HomeDir 'bin'
$ClaudeDir = Join-Path $HomeDir '.claude'
$Settings  = Join-Path $ClaudeDir 'settings.json'

function Say($m, $c='Gray') { Write-Host "  $m" -ForegroundColor $c }

Write-Host ""
Write-Host "claude-term-ux 세팅 시작" -ForegroundColor Cyan
Write-Host ""

# 1) bin 폴더 + 래퍼 배치 ----------------------------------------------------
if (-not (Test-Path $BinDir)) { New-Item -ItemType Directory -Path $BinDir | Out-Null }
Copy-Item (Join-Path $Assets 'claude.cmd')      (Join-Path $BinDir 'claude.cmd')      -Force
Copy-Item (Join-Path $Assets 'claude-menu.ps1') (Join-Path $BinDir 'claude-menu.ps1') -Force
# 버전 마커 기록(asset VERSION 과 동기) → 첫 실행 때 불필요한 self-heal 재실행 방지
$verFile = Join-Path $Assets 'VERSION'
if (Test-Path $verFile) {
  $ver = (Get-Content $verFile -Raw).Trim()
  Set-Content -Path (Join-Path $BinDir 'claude-menu.version') -Value $ver -NoNewline -Encoding utf8
} else { $ver = '?' }
Say "세션 메뉴 래퍼 배치: $BinDir\claude.cmd, claude-menu.ps1 (VERSION $ver)" 'Green'

# 2) statusline.js 배치 -------------------------------------------------------
if (-not (Test-Path $ClaudeDir)) { New-Item -ItemType Directory -Path $ClaudeDir | Out-Null }
Copy-Item (Join-Path $Assets 'statusline.js') (Join-Path $ClaudeDir 'statusline.js') -Force
Say "폭 자동맞춤 statusline 배치: $ClaudeDir\statusline.js" 'Green'

# 3) User PATH 맨 앞에 bin 추가 (registry) ------------------------------------
$userPath = [Environment]::GetEnvironmentVariable('Path','User')
if (-not $userPath) { $userPath = '' }
$parts = $userPath.Split(';') | Where-Object { $_ -and ($_.TrimEnd('\') -ne $BinDir.TrimEnd('\')) }
$newPath = (@($BinDir) + $parts) -join ';'
if ($userPath -ne $newPath) {
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Say "User PATH 맨 앞에 $BinDir 추가 (새 세션부터 적용)" 'Yellow'
} else {
    Say "User PATH 이미 OK ($BinDir 선두)" 'DarkGray'
}
# 현재 세션에도 즉시 반영
if (($env:Path -split ';' | Select-Object -First 1).TrimEnd('\') -ne $BinDir.TrimEnd('\')) {
    $env:Path = "$BinDir;$env:Path"
}

# 4) settings.json 의 statusLine 등록 ----------------------------------------
$cmd = 'node "' + ($ClaudeDir -replace '\\','/') + '/statusline.js"'
if (Test-Path $Settings) {
    $json = Get-Content $Settings -Raw | ConvertFrom-Json
} else {
    $json = [pscustomobject]@{}
}
$sl = [pscustomobject]@{ type = 'command'; command = $cmd; padding = 0 }
if ($json.PSObject.Properties['statusLine']) { $json.statusLine = $sl }
else { $json | Add-Member -NotePropertyName statusLine -NotePropertyValue $sl }
($json | ConvertTo-Json -Depth 20) | Set-Content -Path $Settings -Encoding UTF8
Say "settings.json statusLine 등록: $cmd" 'Green'

Write-Host ""
Write-Host "완료." -ForegroundColor Cyan
Write-Host "  - statusline: 다음 렌더부터 폭에 맞춰 자동 줄바꿈됩니다." -ForegroundColor Gray
Write-Host "  - 세션 메뉴: 새 ssh/터미널 세션에서 인자 없이 'claude' 입력 시 동작." -ForegroundColor Gray
Write-Host "    (현재 세션엔 PATH가 stale일 수 있어 재접속 권장. 확인: where claude 첫 줄이 ...\bin\claude.cmd)" -ForegroundColor DarkGray
Write-Host ""
