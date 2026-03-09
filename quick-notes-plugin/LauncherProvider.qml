import QtQuick
import qs.Commons

Item {
    id: root
    
    // Required properties (injected by Noctalia)
    property var pluginApi: null
    property var launcher: null
    property string name: "Quick Notes"
    
    // Provider configuration
    property bool handleSearch: false
    property string supportedLayouts: "list"
    property bool supportsAutoPaste: false
    
    // Our notes data
    property var notes: []
    
    // Initialize on load
    function init() {
        Logger.i("QuickNotes", "Plugin initialized")
        loadNotes()
    }
    
    // Called when launcher opens
    function onOpened() {
        // Refresh notes in case they changed
        loadNotes()
    }
    
    // Load notes from settings
    function loadNotes() {
        if (pluginApi && pluginApi.pluginSettings) {
            notes = pluginApi.pluginSettings.notes || []
        }
    }
    
    // Save notes to settings
    function saveNotes() {
        if (pluginApi) {
            pluginApi.pluginSettings.notes = notes
            pluginApi.saveSettings()
        }
    }
    
    // Add a new note
    function addNote(text) {
        var newNote = {
            "text": text,
            "created": new Date().toISOString()
        }
        notes.unshift(newNote) // Add to beginning
        
        // Limit to maxNotes
        var maxNotes = pluginApi.pluginSettings.maxNotes || 50
        if (notes.length > maxNotes) {
            notes = notes.slice(0, maxNotes)
        }
        
        saveNotes()
        
        // Show confirmation
        if (typeof ToastService !== 'undefined') {
            ToastService.show("Note saved!")
        }
    }
    
    // Delete a note
    function deleteNote(index) {
        notes.splice(index, 1)
        saveNotes()
    }
    
    // Check if we handle this command
    function handleCommand(searchText) {
        return searchText.startsWith(">note")
    }
    
    // Register our command
    function commands() {
        return [{
            "name": ">note",
            "description": "Quick notes - save and search",
            "icon": "note",
            "isTablerIcon": true,
            "onActivate": function() {
                launcher.setSearchText(">note ")
            }
        }]
    }
    
    // Get results based on search text
    function getResults(searchText) {
        if (!searchText.startsWith(">note")) {
            return []
        }
        
        var query = searchText.slice(5).trim()
        var results = []
        
        // Case 1: Empty or just whitespace - show add option + recent notes
        if (query === "") {
            // Add note action
            results.push({
                "name": "Add a new note",
                "description": "Type your note after >note (e.g., >note Buy milk)",
                "icon": "plus",
                "isTablerIcon": true,
                "onActivate": function() {
                    launcher.setSearchText(">note ")
                }
            })
            
            // Show recent notes
            for (var i = 0; i < Math.min(notes.length, 10); i++) {
                results.push(formatNote(notes[i], i))
            }
            
            if (notes.length === 0) {
                results.push({
                    "name": "No notes yet",
                    "description": "Start typing to add your first note!",
                    "icon": "note-off",
                    "isTablerIcon": true,
                    "onActivate": function() {}
                })
            }
        }
        // Case 2: Starts with + - adding a new note
        else if (query.startsWith("+ ")) {
            var noteText = query.slice(2).trim()
            
            if (noteText === "") {
                results.push({
                    "name": "Type your note...",
                    "description": "After '+ ' type your note text",
                    "icon": "pencil",
                    "isTablerIcon": true,
                    "onActivate": function() {}
                })
            } else {
                results.push({
                    "name": "Save: \"" + noteText + "\"",
                    "description": "Press Enter to save this note",
                    "icon": "device-floppy",
                    "isTablerIcon": true,
                    "onActivate": function() {
                        addNote(noteText)
                        launcher.close()
                    }
                })
            }
        }
        // Case 3: Search existing notes
        else {
            var searchQuery = query.toLowerCase()
            var found = false
            
            for (var i = 0; i < notes.length; i++) {
                if (notes[i].text.toLowerCase().indexOf(searchQuery) !== -1) {
                    results.push(formatNote(notes[i], i))
                    found = true
                }
            }
            
            // Also offer to create new note with this text
            results.unshift({
                "name": "Create new note: \"" + query + "\"",
                "description": "Press Enter to save",
                "icon": "plus",
                "isTablerIcon": true,
                "onActivate": function() {
                    addNote(query)
                    launcher.close()
                }
            })
            
            if (!found) {
                results.push({
                    "name": "No matching notes found",
                    "description": "Create a new note instead!",
                    "icon": "search-off",
                    "isTablerIcon": true,
                    "onActivate": function() {}
                })
            }
        }
        
        return results
    }
    
    // Format a note for display
    function formatNote(note, index) {
        var timeAgo = getTimeAgo(note.created)
        
        return {
            "name": note.text,
            "description": timeAgo,
            "icon": "note",
            "isTablerIcon": true,
            "onActivate": function() {
                // Copy to clipboard
                copyToClipboard(note.text)
                launcher.close()
            }
        }
    }
    
    // Calculate time ago string
    function getTimeAgo(isoString) {
        var date = new Date(isoString)
        var now = new Date()
        var diffMs = now - date
        var diffMins = Math.floor(diffMs / 60000)
        var diffHours = Math.floor(diffMs / 3600000)
        var diffDays = Math.floor(diffMs / 86400000)
        
        if (diffMins < 1) return "Just now"
        if (diffMins < 60) return diffMins + " min ago"
        if (diffHours < 24) return diffHours + " hour" + (diffHours > 1 ? "s" : "") + " ago"
        if (diffDays < 7) return diffDays + " day" + (diffDays > 1 ? "s" : "") + " ago"
        return date.toLocaleDateString()
    }
    
    // Copy text to clipboard (Wayland)
    function copyToClipboard(text) {
        var escaped = text.replace(/'/g, "'\\''")
        Quickshell.execDetached([
            "sh", "-c",
            "printf '%s' '" + escaped + "' | wl-copy"
        ])
        
        if (typeof ToastService !== 'undefined') {
            ToastService.show("Copied to clipboard!")
        }
    }
}
