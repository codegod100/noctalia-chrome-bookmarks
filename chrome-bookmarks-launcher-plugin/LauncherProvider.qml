import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
    id: root
    
    property var pluginApi: null
    property var launcher: null
    property string name: "Bookmarks"
    property bool handleSearch: true
    property string supportedLayouts: "list"
    property bool supportsAutoPaste: false
    
    property var bookmarks: []
    property bool loaded: false
    property string lastError: ""
    
    property string bookmarksPath: ""
    property string browserCommand: "xdg-open"
    property int maxResults: 50
    
    function onOpened() {
        Logger.i("BookmarksLauncher", "onOpened called, loaded=" + loaded + ", path=" + bookmarksPath)
        loadSettings()
        loadBookmarks()
    }
    
    Component.onCompleted: {
        Logger.i("BookmarksLauncher", "Component.onCompleted")
        init()
    }

    function init() {
        Logger.i("BookmarksLauncher", "init called")
        loadSettings()
        loadBookmarks()
    }
    
    function loadSettings() {
        Logger.i("BookmarksLauncher", "loadSettings called")
        var defaultPath = "/home/nandi/.config/chrome-noctalia/Default/Bookmarks"
        bookmarksPath = defaultPath
        browserCommand = "xdg-open"
        maxResults = 50

        if (pluginApi && pluginApi.pluginSettings) {
            Logger.i("BookmarksLauncher", "pluginSettings found")
            bookmarksPath = pluginApi.pluginSettings.bookmarksPath || defaultPath
            browserCommand = pluginApi.pluginSettings.browserCommand || "xdg-open"
            maxResults = pluginApi.pluginSettings.maxResults || 50
        } else {
            Logger.i("BookmarksLauncher", "pluginSettings NOT found, using defaults")
        }
        
        if (bookmarksPath.startsWith("~/")) {
            var home = Quickshell.env("HOME") || "/home/nandi"
            bookmarksPath = home + bookmarksPath.slice(1)
        }
        
        Logger.i("BookmarksLauncher", "Settings loaded. Path: " + bookmarksPath + ", Max results: " + maxResults)
    }
    
    function loadBookmarks() {
        if (bookmarksPath === "") {
            Logger.w("BookmarksLauncher", "Cannot load bookmarks: path is empty")
            return
        }
        Logger.i("BookmarksLauncher", "Setting FileView path to: " + bookmarksPath)
        bookmarksFile.path = bookmarksPath
    }
    
    function parseBookmarks(jsonText) {
        Logger.i("BookmarksLauncher", "parseBookmarks called, text length: " + (jsonText ? jsonText.length : 0))
        try {
            if (!jsonText) {
                throw new Error("Empty bookmarks file")
            }
            
            var data = JSON.parse(jsonText)
            var allBookmarks = []
            
            if (data.roots) {
                if (data.roots.bookmark_bar) {
                    extractBookmarks(data.roots.bookmark_bar, allBookmarks, "")
                }
                if (data.roots.other) {
                    extractBookmarks(data.roots.other, allBookmarks, "Other")
                }
                if (data.roots.synced) {
                    extractBookmarks(data.roots.synced, allBookmarks, "Synced")
                }
            }
            
            bookmarks = allBookmarks
            loaded = true
            lastError = ""
            Logger.i("BookmarksLauncher", "Successfully loaded " + bookmarks.length + " bookmarks")
            
            if (launcher) {
                launcher.updateResults()
            }
        } catch (e) {
            lastError = "Failed to parse bookmarks: " + e.message
            Logger.e("BookmarksLauncher", lastError)
            loaded = false
        }
    }
    
    function extractBookmarks(node, results, folderPath) {
        if (!node || !node.children) return
        
        for (var i = 0; i < node.children.length; i++) {
            var item = node.children[i]
            
            if (item.type === "url") {
                if (item.url && item.url.startsWith("javascript:")) continue
                
                results.push({
                    "name": item.name || "Untitled",
                    "url": item.url,
                    "folder": folderPath || "Root"
                })
            } else if (item.type === "folder") {
                var newPath = folderPath ? (folderPath + "/" + item.name) : item.name
                extractBookmarks(item, results, newPath)
            }
        }
    }
    
    FileView {
        id: bookmarksFile
        path: ""
        watchChanges: true
        
        onLoaded: {
            Logger.i("BookmarksLauncher", "FileView onLoaded")
            parseBookmarks(text())
        }
        
        onLoadFailed: {
            lastError = "Failed to load bookmarks file: " + path
            Logger.e("BookmarksLauncher", lastError)
            loaded = false
        }
    }
    
    function handleCommand(searchText) {
        var handles = searchText.startsWith(">bm")
        if (handles) {
            Logger.i("BookmarksLauncher", "handleCommand: true for " + searchText)
        }
        return handles
    }
    
    function commands() {
        return [{
            "name": ">bm",
            "description": "Search Chrome bookmarks",
            "icon": "bookmark",
            "isTablerIcon": true,
            "onActivate": function() {
                launcher.setSearchText(">bm ")
            }
        }]
    }
    
    function getResults(searchText) {
        var isCommand = searchText.startsWith(">bm")
        var query = ""
        
        if (isCommand) {
            query = searchText.slice(3).trim().toLowerCase()
        } else if (handleSearch) {
            query = searchText.trim().toLowerCase()
            if (query.length < 3) return []
        } else {
            return []
        }
        
        var results = []
        
        Logger.i("BookmarksLauncher", "getResults called with query: '" + query + "', isCommand=" + isCommand + ", loaded=" + loaded + ", bookmarks=" + bookmarks.length)
        
        if (isCommand && !loaded && lastError !== "") {
            results.push({
                "name": "Error loading bookmarks",
                "description": lastError,
                "icon": "alert-circle",
                "isTablerIcon": true,
                "onActivate": function() {}
            })
            return results
        }
        
        if (isCommand && !loaded) {
            results.push({
                "name": "Loading bookmarks...",
                "description": "Please wait",
                "icon": "loader",
                "isTablerIcon": true,
                "onActivate": function() {}
            })
            return results
        }
        
        if (!loaded) return []
        
        if (isCommand && query === "") {
            results.push({
                "name": "Search your bookmarks",
                "description": bookmarks.length + " bookmarks loaded",
                "icon": "search",
                "isTablerIcon": true,
                "onActivate": function() {}
            })
            
            for (var i = 0; i < Math.min(bookmarks.length, maxResults); i++) {
                results.push(formatBookmark(bookmarks[i]))
            }
            
            if (bookmarks.length > maxResults) {
                results.push({
                    "name": "... and " + (bookmarks.length - maxResults) + " more",
                    "description": "Type to search",
                    "icon": "dots",
                    "isTablerIcon": true,
                    "onActivate": function() {}
                })
            }
            
            return results
        }
        
        var matches = []
        for (var j = 0; j < bookmarks.length; j++) {
            var bm = bookmarks[j]
            var nameLower = bm.name.toLowerCase()
            var urlLower = bm.url.toLowerCase()
            var folderLower = bm.folder.toLowerCase()
            
            if (nameLower.indexOf(query) !== -1 ||
                urlLower.indexOf(query) !== -1 ||
                folderLower.indexOf(query) !== -1) {
                matches.push(bm)
            }
        }
        
        matches.sort(function(a, b) {
            var aName = a.name.toLowerCase().indexOf(query)
            var bName = b.name.toLowerCase().indexOf(query)
            var aStarts = a.name.toLowerCase().startsWith(query)
            var bStarts = b.name.toLowerCase().startsWith(query)
            if (aStarts !== bStarts) return aStarts ? -1 : 1
            if (aName !== bName && aName !== -1 && bName !== -1) return aName - bName
            return a.name.localeCompare(b.name)
        })
        
        var limit = isCommand ? maxResults : 5
        for (var k = 0; k < Math.min(matches.length, limit); k++) {
            results.push(formatBookmark(matches[k]))
        }
        
        if (isCommand && matches.length === 0) {
            results.push({
                "name": "No bookmarks found",
                "description": "Try a different search term",
                "icon": "bookmark-off",
                "isTablerIcon": true,
                "onActivate": function() {}
            })
        } else if (isCommand && matches.length > limit) {
            results.push({
                "name": "... and " + (matches.length - limit) + " more",
                "description": "Refine your search to see more",
                "icon": "dots",
                "isTablerIcon": true,
                "onActivate": function() {}
            })
        }
        
        return results
    }
    
    function formatBookmark(bookmark) {
        var domain = extractDomain(bookmark.url)
        
        return {
            "name": bookmark.name,
            "description": domain + (bookmark.folder ? " • " + bookmark.folder : ""),
            "icon": "bookmark",
            "isTablerIcon": true,
            "onActivate": function() {
                openBookmark(bookmark.url)
            }
        }
    }
    
    function extractDomain(url) {
        try {
            var match = url.match(/^https?:\/\/([^\/]+)/)
            return match ? match[1] : url
        } catch (e) {
            return url
        }
    }
    
    function openBookmark(url) {
        Logger.i("BookmarksLauncher", "Opening in new window via CDP (Target.createTarget): " + url)
        
        var scriptPath = pluginApi.pluginDir + "/open-cdp.js"
        Quickshell.execDetached(["node", scriptPath, url, "true"])
        
        focusTimer.start()
        
        launcher.close()
    }
    
    Timer {
        id: focusTimer
        interval: 1000
        repeat: false
        onTriggered: {
            Quickshell.execDetached(["niri", "msg", "action", "focus-column-right"])
        }
    }
    
    function reload() {
        loaded = false
        bookmarks = []
        loadBookmarks()
        
        if (typeof ToastService !== "undefined") {
            ToastService.show("Reloading bookmarks...")
        }
    }
}
