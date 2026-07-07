import QtQuick
import "Colors.js" as C

// One "tool" hosted inside ToolsPanel. Reads live rates from the Currency
// singleton; converts FROM -> TO as the amount is typed.
Item {
    id: root
    width: parent ? parent.width : 300
    implicitHeight: col.implicitHeight

    property real amount: 1
    property string fromCode: "USD"
    property string toCode: "EUR"
    property string pickerFor: ""   // "" | "from" | "to"
    property var now: Date.now()

    readonly property color accentColor: C.accent
    function accentA(a) { return Qt.rgba(accentColor.r, accentColor.g, accentColor.b, a) }

    readonly property var rates: Currency.rates
    readonly property bool ready: rates[fromCode] !== undefined && rates[toCode] !== undefined
    readonly property real converted: ready ? amount / rates[fromCode] * rates[toCode] : 0

    // "x min ago" label only needs to tick while our popup window is shown.
    readonly property bool onScreen: Window.window ? Window.window.visible : false
    onOnScreenChanged: if (onScreen) now = Date.now()
    Timer { interval: 30000; running: root.onScreen; repeat: true; onTriggered: root.now = Date.now() }

    function fmtAgo(ms) {
        if (!ms) return "never"
        var s = Math.floor((root.now - ms) / 1000)
        if (s < 60) return "just now"
        var m = Math.floor(s / 60); if (m < 60) return m + "m ago"
        var h = Math.floor(m / 60); if (h < 24) return h + "h ago"
        return Math.floor(h / 24) + "d ago"
    }

    function fmtNum(n) {
        if (!isFinite(n)) return "0.00"
        return n.toLocaleString(Qt.locale("en_US"), 'f', 2)
    }

    function swap() {
        var t = fromCode
        fromCode = toCode
        toCode = t
    }

    component CcyButton: Rectangle {
        property string code
        signal clicked()
        implicitWidth: 70
        implicitHeight: 34
        radius: 8
        color: C.mantle
        border.width: 1
        border.color: btnMa.containsMouse ? root.accentColor : C.surface0
        Behavior on border.color { ColorAnimation { duration: 120 } }
        Row {
            anchors.centerIn: parent
            spacing: 4
            Text { text: parent.parent.code; color: C.text; font.family: Settings.fontFamily; font.pixelSize: Settings.fontSize; font.bold: true }
            Text { text: "▾"; color: C.overlay0; font.family: Settings.fontFamily; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component CcyPicker: Column {
        id: picker
        property string which
        property string query: ""
        visible: root.pickerFor === which
        width: root.width
        spacing: 6

        onVisibleChanged: if (visible) { query = ""; searchInput.forceActiveFocus() }

        readonly property var filtered: {
            var q = picker.query.trim().toLowerCase()
            var codes = Object.keys(Currency.rates).sort()
            if (q === "") return codes
            return codes.filter(function(c) { return c.toLowerCase().indexOf(q) >= 0 })
        }

        Rectangle {
            width: parent.width
            height: 30
            radius: 8
            color: C.mantle
            border.width: 1
            border.color: searchInput.activeFocus ? root.accentColor : C.surface0
            Behavior on border.color { ColorAnimation { duration: 120 } }
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                visible: searchInput.text === ""
                text: "Search currency…"
                color: C.overlay0
                font.family: Settings.fontFamily
                font.pixelSize: 11
            }
            TextInput {
                id: searchInput
                anchors.fill: parent
                anchors.margins: 10
                verticalAlignment: TextInput.AlignVCenter
                color: C.text
                font.family: Settings.fontFamily
                font.pixelSize: 11
                selectByMouse: true
                onTextChanged: picker.query = text
            }
        }

        ListView {
            width: parent.width
            height: Math.min(picker.filtered.length, 5) * 28
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: picker.filtered
            delegate: Rectangle {
                id: cell
                required property string modelData
                readonly property bool sel: (root.pickerFor === "from" ? root.fromCode : root.toCode) === modelData
                width: ListView.view.width
                height: 28
                color: sel ? root.accentA(0.12) : (cellMa.containsMouse ? C.surface0 : "transparent")
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: cell.modelData
                    color: cell.sel ? root.accentColor : C.subtext0
                    font.family: Settings.fontFamily
                    font.pixelSize: 11
                }
                MouseArea {
                    id: cellMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.pickerFor === "from") root.fromCode = cell.modelData
                        else root.toCode = cell.modelData
                        root.pickerFor = ""
                    }
                }
            }
        }

        Text {
            visible: picker.filtered.length === 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No matches"
            color: C.overlay0
            font.family: Settings.fontFamily
            font.pixelSize: 11
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: 10

        // Status row: last-updated + refresh
        Item {
            width: parent.width
            height: 16
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Currency.loading ? "Updating…"
                    : (Currency.error !== "" ? Currency.error : "Updated " + root.fmtAgo(Currency.lastUpdated))
                color: Currency.error !== "" ? C.red : C.overlay0
                font.family: Settings.fontFamily
                font.pixelSize: 10
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "⟳"
                color: refreshMa.containsMouse ? root.accentColor : C.overlay0
                font.family: Settings.fontFamily
                font.pixelSize: 13
                rotation: Currency.loading ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 400 } }
                MouseArea {
                    id: refreshMa
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Currency.refresh()
                }
            }
        }

        // FROM
        Row {
            width: parent.width
            spacing: 8
            Rectangle {
                width: parent.width - fromBtn.width - 8
                height: 34
                radius: 8
                color: C.mantle
                border.width: 1
                border.color: amtInput.activeFocus ? root.accentColor : C.surface0
                Behavior on border.color { ColorAnimation { duration: 120 } }
                TextInput {
                    id: amtInput
                    anchors.fill: parent
                    anchors.margins: 10
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.amount === 0 ? "" : String(root.amount)
                    color: C.text
                    font.family: Settings.fontFamily
                    font.pixelSize: Settings.fontSize
                    selectByMouse: true
                    validator: DoubleValidator { bottom: 0; decimals: 6; notation: DoubleValidator.StandardNotation }
                    onTextChanged: {
                        var v = parseFloat(text)
                        root.amount = isNaN(v) ? 0 : v
                    }
                }
            }
            CcyButton {
                id: fromBtn
                code: root.fromCode
                onClicked: root.pickerFor = root.pickerFor === "from" ? "" : "from"
            }
        }
        CcyPicker { which: "from" }

        // Swap
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
                    onClicked: root.swap()
                }
            }
        }

        // TO
        Row {
            width: parent.width
            spacing: 8
            Rectangle {
                width: parent.width - toBtn.width - 8
                height: 34
                radius: 8
                color: C.mantle
                border.width: 1
                border.color: C.surface0
                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 10
                    text: root.ready ? root.fmtNum(root.converted) : "—"
                    color: root.accentColor
                    font.family: Settings.fontFamily
                    font.pixelSize: Settings.fontSize
                    font.bold: true
                    elide: Text.ElideRight
                }
            }
            CcyButton {
                id: toBtn
                code: root.toCode
                onClicked: root.pickerFor = root.pickerFor === "to" ? "" : "to"
            }
        }
        CcyPicker { which: "to" }
    }
}
