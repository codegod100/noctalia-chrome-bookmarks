import QtQuick
import Quickshell.Io
import qs.Commons

Item {
    id: root
    property var pluginApi: null
    
    // IPC Handler - allows keyboard shortcuts and external commands
    IpcHandler {
        target: "plugin:chrome-bookmarks"
        
        // Toggle launcher with our command prefix
        function toggle() {
            if (!pluginApi) return
            pluginApi.withCurrentScreen(function(screen) {
                pluginApi.toggleLauncher(screen)
            })
        }
        
        // Toggle the panel view
        function togglePanel() {
            if (!pluginApi) return
            pluginApi.withCurrentScreen(function(screen) {
                pluginApi.togglePanel(screen)
            })
        }
    }
    
    Component.onCompleted: {
        Logger.i("Bookmarks", "Main component loaded")
    }
}
