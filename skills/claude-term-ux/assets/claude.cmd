@echo off
rem claude wrapper: no args -> recent-session menu, with args -> real claude.
rem Portable: uses %USERPROFILE% so it works under any Windows username.
if not "%~1"=="" goto passthrough
where pwsh >nul 2>nul
if %errorlevel%==0 (
  pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\bin\claude-menu.ps1"
) else (
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\bin\claude-menu.ps1"
)
goto :eof
:passthrough
rem Auto-detect real claude: native -> npm -> first claude on PATH excluding our wrapper.
rem ASCII-only on purpose: cmd.exe mis-parses UTF-8 comment bytes under DBCS codepages.
if exist "%USERPROFILE%\.local\bin\claude.exe" (
  "%USERPROFILE%\.local\bin\claude.exe" %*
  goto :eof
)
if exist "%APPDATA%\npm\claude.cmd" (
  call "%APPDATA%\npm\claude.cmd" %*
  goto :eof
)
for /f "delims=" %%i in ('where claude 2^>nul ^| findstr /v /i /c:"\bin\claude.cmd"') do (
  call "%%i" %*
  goto :eof
)
echo [claude-term-ux] real claude not found on this machine. 1>&2
