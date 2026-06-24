#!/usr/bin/env bash
# claude-notify-team 맥 세팅. Claude Code 알림을 '차단형 대화상자 없이 알림센터 토스트'로.
# 팀 공용본: 로컬 osascript 토스트만(원격 ssh 전달 없음).
# 규칙: 멱등 · 비파괴(내용 같으면 안 덮어씀) · $HOME 만 · 끝에 요약 · 성공 시 exit 0.
set -euo pipefail
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"
HOOK="$HOOKS_DIR/notify.sh"
SRC="$SKILL_DIR/scripts/notify.sh"
mkdir -p "$HOOKS_DIR"

# 전제조건: osascript(맥 기본)·python3(JSON 머지). jq 는 notify.sh 런타임에서 폴백 있음(없어도 동작).
command -v osascript >/dev/null 2>&1 || { echo "❌ osascript 필요 (macOS 전용)"; exit 1; }
command -v python3   >/dev/null 2>&1 || { echo "❌ python3 필요"; exit 1; }
[ -f "$SRC" ] || { echo "❌ 정본 notify.sh 없음: $SRC"; exit 1; }

# --- 1) 알림 훅 배치 (내용 동일하면 안 건드림 → 비파괴) ---
if [ -f "$HOOK" ] && cmp -s "$SRC" "$HOOK"; then
  echo "ℹ️  notify.sh 이미 최신 (변경 없음): $HOOK"
else
  cp "$SRC" "$HOOK"; chmod +x "$HOOK"
  echo "✅ notify.sh 배치: $HOOK"
fi

# --- 2) settings.json 의 Stop/Notification 훅 배선 (멱등, 기존 훅 보존) ---
STOP_CMD="bash ~/.claude/hooks/notify.sh stop"
NOTIFY_CMD="bash ~/.claude/hooks/notify.sh notify"

python3 - "$SETTINGS" "$STOP_CMD" "$NOTIFY_CMD" <<'PY'
import json, os, sys
path, stop_cmd, notify_cmd = sys.argv[1], sys.argv[2], sys.argv[3]
cfg = json.load(open(path)) if os.path.exists(path) else {}
hooks = cfg.setdefault("hooks", {})

def ensure(evt, cmd):
    arr = hooks.setdefault(evt, [])
    for grp in arr:
        for h in grp.get("hooks", []):
            if h.get("command") == cmd:
                return False
    arr.append({"hooks": [{"type": "command", "command": cmd}]})
    return True

changed = ensure("Stop", stop_cmd) | ensure("Notification", notify_cmd)
if changed:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    json.dump(cfg, open(path, "w"), ensure_ascii=False, indent=2)
    print("✅ settings.json 업데이트")
else:
    print("ℹ️  settings.json 이미 배선됨 (변경 없음)")
PY

# --- 3) 테스트 토스트 (로컬) ---
bash "$HOOK" stop
echo "✅ claude-notify-team 맥 세팅 완료 — 알림센터 토스트를 확인하세요."
exit 0
