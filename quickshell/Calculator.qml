import QtQuick
import "Colors.js" as C

// One "tool" hosted inside ToolsPanel. A simple keypad calculator that
// evaluates one operation at a time (no operator precedence/parens) —
// entry accumulates like a physical calculator: number, op, number, "=".
Item {
    id: root
    width: parent ? parent.width : 300
    implicitHeight: col.implicitHeight

    property real accumulator: 0
    property string pendingOp: ""
    property string display: "0"
    property bool freshEntry: true   // next digit starts a new number
    property bool historyOpen: false
    // Small history line above the display, e.g. "20 +" while entering the
    // second operand, or "20 + 15 =" right after equals — mirrors the
    // expression-so-far line in Google's calculator.
    property string exprLine: ""

    readonly property color accentColor: C.accent

    function fmt(n) {
        if (!isFinite(n)) return "Error"
        var s = n.toLocaleString(Qt.locale("en_US"), 'f', 8)
        if (s.indexOf(".") >= 0) s = s.replace(/0+$/, "").replace(/\.$/, "")
        return s
    }

    function inputDigit(d) {
        if (freshEntry) {
            display = d
            freshEntry = false
            if (pendingOp === "") exprLine = ""
        } else if (display.length < 15) display = (display === "0") ? d : display + d
    }

    function inputDot() {
        if (freshEntry) {
            display = "0."
            freshEntry = false
            if (pendingOp === "") exprLine = ""
        } else if (display.indexOf(".") < 0) display += "."
    }

    function applyPending() {
        var cur = parseFloat(display)
        switch (pendingOp) {
            case "+": accumulator += cur; break
            case "-": accumulator -= cur; break
            case "×": accumulator *= cur; break
            case "÷": accumulator = cur === 0 ? NaN : accumulator / cur; break
            default: accumulator = cur
        }
    }

    function inputOp(op) {
        if (!freshEntry || pendingOp === "") applyPending()
        pendingOp = op
        display = fmt(accumulator)
        freshEntry = true
        exprLine = fmt(accumulator) + " " + op
    }

    function equals() {
        if (pendingOp === "") return
        var left = fmt(accumulator)
        var op = pendingOp
        var right = display
        applyPending()
        var result = fmt(accumulator)
        exprLine = left + " " + op + " " + right + " ="
        display = result
        pendingOp = ""
        freshEntry = true
        CalcHistory.addEntry(left + " " + op + " " + right, result)
    }

    function recall(entry) {
        display = entry.result
        exprLine = ""
        pendingOp = ""
        accumulator = parseFloat(entry.result) || 0
        freshEntry = true
        historyOpen = false
    }

    function clearAll() {
        accumulator = 0
        pendingOp = ""
        display = "0"
        freshEntry = true
        exprLine = ""
    }

    function toggleSign() {
        var v = parseFloat(display)
        if (!isNaN(v) && v !== 0) display = fmt(-v)
    }

    function percent() {
        var v = parseFloat(display)
        if (!isNaN(v)) { display = fmt(v / 100); freshEntry = false }
    }

    component CalcKey: Rectangle {
        id: key
        property string label
        property bool accent: false
        property bool dim: false
        signal clicked()
        implicitHeight: 40
        radius: 8
        color: keyMa.containsMouse
            ? (accent ? root.accentColor : C.surface0)
            : (accent ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.14) : C.mantle)
        border.width: 1
        border.color: accent ? root.accentColor : C.surface0
        Behavior on color { ColorAnimation { duration: 100 } }
        Text {
            anchors.centerIn: parent
            text: key.label
            color: key.accent ? (keyMa.containsMouse ? C.base : root.accentColor) : (key.dim ? C.subtext0 : C.text)
            font.family: Settings.fontFamily
            font.pixelSize: Settings.fontSize + 1
            font.bold: key.accent
        }
        MouseArea {
            id: keyMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: key.clicked()
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: 10

        // Display
        Rectangle {
            width: parent.width
            height: 68
            radius: 8
            color: C.mantle
            border.width: 1
            border.color: C.surface0

            // Thin tab on the display's left edge — click to toggle the
            // history side panel. A slim visual line, not a giant hotspot;
            // the MouseArea is a bit wider than the line for easier hits.
            Rectangle {
                id: historyTab
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 4
                height: parent.height - 16
                radius: 2
                color: (root.historyOpen || historyMa.containsMouse) ? root.accentColor : C.surface1
                Behavior on color { ColorAnimation { duration: 120 } }
            }
            MouseArea {
                id: historyMa
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 20
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.historyOpen = !root.historyOpen
            }

            Column {
                anchors.right: parent.right
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                anchors.rightMargin: 12
                anchors.leftMargin: 20
                spacing: 2
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    text: root.exprLine
                    color: C.overlay1
                    font.family: Settings.fontFamily
                    font.pixelSize: Settings.fontSize - 1
                    elide: Text.ElideLeft
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    text: root.display
                    color: C.text
                    font.family: Settings.fontFamily
                    font.pixelSize: Settings.fontSize + 6
                    elide: Text.ElideLeft
                }
            }
        }

        Column {
            id: keypad
            width: parent.width
            spacing: 8

            readonly property real keyW: (width - 3 * spacing) / 4

            Row {
                width: parent.width
                spacing: keypad.spacing
                CalcKey { width: keypad.keyW; label: "C"; dim: true; onClicked: root.clearAll() }
                CalcKey { width: keypad.keyW; label: "±"; dim: true; onClicked: root.toggleSign() }
                CalcKey { width: keypad.keyW; label: "%"; dim: true; onClicked: root.percent() }
                CalcKey { width: keypad.keyW; label: "÷"; accent: true; onClicked: root.inputOp("÷") }
            }
            Row {
                width: parent.width
                spacing: keypad.spacing
                CalcKey { width: keypad.keyW; label: "7"; onClicked: root.inputDigit("7") }
                CalcKey { width: keypad.keyW; label: "8"; onClicked: root.inputDigit("8") }
                CalcKey { width: keypad.keyW; label: "9"; onClicked: root.inputDigit("9") }
                CalcKey { width: keypad.keyW; label: "×"; accent: true; onClicked: root.inputOp("×") }
            }
            Row {
                width: parent.width
                spacing: keypad.spacing
                CalcKey { width: keypad.keyW; label: "4"; onClicked: root.inputDigit("4") }
                CalcKey { width: keypad.keyW; label: "5"; onClicked: root.inputDigit("5") }
                CalcKey { width: keypad.keyW; label: "6"; onClicked: root.inputDigit("6") }
                CalcKey { width: keypad.keyW; label: "−"; accent: true; onClicked: root.inputOp("-") }
            }
            Row {
                width: parent.width
                spacing: keypad.spacing
                CalcKey { width: keypad.keyW; label: "1"; onClicked: root.inputDigit("1") }
                CalcKey { width: keypad.keyW; label: "2"; onClicked: root.inputDigit("2") }
                CalcKey { width: keypad.keyW; label: "3"; onClicked: root.inputDigit("3") }
                CalcKey { width: keypad.keyW; label: "+"; accent: true; onClicked: root.inputOp("+") }
            }
            Row {
                width: parent.width
                spacing: keypad.spacing
                CalcKey { width: keypad.keyW * 2 + keypad.spacing; label: "0"; onClicked: root.inputDigit("0") }
                CalcKey { width: keypad.keyW; label: "."; onClicked: root.inputDot() }
                CalcKey { width: keypad.keyW; label: "="; accent: true; onClicked: root.equals() }
            }
        }
    }
}
