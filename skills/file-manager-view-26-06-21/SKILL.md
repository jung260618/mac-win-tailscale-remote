---
name: file-manager-view-26-06-21
description: 파일 관리자 폴더 보기/정렬을 "모든 폴더에 항상 동일하게" 고정한다(크로스플랫폼 통합). 윈도우=탐색기(Explorer) 아이콘 크기+정렬 통일, 맥=Finder 생성일순 자동 유지. "폴더 보기 큰 아이콘으로 고정", "탐색기 보기 항상 큰 아이콘", "폴더마다 보기 바뀌는 거 고정", "정렬 기준 모든 폴더 적용", "파인더 정리", "파인더 정렬", "파인더 생성일순", "정렬 풀렸어", "정렬 적용 안 돼", "폴더 보기 자동 유지" 같은 요청에 트리거. 실행 전 반드시 무엇을 하는지 설명하고 사용자 확인을 받는다. (explorer-folder-view + finder-sort-cleanup 통합. cross-platform: setup.sh + setup.ps1)
---

> 전체 새 PC 세팅은 new-pc-setup 이 이 스킬을 3단계로 호출합니다. 보기 고정만 필요하면 여기서 직접.

> **[플랫폼]** 맥 ✅ (Finder 정렬) / 윈도우 ✅ (Explorer 보기)

# file-manager-view — 파일 관리자 보기/정렬 고정 (크로스플랫폼)

OS마다 파일 관리자는 폴더별로 보기/정렬을 따로 기억해서 "폴더마다 제멋대로" 바뀐다. 이 스킬은 양 OS에서 그걸 한 가지로 통일·고정한다. 윈도우는 `scripts/setup.ps1`, 맥은 `scripts/setup.sh`가 담당한다. **실행 전 반드시 무엇을 할지 설명하고 사용자 확인을 받는다.**

---

## 윈도우 (Explorer 폴더 보기 고정)

윈도우 탐색기는 폴더마다 보기(아이콘 크기·정렬)를 따로 기억하고, 폴더 내용으로 "종류(템플릿)"를 자동 판별해 보기를 바꾼다. 그래서 모든 폴더를 한 보기로 고정하려면 **폴더별 기억값 초기화 + 모든 폴더 종류 기본값 통일**이 둘 다 필요하다.

### 가장 중요한 교훈 (먼저 읽을 것)
**아이콘 크기 레지스트리 값을 추측하지 마라.** Windows 버전/머신마다 `Mode`·`LogicalViewMode` 매핑이 다르다(한 머신에선 "큰 아이콘"=`IconSize=96, Mode=1, LogicalViewMode=3`, LVM=1로 넣으면 안 먹음). **반드시 사용자가 직접 설정한 폴더의 Bag 값을 캡처해 복제**한다. 그래야 정렬(이름/내림차순 등)까지 통째로 따라간다.

참고 값(머신별 상이): 큰=`IconSize=96`, 작은=16, 보통=48, 아주큰=256. `Sort` 바이너리 끝 `0A 00 00 00`=이름, `FF FF FF FF`=내림차순 / `01 00 00 00`=오름차순.

레지스트리 2곳 모두 처리: `HKCU\...\Shell\Bags`(+`\BagMRU`), `HKCU\...\Classes\Local Settings\...\Shell\Bags`(+`\BagMRU`, 실제 보기는 주로 여기). 기본값은 `...\Bags\AllFolders\Shell\{폴더종류GUID}`. 폴더종류 GUID 6개(일반·문서·사진·음악·비디오·다운로드)는 setup.ps1에 포함.

