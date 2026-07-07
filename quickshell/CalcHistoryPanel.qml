import QtQuick
import "Colors.js" as C

// Side panel listing CalcHistory entries, opened next to the Calculator tool
// in ToolsPanel. Click a row to recall it back into the calculator, "×" to
// delete one entry, "Clear" to wipe everything.
Rectangle {
    id: root
    signal recall(var entry)

    readonly property int pad: 14

    color: C.base
    border.color: C.surface0
    border.width: 1
    radius: 10
    implicitHeight: content.implicitHeight + 2 * pad

    component HistoryRow: Rectangle {
        id: hrow
        required property var entry
        signal recall()
        signal remove()
        width: parent.width
        height: 40
        radius: 8
        color: rowMa.containsMouse ? C.surface0 : "transparent"

        MouseArea {
            id: rowMa
            anchors.fill: parent
            anchors.rightMargin: 28
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: hrow.recall()
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: delBtn.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Text {
                width: parent.width
                text: hrow.entry.expr
                color: C.overlay1
                font.family: Settings.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: hrow.entry.result
                color: C.text
                font.family: Settings.fontFamily
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
            }
        }

        Text {
            id: delBtn
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "×"
            color: delMa.containsMouse ? C.red : C.overlay0
            font.pixelSize: 14
            MouseArea {
                id: delMa
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: hrow.remove()
            }
        }
    }

    Column {
        id: content
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: 8

        Item {
            width: parent.width
            height: 16
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "RECENT"
                color: C.overlay1
                font.family: Settings.fontFamily
                font.pixelSize: 10
                font.letterSpacing: 1.4
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: CalcHistory.entries.length > 0
                text: "Clear"
                color: clearMa.containsMouse ? C.red : C.overlay0
                font.family: Settings.fontFamily
                font.pixelSize: 10
                MouseArea {
                    id: clearMa
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: CalcHistory.clear()
                }
            }
        }

        Text {
            visible: CalcHistory.entries.length === 0
            text: "No calculations yet"
            color: C.overlay0
            font.family: Settings.fontFamily
            font.pixelSize: 11
        }

        ListView {
            width: parent.width
            height: Math.min(CalcHistory.entries.length, 8) * 40
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: CalcHistory.entries
            delegate: HistoryRow {
                required property var modelData
                required property int index
                entry: modelData
                onRecall: root.recall(modelData)
                onRemove: CalcHistory.removeEntry(index)
            }
        }
    }
}
