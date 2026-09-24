// home/quickshell/.config/quickshell/components/InsetFrame.qml
import QtQuick
import "../theme"

// The style's inner frame line, drawn frame_inset in from the parent's edges.
Rectangle {
    property real top_offset: 0

    visible: Style.frame_inset_width > 0
    anchors.fill: parent
    anchors.margins: Style.frame_inset
    anchors.topMargin: Style.frame_inset + top_offset
    color: "transparent"
    border.width: Style.frame_inset_width
    border.color: Style.frame_inset_color
}
