import Quickshell
import QtQuick
import "Colors.js" as C

Item {
    id: root
    implicitWidth: row.implicitWidth + 16
    implicitHeight: 24

    property var barWindow
    readonly property var now: sysClock.date

    // The bar only shows hh:mm — minute precision wakes up 60x less often
    // than the old 1-second Timer.
    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    function fmtTime(d, force24) {
        var h = d.getHours(), m = d.getMinutes()
        if (Settings.clock24h || force24)
            return (h < 10 ? "0" + h : h) + ":" + (m < 10 ? "0" + m : m)
        var ampm = h >= 12 ? "PM" : "AM"
        h = h % 12 || 12
        return (h < 10 ? "0" + h : h) + ":" + (m < 10 ? "0" + m : m) + " " + ampm
    }

    function fmtDate(d) {
        var days   = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        var months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        var day = d.getDate()
        return days[d.getDay()] + " " + months[d.getMonth()] + " " + (day < 10 ? "0" + day : day)
    }

    function fmtDateNumeric(d) {
        return d.getDate() + "/" + (d.getMonth() + 1) + "/" + d.getFullYear()
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: panel.open = !panel.open
    }

    // Accent underline when the dropdown is open (DWM-style highlight)
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
        color: C.accent
        visible: panel.open
    }

    CalendarPanel {
        id: panel
        barWindow: root.barWindow
        anchorItem: root
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Item {
            implicitWidth: Math.max(time12.implicitWidth, time24.implicitWidth)
            implicitHeight: 24

            Text {
                id: time12
                anchors.centerIn: parent
                visible: !ma.containsMouse
                text: root.fmtTime(root.now, false)
                font.family: Settings.fontFamily
                font.pixelSize: Settings.fontSize
                color: C.subtext1
            }

            Text {
                id: time24
                anchors.centerIn: parent
                visible: ma.containsMouse
                text: root.fmtTime(root.now, true)
                font.family: Settings.fontFamily
                font.pixelSize: Settings.fontSize
                color: C.text
            }
        }

        // Fixed-width date slot — both texts are always laid out so the
        // wider one always determines the width, preventing any shifting.
        Item {
            implicitWidth: Math.max(dateLong.implicitWidth, dateShort.implicitWidth)
            implicitHeight: 24

            Text {
                id: dateLong
                anchors.centerIn: parent
                visible: !ma.containsMouse
                text: root.fmtDate(root.now)
                font.family: Settings.fontFamily
                font.pixelSize: Settings.fontSize
                color: C.subtext1
            }

            Text {
                id: dateShort
                anchors.centerIn: parent
                visible: ma.containsMouse
                text: root.fmtDateNumeric(root.now)
                font.family: Settings.fontFamily
                font.pixelSize: Settings.fontSize
                color: C.text
            }
        }
    }
}
