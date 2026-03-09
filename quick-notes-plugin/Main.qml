import QtQuick
import Quickshell.Io
import qs.Commons

Item {
    id: root
    property var pluginApi: null
    
    // IPC Handler - allows keyboard shortcuts to open launcher directly to our plugin
    IpcHandler {
        target: "plugin:quick-notes"
        
        function toggle() {
            if (!pluginApi) return
            pluginApi.withCurrentScreen(function(screen) {
                pluginApi.toggleLauncher(screen)
            })
        }
    }
    
    Component.onCompleted: {
        Logger.i("QuickNotes", "Main component loaded")
    }
}
