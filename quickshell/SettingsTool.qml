import QtQuick
import Quickshell
import "Colors.js" as C

// One "tool" hosted inside ToolsPanel. Edits Settings.* live — every change
// is applied to the bar immediately and persisted via Settings.save().
Column {
    id: root
    width: parent ? parent.width : 272
    spacing: 6

    readonly property color accentColor: C.accent
    function accentA(a) { return Qt.rgba(accentColor.r, accentColor.g, accentColor.b, a) }

    readonly property var screenNames: {
        var out = []
        var s = Quickshell.screens
        for (var i = 0; i < s.length; i++) out.push(s[i].name)
        return out
    }

    function setCities(list) {
        Settings.worldClockCities = list
        Settings.save()
    }

    // ── Reusable pieces ──────────────────────────────────────────────────

    component SectionHeader: Text {
        width: parent.width
        topPadding: 8
        color: C.overlay1
        font.family: Settings.fontFamily
        font.pixelSize: 10
        font.letterSpacing: 1.8
    }

    component Chip: Rectangle {
        property string label
        property bool active: false
        signal clicked()
        readonly property bool _hot: chipMa.containsMouse
        implicitWidth: chipTxt.implicitWidth + 18
        implicitHeight: 22
        radius: 6
        color: active ? root.accentA(0.10) : "transparent"
        border.width: 1
        border.color: (active || _hot) ? root.accentColor : C.surface0
        Behavior on border.color { ColorAnimation { duration: 120 } }
        Text {
            id: chipTxt
            anchors.centerIn: parent
            text: parent.label
            color: (parent.active || parent._hot) ? root.accentColor : C.subtext0
            font.family: Settings.fontFamily
            font.pixelSize: 11
        }
        MouseArea {
            id: chipMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component RowLabel: Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: C.subtext0
        font.family: Settings.fontFamily
        font.pixelSize: 12
    }

    component StepBtn: Rectangle {
        property string glyph
        property bool canUse: true
        signal clicked()
        width: 20; height: 20; radius: 5
        color: canUse && stepMa.containsMouse ? C.surface0 : "transparent"
        border.width: 1
        border.color: canUse && stepMa.containsMouse ? root.accentColor : C.surface0
        Text {
            anchors.centerIn: parent
            text: parent.glyph
            color: parent.canUse ? C.text : C.surface2
            font.family: Settings.fontFamily
            font.pixelSize: 12
        }
        MouseArea {
            id: stepMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: parent.canUse ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (parent.canUse) parent.clicked()
        }
    }

    // label ........ [−] 24 [+]
    component IntRow: Item {
        id: irow
        property string label
        property int value
        property int min: 0
        property int max: 99
        signal commit(int v)
        width: parent.width
        height: 26
        RowLabel { text: irow.label }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            StepBtn { glyph: "−"; canUse: irow.value > irow.min; onClicked: irow.commit(irow.value - 1) }
            Text {
                width: 30; height: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: irow.value
                color: C.text
                font.family: Settings.fontFamily
                font.pixelSize: 12
            }
            StepBtn { glyph: "+"; canUse: irow.value < irow.max; onClicked: irow.commit(irow.value + 1) }
        }
    }

    // label ........ [ON/OFF chip]
    component ToggleRow: Item {
        id: trow
        property string label
        property bool checked
        signal commit(bool v)
        width: parent.width
        height: 26
        RowLabel { text: trow.label }
        Chip {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            label: trow.checked ? "ON" : "OFF"
            active: trow.checked
            onClicked: trow.commit(!trow.checked)
        }
    }

    // label ........ [current option ▸]  — click cycles through options
    component CycleRow: Item {
        id: crow
        property string label
        property var options: []      // [{ v, text }]
        property var value
        signal commit(var v)
        readonly property int idx: {
            for (var i = 0; i < options.length; i++)
                if (options[i].v === value) return i
            return 0
        }
        width: parent.width
        height: 26
        RowLabel { text: crow.label }
        Chip {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            label: (crow.options[crow.idx] ? crow.options[crow.idx].text : "?") + "  ▸"
            onClicked: crow.commit(crow.options[(crow.idx + 1) % crow.options.length].v)
        }
    }

    // Small framed TextInput with placeholder, used by the add-city row.
    component AddInput: Rectangle {
        property alias input: fld
        property string hint
        height: 22; radius: 5
        color: C.mantle
        border.width: 1
        border.color: fld.activeFocus ? root.accentColor : C.surface0
        TextInput {
            id: fld
            anchors.fill: parent
            anchors.leftMargin: 7; anchors.rightMargin: 7
            verticalAlignment: TextInput.AlignVCenter
            color: C.text
            font.family: Settings.fontFamily
            font.pixelSize: 11
            clip: true
            selectByMouse: true
            selectionColor: root.accentA(0.35)
        }
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 7
            anchors.verticalCenter: parent.verticalCenter
            visible: fld.text === "" && !fld.activeFocus
            text: parent.hint
            color: C.overlay0
            font.family: Settings.fontFamily
            font.pixelSize: 11
        }
    }

    // label ........ [ text input ]
    component TextRow: Item {
        id: xrow
        property string label
        property string value
        property int inputWidth: 150
        signal commit(string v)
        width: parent.width
        height: 26
        RowLabel { text: xrow.label }
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: xrow.inputWidth; height: 22; radius: 5
            color: C.mantle
            border.width: 1
            border.color: xinput.activeFocus ? root.accentColor : C.surface0
            TextInput {
                id: xinput
                anchors.fill: parent
                anchors.leftMargin: 7; anchors.rightMargin: 7
                verticalAlignment: TextInput.AlignVCenter
                text: xrow.value
                color: C.text
                font.family: Settings.fontFamily
                font.pixelSize: 11
                clip: true
                selectByMouse: true
                selectionColor: root.accentA(0.35)
                onEditingFinished: if (text !== xrow.value) xrow.commit(text)
            }
        }
    }

    // ── BAR ──────────────────────────────────────────────────────────────
    SectionHeader { text: "BAR" }
    IntRow { label: "height";        value: Settings.barHeight;       min: 16; max: 48; onCommit: v => { Settings.barHeight = v;       Settings.save() } }
    IntRow { label: "workspaces";    value: Settings.workspaceCount;  min: 1;  max: 10; onCommit: v => { Settings.workspaceCount = v;  Settings.save() } }
    IntRow { label: "left padding";  value: Settings.wsLeftPadding;   min: 0;  max: 40; onCommit: v => { Settings.wsLeftPadding = v;   Settings.save() } }
    IntRow { label: "right padding"; value: Settings.barRightPadding; min: 0;  max: 40; onCommit: v => { Settings.barRightPadding = v; Settings.save() } }

    // ── FONT ─────────────────────────────────────────────────────────────
    SectionHeader { text: "FONT" }
    TextRow { label: "family"; value: Settings.fontFamily; onCommit: v => { Settings.fontFamily = v; Settings.save() } }
    IntRow  { label: "size"; value: Settings.fontSize; min: 8; max: 20; onCommit: v => { Settings.fontSize = v; Settings.save() } }

    // ── CLOCK ────────────────────────────────────────────────────────────
    SectionHeader { text: "CLOCK" }
    ToggleRow { label: "24-hour time"; checked: Settings.clock24h; onCommit: v => { Settings.clock24h = v; Settings.save() } }

    // ── MONITORS ─────────────────────────────────────────────────────────
    SectionHeader { text: "MONITORS" }
    CycleRow {
        label: "bar monitor"
        value: Settings.barScreen
        options: [{ v: "", text: "all screens" }].concat(
            root.screenNames.map(function(n) { return { v: n, text: n } }))
        onCommit: v => { Settings.barScreen = v; Settings.save() }
    }
    CycleRow {
        label: "toast monitor"
        value: Settings.toastScreen
        options: [{ v: "", text: "same as bar" }].concat(
            root.screenNames.map(function(n) { return { v: n, text: n } }))
        onCommit: v => { Settings.toastScreen = v; Settings.save() }
    }

    // ── CALENDAR ─────────────────────────────────────────────────────────
    SectionHeader { text: "CALENDAR" }
    CycleRow {
        label: "week starts"
        value: Settings.weekStart
        options: [{ v: "Sunday", text: "Sunday" }, { v: "Monday", text: "Monday" }]
        onCommit: v => { Settings.weekStart = v; Settings.save() }
    }
    CycleRow {
        label: "default view"
        value: Settings.defaultCalendar
        options: [{ v: "Gregorian", text: "Gregorian" }, { v: "Hijri", text: "Hijri" }]
        onCommit: v => { Settings.defaultCalendar = v; Settings.save() }
    }
    ToggleRow {
        label: "world clock seconds"
        checked: Settings.worldClockSeconds
        onCommit: v => { Settings.worldClockSeconds = v; Settings.save() }
    }

    // ── WORLD CLOCKS ─────────────────────────────────────────────────────
    SectionHeader { text: "WORLD CLOCKS" }
    Repeater {
        model: Settings.worldClockCities
        delegate: Item {
            required property var modelData
            required property int index
            width: parent.width
            height: 24
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 110
                text: modelData.label + "  ·  " + modelData.tz
                color: C.subtext0
                font.family: Settings.fontFamily
                font.pixelSize: 11
                elide: Text.ElideMiddle
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Chip {
                    label: modelData.h12 ? "12H" : "24H"
                    onClicked: {
                        var list = Settings.worldClockCities.slice()
                        list[index] = { label: modelData.label, tz: modelData.tz, h12: !modelData.h12 }
                        root.setCities(list)
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "×"
                    color: rmMa.containsMouse ? root.accentColor : C.overlay0
                    font.family: Settings.fontFamily
                    font.pixelSize: 14
                    MouseArea {
                        id: rmMa
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var list = Settings.worldClockCities.slice()
                            list.splice(index, 1)
                            root.setCities(list)
                        }
                    }
                }
            }
        }
    }

    // Add-city row: label + IANA tz (e.g. Asia/Tokyo), then +
    Item {
        width: parent.width
        height: 26

        Row {
            anchors.fill: parent
            spacing: 6
            AddInput { id: addLabel; width: 80;  hint: "City";        anchors.verticalCenter: parent.verticalCenter }
            AddInput { id: addTz;    width: 130; hint: "Asia/Tokyo";  anchors.verticalCenter: parent.verticalCenter }
            Chip {
                anchors.verticalCenter: parent.verticalCenter
                label: "+"
                onClicked: {
                    var l = addLabel.input.text.trim()
                    var z = addTz.input.text.trim()
                    if (l === "" || z === "") return
                    root.setCities(Settings.worldClockCities.concat([{ label: l, tz: z, h12: false }]))
                    addLabel.input.text = ""
                    addTz.input.text = ""
                }
            }
        }
    }
}
