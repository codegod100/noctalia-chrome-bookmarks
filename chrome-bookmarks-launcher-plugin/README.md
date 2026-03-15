# Chrome Bookmarks Launcher Plugin

Search and open Chrome/Chromium bookmarks directly from the Noctalia launcher.

This is the launcher half of the bookmarks integration. The detachable panel lives in the sibling [`chrome-bookmarks-plugin`](/home/nandi/code/widget/chrome-bookmarks-plugin) directory.

## Commands

- `>bm` shows initial bookmark results
- `>bm github` searches bookmark names, URLs, and folders

## IPC

```bash
qs -c noctalia-shell ipc call plugin:chrome-bookmarks-launcher toggle
```
