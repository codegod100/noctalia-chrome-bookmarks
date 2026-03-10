#!/bin/bash

# Big Clock Plugin Installer

PLUGIN_NAME="clock-plugin"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
NOCTALIA_PLUGINS="$HOME/.config/noctalia/plugins"
NOCTALIA_PLUGINS_JSON="$HOME/.config/noctalia/plugins.json"

echo "🚀 Installing Big Clock plugin for Noctalia..."

# Create plugins directory if it doesn't exist
mkdir -p "$NOCTALIA_PLUGINS"

# Remove existing installation if present
if [ -d "$NOCTALIA_PLUGINS/$PLUGIN_NAME" ]; then
    echo "📁 Removing existing installation..."
    rm -rf "$NOCTALIA_PLUGINS/$PLUGIN_NAME"
fi

# Create symlink
echo "🔗 Creating symlink..."
ln -s "$PLUGIN_DIR" "$NOCTALIA_PLUGINS/$PLUGIN_NAME"

# Update plugins.json
echo "📝 Registering plugin..."
if [ -f "$NOCTALIA_PLUGINS_JSON" ]; then
    # Check if plugin already registered
    if grep -q "\"$PLUGIN_NAME\"" "$NOCTALIA_PLUGINS_JSON"; then
        echo "   Plugin already registered in plugins.json"
    else
        echo "   Please add this to your plugins.json:"
        echo ""
        echo '   "'$PLUGIN_NAME'": { "enabled": true }'
        echo ""
    fi
else
    echo "   Creating new plugins.json..."
    echo '{' > "$NOCTALIA_PLUGINS_JSON"
    echo '  "'$PLUGIN_NAME'": { "enabled": true }' >> "$NOCTALIA_PLUGINS_JSON"
    echo '}' >> "$NOCTALIA_PLUGINS_JSON"
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Restart Noctalia: noctalia-shell -r"
echo "  2. Enable the plugin in Settings > Plugins"
echo ""
