// home/quickshell/.config/quickshell/components/CornerBrackets.qml
pragma ComponentBehavior: Bound
import QtQuick
import "../theme"

// The style's corner brackets at the top left and top right, inset from the frame edge.
Item {
    id: root

    property color color: Style.for_item(root).frame_brackets
    property int inset: 4
    property int arm: 10
    property real thickness: 1
    // Adds the two bottom corners.
    property bool all_corners: false

    visible: root.color.a > 0

    Repeater {
        model: !root.visible ? [] : root.all_corners ? [[0, 0, 0], [0, 1, 0], [1, 0, 0], [1, 1, 0], [0, 0, 1], [0, 1, 1], [1, 0, 1], [1, 1, 1]] : [[0, 0, 0], [0, 1, 0], [1, 0, 0], [1, 1, 0]]

        Rectangle {
            id: arm_line
            required property var modelData
            readonly property bool on_right: arm_line.modelData[0] === 1
            readonly property bool upright: arm_line.modelData[1] === 1
            readonly property bool on_bottom: arm_line.modelData[2] === 1

            x: arm_line.on_right ? root.width - root.inset - arm_line.width : root.inset
            y: arm_line.on_bottom ? root.height - root.inset - arm_line.height : root.inset
            width: arm_line.upright ? root.thickness : root.arm
            height: arm_line.upright ? root.arm : root.thickness
            color: root.color
        }
    }
}
