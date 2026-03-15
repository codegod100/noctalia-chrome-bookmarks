#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <extension-id>" >&2
  exit 1
fi

EXTENSION_ID="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_PATH="$SCRIPT_DIR/host.py"
MANIFEST_TEMPLATE="$SCRIPT_DIR/org.noctalia.thorium_tabs.json"
TARGET_DIR="${NATIVE_MESSAGING_HOST_DIR:-${HOME}/.config/chromium/NativeMessagingHosts}"
TARGET_PATH="${TARGET_DIR}/org.noctalia.thorium_tabs.json"

mkdir -p "$TARGET_DIR"
sed \
  -e "s|__HOST_PATH__|${HOST_PATH}|g" \
  -e "s|__EXTENSION_ORIGIN__|chrome-extension://${EXTENSION_ID}/|g" \
  "$MANIFEST_TEMPLATE" > "$TARGET_PATH"

chmod +x "$HOST_PATH"
echo "installed native host manifest to $TARGET_PATH"
