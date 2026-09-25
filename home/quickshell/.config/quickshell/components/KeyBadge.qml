// home/quickshell/.config/quickshell/components/KeyBadge.qml
import QtQuick
import "../theme"
import "KeyHints.js" as KeyHints

Rectangle {
    id: root

    readonly property var st: Style.for_item(root)

    property string key: ""
    // Set on a filled active tab so an outline badge takes the tab's text color; keycap badges keep theirs.
    property bool on_fill: false
    readonly property bool tinted: root.on_fill && root.st.key_bg.a === 0 && !root.orb
    // The raw key (before glyphs) for styles with a controller; set it to draw that controller's buttons.
    property string button_key: ""
    // Keeps the keyboard key beside the buttons, as the ? help does.
    property bool with_key: false
    readonly property var parts: root.button_key !== "" && root.st.controller !== "" ? KeyHints.controller_parts(root.st.controller, root.button_key) : null
    readonly property bool pad: root.parts !== null

    implicitWidth: root.pad ? pad_row.implicitWidth : Math.max(implicitHeight, key_text.implicitWidth + 8)
    implicitHeight: key_text.implicitHeight + 2
    width: implicitWidth
    height: implicitHeight
    radius: root.st.key_round ? height / 2 : Style.radius(3)
    readonly property bool cut: root.st.key_cut > 0
    readonly property bool orb: root.st.materia.key !== undefined
    color: root.pad || root.cut || root.orb ? "transparent" : root.st.key_bg
    border.width: root.pad || root.cut || root.orb ? 0 : root.st.pixel_border.a > 0 ? 2 : 1
    border.color: root.tinted ? root.st.tab_active_fg : root.st.key_border

    CutBox {
        visible: root.cut && !root.pad
        anchors.fill: parent
        cut_tl: root.st.key_cut
        cut_br: root.st.key_cut
        fill: root.st.key_bg
        stroke: root.tinted ? root.st.tab_active_fg : root.st.key_border
    }

    MateriaOrb {
        visible: root.orb && !root.pad
        anchors.fill: parent
        color: root.orb ? root.st.materia.key : "transparent"
    }

    Row {
        id: pad_row
        visible: root.pad
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        ControllerBadge {
            anchors.verticalCenter: parent.verticalCenter
            controller: root.st.controller
            parts: root.parts || []
            size: root.height
            text_color: key_text.color
            font_family: key_text.font.family
            font_size: key_text.font.pixelSize
        }

        Text {
            visible: root.with_key
            anchors.verticalCenter: parent.verticalCenter
            text: root.key
            color: root.st.text_muted
            font: key_text.font
        }
    }

    Text {
        id: key_text
        visible: !root.pad
        anchors.centerIn: parent
        text: root.key
        color: root.tinted ? root.st.tab_active_fg : root.st.key_fg
        font.family: root.st.mono_font
        font.pixelSize: root.st.font_size - 5
        font.bold: root.orb || root.st.mono_font === root.st.font_family
    }
}
