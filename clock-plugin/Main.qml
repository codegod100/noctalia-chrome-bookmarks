import QtQuick
import Quickshell.Io
import qs.Commons

Item {
    id: root
    property var pluginApi: null
    
    Component.onCompleted: {
        Logger.i("Clock", "Main component loaded")
    }
}
