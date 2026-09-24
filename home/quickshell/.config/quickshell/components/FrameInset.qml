// home/quickshell/.config/quickshell/components/FrameInset.qml
import QtQuick
import "../theme"

// The style's second ring, drawn just inside the frame border.
Rectangle {
    id: root

    property real bottom_radius: 0
    property real top_radius: 0

    visible: Style.frame_inset_width > 0
    color: "transparent"
    topLeftRadius: root.top_radius
    topRightRadius: root.top_radius
    bottomLeftRadius: root.bottom_radius
    bottomRightRadius: root.bottom_radius
    border.width: Style.frame_inset_width
    border.color: Style.frame_inset_color
}
