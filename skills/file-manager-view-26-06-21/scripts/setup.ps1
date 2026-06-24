<#
  setup.ps1  (file-manager-view — 윈도우: Explorer 폴더 보기 고정)
  install.ps1이 설치 후 인자 없이 자동 실행 → 사용법만 출력하고 exit 0 (변경 없음).
  탐색기 폴더 보기(아이콘 크기 + 정렬)를 "모든 폴더에 항상 동일하게" 고정한다.

  핵심 원리 (machine마다 값이 다를 수 있으므로 추측하지 말 것):
    - 사용자가 폴더 하나를 원하는 보기로 직접 설정 → 그 폴더의 Bag 값을 캡처
    - 그 값을 모든 폴더 종류(템플릿)의 기본값(AllFolders)으로 복제
    - 기존에 제각각 기억된 폴더별 Bag + BagMRU 초기화 → 전부 기본값을 따름

  레지스트리 위치 2곳 (둘 다 처리해야 함):
    HKCU\Software\Microsoft\Windows\Shell\Bags                                   (+ \BagMRU)
    HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags   (+ \BagMRU)  <- 실제 폴더 보기는 주로 여기

  사용법:
    1) -Backup            : 현재 Bags/BagMRU 백업 (Desktop)
    2) -FindUserBag       : 사용자가 방금 설정한(=다른 값) Bag을 찾아 후보 출력
    3) -Apply -SourceKey <레지스트리경로>  : 그 Bag을 전체 기본값으로 복제 + 기존 Bag 초기화 + 탐색기 재시작
#>

param(
  [switch]$Backup,
  [switch]$FindUserBag,
  [switch]$Apply,
  [string]$SourceKey,
  [switch]$RestartExplorer
)

$ErrorActionPreference = 'Stop'

# 표준 폴더 종류(템플릿) GUID — 모든 종류에 동일 보기를 박아 자동 템플릿 전환을 무력화
$FolderTypeGUIDs = @(
  "{5C4F28B5-F869-4E84-8E60-F11DB97C5CC7}",  # 일반 항목 (Generic/NotSpecified)
  "{7D49D726-3C21-4F05-99AA-FDC2C9474656}",  # 문서 (Documents)
  "{B3690E58-E961-423B-B687-386EBFD83239}",  # 사진 (Pictures)
  "{94D6DDCC-4A68-4175-A374-BD584A510B78}",  # 음악 (Music)
  "{5FA96407-7E77-483C-AC93-691D05850DE8}",  # 비디오 (Videos)
  "{885A186E-A440-4ADA-812B-DB871B942259}"   # 다운로드 (Downloads)
)

$BagRoots = @(
  "HKCU:\Software\Microsoft\Windows\Shell\Bags",
  "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags"
)
$MruRoots = @(
  "HKCU:\Software\Microsoft\Windows\Shell\BagMRU",
  "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU"
)

function Do-Backup {
  $desktop = [Environment]::GetFolderPath('Desktop')
  $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
  $i = 0
  foreach ($r in $BagRoots) {
    $i++
    $hive = $r -replace '^HKCU:\\','HKCU\'
    $out = Join-Path $desktop "FolderView_Backup_${stamp}_$i.reg"
    reg export $hive "$out" /y 2>&1 | Out-Null
    "  백업: $out"
  }
}

function Find-UserBag {
  # IconSize 값이 있는 모든 Bag 중, "기본값(Default)과 다른 = 사용자가 직접 만진" 후보를 출력
  $rows = @()
  foreach ($r in $BagRoots) {
    Get-ChildItem $r -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
      $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
      if ($null -ne $p.IconSize) {
        $rows += [PSCustomObject]@{
          Path = $_.PSPath
          Key  = ($_.Name -replace '.*\\Bags\\','')
          IconSize = $p.IconSize; Mode = $p.Mode; LVM = $p.LogicalViewMode
          HasSort = ($null -ne $p.Sort)
        }
      }
    }
  }
  $rows | Where-Object { $_.Key -notmatch 'AllFolders' } |
    Sort-Object IconSize -Descending |
    Format-Table Key, IconSize, Mode, LVM, HasSort -AutoSize
  ""
  "위 목록에서 원하는 보기(예: IconSize=96=큰아이콘)인 Key의 전체 경로를 -SourceKey 로 넘기세요."
  "전체 경로 확인:  (Get-Item '<PSPath>')"
}

function Apply-View {
  param([string]$Src)
  if (-not $Src) { throw "-SourceKey <레지스트리경로> 가 필요합니다 (-FindUserBag 로 찾으세요)" }
  $Src = $Src -replace '^Microsoft\.PowerShell\.Core\\Registry::','' -replace '^HKEY_CURRENT_USER','HKCU:'
  if (-not (Test-Path $Src)) { throw "SourceKey 가 존재하지 않습니다: $Src" }

  # reg.exe 용 경로로 변환
  $srcReg = ($Src -replace '^HKCU:\\','HKCU\')

  # 1) 모든 폴더 종류 기본값으로 복제 (두 위치 모두)
  $destRoots = @(
    "HKCU\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell",
    "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell"
  )
  foreach ($root in $destRoots) {
    foreach ($g in $FolderTypeGUIDs) {
      reg copy "$srcReg" "$root\$g" /f 2>&1 | Out-Null
    }
  }
  "  기본값 복제: $($destRoots.Count) 위치 x $($FolderTypeGUIDs.Count) 폴더종류"

  # 2) 기존 폴더별 Bag(숫자키) + BagMRU 초기화 (AllFolders 기본값은 보존)
  foreach ($r in $BagRoots) {
    Get-ChildItem $r -ErrorAction SilentlyContinue |
      Where-Object { $_.PSChildName -match '^\d+$' } |
      ForEach-Object { Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue }
  }
  foreach ($m in $MruRoots) { if (Test-Path $m) { Remove-Item $m -Recurse -Force -ErrorAction SilentlyContinue } }
  "  폴더별 기억값 초기화 완료"

  Restart-Explorer
}

function Restart-Explorer {
  Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 2
  Start-Process explorer
  "  탐색기 재시작 완료"
}

if ($Backup)        { "[백업]";        Do-Backup }
if ($FindUserBag)   { "[사용자 Bag 탐색]"; Find-UserBag }
if ($Apply)         { "[적용]";        Apply-View -Src $SourceKey }
if ($RestartExplorer -and -not $Apply) { Restart-Explorer }
if (-not ($Backup -or $FindUserBag -or $Apply -or $RestartExplorer)) {
  # 인자 없이 실행(=install 자동실행): 변경하지 않고 사용법만 출력 후 정상 종료
  "file-manager-view (윈도우): Explorer 폴더 보기 고정"
  "사용법: -Backup | -FindUserBag | -Apply -SourceKey <경로> | -RestartExplorer"
  "전체 절차는 SKILL.md(## 윈도우) 참조. 추측 금지 — 사용자가 만든 보기를 캡처해 적용."
  exit 0
}
