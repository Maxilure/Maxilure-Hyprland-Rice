import Quickshell
import Quickshell.Hyprland
import QtQuick
import "Colors.js" as C

// Dropdown panel that falls from the bar's center (WindowTitle). Shows a menu
// of small utility tools; picking one morphs into it (slide + height tween)
// with a Back button. Tool components are instantiated once and just moved
// off-screen (not destroyed/reloaded), so their state — last amount
// converted, last time entered, etc. — survives both navigating back to the
// menu and closing/reopening the whole panel.
PopupWindow {
    id: panel

    property var barWindow
    property var anchorItem       // the WindowTitle Item, for horizontal placement
    property bool open: false

    readonly property int panelWidth: 300
    readonly property int pad: 14
    readonly property int topGap: 10
    readonly property int contentH: content.implicitHeight + 2 * pad

    readonly property var tools: [
        { id: "currency", label: "Currency Converter" },
        { id: "time", label: "Clock Converter" },
        { id: "calculator", label: "Calculator" },
        { id: "settings", label: "Settings" }
    ]
    // Which screen is showing — "menu" or a tool id. Persists across
    // open/close since this property lives on the panel itself, which is
    // never destroyed (only hidden).
    property string view: "menu"
    // Currency converter opened as a side panel from the calculator's "$"
    // button, so it can be used without leaving the calculator screen.
    property bool calcCurrencyOpen: false

    // Fetch rates only when a currency view actually comes on screen.
    readonly property bool currencyShown: open && (view === "currency" || calcCurrencyOpen)
    onCurrencyShownChanged: if (currencyShown) Currency.ensureFresh()

    readonly property real titleCenterX: anchorItem
        ? anchorItem.x
          + (anchorItem.parent ? anchorItem.parent.x : 0)
          + (anchorItem.parent && anchorItem.parent.parent ? anchorItem.parent.parent.x : 0)
          + anchorItem.width / 2
        : 0

    readonly property real panelX: barWindow
        ? Math.max(6, Math.min(titleCenterX - panelWidth / 2, barWindow.width - panelWidth - 6))
        : 0

    visible: false
    color: "transparent"

    // Grabs Wayland keyboard focus for the popup's surface — without this,
    // TextInput children in the popup never receive typed input (the generic
    // PopupWindow.grabFocus only re-applies on the next show/hide cycle).
    HyprlandFocusGrab {
        windows: [panel, historyPopup, currencyPopup]
        active: panel.open
    }

    anchor.window: barWindow
    anchor.rect: barWindow
        ? Qt.rect(panel.panelX, 0, panelWidth, barWindow.implicitHeight)
        : Qt.rect(0, 0, 0, 0)
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    implicitWidth: panelWidth
    implicitHeight: contentH + topGap + 4

    Timer { id: closeTimer; interval: 240; onTriggered: panel.visible = false }
    onOpenChanged: {
        if (open) { closeTimer.stop(); visible = true }
        else closeTimer.start()
    }

    component MenuItem: Rectangle {
        property string label
        signal clicked()
        readonly property bool _hot: itemMa.containsMouse
        width: parent.width
        height: 38
        radius: 8
        color: _hot ? C.surface0 : "transparent"
        border.width: 1
        border.color: _hot ? C.accent : C.surface0
        Behavior on border.color { ColorAnimation { duration: 120 } }
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: parent.label
            color: C.text
            font.family: Settings.fontFamily
            font.pixelSize: Settings.fontSize
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "›"
            color: parent._hot ? C.accent : C.overlay0
            font.pixelSize: 14
        }
        MouseArea {
            id: itemMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    // A real, self-contained button — only the pill itself is clickable,
    // not the whole header row (previously the header's full width acted
    // as one giant hit target, which felt broken).
    component BackHeader: Item {
        id: header
        property string label
        // Optional pill button shown right after Back — e.g. "$" to pop
        // open the currency converter without leaving the current tool.
        property string extraLabel: ""
        property bool extraActive: false
        signal back()
        signal extraClicked()
        width: parent.width
        height: 24

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Rectangle {
                id: backBtn
                width: backRow.implicitWidth + 16
                height: 24
                radius: 6
                color: backMa.containsMouse ? Qt.rgba(C.accent.r, C.accent.g, C.accent.b, 0.10) : "transparent"
                border.width: 1
                border.color: backMa.containsMouse ? C.accent : C.surface0
                Behavior on border.color { ColorAnimation { duration: 120 } }
                Row {
                    id: backRow
                    anchors.centerIn: parent
                    Text {
                        text: "Back"
                        color: backMa.containsMouse ? C.accent : C.subtext0
                        font.family: Settings.fontFamily
                        font.pixelSize: 11
                    }
                }
                MouseArea {
                    id: backMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: header.back()
                }
            }

            Rectangle {
                id: extraBtn
                visible: header.extraLabel !== ""
                width: visible ? extraRow.implicitWidth + 16 : 0
                height: 24
                radius: 6
                color: (header.extraActive || extraMa.containsMouse) ? Qt.rgba(C.accent.r, C.accent.g, C.accent.b, 0.10) : "transparent"
                border.width: 1
                border.color: (header.extraActive || extraMa.containsMouse) ? C.accent : C.surface0
                Behavior on border.color { ColorAnimation { duration: 120 } }
                Row {
                    id: extraRow
                    anchors.centerIn: parent
                    Text {
                        text: header.extraLabel
                        color: (header.extraActive || extraMa.containsMouse) ? C.accent : C.subtext0
                        font.family: Settings.fontFamily
                        font.pixelSize: 11
                    }
                }
                MouseArea {
                    id: extraMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: header.extraClicked()
                }
            }
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: header.label
            color: C.overlay1
            font.family: Settings.fontFamily
            font.pixelSize: 10
            font.letterSpacing: 1.4
        }
    }

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

                // Clips the horizontal slide between screens.
                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: panel.pad
                    height: content.implicitHeight
                    clip: true

                    Item {
                        id: content
                        width: parent.width
                        implicitHeight: panel.view === "menu" ? menuScreen.implicitHeight
                                       : panel.view === "currency" ? currencyScreen.implicitHeight
                                       : panel.view === "time" ? timeScreen.implicitHeight
                                       : panel.view === "settings" ? settingsScreen.implicitHeight
                                       : calculatorScreen.implicitHeight
                        Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                        // ── Menu ─────────────────────────────────────────
                        Column {
                            id: menuScreen
                            width: parent.width
                            spacing: 6
                            x: panel.view === "menu" ? 0 : -width
                            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Repeater {
                                model: panel.tools
                                delegate: MenuItem {
                                    required property var modelData
                                    label: modelData.label
                                    onClicked: panel.view = modelData.id
                                }
                            }
                        }

                        // ── Currency ─────────────────────────────────────
                        Column {
                            id: currencyScreen
                            width: parent.width
                            spacing: 12
                            x: panel.view === "currency" ? 0 : width
                            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            BackHeader { label: "CURRENCY CONVERTER"; onBack: panel.view = "menu" }
                            CurrencyConverter {}
                        }

                        // ── Time ──────────────────────────────────────────
                        Column {
                            id: timeScreen
                            width: parent.width
                            spacing: 12
                            x: panel.view === "time" ? 0 : width
                            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            BackHeader { label: "CLOCK CONVERTER"; onBack: panel.view = "menu" }
                            TimeConverter {}
                        }

                        // ── Calculator ────────────────────────────────────
                        Column {
                            id: calculatorScreen
                            width: parent.width
                            spacing: 12
                            x: panel.view === "calculator" ? 0 : width
                            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            BackHeader {
                                label: "CALCULATOR"
                                extraLabel: "$"
                                extraActive: panel.calcCurrencyOpen
                                onBack: panel.view = "menu"
                                onExtraClicked: panel.calcCurrencyOpen = !panel.calcCurrencyOpen
                            }
                            Calculator { id: calcTool }
                        }

                        // ── Settings ──────────────────────────────────────
                        Column {
                            id: settingsScreen
                            width: parent.width
                            spacing: 12
                            x: panel.view === "settings" ? 0 : width
                            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            BackHeader { label: "SETTINGS"; onBack: panel.view = "menu" }
                            SettingsTool {}
                        }
                    }
                }
            }
        }
    }

    // Side panel for calculator history — a separate popup that opens next
    // to the main panel (the thin tab on the calculator's display toggles
    // it) rather than replacing the keypad in place. Prefers the left side;
    // falls back to the right only if there's no room on the left.
    PopupWindow {
        id: historyPopup

        readonly property bool wantOpen: panel.open && panel.view === "calculator" && calcTool.historyOpen
        readonly property int sideWidth: 220
        readonly property int gap: 8
        readonly property bool spaceLeft: barWindow
            ? (panel.panelX - gap - sideWidth >= 6)
            : true
        readonly property real sideX: barWindow
            ? (spaceLeft ? panel.panelX - gap - sideWidth
                         : Math.min(panel.panelX + panel.panelWidth + gap, barWindow.width - sideWidth - 6))
            : 0

        visible: false
        color: "transparent"

        anchor.window: barWindow
        anchor.rect: barWindow
            ? Qt.rect(sideX, 0, sideWidth, barWindow.implicitHeight)
            : Qt.rect(0, 0, 0, 0)
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        implicitWidth: sideWidth
        implicitHeight: historyContent.implicitHeight + panel.topGap + 4

        Timer { id: historyCloseTimer; interval: 240; onTriggered: historyPopup.visible = false }
        onWantOpenChanged: {
            if (wantOpen) { historyCloseTimer.stop(); visible = true }
            else historyCloseTimer.start()
        }

        Item {
            anchors.fill: parent
            clip: true

            Item {
                id: historySlide
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height - panel.topGap
                y: historyPopup.wantOpen ? panel.topGap : -height
                opacity: historyPopup.wantOpen ? 1 : 0
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                CalcHistoryPanel {
                    id: historyContent
                    width: parent.width
                    onRecall: entry => calcTool.recall(entry)
                }
            }
        }
    }

    // Side panel for the currency converter, opened from the calculator's
    // "$" button. Prefers the right side; falls back to the left only if
    // there's no room on the right.
    PopupWindow {
        id: currencyPopup

        readonly property bool wantOpen: panel.open && panel.view === "calculator" && panel.calcCurrencyOpen
        readonly property int sideWidth: 260
        readonly property int gap: 8
        readonly property bool spaceRight: barWindow
            ? (panel.panelX + panel.panelWidth + gap + sideWidth + 6 <= barWindow.width)
            : true
        readonly property real sideX: barWindow
            ? (spaceRight ? panel.panelX + panel.panelWidth + gap
                          : Math.max(6, panel.panelX - gap - sideWidth))
            : 0

        visible: false
        color: "transparent"

        anchor.window: barWindow
        anchor.rect: barWindow
            ? Qt.rect(sideX, 0, sideWidth, barWindow.implicitHeight)
            : Qt.rect(0, 0, 0, 0)
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        implicitWidth: sideWidth
        implicitHeight: currencyContent.implicitHeight + panel.topGap + 4

        Timer { id: currencyCloseTimer; interval: 240; onTriggered: currencyPopup.visible = false }
        onWantOpenChanged: {
            if (wantOpen) { currencyCloseTimer.stop(); visible = true }
            else currencyCloseTimer.start()
        }

        Item {
            anchors.fill: parent
            clip: true

            Item {
                id: currencySlide
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height - panel.topGap
                y: currencyPopup.wantOpen ? panel.topGap : -height
                opacity: currencyPopup.wantOpen ? 1 : 0
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                CurrencySidePanel {
                    id: currencyContent
                    width: parent.width
                }
            }
        }
    }
}
