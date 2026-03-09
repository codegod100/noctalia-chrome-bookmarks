# Quick Notes - Noctalia Launcher Plugin

A simple plugin to quickly save and search short notes from the Noctalia launcher.

## Installation

### Method 1: Manual Installation

1. Copy this folder to your Noctalia plugins directory:
   ```bash
   cp -r quick-notes-plugin ~/.config/noctalia/plugins/quick-notes
   ```

2. Register the plugin in `~/.config/noctalia/plugins.json`:
   ```json
   {
     "quick-notes": {
       "enabled": true
     }
   }
   ```

3. Restart Noctalia:
   ```bash
   noctalia-shell -r
   ```

4. Enable the plugin in Settings > Plugins

### Method 2: Symlink (for development)

```bash
# From this directory
ln -s $(pwd) ~/.config/noctalia/plugins/quick-notes
```

Then follow steps 2-4 above.

## Usage

### Open the Launcher
Press `Super+D` (or your configured launcher shortcut)

### Basic Commands

| Command | Action |
|---------|--------|
| `>note` | View recent notes |
| `>note your text` | Search for notes or create new one |
| `>note + your text` | Explicitly add a new note |

### Examples

```
>note                    → Shows recent notes
>note buy                → Searches "buy" or creates "buy" note
>note + Buy groceries    → Creates new note "Buy groceries"
>note Buy milk           → Creates new note (if no match) or shows matches
```

### What Happens When You Select a Note?
- The note text is copied to your clipboard
- The launcher closes

## Keyboard Shortcut

Add a keyboard shortcut to open directly to Quick Notes:

### Niri
```
bind = Super, N, exec, noctalia-shell ipc call plugin:quick-notes toggle
```

### Sway/i3
```
bindsym $mod+n exec noctalia-shell ipc call plugin:quick-notes toggle
```

### Hyprland
```
bind = SUPER, N, exec, noctalia-shell ipc call plugin:quick-notes toggle
```

## Development

### Enable Hot Reload
1. Open Noctalia Settings
2. Go to About tab
3. Click the Noctalia logo 8 times to enable debug mode
4. Your QML changes will auto-reload

### View Logs
Run Noctalia from terminal to see logs:
```bash
noctalia-shell
```

### File Structure
```
quick-notes/
├── manifest.json         # Plugin metadata
├── LauncherProvider.qml  # Main launcher integration
├── Main.qml              # IPC handler
└── README.md             # This file
```

## Settings

Settings are stored in `~/.config/noctalia/plugins/quick-notes/settings.json`:

```json
{
  "maxNotes": 50,
  "notes": [
    {
      "text": "Example note",
      "created": "2024-01-15T10:30:00.000Z"
    }
  ]
}
```

## Limitations

- Notes are stored in plain text
- Maximum notes limited to 50 by default (configurable)
- No categories or tags (yet)
- No sync between machines

## License

MIT
