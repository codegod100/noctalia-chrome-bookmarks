import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Item {
    id: root
    
    property var pluginApi: null
    property ShellScreen screen
    readonly property var geometryPlaceholder: panelGeometry
    
    // Safety helper
    function getSafe(obj, prop, fallback) {
        try {
            if (typeof obj !== 'undefined' && obj && prop in obj && obj[prop] !== undefined && obj[prop] !== null) {
                return obj[prop];
            }
        } catch (e) {}
        return fallback;
    }

    property real contentPreferredWidth: 900 * getSafe(Style, "uiScaleRatio", 1.0)
    property real contentPreferredHeight: 600 * getSafe(Style, "uiScaleRatio", 1.0)
    readonly property bool allowAttach: true
    anchors.fill: parent
    
    // Data
    property var bookmarks: []
    property var tabs: []
    property string bookmarkSearch: ""
    property string tabSearch: ""
    property bool bookmarksLoaded: false
    property bool tabsLoaded: false
    readonly property string tabsSnapshotPath: "/tmp/thorium-tabs.json"
    
    // Settings
    property string bookmarksPath: ""
    property string browserCommand: "xdg-open"
    property int maxResults: 50
    
    Item {
        id: panelGeometry
        anchors.fill: parent
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        anchors.topMargin: 1
        color: "transparent"
        radius: getSafe(Style, "radiusL", 8)
        clip: true
        antialiasing: true
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: getSafe(Style, "marginM", 16)
            spacing: getSafe(Style, "marginM", 16)
            
            // Left: Bookmarks
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: getSafe(Style, "marginS", 8)
                
                NText {
                    text: "Bookmarks (" + bookmarks.length + ")"
                    color: getSafe(Color, "mOnSurface", "#ffffff")
                    font.weight: Font.Bold
                    pointSize: getSafe(Style, "fontSizeM", 12)
                }
                
                NTextInput {
                    id: bookmarkSearchInput
                    Layout.fillWidth: true
                    placeholderText: "Search bookmarks..."
                    onTextChanged: bookmarkSearch = text
                    focus: true
                    
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            if (pluginApi) pluginApi.closePanel(pluginApi.panelOpenScreen);
                            event.accepted = true;
                        }
                    }
                }
                
                NScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    ListView {
                        id: bookmarksListView
                        anchors.fill: parent
                        model: bookmarksLoaded ? bookmarks.filter(function(bm) {
                            if (bookmarkSearch === "") return true;
                            var query = bookmarkSearch.toLowerCase();
                            return (bm.name && bm.name.toLowerCase().indexOf(query) !== -1) ||
                                   (bm.url && bm.url.toLowerCase().indexOf(query) !== -1);
                        }).slice(0, maxResults) : []
                        
                        spacing: 4
                        clip: true
                        
                        delegate: Rectangle {
                            width: bookmarksListView.width
                            height: 48
                            color: bookmarkMouseArea.containsMouse ? getSafe(Color, "mSurfaceVariant", "#333333") : "transparent"
                            radius: getSafe(Style, "radiusS", 4)
                            border.width: bookmarkMouseArea.containsMouse ? 1 : 0
                            border.color: getSafe(Color, "mOutline", "#666666")
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8
                                
                                NIcon {
                                    icon: "bookmark"
                                    color: getSafe(Color, "mPrimary", "#4dabf7")
                                    pointSize: getSafe(Style, "fontSizeS", 10)
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    
                                    NText {
                                        Layout.fillWidth: true
                                        text: modelData.name || "Untitled"
                                        color: getSafe(Color, "mOnSurface", "#ffffff")
                                        pointSize: getSafe(Style, "fontSizeS", 10)
                                        elide: Text.ElideRight
                                    }
                                    NText {
                                        Layout.fillWidth: true
                                        text: extractDomain(modelData.url)
                                        color: getSafe(Color, "mOutline", "#888888")
                                        pointSize: getSafe(Style, "fontSizeXs", 9)
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                            
                            MouseArea {
                                id: bookmarkMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: openBookmark(modelData.url)
                            }
                        }
                    }
                }
            }
            
            // Right: Tabs
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: getSafe(Style, "marginS", 8)
                
                NText {
                    text: "Open Tabs (" + tabs.length + ")"
                    color: getSafe(Color, "mOnSurface", "#ffffff")
                    font.weight: Font.Bold
                    pointSize: getSafe(Style, "fontSizeM", 12)
                }
                
                NTextInput {
                    id: tabSearchInput
                    Layout.fillWidth: true
                    placeholderText: "Search tabs..."
                    onTextChanged: tabSearch = text
                }
                
                NScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    ListView {
                        id: tabsListView
                        anchors.fill: parent
                        model: tabsLoaded ? tabs.filter(function(t) {
                            var title = (t.title || "").toLowerCase();
                            var url = (t.url || "").toLowerCase();
                            if (title.indexOf("omnibox") !== -1 || url.indexOf("omnibox") !== -1) {
                                return false;
                            }
                            
                            if (tabSearch === "") return true;
                            var query = tabSearch.toLowerCase();
                            return title.indexOf(query) !== -1 || url.indexOf(query) !== -1;
                        }) : []
                        
                        spacing: 4
                        clip: true
                        
                        delegate: Rectangle {
                            width: tabsListView.width
                            height: 48
                            color: tabMouseArea.containsMouse ? getSafe(Color, "mSurfaceVariant", "#333333") : "transparent"
                            radius: getSafe(Style, "radiusS", 4)
                            border.width: tabMouseArea.containsMouse ? 1 : 0
                            border.color: getSafe(Color, "mOutline", "#666666")
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8
                                
                                NIcon {
                                    icon: "browser"
                                    color: getSafe(Color, "mSecondary", "#69db7c")
                                    pointSize: getSafe(Style, "fontSizeS", 10)
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    
                                    NText {
                                        Layout.fillWidth: true
                                        text: modelData.title || "Untitled"
                                        color: getSafe(Color, "mOnSurface", "#ffffff")
                                        pointSize: getSafe(Style, "fontSizeS", 10)
                                        elide: Text.ElideRight
                                    }
                                    NText {
                                        Layout.fillWidth: true
                                        text: extractDomain(modelData.url)
                                        color: getSafe(Color, "mOutline", "#888888")
                                        pointSize: getSafe(Style, "fontSizeXs", 9)
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                            
                            MouseArea {
                                id: tabMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: openTab(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
    
    Component.onCompleted: {
        loadSettings()
        loadBookmarks()
        loadTabs()
        focusTimer.restart()
    }
    
    onVisibleChanged: {
        if (visible) {
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 200
        repeat: false
        onTriggered: {
            if (bookmarkSearchInput && bookmarkSearchInput.inputItem) {
                bookmarkSearchInput.inputItem.forceActiveFocus()
            }
        }
    }
    
    function loadSettings() {
        var defaultPath = "/home/nandi/.config/chrome-noctalia/Default/Bookmarks"
        bookmarksPath = defaultPath
        browserCommand = "xdg-open"
        maxResults = 50
        
        if (pluginApi && pluginApi.pluginSettings) {
            if (pluginApi.pluginSettings.bookmarksPath) {
                bookmarksPath = pluginApi.pluginSettings.bookmarksPath
            }
            if (pluginApi.pluginSettings.browserCommand) {
                browserCommand = pluginApi.pluginSettings.browserCommand
            }
            if (pluginApi.pluginSettings.maxResults) {
                maxResults = pluginApi.pluginSettings.maxResults
            }
        }
        
        if (bookmarksPath.startsWith("~/")) {
            var home = Quickshell.env("HOME") || "/home/nandi"
            bookmarksPath = home + bookmarksPath.slice(1)
        }
    }
    
    FileView {
        id: bookmarksFile
        path: ""
        watchChanges: true
        onLoaded: parseBookmarks(text())
    }
    
    function loadBookmarks() {
        if (bookmarksPath !== "") bookmarksFile.path = bookmarksPath
    }
    
    function parseBookmarks(jsonText) {
        try {
            if (!jsonText) return
            var data = JSON.parse(jsonText)
            var allBookmarks = []
            if (data.roots) {
                if (data.roots.bookmark_bar) extractBookmarks(data.roots.bookmark_bar, allBookmarks, "")
                if (data.roots.other) extractBookmarks(data.roots.other, allBookmarks, "Other")
                if (data.roots.synced) extractBookmarks(data.roots.synced, allBookmarks, "Synced")
            }
            bookmarks = allBookmarks
            bookmarksLoaded = true
        } catch (e) {
            Logger.e("Bookmarks", "Panel failed to parse: " + e)
        }
    }
    
    function extractBookmarks(node, results, folderPath) {
        if (!node || !node.children) return
        for (var i = 0; i < node.children.length; i++) {
            var item = node.children[i]
            if (item.type === "url") {
                if (item.url && !item.url.startsWith("javascript:")) {
                    results.push({"name": item.name || "Untitled", "url": item.url, "folder": folderPath || "Root"})
                }
            } else if (item.type === "folder") {
                var newPath = folderPath ? (folderPath + "/" + item.name) : item.name
                extractBookmarks(item, results, newPath)
            }
        }
    }
    
    FileView {
        id: tabsFile
        path: tabsSnapshotPath
        watchChanges: true
        onLoaded: parseTabs(text())
        onLoadFailed: {
            tabs = []
            tabsLoaded = false
        }
    }
    
    function loadTabs() {
        tabsFile.path = tabsSnapshotPath
    }

    function parseTabs(jsonText) {
        try {
            if (!jsonText) return
            var data = JSON.parse(jsonText)
            tabs = data.tabs || []
            tabsLoaded = true
        } catch (e) {
            Logger.e("Bookmarks", "Panel failed to parse tabs: " + e)
            tabs = []
            tabsLoaded = false
        }
    }
    
    function extractDomain(url) {
        try {
            var match = url.match(/^https?:\/\/([^\/]+)/)
            return match ? match[1] : url
        } catch (e) { return url }
    }
    
    function openBookmark(url) {
        Logger.i("Bookmarks", "Panel opening bookmark via CDP (Target.createTarget): " + url)
        var scriptPath = pluginApi.pluginDir + "/open-cdp.js"
        Quickshell.execDetached(["node", scriptPath, url, "true"])
        
        if (pluginApi) pluginApi.closePanel(pluginApi.panelOpenScreen)
    }
    
    function openTab(tab) {
        if (tab && tab.id) {
            Logger.i("Bookmarks", "Requesting focus for tab: " + tab.id)
            var scriptPath = pluginApi.pluginDir + "/focus-tab.js"
            Quickshell.execDetached(["node", scriptPath, String(tab.id), String(tab.windowId || "")])
        } else if (tab && tab.url) {
            Logger.i("Bookmarks", "Falling back to opening tab URL: " + tab.url)
            Quickshell.execDetached([browserCommand, tab.url])
        }
        
        if (pluginApi) pluginApi.closePanel(pluginApi.panelOpenScreen)
    }
}
