pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property int    barHeight:         24
    property int    wsLeftPadding:     6
    property int    barRightPadding:   8
    property string fontFamily:        "JetBrainsMono Nerd Font"
    property int    fontSize:          12
    property int    workspaceCount:    10
    property bool   clock24h:          false

    // Multi-monitor
    property string barScreen:   ""   // "" = all monitors; screen name = that monitor only
    property string toastScreen: ""   // "" = follow barScreen; screen name = that monitor

    // Calendar & notifications panel
    property string weekStart:         "Sunday"      // "Sunday" | "Monday"
    property string defaultCalendar:   "Gregorian"   // "Gregorian" | "Hijri"
    property bool   worldClockSeconds: false
    property var    worldClockCities:  [
        { "label": "Mecca",    "tz": "Asia/Riyadh",      "h12": false },
        { "label": "London",   "tz": "Europe/London",    "h12": false },
        { "label": "New York", "tz": "America/New_York", "h12": true  },
        { "label": "Tokyo",    "tz": "Asia/Tokyo",       "h12": false }
    ]

    readonly property string _path:
        Qt.resolvedUrl("./settings.json").toString().replace(/^file:\/\//, "")

    // Reads settings.json and live-reloads on external edits.
    FileView {
        id: _file
        path: root._path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try { root._apply(JSON.parse(text())) } catch(e) {}
        }
    }

    // Persist current values — called by the in-bar settings tool after each
    // change. (The watcher will see our own write and re-apply; harmless no-op.)
    function save() {
        _file.setText(JSON.stringify({
            barHeight: barHeight,
            wsLeftPadding: wsLeftPadding,
            barRightPadding: barRightPadding,
            fontFamily: fontFamily,
            fontSize: fontSize,
            workspaceCount: workspaceCount,
            clock24h: clock24h,
            barScreen: barScreen,
            toastScreen: toastScreen,
            weekStart: weekStart,
            defaultCalendar: defaultCalendar,
            worldClockSeconds: worldClockSeconds,
            worldClockCities: worldClockCities
        }, null, 2))
    }

    function _apply(d) {
        if ("barHeight"         in d) barHeight         = d.barHeight
        if ("wsLeftPadding"     in d) wsLeftPadding     = d.wsLeftPadding
        if ("barRightPadding"   in d) barRightPadding   = d.barRightPadding
        if ("fontFamily"        in d) fontFamily        = d.fontFamily
        if ("fontSize"          in d) fontSize          = d.fontSize
        if ("workspaceCount"    in d) workspaceCount    = d.workspaceCount
        if ("clock24h"          in d) clock24h          = d.clock24h
        if ("barScreen"         in d) barScreen         = d.barScreen
        if ("toastScreen"       in d) toastScreen       = d.toastScreen
        if ("weekStart"         in d) weekStart         = d.weekStart
        if ("defaultCalendar"   in d) defaultCalendar   = d.defaultCalendar
        if ("worldClockSeconds" in d) worldClockSeconds = d.worldClockSeconds
        if ("worldClockCities"  in d) worldClockCities  = d.worldClockCities
    }
}
