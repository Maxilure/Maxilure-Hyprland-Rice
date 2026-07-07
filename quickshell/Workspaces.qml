import Quickshell.Hyprland
import QtQuick
import "Colors.js" as C

Row {
    id: root
    spacing: 0

    Repeater {
        model: Settings.workspaceCount

        delegate: Item {
            id: btn
            readonly property int wsId: index + 1

            // Focused workspace on this monitor
            readonly property bool isActive: (Hyprland.focusedWorkspace?.id ?? -1) === wsId

            // Workspace exists in Hyprland's list → it has windows (or is special)
            readonly property bool isOccupied: {
                var list = Hyprland.workspaces.values
                for (var i = 0; i < list.length; i++) {
                    if (list[i].id === wsId) return true
                }
                return false
            }

            visible: isActive || isOccupied
            width: visible ? lbl.implicitWidth + 8 : 0
            height: 24

            Behavior on width { NumberAnimation { duration: 80 } }

            Text {
                id: lbl
                anchors.centerIn: parent
                text: btn.wsId
                font.family: Settings.fontFamily
                font.pixelSize: Settings.fontSize
                font.bold: btn.isActive
                color: btn.isActive   ? C.accent
                     : btn.isOccupied ? C.overlay2
                     : C.overlay0
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var list = Hyprland.workspaces.values
                    for (var i = 0; i < list.length; i++) {
                        if (list[i].id === btn.wsId) {
                            list[i].activate()
                            return
                        }
                    }
                }
            }
        }
    }
}
