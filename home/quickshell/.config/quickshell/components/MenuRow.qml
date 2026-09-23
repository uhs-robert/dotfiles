// home/quickshell/.config/quickshell/components/MenuRow.qml
import QtQuick
import "../theme"

Rectangle {
    id: root

    property bool selected: false
    property real base_radius: 4

    radius: Style.radius(root.base_radius)
    color: root.selected ? Style.selection_bg : "transparent"

    // Styles with an inverse selection repaint the row's text and glyphs in one color.
    function fg(c) {
        return root.selected && Style.selection_inverse ? Style.selection_fg : c;
    }
}
