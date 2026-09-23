// home/quickshell/.config/quickshell/components/KeyBadge.qml
import QtQuick
import "../theme"

Rectangle {
    id: root

    property string key: ""
    // On an inverse-selected row or active tab the badge takes the selection color.
    property bool on_selection: false

    implicitWidth: Math.max(implicitHeight, key_text.implicitWidth + 8)
    implicitHeight: key_text.implicitHeight + 2
    width: implicitWidth
    height: implicitHeight
    radius: Style.radius(3)
    color: Style.key_bg
    border.width: 1
    border.color: root.on_selection && Style.selection_inverse ? Style.selection_fg : Style.key_border

    Text {
        id: key_text
        anchors.centerIn: parent
        text: root.key
        color: root.on_selection && Style.selection_inverse ? Style.selection_fg : Style.key_fg
        font.family: Style.font_family
        font.pixelSize: Style.font_size - 5
        font.bold: true
    }
}
