pragma Singleton
import QtQuick
import Quickshell.Io

// Persistent history for the calculator tool — newest first, capped at 50,
// shared across every monitor's Bar (singleton) and surviving quickshell
// restarts via calc_history.json next to settings.json.
Item {
    id: root

    readonly property int maxEntries: 50
    property var entries: []   // [{ expr, result, ts }, ...] newest first

    readonly property string _path:
        Qt.resolvedUrl("./calc_history.json").toString().replace(/^file:\/\//, "")

    function addEntry(expr, result) {
        var list = entries.slice()
        list.unshift({ expr: expr, result: result, ts: Date.now() })
        if (list.length > maxEntries) list.length = maxEntries
        entries = list
        _save()
    }

    function removeEntry(index) {
        var list = entries.slice()
        list.splice(index, 1)
        entries = list
        _save()
    }

    function clear() {
        entries = []
        _save()
    }

    function _save() { _file.setText(JSON.stringify(root.entries)) }

    FileView {
        id: _file
        path: root._path
        printErrors: false
        onLoaded: {
            try {
                var d = JSON.parse(text())
                if (Array.isArray(d)) root.entries = d
            } catch(e) {}
        }
    }
}
