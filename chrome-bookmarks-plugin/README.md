# Chrome Bookmarks - Noctalia Launcher Plugin

Search and open Chrome/Chromium bookmarks directly from the Noctalia launcher.

## Features

- 🔍 **Fast search** - Search by bookmark name, URL, or folder
- 🚀 **Quick access** - Open bookmarks in a new browser window
- 📁 **Folder support** - Shows folder path in results
- 🔄 **Auto-loads** - Bookmarks load when the launcher opens
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

### Basic Commands

| Command | Action |
|---------|--------|
| `>bm` | View recent bookmarks |
| `>bm search` | Search bookmarks containing "search" |
| `>bm github` | Find all GitHub bookmarks |

### Examples

```
>bm                    → Shows first 10 bookmarks
>bm youtube            → Finds all YouTube bookmarks
>bm github.com/codegod → Searches URLs too
>bm rust               → Finds bookmarks with "rust" in name/URL
```

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
# Open launcher to bookmarks
qs -c noctalia-shell ipc call plugin:chrome-bookmarks toggle

# Reload bookmarks from file
qs -c noctalia-shell ipc call plugin:chrome-bookmarks reload

# Open a URL directly
qs -c noctalia-shell ipc call plugin:chrome-bookmarks open "https://github.com"
```

## How It Works

1. Reads Chrome's `Bookmarks` JSON file
2. Recursively extracts all bookmarks from folders
3. Filters out JavaScript bookmarklets
4. Searches name, URL, and folder path
5. Opens selected bookmark with `browserCommand --new-window`

## Troubleshooting

### "Error loading bookmarks"

- Check the `bookmarksPath` in settings
- Make sure Chrome/Chromium is installed
- Verify the file exists: `ls ~/.config/google-chrome/Default/Bookmarks`

### Browser doesn't open

- Check `browserCommand` in settings
- Verify browser is in PATH: `which chromium`
- Try alternative: `google-chrome-stable`, `brave`, `firefox`

### Bookmarks not updating

- Bookmarks load when the launcher first opens
- Use IPC to reload: `qs -c noctalia-shell ipc call plugin:chrome-bookmarks reload`
- Or restart Noctalia

## File Structure

```
chrome-bookmarks/
├── manifest.json         # Plugin metadata
├── LauncherProvider.qml  # Main launcher integration
├── Main.qml              # IPC handler
└── README.md             # This file
```

## License

MIT
