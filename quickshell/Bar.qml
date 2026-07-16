import Quickshell
import QtQuick
import "Colors.js" as C

PanelWindow {
    id: root

    anchors { top: true; left: true; right: true }
    implicitHeight: Settings.barHeight
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: C.base

        // Bottom border (DWM style)
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: C.surface0
        }

        // Left: workspace tags
        Workspaces {
            anchors.left: parent.left
            anchors.leftMargin: Settings.wsLeftPadding
            anchors.verticalCenter: parent.verticalCenter
        }

        // Center: active window title
        WindowTitle {
            anchors.centerIn: parent
        }

        // Right: tray + clock
        Row {
            anchors.right: parent.right
            anchors.rightMargin: Settings.barRightPadding
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Tray { barWindow: root }
            Clock { barWindow: root }

            Item {
                implicitWidth: 14
                implicitHeight: parent.height
                Rectangle {
                    id: notifDot
                    anchors.centerIn: parent
                    width: 6; height: 6; radius: 3
                    color: Notifications.hasUrgentUnread ? C.red
                         : (Notifications.unreadKeys.length > 0 ? C.accent : C.surface1)

                    property real breathe: 0
                    SequentialAnimation on breathe {
                        running: Notifications.hasUrgentUnread
                        loops: Animation.Infinite
                        NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0; duration: 900; easing.type: Easing.InOutSine }
                    }
                    opacity: Notifications.hasUrgentUnread ? (0.35 + breathe * 0.65) : 1
                }
            }
        }
    }
}
