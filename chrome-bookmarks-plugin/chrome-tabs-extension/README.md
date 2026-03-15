# Thorium Tabs Reader

Minimal Manifest V3 extension that reads open tab info through the browser `tabs` API.

## Load

1. Open `chrome://extensions` or `thorium://extensions`.
2. Enable Developer Mode.
3. Click `Load unpacked`.
4. Select this folder.

## What It Does

- Uses the `tabs` permission
- Reads all open tabs in the background service worker
- Shows tab title, URL, window ID, and state in the popup
- Publishes tab snapshots to a native host for local consumers

## Native Host

This repo includes a native messaging host in `native-host/` that writes tab snapshots to `/tmp/thorium-tabs.json`.

Install the host manifest after loading the extension:

```bash
./native-host/install.sh <extension-id>
```

The extension ID is shown on the extensions page after loading the unpacked extension.
If Thorium uses a different native messaging directory on your system, override it with `NATIVE_MESSAGING_HOST_DIR=/path/to/NativeMessagingHosts`.

## Files

- `manifest.json`: extension manifest
- `background.js`: tab query handler
- `popup.html`: popup UI
- `popup.js`: popup data loading
- `popup.css`: popup styling
- `native-host/host.py`: native messaging host
- `native-host/install.sh`: installs the host manifest
