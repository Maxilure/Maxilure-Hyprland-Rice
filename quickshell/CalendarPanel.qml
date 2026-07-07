import Quickshell
import Quickshell.Io
import QtQuick
import "Colors.js" as C
import "Calendar.js" as Cal

// Dropdown panel that falls from the bar clock: calendar + world clocks on the
// left, the live notification center on the right. One instance lives inside
// each monitor's Clock; notification data is shared via the Notifications singleton.
PopupWindow {
    id: panel

    property var barWindow
    property var anchorItem          // the Clock Item, for horizontal placement
    property bool open: false

    // ── Geometry ─────────────────────────────────────────────────────────
    readonly property int panelWidth: 600
    readonly property int pad: 14
    readonly property int gap: 14
    readonly property int leftW: 296
    readonly property real cellW: (leftW - 6 * 3) / 7
    readonly property real rightW: panelWidth - 2 * pad - leftW - 1 - 2 * gap
    readonly property int topGap: 10
    readonly property int contentH: leftColumn.implicitHeight + 2 * pad

    // ── Theme ────────────────────────────────────────────────────────────
    readonly property color accent: C.accent
    function accentA(a) { return Qt.rgba(accent.r, accent.g, accent.b, a) }

    // ── State ────────────────────────────────────────────────────────────
    property var now: new Date()
    property int viewY: now.getFullYear()
    property int viewM: now.getMonth()
    property var hijriRef: new Date()
    property string selectedKey: ""
    property bool hijri: Settings.defaultCalendar === "Hijri"
    property var h12: ({})
    property bool secOn: Settings.worldClockSeconds
    property var offsets: ({})

    readonly property bool monStart: Settings.weekStart === "Monday"
    readonly property var cities: Settings.worldClockCities
    readonly property var gridCells: Cal.buildGrid(now, viewY, viewM, hijriRef, hijri, monStart, selectedKey)
    readonly property bool hasSel: selectedKey !== ""
    readonly property var selDate: hasSel ? Cal.dateFromKey(selectedKey) : now

    function navMonth(dir) {
        var m = viewM + dir, y = viewY
        if (m < 0) { m = 11; y-- }
        if (m > 11) { m = 0; y++ }
        viewM = m; viewY = y
    }
    function prev() { if (hijri) hijriRef = Cal.navHijri(hijriRef, -1); else navMonth(-1) }
    function next() { if (hijri) hijriRef = Cal.navHijri(hijriRef, 1);  else navMonth(1) }
    function goToday() {
        viewY = now.getFullYear(); viewM = now.getMonth()
        hijriRef = now; selectedKey = ""
    }
    function toGreg() { hijri = false; viewY = hijriRef.getFullYear(); viewM = hijriRef.getMonth() }
    function toHijri() { hijri = true; hijriRef = now }
    function cityH12(c) { return h12[c.tz] !== undefined ? h12[c.tz] : c.h12 }
    function toggleCity(c) { var o = Object.assign({}, h12); o[c.tz] = !cityH12(c); h12 = o }

    Timer { interval: 1000; running: panel.visible; repeat: true; onTriggered: panel.now = new Date() }

    // World-clock UTC offsets (refreshed occasionally to catch DST changes).
    Process {
        id: tzProc
        function rebuild() {
            var list = ""
            for (var i = 0; i < panel.cities.length; i++) list += " '" + panel.cities[i].tz + "'"
            command = ["sh", "-c",
                "for tz in" + list + "; do printf '%s=%s\\n' \"$tz\" \"$(TZ=$tz date +%z)\"; done"]
            running = true
        }
        stdout: SplitParser {
            onRead: line => {
                var i = line.lastIndexOf("=")
                if (i < 0) return
                var o = Object.assign({}, panel.offsets)
                o[line.slice(0, i)] = Cal.parseOffset(line.slice(i + 1).trim())
                panel.offsets = o
            }
        }
    }
    // Only refresh offsets while the panel is actually on screen; they are
    // rebuilt on every open anyway (cheap: one sh + date per city).
    Timer { interval: 600000; running: panel.visible; repeat: true; onTriggered: tzProc.rebuild() }
    onCitiesChanged: if (visible) tzProc.rebuild()

    // ── Window ───────────────────────────────────────────────────────────
    visible: false
    color: "transparent"

    readonly property real clockRightX: anchorItem
        ? anchorItem.x
          + (anchorItem.parent ? anchorItem.parent.x : 0)
          + (anchorItem.parent && anchorItem.parent.parent ? anchorItem.parent.parent.x : 0)
          + anchorItem.width
        : 0

    anchor.window: barWindow
    anchor.rect: barWindow
        ? Qt.rect(Math.max(6, clockRightX - panelWidth), 0, panelWidth, barWindow.implicitHeight)
        : Qt.rect(0, 0, 0, 0)
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    implicitWidth: panelWidth
    implicitHeight: contentH + topGap + 4

    Timer { id: closeTimer; interval: 240; onTriggered: panel.visible = false }
    onOpenChanged: {
        if (open) {
            closeTimer.stop()
            visible = true
            Notifications.markAllRead()
            now = new Date()
            tzProc.rebuild()
        } else {
            closeTimer.start()
        }
    }

    // ── Reusable chip ────────────────────────────────────────────────────
    component ToggleChip: Rectangle {
        property string label
        property bool active: false
        property bool hoverAccent: true
        property int fontPx: 11
        property color inactiveColor: C.overlay1
        signal clicked()
        readonly property bool _hot: hoverAccent && chipMa.containsMouse
        implicitHeight: fontPx + 10
        implicitWidth: chipTxt.implicitWidth + 20
        radius: 6
        color: active ? panel.accentA(0.10) : "transparent"
        border.width: 1
        border.color: active ? panel.accent : (_hot ? panel.accent : C.surface0)
        Behavior on border.color { ColorAnimation { duration: 120 } }
        Text {
            id: chipTxt
            anchors.centerIn: parent
            text: parent.label
            font.family: Settings.fontFamily
            font.pixelSize: parent.fontPx
            color: parent.active ? panel.accent : (parent._hot ? panel.accent : parent.inactiveColor)
        }
        MouseArea {
            id: chipMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    // ── Content (clipped slide-in) ───────────────────────────────────────
    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: slide
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height - panel.topGap
            y: panel.open ? panel.topGap : -height
            opacity: panel.open ? 1 : 0
            Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.fill: parent
                color: C.base
                border.color: C.surface0
                border.width: 1
                radius: 10

                Row {
                    anchors.fill: parent
                    anchors.margins: panel.pad
                    spacing: panel.gap

                    // ════════ LEFT COLUMN ════════
                    Column {
                        id: leftColumn
                        width: panel.leftW
                        spacing: 13

                        // ── Calendar block ──
                        Column {
                            width: parent.width
                            spacing: 9

                            // Header: prev / month / next
                            Item {
                                width: parent.width
                                height: 22
                                Rectangle {
                                    id: prevBtn
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 26; height: 22; radius: 6
                                    color: prevMa.containsMouse ? C.surface0 : "transparent"
                                    Text { anchors.centerIn: parent; text: "◂"; color: prevMa.containsMouse ? C.text : C.subtext0; font.family: Settings.fontFamily; font.pixelSize: 13 }
                                    MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panel.prev() }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: Cal.monthLabel(panel.viewY, panel.viewM, panel.hijriRef, panel.hijri)
                                    color: C.text
                                    font.family: Settings.fontFamily
                                    font.pixelSize: 15
                                }
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 26; height: 22; radius: 6
                                    color: nextMa.containsMouse ? C.surface0 : "transparent"
                                    Text { anchors.centerIn: parent; text: "▸"; color: nextMa.containsMouse ? C.text : C.subtext0; font.family: Settings.fontFamily; font.pixelSize: 13 }
                                    MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panel.next() }
                                }
                            }

                            // Controls: GREG / HIJRI + TODAY
                            Item {
                                width: parent.width
                                height: 22
                                Row {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 6
                                    ToggleChip { label: "GREG";  active: !panel.hijri; hoverAccent: false; onClicked: panel.toGreg() }
                                    ToggleChip { label: "HIJRI"; active: panel.hijri;  hoverAccent: false; onClicked: panel.toHijri() }
                                }
                                ToggleChip {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    label: "TODAY"; active: false; inactiveColor: C.subtext0
                                    onClicked: panel.goToday()
                                }
                            }

                            // Weekday header
                            Row {
                                width: parent.width
                                spacing: 3
                                Repeater {
                                    model: Cal.weekdayHeaders(panel.monStart)
                                    delegate: Text {
                                        required property var modelData
                                        width: panel.cellW
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData
                                        color: C.overlay0
                                        font.family: Settings.fontFamily
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            // Day grid 7×6
                            Grid {
                                width: parent.width
                                columns: 7
                                spacing: 3
                                Repeater {
                                    model: panel.gridCells
                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property bool sel: modelData.isSel
                                        readonly property bool today: modelData.isToday && !sel
                                        width: panel.cellW
                                        height: 30
                                        radius: 7
                                        border.width: 1
                                        color: sel ? panel.accent
                                             : today ? panel.accentA(0.09)
                                             : (dayMa.containsMouse ? C.surface0 : "transparent")
                                        border.color: sel ? panel.accent
                                                    : today ? panel.accent
                                                    : (dayMa.containsMouse ? C.surface1 : "transparent")
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Behavior on border.color { ColorAnimation { duration: 120 } }
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.num
                                            font.family: Settings.fontFamily
                                            font.pixelSize: 13
                                            color: sel ? C.crust
                                                 : today ? panel.accent
                                                 : (modelData.inMonth ? (dayMa.containsMouse ? C.text : C.text) : C.surface1)
                                        }
                                        MouseArea {
                                            id: dayMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: panel.selectedKey = modelData.key
                                        }
                                    }
                                }
                            }

                            // Readout box
                            Rectangle {
                                width: parent.width
                                height: 46
                                radius: 8
                                color: C.mantle
                                border.color: C.surface0
                                border.width: 1
                                Item {
                                    anchors.fill: parent
                                    anchors.leftMargin: 11
                                    anchors.rightMargin: 11
                                    Column {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.right: relTxt.left
                                        anchors.rightMargin: 10
                                        spacing: 3
                                        Text {
                                            text: panel.hasSel ? "SELECTED" : "TODAY"
                                            color: C.overlay0
                                            font.family: Settings.fontFamily
                                            font.pixelSize: 10
                                            font.letterSpacing: 1.4
                                        }
                                        Text {
                                            width: parent.width
                                            text: Cal.formatFull(panel.selDate, panel.hijri)
                                            color: C.text
                                            font.family: Settings.fontFamily
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                        }
                                    }
                                    Text {
                                        id: relTxt
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: panel.hasSel ? Cal.relative(panel.now, panel.selDate) : "Today"
                                        color: panel.accent
                                        font.family: Settings.fontFamily
                                        font.pixelSize: 15
                                    }
                                }
                            }
                        }

                        // Divider
                        Rectangle { width: parent.width; height: 1; color: C.surface0 }

                        // ── World clocks ──
                        Column {
                            width: parent.width
                            spacing: 8
                            Row {
                                spacing: 8
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "WORLD CLOCKS"
                                    color: C.overlay1
                                    font.family: Settings.fontFamily
                                    font.pixelSize: 10
                                    font.letterSpacing: 1.8
                                }
                                ToggleChip {
                                    anchors.verticalCenter: parent.verticalCenter
                                    label: "SEC"; fontPx: 10; active: panel.secOn
                                    inactiveColor: C.overlay0
                                    onClicked: panel.secOn = !panel.secOn
                                }
                            }
                            Item {
                                id: clocksContainer
                                width: parent.width
                                readonly property int rowH: 72
                                readonly property int rows: Math.ceil(panel.cities.length / 2)
                                readonly property int fullH: rows * rowH + Math.max(0, rows - 1) * 8
                                height: Math.min(fullH, 2 * rowH + 8)
                                clip: true

                                Flickable {
                                    id: clocksFlick
                                    anchors.fill: parent
                                    contentWidth: width
                                    contentHeight: clocksContainer.fullH
                                    boundsBehavior: Flickable.StopAtBounds

                                    Grid {
                                        width: parent.width
                                        columns: 2
                                        rowSpacing: 8
                                        columnSpacing: 8
                                        Repeater {
                                            model: panel.cities
                                            delegate: Rectangle {
                                                id: ckCard
                                                required property var modelData
                                                readonly property bool is12: panel.cityH12(modelData)
                                                readonly property var off: panel.offsets[modelData.tz]
                                                width: (panel.leftW - 8) / 2
                                                height: 72
                                                radius: 8
                                                color: C.mantle
                                                border.width: 1
                                                border.color: ckMa.containsMouse ? panel.accent : C.surface0
                                                Behavior on border.color { ColorAnimation { duration: 120 } }
                                                Column {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 10
                                                    anchors.rightMargin: 10
                                                    anchors.topMargin: 9
                                                    spacing: 3
                                                    Item {
                                                        width: parent.width
                                                        height: 14
                                                        Text {
                                                            anchors.left: parent.left
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: modelData.label
                                                            color: C.subtext1
                                                            font.family: Settings.fontFamily
                                                            font.pixelSize: 11
                                                        }
                                                        Rectangle {
                                                            anchors.right: parent.right
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            width: tagTxt.implicitWidth + 8
                                                            height: 14
                                                            radius: 4
                                                            color: "transparent"
                                                            border.color: C.surface0
                                                            border.width: 1
                                                            Text {
                                                                id: tagTxt
                                                                anchors.centerIn: parent
                                                                text: ckCard.is12 ? "12H" : "24H"
                                                                color: C.overlay0
                                                                font.family: Settings.fontFamily
                                                                font.pixelSize: 9
                                                            }
                                                        }
                                                    }
                                                    Text {
                                                        text: off !== undefined ? Cal.fmtClock(panel.now, off, is12, panel.secOn) : "··:··"
                                                        color: C.text
                                                        font.family: Settings.fontFamily
                                                        font.pixelSize: 18
                                                    }
                                                    Text {
                                                        text: off !== undefined ? Cal.clockWeekday(panel.now, off) : ""
                                                        color: C.overlay0
                                                        font.family: Settings.fontFamily
                                                        font.pixelSize: 10
                                                    }
                                                }
                                                MouseArea {
                                                    id: ckMa
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: panel.toggleCity(modelData)
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: clocksContainer.fullH > clocksContainer.height
                                    anchors.right: parent.right
                                    anchors.rightMargin: 1
                                    y: clocksFlick.visibleArea.yPosition * clocksContainer.height
                                    width: 2
                                    height: clocksFlick.visibleArea.heightRatio * clocksContainer.height
                                    radius: 1
                                    color: C.overlay0
                                    opacity: 0.6
                                }
                            }
                        }
                    }

                    // Vertical divider
                    Rectangle { width: 1; height: leftColumn.implicitHeight; color: C.surface0 }

                    // ════════ RIGHT COLUMN — notifications ════════
                    Column {
                        width: panel.rightW
                        height: leftColumn.implicitHeight
                        spacing: 8

                        Item {
                            width: parent.width
                            height: 22
                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "NOTIFICATIONS"
                                    color: C.overlay1
                                    font.family: Settings.fontFamily
                                    font.pixelSize: 10
                                    font.letterSpacing: 1.8
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: cntTxt.implicitWidth + 14
                                    height: 16
                                    radius: 10
                                    color: panel.accentA(0.12)
                                    Text {
                                        id: cntTxt
                                        anchors.centerIn: parent
                                        text: Notifications.history.length
                                        color: panel.accent
                                        font.family: Settings.fontFamily
                                        font.pixelSize: 10
                                    }
                                }
                            }
                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8
                                ToggleChip {
                                    anchors.verticalCenter: parent.verticalCenter
                                    label: "DND"; fontPx: 10; active: Notifications.dnd
                                    inactiveColor: C.overlay0
                                    onClicked: Notifications.toggleDnd()
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "CLEAR ALL"
                                    color: clearMa.containsMouse ? panel.accent : C.overlay0
                                    font.family: Settings.fontFamily
                                    font.pixelSize: 10
                                    font.letterSpacing: 0.8
                                    MouseArea {
                                        id: clearMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Notifications.clearAll()
                                    }
                                }
                            }
                        }

                        // Scrollable list
                        ListView {
                            id: notifList
                            width: parent.width
                            visible: Notifications.history.length > 0
                            height: visible ? Math.min(leftColumn.implicitHeight - 30, 474) : 0
                            clip: true
                            spacing: 8
                            boundsBehavior: Flickable.StopAtBounds
                            model: Notifications.history

                            delegate: Rectangle {
                                id: card
                                required property var modelData
                                readonly property string iconSrc: {
                                    var ai = modelData.appIcon || ""
                                    if (ai === "") return ""
                                    return ai.indexOf("/") >= 0 ? ai : Quickshell.iconPath(ai, true)
                                }
                                readonly property bool urgent: (modelData.urgency || 0) >= 2
                                readonly property color red: C.red
                                // Hover expands the card to show the full (wrapped)
                                // summary/body instead of one elided line.
                                readonly property bool expanded: cardMa.containsMouse

                                width: notifList.width
                                height: expanded ? Math.max(58, textCol.implicitHeight + 18) : 58
                                Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                clip: true
                                radius: 8
                                color: C.mantle
                                border.width: 1
                                border.color: card.urgent ? red : (cardMa.containsMouse ? C.surface1 : C.surface0)
                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                MouseArea { id: cardMa; anchors.fill: parent; hoverEnabled: true }

                                // Icon tile
                                Rectangle {
                                    id: tile
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 32; height: 32; radius: 7
                                    color: C.surface0
                                    Image {
                                        anchors.centerIn: parent
                                        width: 18; height: 18
                                        visible: card.iconSrc !== ""
                                        source: card.iconSrc
                                        smooth: true; mipmap: true
                                        sourceSize.width: 36; sourceSize.height: 36
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        visible: card.iconSrc === ""
                                        text: Notifications.letterFor(modelData.app)
                                        color: Notifications.tintFor(modelData.app)
                                        font.family: Settings.fontFamily
                                        font.pixelSize: 14
                                    }
                                }

                                // Text block
                                Column {
                                    id: textCol
                                    anchors.left: tile.right
                                    anchors.leftMargin: 10
                                    anchors.right: parent.right
                                    anchors.rightMargin: 24
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    Item {
                                        width: parent.width
                                        height: 13
                                        Text {
                                            anchors.left: parent.left
                                            text: modelData.app
                                            color: C.subtext0
                                            font.family: Settings.fontFamily
                                            font.pixelSize: 11
                                        }
                                        Text {
                                            anchors.right: parent.right
                                            text: Notifications.relTimeOf(modelData.time, panel.now.getTime())
                                            color: C.overlay0
                                            font.family: Settings.fontFamily
                                            font.pixelSize: 10
                                        }
                                    }
                                    // maximumLineCount: 1 also swallows embedded \n in
                                    // notification bodies, which used to overflow the card.
                                    Text {
                                        width: parent.width
                                        text: modelData.summary || ""
                                        color: C.text
                                        font.family: Settings.fontFamily
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        wrapMode: Text.Wrap
                                        maximumLineCount: card.expanded ? 10 : 1
                                    }
                                    Text {
                                        width: parent.width
                                        visible: (modelData.body || "") !== ""
                                        text: modelData.body || ""
                                        color: C.overlay1
                                        font.family: Settings.fontFamily
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        wrapMode: Text.Wrap
                                        maximumLineCount: card.expanded ? 30 : 1
                                    }
                                }

                                // Dismiss ×
                                Text {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.topMargin: 7
                                    anchors.rightMargin: 9
                                    text: "×"
                                    color: xMa.containsMouse ? panel.accent : C.overlay0
                                    font.family: Settings.fontFamily
                                    font.pixelSize: 14
                                    MouseArea {
                                        id: xMa
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Notifications.dismissFromHistory(modelData.key)
                                    }
                                }
                            }
                        }

                        // Empty state
                        Item {
                            width: parent.width
                            height: Math.min(leftColumn.implicitHeight - 30, 474)
                            visible: Notifications.history.length === 0
                            Text {
                                anchors.centerIn: parent
                                text: "All caught up ✓"
                                color: C.overlay0
                                font.family: Settings.fontFamily
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }
        }
    }
}
