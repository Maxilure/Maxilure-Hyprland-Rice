import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "Colors.js" as C

Item {
    id: root

    property var barWindow

    readonly property string title: Hyprland.activeToplevel?.title ?? ""
    property string cls: ""

    // Seed class for windows already open at startup
    Component.onCompleted: _init.running = true

    Process {
        id: _init
        command: ["hyprctl", "activewindow", "-j"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    var d = JSON.parse(line.trim())
                    if (d["class"]) root.cls = d["class"]
                } catch(e) {}
            }
        }
    }

    // Update class for new windows via raw IPC event
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activewindow") {
                var comma = event.data.indexOf(",")
                root.cls = comma > 0 ? event.data.substring(0, comma) : ""
            }
        }
    }

    implicitWidth:  Math.min(row.implicitWidth + 24, 560)
    implicitHeight: 24

    MouseArea {
        id: titleMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: toolsPanel.open = !toolsPanel.open
    }

    // Accent underline when the dropdown is open (DWM-style highlight)
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
        color: C.accent
        visible: toolsPanel.open
    }

    ToolsPanel {
        id: toolsPanel
        barWindow: root.barWindow
        anchorItem: root
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: cls !== ""
            text: cls
            font.family: Settings.fontFamily
            font.pixelSize: Settings.fontSize
            font.bold: true
            color: C.accent
        }

        Text {
            visible: cls !== "" && title !== ""
            text: "·"
            font.family: Settings.fontFamily
            font.pixelSize: Settings.fontSize
            color: C.surface2
        }

        Text {
            visible: title !== ""
            width: Math.min(implicitWidth, 360)
            text: title
            font.family: Settings.fontFamily
            font.pixelSize: Settings.fontSize
            color: C.subtext0
            elide: Text.ElideRight
        }
    }
}
