import QtQuick
import "Colors.js" as C

// One "tool" hosted inside ToolsPanel. A simple 24-hour <-> 12-hour time
// converter — both fields are live-linked to the same canonical time-of-day,
// so editing either one updates the other immediately.
Item {
    id: root
    width: parent ? parent.width : 300
    implicitHeight: col.implicitHeight

    property int totalMinutes: {
        var d = new Date()
        return d.getHours() * 60 + d.getMinutes()
    }

    readonly property int hour24: Math.floor(totalMinutes / 60) % 24
    readonly property int minute: totalMinutes % 60
    readonly property bool isPM: hour24 >= 12
    readonly property int hour12: { var h = hour24 % 12; return h === 0 ? 12 : h }

    readonly property color accentColor: C.accent

    function pad2(n) { return n < 10 ? "0" + n : String(n) }
    function fmt24() { return pad2(hour24) + ":" + pad2(minute) }
    function fmt12() { return hour12 + ":" + pad2(minute) }

    function combine12(h12, mi, pm) {
        var h = h12 % 12
        if (pm) h += 12
        return h * 60 + mi
    }

    // Parses "H:MM" / "HH:MM" with hour in [minH, maxH]; null if invalid.
    function parseHM(text, minH, maxH) {
        var m = /^\s*(\d{1,2})\s*:\s*(\d{1,2})\s*$/.exec(text)
        if (!m) return null
        var h = parseInt(m[1], 10), mi = parseInt(m[2], 10)
        if (isNaN(h) || isNaN(mi) || mi < 0 || mi > 59 || h < minH || h > maxH) return null
        return { h: h, m: mi }
    }

    component FieldLabel: Text {
        color: C.overlay1
        font.family: Settings.fontFamily
        font.pixelSize: 10
        font.letterSpacing: 1.4
    }

    property bool flipped: false

    component Block24: Column {
        width: parent.width
        spacing: 4
        FieldLabel { text: "24-HOUR" }
        Rectangle {
            width: parent.width
            height: 34
            radius: 8
            color: C.mantle
            border.width: 1
            border.color: h24Input.activeFocus ? root.accentColor : C.surface0
            Behavior on border.color { ColorAnimation { duration: 120 } }
            TextInput {
                id: h24Input
                anchors.fill: parent
                anchors.margins: 10
                verticalAlignment: TextInput.AlignVCenter
                text: root.fmt24()
                color: C.text
                font.family: Settings.fontFamily
                font.pixelSize: Settings.fontSize
                selectByMouse: true
                onTextChanged: {
                    var r = root.parseHM(text, 0, 23)
                    if (r) root.totalMinutes = r.h * 60 + r.m
                }
            }
        }
    }

    component Block12: Column {
        width: parent.width
        spacing: 4
        FieldLabel { text: "12-HOUR" }
        Row {
            width: parent.width
            spacing: 8
            Rectangle {
                width: parent.width - meridiem.width - 8
                height: 34
                radius: 8
                color: C.mantle
                border.width: 1
                border.color: h12Input.activeFocus ? root.accentColor : C.surface0
                Behavior on border.color { ColorAnimation { duration: 120 } }
                TextInput {
                    id: h12Input
                    anchors.fill: parent
                    anchors.margins: 10
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.fmt12()
                    color: C.text
                    font.family: Settings.fontFamily
                    font.pixelSize: Settings.fontSize
                    selectByMouse: true
                    onTextChanged: {
                        var r = root.parseHM(text, 1, 12)
                        if (r) root.totalMinutes = root.combine12(r.h, r.m, root.isPM)
                    }
                }
            }
            MeridiemChip { id: meridiem }
        }
    }

    component MeridiemChip: Rectangle {
        implicitWidth: 54
        implicitHeight: 34
        radius: 8
        color: C.mantle
        border.width: 1
        border.color: chipMa.containsMouse ? root.accentColor : C.surface0
        Behavior on border.color { ColorAnimation { duration: 120 } }
        Text {
            anchors.centerIn: parent
            text: root.isPM ? "PM" : "AM"
            color: root.accentColor
            font.bold: true
            font.family: Settings.fontFamily
            font.pixelSize: Settings.fontSize
        }
        MouseArea {
            id: chipMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.totalMinutes = root.combine12(root.hour12, root.minute, !root.isPM)
        }
    }

    Component { id: block24Comp; Block24 {} }
    Component { id: block12Comp; Block12 {} }

    Column {
        id: col
        width: parent.width
        spacing: 10

        Loader { width: parent.width; sourceComponent: root.flipped ? block12Comp : block24Comp }

        // Swap — flips which field (24h/12h) is on top.
        Item {
            width: parent.width
            height: 28
            Rectangle {
                anchors.centerIn: parent
                width: 28; height: 28; radius: 14
                color: "transparent"
                border.width: 1
                border.color: swapMa.containsMouse ? root.accentColor : C.surface0
                Behavior on border.color { ColorAnimation { duration: 120 } }
                Text {
                    anchors.centerIn: parent
                    text: "⇅"
                    color: swapMa.containsMouse ? root.accentColor : C.subtext0
                    font.pixelSize: 13
                }
                MouseArea {
                    id: swapMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.flipped = !root.flipped
                }
            }
        }

        Loader { width: parent.width; sourceComponent: root.flipped ? block24Comp : block12Comp }
    }
}
