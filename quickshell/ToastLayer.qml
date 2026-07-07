import Quickshell
import QtQuick
import "Colors.js" as C

// Transient notification toasts, top-right of the screen. Instantiated once
// (in shell.qml), driven by the Notifications singleton.
PanelWindow {
    id: root

    // Fixed-size strip down the right edge: resizing the window itself every
    // animation frame leaves stale-buffer artifacts on Wayland (visible corner
    // remnants when a toast retracts). Toasts animate inside; input only lands
    // on the toast column thanks to the mask.
    anchors { top: true; right: true; bottom: true }
    margins.top: Settings.barHeight + 8
    margins.right: 14
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region { item: col }

    readonly property color accent: C.accent

    property var toasts: []
    property int idCounter: 0
    implicitWidth: 330
    visible: toasts.length > 0

    function addToast(n, histKey) {
        var ai = n.appIcon || ""
        var src = ai === "" ? "" : (ai.indexOf("/") >= 0 ? ai : Quickshell.iconPath(ai, true))
        var arr = toasts.slice()
        arr.push({
            key: ++idCounter,
            histKey: histKey || "",
            app: n.appName || "Notification",
            summary: n.summary || "",
            body: n.body || "",
            icon: src,
            urgent: (n.urgency || 0) >= 2
        })
        toasts = arr
    }
    function removeToast(key) {
        toasts = toasts.filter(function(t) { return t.key !== key })
    }

    Connections {
        target: Notifications
        function onToastRequested(n, histKey) { root.addToast(n, histKey) }
    }

    Column {
        id: col
        width: parent.width
        spacing: 10

        Repeater {
            model: root.toasts
            delegate: Rectangle {
                id: toast
                required property var modelData
                property bool shown: false
                property real breathe: 0
                readonly property color red: C.red

                SequentialAnimation on breathe {
                    running: toast.modelData.urgent
                    loops: Animation.Infinite
                    NumberAnimation { to: 1; duration: 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0; duration: 1000; easing.type: Easing.InOutSine }
                }

                width: col.width
                implicitHeight: tcontent.implicitHeight + 24
                height: implicitHeight
                radius: 10
                clip: true
                Behavior on implicitHeight { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                color: C.base
                border.width: 1
                border.color: toast.modelData.urgent
                    ? Qt.rgba(red.r, red.g, red.b, 0.3 + breathe * 0.7)
                    : (tma.containsMouse ? C.surface2 : C.surface1)

                // Pop-in: opacity + translateX(20) + scale(.97)
                opacity: shown ? 1 : 0
                transform: [
                    Translate { x: toast.shown ? 0 : 20 },
                    Scale {
                        origin.x: toast.width / 2; origin.y: toast.height / 2
                        xScale: toast.shown ? 1 : 0.97; yScale: toast.shown ? 1 : 0.97
                    }
                ]
                Behavior on opacity { NumberAnimation { duration: 340; easing.type: Easing.Bezier; easing.bezierCurve: [0.2,0.85,0.25,1, 1,1] } }

                Component.onCompleted: shown = true

                MouseArea {
                    id: tma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Notifications.markRead(toast.modelData.histKey)
                        root.removeToast(toast.modelData.key)
                    }
                }

                Row {
                    id: tcontent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 11
                    spacing: 10

                    Rectangle {
                        width: 34; height: 34; radius: 8
                        color: C.surface0
                        Image {
                            anchors.centerIn: parent
                            width: 19; height: 19
                            visible: toast.modelData.icon !== ""
                            source: toast.modelData.icon
                            smooth: true; mipmap: true
                            sourceSize.width: 38; sourceSize.height: 38
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: toast.modelData.icon === ""
                            text: Notifications.letterFor(toast.modelData.app)
                            color: Notifications.tintFor(toast.modelData.app)
                            font.family: Settings.fontFamily
                            font.pixelSize: 15
                        }
                    }

                    Column {
                        width: parent.width - 34 - 10 - 4
                        spacing: 2
                        Text {
                            width: parent.width
                            text: toast.modelData.app
                            color: C.subtext0
                            font.family: Settings.fontFamily
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                        // Collapsed: one elided line (also swallows embedded \n,
                        // which plain elide does not). Hover: full wrapped text.
                        Text {
                            width: parent.width
                            text: toast.modelData.summary
                            color: C.text
                            font.family: Settings.fontFamily
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            wrapMode: Text.Wrap
                            maximumLineCount: tma.containsMouse ? 10 : 1
                        }
                        Text {
                            width: parent.width
                            visible: toast.modelData.body !== ""
                            text: toast.modelData.body
                            color: C.overlay1
                            font.family: Settings.fontFamily
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            wrapMode: Text.Wrap
                            maximumLineCount: tma.containsMouse ? 30 : 1
                        }
                    }
                }

                // Timeout bar (6s linear)
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 2
                    color: Qt.rgba(0.80, 0.84, 0.96, 0.06)
                    Rectangle {
                        id: barFill
                        height: parent.height
                        width: parent.width
                        color: root.accent
                        // Doubles as the dismiss timer — paused while hovered so
                        // long toasts can actually be read.
                        NumberAnimation on width {
                            to: 0; duration: 6000
                            paused: tma.containsMouse
                            onFinished: root.removeToast(toast.modelData.key)
                        }
                    }
                }
            }
        }
    }
}
