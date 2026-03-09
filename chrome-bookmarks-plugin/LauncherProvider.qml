import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
    id: root
    
    // Required properties (injected by Noctalia)
    property var pluginApi: null
    property var launcher: null
    property string name: "Bookmarks"
    
    // Provider configuration
    property bool handleSearch: true
    property string supportedLayouts: "list"
    property bool supportsAutoPaste: false
    
    // Our data
    property var bookmarks: []
    property bool loaded: false
    property string lastError: ""
    
    // Settings
    property string bookmarksPath: ""
    property string browserCommand: "xdg-open"
    property int maxResults: 50
    
    // Called when launcher opens
    function onOpened() {
        Logger.i("Bookmarks", "onOpened called, loaded=" + loaded + ", path=" + bookmarksPath)
        loadSettings()
        loadBookmarks()
    }
    
    // Initialize on load
    Component.onCompleted: {
        Logger.i("Bookmarks", "Component.onCompleted")
        init()
    }

    // Initialize function
    function init() {
        Logger.i("Bookmarks", "init called")
        loadSettings()
        loadBookmarks()
    }
    
    // Load settings from pluginApi
    function loadSettings() {
        Logger.i("Bookmarks", "loadSettings called")
        // Default values
        var defaultPath = "/home/nandi/.config/chrome-noctalia/Default/Bookmarks"
        bookmarksPath = defaultPath
        browserCommand = "xdg-open"
        maxResults = 50

        if (pluginApi && pluginApi.pluginSettings) {
            Logger.i("Bookmarks", "pluginSettings found")
            bookmarksPath = pluginApi.pluginSettings.bookmarksPath || defaultPath
            browserCommand = pluginApi.pluginSettings.browserCommand || "xdg-open"
            maxResults = pluginApi.pluginSettings.maxResults || 50
        } else {
            Logger.i("Bookmarks", "pluginSettings NOT found, using defaults")
        }
        
        // Expand ~ to home directory
        if (bookmarksPath.startsWith("~/")) {
            var home = Quickshell.env("HOME") || "/home/nandi"
            bookmarksPath = home + bookmarksPath.slice(1)
        }
        
        Logger.i("Bookmarks", "Settings loaded. Path: " + bookmarksPath + ", Max results: " + maxResults)
    }
    
    // Load bookmarks from Chrome's JSON file
    function loadBookmarks() {
        if (bookmarksPath === "") {
            Logger.w("Bookmarks", "Cannot load bookmarks: path is empty")
            return
        }
        Logger.i("Bookmarks", "Setting FileView path to: " + bookmarksPath)
        bookmarksFile.path = bookmarksPath
    }
    
    // Parse Chrome bookmarks JSON
    function parseBookmarks(jsonText) {
        Logger.i("Bookmarks", "parseBookmarks called, text length: " + (jsonText ? jsonText.length : 0))
        if (jsonText && jsonText.length > 0) {
            Logger.i("Bookmarks", "First 50 chars: " + jsonText.substring(0, 50))
        }
        try {
            if (!jsonText) {
                throw new Error("Empty bookmarks file")
            }
            
            var data = JSON.parse(jsonText)
            var allBookmarks = []
            
            // Chrome stores bookmarks in roots: bookmark_bar, other, synced
            if (data.roots) {
                Logger.i("Bookmarks", "Roots found: " + Object.keys(data.roots).join(", "))
                if (data.roots.bookmark_bar) {
                    extractBookmarks(data.roots.bookmark_bar, allBookmarks, "")
                }
                if (data.roots.other) {
                    extractBookmarks(data.roots.other, allBookmarks, "Other")
                }
                if (data.roots.synced) {
                    extractBookmarks(data.roots.synced, allBookmarks, "Synced")
                }
            } else {
                Logger.w("Bookmarks", "No roots found in JSON")
            }
            
            bookmarks = allBookmarks
            loaded = true
            lastError = ""
            Logger.i("Bookmarks", "Successfully loaded " + bookmarks.length + " bookmarks")
            
            if (launcher) {
                launcher.updateResults()
            }
        } catch (e) {
            lastError = "Failed to parse bookmarks: " + e.message
            Logger.e("Bookmarks", lastError)
            loaded = false
        }
    }
    
    // Recursively extract bookmarks from Chrome's nested structure
    function extractBookmarks(node, results, folderPath) {
        if (!node || !node.children) return
        
        for (var i = 0; i < node.children.length; i++) {
            var item = node.children[i]
            
            if (item.type === "url") {
                // Skip javascript: bookmarklets
                if (item.url && item.url.startsWith("javascript:")) continue
                
                results.push({
                    "name": item.name || "Untitled",
                    "url": item.url,
                    "folder": folderPath || "Root"
                })
            } else if (item.type === "folder") {
                // Recurse into folders
                var newPath = folderPath ? (folderPath + "/" + item.name) : item.name
                extractBookmarks(item, results, newPath)
            }
        }
    }
    
    // File loader for bookmarks JSON
    FileView {
        id: bookmarksFile
        path: ""
        watchChanges: true
        
        onLoaded: {
            Logger.i("Bookmarks", "FileView onLoaded")
            parseBookmarks(text())
        }
        
        onLoadFailed: {
            lastError = "Failed to load bookmarks file: " + path
            Logger.e("Bookmarks", lastError)
            loaded = false
        }
    }
    
    // Check if we handle this command
    function handleCommand(searchText) {
        var handles = searchText.startsWith(">bm")
        if (handles) {
            Logger.i("Bookmarks", "handleCommand: true for " + searchText)
        }
        return handles
    }
    
    // Register our command
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
    
    // Get results based on search text
    function getResults(searchText) {
        var isCommand = searchText.startsWith(">bm")
        var query = ""
        
        if (isCommand) {
            query = searchText.slice(3).trim().toLowerCase()
        } else if (handleSearch) {
            query = searchText.trim().toLowerCase()
            // Don't show results for very short queries in general search to avoid noise
            if (query.length < 3) return []
        } else {
            return []
        }
        
        var results = []
        
        Logger.i("Bookmarks", "getResults called with query: '" + query + "', isCommand=" + isCommand + ", loaded=" + loaded + ", bookmarks=" + bookmarks.length)
        
        // Show error if failed to load (only in command mode)
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
        
        // Show loading state (only in command mode)
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
        
        // Empty query in command mode - show recent/popular bookmarks
        if (isCommand && query === "") {
            results.push({
                "name": "Search your bookmarks",
                "description": bookmarks.length + " bookmarks loaded",
                "icon": "search",
                "isTablerIcon": true,
                "onActivate": function() {}
            })
            
            // Show all bookmarks (up to maxResults)
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
        
        // Search bookmarks
        var matches = []
        for (var i = 0; i < bookmarks.length; i++) {
            var bm = bookmarks[i]
            var nameLower = bm.name.toLowerCase()
            var urlLower = bm.url.toLowerCase()
            var folderLower = bm.folder.toLowerCase()
            
            // Search in name, url, and folder
            if (nameLower.indexOf(query) !== -1 || 
                urlLower.indexOf(query) !== -1 ||
                folderLower.indexOf(query) !== -1) {
                matches.push(bm)
            }
        }
        
        // Sort matches by relevance (name match first, then url)
        matches.sort(function(a, b) {
            var aName = a.name.toLowerCase().indexOf(query)
            var bName = b.name.toLowerCase().indexOf(query)
            
            // If one starts with the query and the other doesn't, prioritize the one that starts with it
            var aStarts = a.name.toLowerCase().startsWith(query)
            var bStarts = b.name.toLowerCase().startsWith(query)
            if (aStarts !== bStarts) return aStarts ? -1 : 1
            
            if (aName !== bName && aName !== -1 && bName !== -1) return aName - bName
            return a.name.localeCompare(b.name)
        })
        
        // Limit results
        var limit = isCommand ? maxResults : 5 // Fewer results for general search
        for (var i = 0; i < Math.min(matches.length, limit); i++) {
            results.push(formatBookmark(matches[i]))
        }
        
        // No results message (only in command mode)
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
    
    // Format a bookmark for display
    function formatBookmark(bookmark) {
        // Extract domain for description
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
    
    // Extract domain from URL
    function extractDomain(url) {
        try {
            var match = url.match(/^https?:\/\/([^\/]+)/)
            return match ? match[1] : url
        } catch (e) {
            return url
        }
    }
    
    // Open bookmark in browser
    function openBookmark(url) {
        Logger.i("Bookmarks", "Opening in new window via CDP (Target.createTarget): " + url)
        
        // Use our helper script to send the CDP command over WebSocket
        var scriptPath = pluginApi.pluginDir + "/open-cdp.js"
        Quickshell.execDetached(["node", scriptPath, url, "true"])
        
        // Focus new window after delay
        focusTimer.start()
        
        launcher.close()
    }
    
    Timer {
        id: focusTimer
        interval: 1000
        repeat: false
        onTriggered: {
            // Focus the rightmost window (new windows open on right in niri)
            Quickshell.execDetached(["niri", "msg", "action", "focus-column-right"])
        }
    }
    
    // Reload bookmarks manually
    function reload() {
        loaded = false
        bookmarks = []
        loadBookmarks()
        
        if (typeof ToastService !== 'undefined') {
            ToastService.show("Reloading bookmarks...")
        }
    }
}
