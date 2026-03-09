# Creating a Noctalia Launcher Plugin

## Overview

Noctalia is a desktop shell that supports plugins written in QML. Launcher providers are plugins that extend the Noctalia app launcher with custom search sources, command handlers, and browsable content.

## What Launcher Providers Can Do

- Add custom search sources (emoji, kaomoji, code snippets, etc.)
- Create command handlers (e.g., `>emoji`, `>todo`)
- Implement category-based browsing
- Support auto-paste functionality
- Integrate with keyboard shortcuts via IPC

## Getting Started

### Prerequisites

1. Noctalia Shell installed and running
2. Basic knowledge of QML (Qt Quick)
3. Text editor of your choice

### Step 1: Set Up Plugin Directory

Plugins are stored in `~/.config/noctalia/plugins/`. Create a directory for your plugin:

```bash
mkdir -p ~/.config/noctalia/plugins/my-launcher-plugin
cd ~/.config/noctalia/plugins/my-launcher-plugin
```

### Step 2: Create the Manifest

Create a `manifest.json` file:

```json
{
  "id": "my-launcher-plugin",
  "name": "My Launcher Plugin",
  "version": "1.0.0",
  "author": "Your Name",
  "description": "A custom launcher provider",
  "minNoctaliaVersion": "3.9.0",
  "entryPoints": {
    "launcherProvider": "LauncherProvider.qml"
  },
  "metadata": {
    "commandPrefix": "mycommand"
  }
}
```

### Step 3: Create the Launcher Provider

Create `LauncherProvider.qml`:

```qml
import QtQuick
import qs.Commons

Item {
    id: root
    
    // Required properties
    property var pluginApi: null
    property var launcher: null
    property string name: "My Provider"
    
    // Optional properties
    property bool handleSearch: false
    property string supportedLayouts: "list"
    property bool supportsAutoPaste: true
    
    // Initialize the provider
    function init() {
        Logger.i("MyProvider", "Initialized")
    }
    
    // Called when launcher opens
    function onOpened() {
        Logger.i("MyProvider", "Launcher opened")
    }
    
    // Check if this provider handles the command
    function handleCommand(searchText) {
        return searchText.startsWith(">mycommand")
    }
    
    // Return available commands when user types ">"
    function commands() {
        return [{
            "name": ">mycommand",
            "description": "Search my custom content",
            "icon": "search",
            "isTablerIcon": true,
            "onActivate": function() {
                launcher.setSearchText(">mycommand ")
            }
        }]
    }
    
    // Get search results
    function getResults(searchText) {
        if (!searchText.startsWith(">mycommand")) {
            return []
        }
        
        var query = searchText.slice(10).trim() // Remove ">mycommand "
        
        // Return results based on query
        return [{
            "name": "Result 1",
            "description": "A sample result",
            "icon": "star",
            "isTablerIcon": true,
            "onActivate": function() {
                // Do something when activated
                Logger.i("MyProvider", "Result activated")
                launcher.close()
            }
        }]
    }
}
```

### Step 4: Register Your Plugin

Add your plugin to `~/.config/noctalia/plugins.json`:

```json
{
  "my-launcher-plugin": {
    "enabled": true
  }
}
```

### Step 5: Restart Noctalia

```bash
# Logout and login again, or restart from terminal
noctalia-shell -r
```

### Step 6: Enable the Plugin

1. Open Noctalia Settings (Super+comma)
2. Navigate to the **Plugins** tab
3. Find your plugin and click **Enable**

## Advanced Features

### Category-Based Browsing

Add categories to your provider:

```qml
property bool showsCategories: true
property string selectedCategory: "all"
property var categories: ["all", "recent", "favorites"]
property var categoryIcons: {
    "all": "list",
    "recent": "clock",
    "favorites": "star"
}

function getCategoryName(category) {
    const names = {
        "all": "All",
        "recent": "Recent",
        "favorites": "Favorites"
    }
    return names[category] || category
}

function selectCategory(category) {
    selectedCategory = category
    if (launcher) {
        launcher.updateResults()
    }
}
```

