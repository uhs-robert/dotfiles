// home/quickshell/.config/quickshell/components/KeyBadge.qml
import QtQuick
import "../theme"

Rectangle {
    id: root

    property string key: ""
    // Set on a filled active tab so an outline badge takes the tab's text color; keycap badges keep theirs.
    property bool on_fill: false
    readonly property bool tinted: root.on_fill && Style.key_bg.a === 0

    implicitWidth: Math.max(implicitHeight, key_text.implicitWidth + 8) + Style.slant * implicitHeight
    implicitHeight: key_text.implicitHeight + 2
    width: implicitWidth
    height: implicitHeight
    radius: Style.radius(3)
    color: Style.slant > 0 ? "transparent" : Style.key_bg
    border.width: Style.slant > 0 ? 0 : 1
    border.color: root.tinted ? Style.tab_active_fg : Style.key_border

    Slant {
        visible: Style.slant > 0
        color: Style.key_bg
        border.width: 1
        border.color: root.border.color
    }

    Text {
        id: key_text
        anchors.centerIn: parent
        text: root.key
        color: root.tinted ? Style.tab_active_fg : Style.key_fg
        font.family: Style.font_family
        font.pixelSize: Style.font_size - 5
        font.bold: true
    }
}
