import QtQuick
import Quickshell.Io
import qs.Commons

Item {
    id: root
    property var pluginApi: null
    
    IpcHandler {
        target: "plugin:chrome-bookmarks-launcher"
        
        function toggle() {
            if (!pluginApi) return
            pluginApi.withCurrentScreen(function(screen) {
                pluginApi.toggleLauncher(screen)
            })
        }
    }
    
    Component.onCompleted: {
        Logger.i("BookmarksLauncher", "Main component loaded")
    }
}