### Loading Data from Files

Use `FileView` to load data:

```qml
import Quickshell.Io

property var database: ({})

FileView {
    id: databaseLoader
    path: pluginApi.pluginDir + "/database.json"
    watchChanges: false
    
    onLoaded: {
        try {
            database = JSON.parse(text())
            if (launcher) {
                launcher.updateResults()
            }
        } catch (e) {
            Logger.e("MyProvider", "Failed to load database:", e)
        }
    }
}
```

### IPC Integration for Keyboard Shortcuts

Add an IPC handler in `Main.qml`:

```qml
import QtQuick
import Quickshell.Io

Item {
    property var pluginApi: null
    
    IpcHandler {
        target: "plugin:my-launcher-plugin"
        
        function toggle() {
            if (!pluginApi) return;
            pluginApi.withCurrentScreen(screen => {
                pluginApi.toggleLauncher(screen);
            });
        }
    }
}
```

Then bind it in your compositor config:

```bash
# For Niri
Mod+D { spawn "noctalia-shell" "ipc" "call" "plugin:my-launcher-plugin" "toggle"; }

# For i3/Sway
bindsym Mod4+d exec noctalia-shell ipc call plugin:my-launcher-plugin toggle
```

## Result Object Structure

Each result should have:

```javascript
{
    // Display
    "name": "Result Title",
    "description": "Subtitle text",
    
    // Icon options
    "icon": "star",
    "isTablerIcon": true,
    "displayString": "🎉",  // Alternative: text instead of icon
    "hideIcon": false,
    
    // Layout
    "singleLine": false,
    
    // Auto-paste
    "autoPasteText": "🎉",
    
    // Reference
    "provider": root,
    
    // Callbacks
    "onActivate": function() {
        launcher.close()
    },
    "onAutoPaste": function() {
        // Called before auto-pasting
    }
}
```

## Development Tips

### Hot Reload

Enable debug mode for hot reload during development:

1. Click the **Noctalia logo** in the About tab **8 times** quickly
2. Or launch with: `NOCTALIA_DEBUG=1 noctalia-shell`

### Debugging

View logs in terminal:

```bash
noctalia-shell
```

Use Logger in your plugin:

```qml
Logger.i("MyProvider", "Info message")
Logger.e("MyProvider", "Error message")
```

### Testing

Test your provider by:
1. Opening the launcher (usually Super+D)
2. Type `>` to see available commands
3. Type `>mycommand` to activate your provider
4. Search or browse your content

## Complete Example: Kaomoji Provider

Check the complete example at:
https://github.com/noctalia-dev/noctalia-plugins/tree/main/kaomoji-provider

## Resources

- **Official Documentation**: https://docs.noctalia.dev/development/plugins/launcher-provider/
- **Getting Started Guide**: https://docs.noctalia.dev/development/plugins/getting-started/
- **Example Plugins**: https://github.com/noctalia-dev/noctalia-plugins
- **Discord Community**: https://discord.noctalia.dev

## Best Practices

1. Use `>` prefix for commands to distinguish from regular search
2. Close the launcher with `launcher.close()` after an action
3. Set appropriate `supportedLayouts` ("list", "grid", or "both")
4. Implement `init()` for loading data
5. Use `onOpened()` to reset state when launcher opens
6. Support categories for better browsing experience
7. Add icons using Tabler icon set for consistency
8. Test with hot reload during development
9. Provide clear descriptions in the manifest
10. Follow the example plugins for structure and patterns

## Plugin Architecture Overview

