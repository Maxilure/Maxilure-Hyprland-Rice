import QtQuick
import "Colors.js" as C

// Side panel hosting the currency converter, opened from the calculator
// screen's "$" button in ToolsPanel — the same CurrencyConverter used by the
// tools menu, just reachable without leaving the calculator.
Rectangle {
    id: root

    readonly property int pad: 14

    color: C.base
    border.color: C.surface0
    border.width: 1
    radius: 10
    implicitHeight: content.implicitHeight + 2 * pad

    Column {
        id: content
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: 12

        Text {
            text: "CURRENCY CONVERTER"
            color: C.overlay1
            font.family: Settings.fontFamily
            font.pixelSize: 10
            font.letterSpacing: 1.4
        }

        CurrencyConverter {}
    }
}
