// home/quickshell/.config/quickshell/components/mgs2/Rail.qml
import QtQuick
import "../../theme"

// A framed box with a narrow rail strip down its left inside edge; children sit right of the rail.
Item {
    id: root

    property real rail_width: 8
    property real outline_width: 1.5
    property color outline_color: Qt.alpha(Theme.fg_core, 0.55)
    property color rail_fill: Qt.alpha(Theme.fg_core, 0.08)
    property color rail_edge: Qt.alpha(Theme.fg_core, 0.55)
    default property alias content: body.data

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: root.outline_width
        border.color: root.outline_color
    }

    Rectangle {
        x: root.outline_width
        y: root.outline_width
        width: root.rail_width
        height: parent.height - root.outline_width * 2
        color: root.rail_fill
    }

    Rectangle {
        x: root.outline_width + root.rail_width - 1
        y: root.outline_width
        width: 1
        height: parent.height - root.outline_width * 2
        color: root.rail_edge
    }

    Item {
        id: body
        x: root.outline_width + root.rail_width
        y: root.outline_width
        width: parent.width - x - root.outline_width
        height: parent.height - root.outline_width * 2
    }
}
