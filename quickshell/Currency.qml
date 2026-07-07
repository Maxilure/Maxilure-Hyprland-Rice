pragma Singleton
import QtQuick
import Quickshell.Io

// Shared FX rate cache (base USD) backing the currency-converter tool. A
// singleton so every monitor's ToolsPanel shares one fetch instead of each
// spawning its own curl call. Rates are fetched on demand (ensureFresh) and
// considered stale after 30 minutes.
Item {
    id: root

    property var rates: ({})      // { "USD": 1, "EUR": 0.92, ... }
    property bool loading: false
    property string error: ""
    property real lastUpdated: 0  // epoch ms, 0 = never fetched

    function refresh() {
        if (_proc.running) return
        loading = true
        error = ""
        _proc.running = true
    }

    // Lazy fetch: called when a currency tool comes on screen. Avoids hitting
    // the network at startup / every 30 min for a tool that may never open.
    function ensureFresh() {
        if (Date.now() - lastUpdated > 1800000) refresh()
    }

    Process {
        id: _proc
        running: false
        command: ["curl", "-s", "--max-time", "8", "https://api.exchangerate-api.com/v4/latest/USD"]
        property string _buf: ""
        stdout: SplitParser { onRead: line => { _proc._buf += line } }
        onRunningChanged: {
            if (running) return
            root.loading = false
            try {
                var d = JSON.parse(_proc._buf)
                if (d && d.rates) {
                    root.rates = d.rates
                    root.lastUpdated = Date.now()
                    root.error = ""
                } else {
                    root.error = "bad response"
                }
            } catch(e) { root.error = "network error" }
            _proc._buf = ""
        }
    }

}
