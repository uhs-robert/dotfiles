// home/quickshell/.config/quickshell/components/FrameTicks.qml
pragma ComponentBehavior: Bound
import QtQuick
import "../theme"

// The style's hairline frame marks: a tick scale on the top or left edge, with corner crosses or a corner ring.
Item {
    id: root

    property var st: Style.for_item(root)
    readonly property string mode: root.st.frame_ticks
    readonly property bool on_top: root.mode === "top"
    readonly property int step: root.on_top ? 10 : 8
    readonly property int major_every: 5
    readonly property real span: root.on_top ? root.width : Math.max(0, root.height - 28)

    visible: root.mode !== ""

    Repeater {
        model: root.visible ? Math.floor(root.span / root.step) + 1 : 0

        Rectangle {
            required property int index
            readonly property bool major: index % root.major_every === 0

            x: root.on_top ? index * root.step : 0
            y: root.on_top ? 0 : 14 + index * root.step
            width: root.on_top ? 1 : major ? 7 : 4
            height: root.on_top ? (major ? 10 : 5) : 1
            color: major ? root.st.hairline : root.st.hairline_dim
        }
    }

    Rectangle {
        visible: root.on_top
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: root.st.hairline_dim
    }

    Repeater {
        model: root.on_top ? [0, 1] : []

        Item {
            required property int modelData
            x: modelData === 0 ? 0 : root.width - 9
            y: root.height - 9
            width: 9
            height: 9

            Rectangle {
                y: 4
                width: 9
                height: 1
                color: root.st.text_strong
            }

            Rectangle {
                x: 4
                width: 1
                height: 9
                color: root.st.text_strong
            }
        }
    }

    Rectangle {
        visible: !root.on_top
        x: root.width - 11
        y: 3
        width: 8
        height: 8
        radius: 4
        color: Theme.bg_crust
        border.width: 1
        border.color: root.st.text_strong
    }
}
