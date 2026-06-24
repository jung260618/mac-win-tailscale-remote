#!/usr/bin/env bash
# bootstrap.sh — 한 줄 설치용. GitHub에서 번들을 받아 install.sh 를 실행한다.
#   사용: curl -fsSL https://raw.githubusercontent.com/jung260618/mac-win-tailscale-remote/main/bootstrap.sh | bash
set -euo pipefail
URL="https://github.com/jung260618/mac-win-tailscale-remote/archive/refs/heads/main.tar.gz"
TMP="$(mktemp -d)"
echo "[bootstrap] 다운로드: $URL"
curl -fsSL "$URL" | tar -xz -C "$TMP"
bash "$TMP/mac-win-tailscale-remote-main/install.sh"
