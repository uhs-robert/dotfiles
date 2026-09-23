// home/quickshell/.config/quickshell/components/Meter.qml
import QtQuick
import "../theme"

Row {
    id: root

    property real value: 0
    property bool hot: false
    readonly property int segment_count: 20

    spacing: 2
    height: 10

    Repeater {
        model: root.segment_count

        Rectangle {
            required property int index

            width: 3
            height: 10
            radius: 1
            color: index < Math.round(root.value * root.segment_count)
                ? (root.hot ? Theme.theme_label : Theme.theme_primary)
                : Theme.bg_surface
        }
    }
}
