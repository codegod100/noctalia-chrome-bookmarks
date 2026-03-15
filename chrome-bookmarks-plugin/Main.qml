import QtQuick
import Quickshell.Io
import qs.Commons

Item {
    id: root
    property var pluginApi: null
    
    IpcHandler {
        target: "plugin:chrome-bookmarks"
        
        function toggle() {
            if (!pluginApi) return
            pluginApi.withCurrentScreen(function(screen) {
                pluginApi.togglePanel(screen)
            })
        }
        
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
