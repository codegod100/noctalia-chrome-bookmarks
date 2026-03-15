# Chrome Bookmarks - Noctalia Panel Plugin

Browse and open Chrome/Chromium bookmarks and tabs from a detachable Noctalia panel.

## Features

- 🔍 **Fast search** - Search bookmarks and open tabs
- 🚀 **Quick access** - Open bookmarks in a new browser window
- 📁 **Folder support** - Shows bookmark folders and active tabs side by side
- 🪟 **Panel UI** - Works as a detachable panel instead of launcher results
- ⚡ **Efficient** - Skips JavaScript bookmarklets, limits results

## Installation

### Method 1: Symlink (recommended for development)

```bash
ln -s /home/nandi/code/widget/chrome-bookmarks-plugin ~/.config/noctalia/plugins/chrome-bookmarks
```

### Method 2: Manual copy

```bash
cp -r chrome-bookmarks-plugin ~/.config/noctalia/plugins/chrome-bookmarks
```

### Register the plugin

Add to `~/.config/noctalia/plugins.json`:

```json
{
  "states": {
    "chrome-bookmarks": {
      "enabled": true
    }
  }
}
```

### Restart Noctalia

```bash
pkill -f "qs -c noctalia-shell" && qs -c noctalia-shell &
```

## Usage

### Keyboard Shortcut

Add to your compositor config:

**Niri** (`~/.config/niri/config.kdl`):
```kdl
Mod+B { spawn "qs" "-c" "noctalia-shell" "ipc" "call" "plugin:chrome-bookmarks" "toggle"; }
```

**Sway/i3**:
```
bindsym $mod+b exec qs -c noctalia-shell ipc call plugin:chrome-bookmarks toggle
```

**Hyprland**:
```
bind = SUPER, B, exec, qs -c noctalia-shell ipc call plugin:chrome-bookmarks toggle
```

## Configuration

Settings are stored in `~/.config/noctalia/plugins/chrome-bookmarks/settings.json`:

```json
{
  "bookmarksPath": "~/.config/google-chrome/Default/Bookmarks",
  "browserCommand": "chromium",
  "maxResults": 20
}
```

### Options

| Setting | Default | Description |
|---------|---------|-------------|
| `bookmarksPath` | `~/.config/google-chrome/Default/Bookmarks` | Path to Chrome bookmarks file |
| `browserCommand` | `chromium` | Browser command (chromium, google-chrome-stable, firefox, etc.) |
| `maxResults` | `20` | Maximum search results to show |

### For Chromium

```json
{
  "bookmarksPath": "~/.config/chromium/Default/Bookmarks",
  "browserCommand": "chromium"
}
```

### For Google Chrome

```json
{
  "bookmarksPath": "~/.config/google-chrome/Default/Bookmarks",
  "browserCommand": "google-chrome-stable"
}
```

### For Brave

```json
{
  "bookmarksPath": "~/.config/BraveSoftware/Brave-Browser/Default/Bookmarks",
  "browserCommand": "brave"
}
```

## IPC Commands

External commands you can use:

```bash
# Toggle the bookmarks panel
qs -c noctalia-shell ipc call plugin:chrome-bookmarks toggle

# Toggle the bookmarks panel explicitly
qs -c noctalia-shell ipc call plugin:chrome-bookmarks togglePanel
```

## How It Works

1. Reads Chrome's `Bookmarks` JSON file
2. Recursively extracts all bookmarks from folders
3. Queries Chrome DevTools for open tabs
4. Filters bookmarks and tabs in the panel
5. Opens or activates the selected entry

## Troubleshooting

### "Error loading bookmarks"

- Check the `bookmarksPath` in settings
- Make sure Chrome/Chromium is installed
- Verify the file exists: `ls ~/.config/google-chrome/Default/Bookmarks`

### Browser doesn't open

- Check `browserCommand` in settings
- Verify browser is in PATH: `which chromium`
- Try alternative: `google-chrome-stable`, `brave`, `firefox`

## File Structure

```
chrome-bookmarks/
├── manifest.json         # Plugin metadata
├── Panel.qml             # Main panel UI
├── Main.qml              # IPC handler
├── open-cdp.js           # CDP helper for opening windows
└── README.md             # This file
```

## License

MIT
