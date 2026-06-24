# claude-notify 윈도우 세팅. Claude Code 알림을 '메시지박스 없이 네이티브 토스트(Cursor 표시)'로 세팅.
# 규칙: 멱등 · 전제조건 점검 · $env:USERPROFILE 만 · 끝에 요약 · 성공 시 exit 0. (pwsh 7 로 실행 가정)
[CmdletBinding()]
param(
  [string]$AppId = "Anysphere.Cursor"   # 토스트 헤더에 보일 등록된 앱 AUMID (기본: Cursor)
)
$ErrorActionPreference = "Stop"

$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$HooksDir  = Join-Path $ClaudeDir "hooks"
$Settings  = Join-Path $ClaudeDir "settings.json"
$HookPath  = Join-Path $HooksDir "peer-notify.ps1"
New-Item -ItemType Directory -Force -Path $HooksDir | Out-Null

# --- 1) 알림 훅 스크립트 작성 (UTF-8 BOM 필수: hook 은 WinPS 5.1 로 실행되어 한글 파싱에 BOM 필요) ---
# 단일따옴표 here-string → 내부 $Kind/$t/$b/$env 등은 리터럴 보존. __APPID__ 만 치환.
$hook = @'
# peer-notify.ps1 - Windows 토스트(네이티브 API). 메시지박스(msg.exe) 절대 안 띄움.
# 한글이 여기 들어있으므로 이 파일은 반드시 UTF-8 with BOM 으로 저장돼야 WinPS 5.1 이 안 깨짐.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File peer-notify.ps1 -Kind approve|done|test
param(
  [string]$Kind = "approve",
  [string]$Body = ""
)
$ErrorActionPreference = "SilentlyContinue"
switch ($Kind) {
  "done"    { $t = "작업 완료";     $b = "명령한 일을 끝냈어요" }
  "approve" { $t = "확인이 필요해요"; $b = "승인 대기 중" }
  "test"    { $t = "테스트";        $b = "새 PC 알림 작동" }
  default   { $t = "Claude Code";   $b = $Kind }
}
if ($Body) { $b = $Body }
# 토스트를 등록된 AUMID 이름·아이콘으로 표시. msg 메시지박스는 절대 사용 안 함.
$AppId = "__APPID__"
try {
  [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime]
  $tmpl = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
  $texts = $tmpl.GetElementsByTagName("text")
  [void]$texts.Item(0).AppendChild($tmpl.CreateTextNode($t))
  [void]$texts.Item(1).AppendChild($tmpl.CreateTextNode($b))
  $toast = [Windows.UI.Notifications.ToastNotification]::new($tmpl)
  [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId).Show($toast)
} catch {
  # 토스트 실패 시: 메시지박스(msg) 절대 띄우지 않음. 조용히 로그만.
  "$((Get-Date).ToString('s')) [toast-fail] $t - $b" |
    Out-File -Append -Encoding utf8 "$env:USERPROFILE\.claude\hooks\peer-notify-fallback.log"
}
exit 0
'@
$hook = $hook.Replace('__APPID__', $AppId)
[System.IO.File]::WriteAllText($HookPath, $hook, (New-Object System.Text.UTF8Encoding($true)))
Write-Host "✅ hook 작성: $HookPath (AppId=$AppId, UTF-8 BOM)" -ForegroundColor Green

# --- 2) settings.json 의 Stop/Notification 훅 배선 (멱등: 이미 있으면 안 건드림) ---
$doneCmd = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$HookPath`" -Kind done"
$apprCmd = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$HookPath`" -Kind approve"

$cfg = if (Test-Path $Settings) { Get-Content $Settings -Raw | ConvertFrom-Json -AsHashtable } else { @{} }
if (-not $cfg.ContainsKey('hooks') -or $null -eq $cfg['hooks']) { $cfg['hooks'] = @{} }
$hooks = $cfg['hooks']
$changed = $false

function Test-HasCmd($arr, $cmd) {
  foreach ($grp in @($arr)) {
    foreach ($h in @($grp.hooks)) { if ($h.command -eq $cmd) { return $true } }
  }
  return $false
}
function Add-Hook([string]$evt, [string]$cmd) {
  if (-not $hooks.ContainsKey($evt) -or $null -eq $hooks[$evt]) { $hooks[$evt] = @() }
  if (Test-HasCmd $hooks[$evt] $cmd) { return $false }
  $entry = @{ hooks = @( @{ type = 'command'; command = $cmd } ) }
  $hooks[$evt] = @($hooks[$evt]) + (, $entry)
  return $true
}

if (Add-Hook 'Stop'         $doneCmd) { $changed = $true; Write-Host "  + Stop(done) 배선" }
if (Add-Hook 'Notification' $apprCmd) { $changed = $true; Write-Host "  + Notification(approve) 배선" }

if ($changed) {
  $cfg | ConvertTo-Json -Depth 30 | Set-Content -Path $Settings -Encoding utf8
  Write-Host "✅ settings.json 업데이트" -ForegroundColor Green
} else {
  Write-Host "ℹ️  settings.json 이미 배선됨 (변경 없음)" -ForegroundColor DarkGray
}

# --- 3) 테스트 토스트 ---
& "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $HookPath -Kind test | Out-Null
Write-Host "✅ claude-notify 윈도우 세팅 완료 — 테스트 토스트를 확인하세요 ('$AppId' 로 표시)." -ForegroundColor Green
exit 0