### 절차 (이대로, 확인받고 진행)
1. **백업**: `powershell -ep bypass -f "$env:USERPROFILE\.claude\skills\file-manager-view-26-06-21\scripts\setup.ps1" -Backup`
2. **사용자가 "원하는 보기"를 한 폴더에 직접 설정**(우클릭→보기→큰 아이콘 등 + 정렬). 빈 폴더면 안 보이니 하위폴더·파일 몇 개 넣어준다.
3. **그 Bag 찾기**: `... setup.ps1 -FindUserBag` → IconSize가 원하는 값(예 96)인 Key의 전체 PSPath 확인.
4. **전체 적용**: `... setup.ps1 -Apply -SourceKey '<3번 경로>'` → 모든 폴더종류 기본값 복제 + 폴더별 기억값 초기화 + 탐색기 재시작.
5. **검증**: 새/기존 폴더 몇 개 열어 지정 보기로 나오는지 **사용자 눈 확인**(레지스트리 자동검증 불가). 안 되는 종류 있으면 그 폴더 설정 후 3·4 반복.
6. **정리**: 확인 끝나면 Desktop의 `FolderView_Backup_*.reg`·테스트 폴더를 동의 후 삭제.

되돌리기: `FolderView_Backup_*.reg` 더블클릭(또는 `reg import`). 주의: `reg copy`는 `Sort/ColInfo` 바이너리까지 복사(정렬·열 그대로 따라감), 폴더별 Bag(숫자키)만 지우고 `AllFolders` 기본값은 보존, 작업 후 탐색기 재시작 필수.

---

## 맥 (Finder 정렬 "생성일순 자동 유지" 고정)

Finder는 위치마다 정렬을 따로 들고 있다(일반 폴더·바탕화면·내 컴퓨터·네트워크 볼륨·검색·휴지통·태그). 한 곳만 바꾸면 빠지는 곳이 생긴다. 번들 도구 `finder-sort-datecreated`가 plist 전체를 재귀로 훑어 `arrangeBy`/`sortColumn`을 전부 생성일로 통일한다. (도구가 없으면 setup.sh가 `assets/`의 번들본을 `~/.local/bin`에 자동 설치.)

### 절차 (반드시 이 순서)
1. **설명**: 정렬을 생성일순 자동 유지로 고정 / 모든 보기 위치에 빠짐없이 / 기존 `.DS_Store` 정렬 기억 초기화. ⚠️ `.DS_Store` 초기화는 그 폴더 **창 크기·아이콘 위치**도 기본값으로 리셋(정렬 자동화 비용).
2. **인터뷰(`AskUserQuestion`)** — 범위를 한국어 선택지로 묻는다:
   - 내 맥 전체만 (홈 `~` 아래, 네트워크 볼륨 제외)
   - 맥 전체 + 특정 네트워크 볼륨까지 (예: `/Volumes/<공유>` — 느리고 그 볼륨 배치도 리셋)
   - 전역 기본값만, 폴더 초기화 안 함 (앞으로 만드는 폴더만)
   사용자가 "실행해"라고 명확히 확인하기 전엔 실행 금지.
3. **실행**:
   - 내 맥 전체: `bash "$HOME/.claude/skills/file-manager-view-26-06-21/scripts/setup.sh" home`
   - 특정 폴더만: `bash ".../setup.sh" ~/Desktop/<폴더>`
   - (네트워크 볼륨 포함/전역 기본값만 등 세부 범위는 도구 직접 호출 `finder-sort-datecreated [경로]`로 처리)
4. **결과 보고**: 데몬 경유 `arrangeBy = dateCreated`가 박혔는지, 잔여 `dateAdded`/`name`/`kind` 없는지 검증해 한국어로 보고(전송 전 오타·맞춤법 검수).

주의: 네트워크 볼륨 `.DS_Store` 초기화는 느리고 외부 서버를 건드리므로 사용자가 명시할 때만. 옛 명령 `finder-sort-dateadded`는 이제 생성일순 별칭.

---

## 공유 / 자산
- 윈도우 로직: `scripts/setup.ps1` (파라미터 `-Backup`/`-FindUserBag`/`-Apply -SourceKey`/`-RestartExplorer`).
- 맥 로직: `scripts/setup.sh` (래퍼) + `assets/finder-sort-datecreated` (번들 도구, 자체완결).
- 전신: `explorer-folder-view-26-06-20`(윈도우) + `finder-sort-cleanup`(맥)을 통합. 그 두 스킬은 [통합됨] 표시 후 보관(단독 트리거 유지), 유지보수는 이 스킬에서.