```
your-plugin/
├── manifest.json           # Plugin metadata (required)
├── preview.png             # Preview image for plugin gallery (optional, recommended)
├── Main.qml                # Background logic with IPC handlers (optional)
├── BarWidget.qml           # Bar widget component (optional)
├── DesktopWidget.qml       # Desktop widget component (optional)
├── ControlCenterWidget.qml # Control center button (optional)
├── LauncherProvider.qml    # Launcher search provider (optional)
├── Panel.qml               # Panel overlay component (optional)
├── Settings.qml            # Settings UI component (optional)
├── i18n/                   # Translations (optional)
│   ├── en.json
│   └── es.json
├── README.md               # Plugin documentation
└── settings.json           # User saved settings (should not be committed to the repository)
```

## Plugin Lifecycle

1. **Installation**: Plugin is downloaded from a registry to `~/.config/noctalia/plugins/`
2. **Registration**: PluginRegistry scans the folder and validates the manifest
3. **Enabling**: User enables the plugin in settings
4. **Loading**: PluginService loads the plugin components and injects the Plugin API
5. **Running**: Plugin components receive `pluginApi` property with access to services
6. **Settings**: Users can configure the plugin through the integrated settings UI
7. **Unloading**: When disabled, the plugin is cleanly unloaded
8. **Uninstallation**: Plugin folder is removed from disk

## Plugin API

Every plugin component receives a `pluginApi` object that provides access to plugin functionality and Noctalia services.

### Core Properties

- **`pluginId`** - Unique plugin identifier
- **`pluginDir`** - Plugin directory path
- **`pluginSettings`** - User settings object (read/write)
- **`manifest`** - Plugin manifest data
- **`currentLanguage`** - Current UI language code
- **`mainInstance`** - Reference to the instantiated Main.qml component (null if not loaded)
- **`barWidget`** - Reference to the bar widget Component (null if not provided)

### Core Functions

- **`saveSettings()`** - Persist settings to disk
- **`openPanel(screen, buttonItem?)`** - Open the plugin's panel (optionally near buttonItem)
- **`closePanel(screen)`** - Close the plugin's panel
- **`togglePanel(screen, buttonItem?)`** - Toggle the plugin's panel open/closed (optionally near buttonItem)
- **`tr(key, interpolations)`** - Translate text
- **`trp(key, count, ...)`** - Translate with plurals
- **`hasTranslation(key)`** - Check if translation exists
- **`toggleLauncher(screen)`** - Toggle the launcher with your provider's command prefix

### Noctalia Services

Plugins have full access to Noctalia's service ecosystem:

**`qs.Commons`** - Core utilities
- `Settings` - Global Noctalia settings
- `I18n` - Internationalization
- `Logger` - Logging utilities
- `Style` - Design system constants
- `Color` - Theme-aware colors

**`qs.Services.UI`** - UI services
- `ToastService` - Toast notifications
- `PanelService` - Panel management
- `TooltipService` - Tooltip display

**`qs.Services.System`** - System services
- `AudioService` - Audio control
- `BatteryService` - Battery information
- `NetworkService` - Network status
- And many more…

**`qs.Widgets`** - UI components
- `NButton`, `NIcon`, `NText`, `NTextInput`
- `NScrollView`, `NColorPicker`, and more

## Common Issues and Solutions

### Plugin doesn't appear in settings

- Make sure your plugin is registered in `~/.config/noctalia/plugins.json` with `"enabled": true`
- Check that `manifest.json` is valid JSON
- Verify the plugin ID matches the directory name and the key in `plugins.json`
- Restart Noctalia

### Widget doesn't show in launcher

- Make sure you enabled the plugin in Settings > Plugins
- Check that your `handleCommand()` function returns `true` for your prefix
- Look for errors in the terminal output
- Verify `getResults()` returns valid result objects

### Settings don't persist

- Make sure you call `pluginApi.saveSettings()` after changing settings
- Check file permissions on `~/.config/noctalia/plugins/`

### IPC commands not working

- Verify the IPC handler target matches the expected format: `plugin:your-plugin-id`
- Check that `Main.qml` is properly set up as an entry point
- Test with: `noctalia-shell ipc call plugin:your-plugin-id toggle`

This should give you everything you need to create a Noctalia launcher plugin! Let me know if you need help with any specific aspect of the implementation.
