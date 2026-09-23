// home/quickshell/.config/quickshell/components/MenuRow.qml
import QtQuick
import "../theme"

Rectangle {
    id: root

    property bool selected: false
    property real base_radius: 4
    // Room reserved at the left for the style's cursor marker; rows add it to their left margin.
    readonly property real inset: Style.row_cursor !== "" ? cursor_text.implicitWidth + 4 : 0

    radius: Style.radius(root.base_radius)
    color: root.selected ? Style.selection_bg : "transparent"

    // Styles with an inverse selection repaint the row's text and glyphs in one color.
    function fg(c) {
        return root.selected && Style.selection_inverse ? Style.selection_fg : c;
    }

    Text {
        id: cursor_text
        visible: root.selected && Style.row_cursor !== ""
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        text: Style.row_cursor
        color: root.fg(Theme.theme_primary)
        font.family: Style.font_family
        font.pixelSize: Style.font_size - 1
        font.bold: true
    }
}
