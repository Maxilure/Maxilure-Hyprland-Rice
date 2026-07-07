import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import "Colors.js" as C

Item {
    id: root
    width: 18
    height: 24

    property var barWindow
    property bool popupOpen: false

    // Menu page stack: [{handle: QsMenuHandle, title: string}]
    property var menuStack: []
    readonly property bool inMenu: menuStack.length > 0
    readonly property var currentHandle: inMenu ? menuStack[menuStack.length - 1].handle : null
    readonly property string currentTitle: inMenu ? menuStack[menuStack.length - 1].title : ""

    function openMenu(trayItem) {
        menuStack = [{handle: trayItem.menu, title: trayItem.title || ""}]
    }
    function pushMenu(entry, title) {
        menuStack = menuStack.concat([{handle: entry, title: title}])
    }
    function popMenu() {
        if (menuStack.length <= 1) menuStack = []
        else menuStack = menuStack.slice(0, -1)
    }
    function closeAll() {
        menuStack = []
        popupOpen = false
    }

    readonly property real trayBarX: root.x
        + (root.parent ? root.parent.x : 0)
        + (root.parent && root.parent.parent ? root.parent.parent.x : 0)

    // One opener per depth level. Each opener stays bound to its level's handle so
    // its children (QsMenuEntry objects) stay alive while the next level is shown.
    // This means deeper levels can safely hold references to entries from shallower ones.
    QsMenuOpener {
        id: opener0
        menu: root.menuStack.length > 0 ? root.menuStack[0].handle : null
    }
    QsMenuOpener {
        id: opener1
        menu: root.menuStack.length > 1 ? root.menuStack[1].handle : null
    }
    QsMenuOpener {
        id: opener2
        menu: root.menuStack.length > 2 ? root.menuStack[2].handle : null
    }
    readonly property var activeChildren: {
        if (root.menuStack.length >= 3) return opener2.children
        if (root.menuStack.length >= 2) return opener1.children
        if (root.menuStack.length >= 1) return opener0.children
        return null
    }

    Timer {
        id: closeTimer
        interval: 220
        onTriggered: popup.visible = false
    }

    onPopupOpenChanged: {
        if (popupOpen) {
            closeTimer.stop()
            popup.visible = true
        } else {
            menuStack = []
            closeTimer.start()
        }
    }

    PopupWindow {
        id: popup
        visible: false
        color: "transparent"

        anchor.window: root.barWindow
        anchor.rect: root.barWindow
            ? Qt.rect(root.trayBarX, 0, root.width, root.barWindow.implicitHeight)
            : Qt.rect(0, 0, 0, 0)
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Behavior on implicitWidth  { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on implicitHeight { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        implicitWidth: root.inMenu ? 210 : trayGrid.implicitWidth + 12
        implicitHeight: root.inMenu
            ? menuCol.implicitHeight + 12 + 6
            : trayGrid.implicitHeight + 12 + 6


        Item {
            anchors.fill: parent
            clip: true

            Item {
                id: slideContent
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height - 6
                y: root.popupOpen ? 6 : -height
                opacity: root.popupOpen ? 1 : 0

                Behavior on y       { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    color: C.mantle
                    border.color: C.surface1
                    border.width: 1
                    radius: 6
                    clip: true

                    // ── Icon grid ─────────────────────────────────
                    Grid {
                        id: trayGrid
                        anchors.centerIn: parent
                        visible: !root.inMenu
                        columns: 3
                        spacing: 2

                        Repeater {
                            model: SystemTray.items
                            delegate: Item {
                                required property var modelData
                                width: 22; height: 22

                                Rectangle {
                                    anchors.fill: parent
                                    color: iconMa.containsMouse ? C.surface0 : "transparent"
                                    radius: 3
                                }
                                Image {
                                    anchors.centerIn: parent
                                    source: modelData.icon
                                    width: 14; height: 14
                                    smooth: true; mipmap: true
                                }
                                MouseArea {
                                    id: iconMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.LeftButton) {
                                            modelData.activate()
                                            root.popupOpen = false
                                        } else if (mouse.button === Qt.RightButton) {
                                            if (modelData.hasMenu)
                                                root.openMenu(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Menu page ──────────────────────────────────
                    Column {
                        id: menuCol
                        visible: root.inMenu
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 4
                        spacing: 0

                        // Header row: back arrow + title
                        Item {
                            width: parent.width
                            height: 26

                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 22; height: 22; radius: 3
                                color: backMa.containsMouse ? C.surface0 : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "←"
                                    color: C.text
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    id: backMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.popMenu()
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: root.currentTitle
                                color: C.subtext0
                                font.pixelSize: 11
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width - 52
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        // Divider
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: C.surface0
                        }

                        // Scrollable menu items + fade indicators
                        Item {
                            width: parent.width
                            height: menuFlick.height

                        Flickable {
                            id: menuFlick
                            width: parent.width
                            height: Math.min(menuItemsCol.implicitHeight, 260)
                            contentHeight: menuItemsCol.implicitHeight
                            clip: true
                            boundsMovement: Flickable.StopAtBounds

                            Column {
                                id: menuItemsCol
                                width: parent.width
                                spacing: 0

                                Repeater {
                                    model: root.activeChildren

                                    delegate: Item {
                                        required property var modelData
                                        width: menuItemsCol.width

                                        readonly property bool hasSub: modelData.hasChildren
                                        readonly property bool isSep: modelData.isSeparator

                                        height: isSep ? 9 : 26

                                        Rectangle {
                                            visible: isSep
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.leftMargin: 6; anchors.rightMargin: 6
                                            height: 1
                                            color: C.surface1
                                        }

                                        Rectangle {
                                            visible: !isSep
                                            anchors.fill: parent
                                            anchors.margins: 2
                                            radius: 3
                                            color: rowMa.containsMouse && modelData.enabled
                                                ? C.surface0 : "transparent"

                                            Text {
                                                id: rowLabel
                                                anchors.left: parent.left
                                                anchors.leftMargin: 8
                                                anchors.right: rowArrow.visible ? rowArrow.left : parent.right
                                                anchors.rightMargin: 8
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData.text
                                                color: modelData.enabled ? C.text : C.overlay0
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                id: rowArrow
                                                visible: hasSub
                                                anchors.right: parent.right
                                                anchors.rightMargin: 8
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "▶"
                                                color: C.overlay1
                                                font.pixelSize: 8
                                            }

                                            MouseArea {
                                                id: rowMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: modelData.enabled
                                                    ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                onClicked: {
                                                    if (!modelData.enabled) return
                                                    if (hasSub) {
                                                        root.pushMenu(modelData, modelData.text)
                                                    } else {
                                                        // Emitting QsMenuEntry.triggered() sends the
                                                        // DBus activation (connected internally to
                                                        // DBusMenuItem::sendTriggered).
                                                        modelData.triggered()
                                                        root.closeAll()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Top fade — visible when scrolled down
                        Rectangle {
                            anchors.top: menuFlick.top
                            anchors.left: menuFlick.left
                            anchors.right: menuFlick.right
                            height: 20
                            opacity: menuFlick.contentY > 1 ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: C.mantle }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        // Bottom fade — visible when more content below
                        Rectangle {
                            anchors.bottom: menuFlick.bottom
                            anchors.left: menuFlick.left
                            anchors.right: menuFlick.right
                            height: 20
                            opacity: menuFlick.contentY + menuFlick.height < menuFlick.contentHeight - 1 ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: C.mantle }
                            }
                        }
                        }
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.popupOpen ? "▲" : "▼"
        font.family: Settings.fontFamily
        font.pixelSize: 10
        color: arrowMa.containsMouse ? C.text : C.overlay0
    }

    MouseArea {
        id: arrowMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.popupOpen = !root.popupOpen
    }
}
