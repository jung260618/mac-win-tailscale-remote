# bootstrap.ps1 — 한 줄 설치용. GitHub에서 번들을 받아 install.ps1 을 실행한다.
#   사용: powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/jung260618/mac-win-tailscale-remote/main/bootstrap.ps1 | iex"
$ErrorActionPreference = "Stop"
$url = "https://github.com/jung260618/mac-win-tailscale-remote/archive/refs/heads/main.zip"
$tmp = Join-Path $env:TEMP ("mwtr_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$zip = Join-Path $tmp "bundle.zip"
Write-Host "[bootstrap] 다운로드: $url"
Invoke-WebRequest -Uri $url -OutFile $zip
Expand-Archive -Path $zip -DestinationPath $tmp -Force
& (Join-Path $tmp "mac-win-tailscale-remote-main\install.ps1")
