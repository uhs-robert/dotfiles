// home/quickshell/.config/quickshell/bar/BarWindow.qml
import QtQuick
import Quickshell
import Quickshell.Wayland

// Full screen and never resized (per-frame resizes jitter); the mask limits input to what is drawn.
PanelWindow {
    id: root

    property var rule: null
    property string screen_name: ""
    readonly property real center_width: bar.center_width

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Setting exclusiveZone would flip this back to Normal; BarReserve holds the space instead.
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    mask: Region {
        width: root.width
        height: bar.bar_height
    }

    Bar {
        id: bar
        anchors.fill: parent
        screen_name: root.screen_name
        rule: root.rule
    }
}
