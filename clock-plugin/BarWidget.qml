import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    // Settings
    property bool use12Hour: pluginApi?.pluginSettings?.use12Hour ?? true
    property bool showSeconds: pluginApi?.pluginSettings?.showSeconds ?? false
    property int fontSize: pluginApi?.pluginSettings?.fontSize ?? 24

    // Internal state
    property date currentTime: new Date()

    readonly property string barPosition: Settings.getBarPositionForScreen(screen?.name ?? "")
    readonly property bool barIsVertical: barPosition === "left" || barPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screen?.name ?? "")

    // Build format string based on settings
    readonly property string timeFormat: {
        let fmt = use12Hour ? "h:mm" : "HH:mm"
        if (showSeconds) fmt = use12Hour ? "h:mm:ss" : "HH:mm:ss"
        if (use12Hour) fmt += " AP"
        return fmt
    }

    implicitWidth: clockText.implicitWidth + 20
    implicitHeight: capsuleHeight

    function updateTime() {
        currentTime = new Date()
    }

    Timer {
        interval: showSeconds ? 500 : 10000
        running: true
        repeat: true
        onTriggered: updateTime()
    }

    Component.onCompleted: {
        updateTime()
    }

    Rectangle {
        id: container
        anchors.fill: parent
        color: mouseArea.containsMouse ? Style.capsuleColor : "transparent"
        radius: Style.radiusL

        Behavior on color {
            ColorAnimation { duration: Style.animationNormal }
        }

        NText {
            id: clockText
            anchors.centerIn: parent
            text: Qt.formatDateTime(currentTime, timeFormat)
            color: Color.mOnSurface
            font.pixelSize: fontSize
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    contextMenu.open()
                } else {
                    Logger.i("Clock", "Clock widget clicked")
                }
            }
        }
    }

    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": I18n.tr("actions.widget-settings"),
                "action": "widget-settings",
                "icon": "settings"
            }
        ]

        onTriggered: function(action) {
            contextMenu.close()
            PanelService.closeContextMenu(screen)
            if (action === "widget-settings") {
                BarService.openPluginSettings(root.screen, pluginApi.manifest)
            }
        }
    }
}
