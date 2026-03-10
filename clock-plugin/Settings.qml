import QtQuick
import QtQuick.Layouts
import qs.Widgets
import qs.Commons

ColumnLayout {
    id: root

    property var pluginApi: null

    // Local state
    property bool use12Hour: pluginApi?.pluginSettings?.use12Hour ?? true
    property bool showSeconds: pluginApi?.pluginSettings?.showSeconds ?? false
    property int fontSize: pluginApi?.pluginSettings?.fontSize ?? 24

    spacing: Style.marginM

    Component.onCompleted: {
        Logger.i("Clock", "Settings UI loaded")
    }

    NToggle {
        label: pluginApi?.tr("settings.12hour.label") || "12-Hour Format"
        description: pluginApi?.tr("settings.12hour.description") || "Show time in 12-hour format (AM/PM)"

        checked: root.use12Hour
        onToggled: function(checked) {
            root.use12Hour = checked
        }
    }

    NToggle {
        label: pluginApi?.tr("settings.seconds.label") || "Show Seconds"
        description: pluginApi?.tr("settings.seconds.description") || "Display seconds in the clock"

        checked: root.showSeconds
        onToggled: function(checked) {
            root.showSeconds = checked
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: pluginApi?.tr("settings.fontSize.label") || "Font Size"
            description: pluginApi?.tr("settings.fontSize.description") || "Size of the clock text in pixels"
        }

        NSlider {
            id: fontSizeSlider
            from: 12
            to: 48
            value: root.fontSize
            stepSize: 2
            onValueChanged: {
                root.fontSize = value
            }
        }

        Text {
            text: (pluginApi?.tr("settings.currentFontSize") || "Current size: {value}px").replace("{value}", fontSizeSlider.value)
            color: Color.mOnSurfaceVariant
            font.pointSize: Style.fontSizeS
        }
    }

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("Clock", "Cannot save settings: pluginApi is null")
            return
        }

        pluginApi.pluginSettings.use12Hour = root.use12Hour
        pluginApi.pluginSettings.showSeconds = root.showSeconds
        pluginApi.pluginSettings.fontSize = root.fontSize

        pluginApi.saveSettings()

        Logger.i("Clock", "Settings saved successfully")
    }
}
