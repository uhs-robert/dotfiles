// home/quickshell/.config/quickshell/bar/CavaStrip.qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// A thin cava visualizer flush under the center island, hanging bars down from its
// bottom edge. Hidden while a submap tab occupies the same spot.
PanelWindow {
    id: root

    property real strip_width: 260
    property bool bar_present: true
    property real opacity_level: 0

    readonly property int bar_count: CavaState.bar_count
    readonly property bool wanted: root.bar_present && MediaState.playing && !SubmapState.active

    visible: false
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-cava"
    anchors.top: true
    implicitWidth: root.strip_width
    readonly property int strip_height: 6
    implicitHeight: root.strip_height
    mask: Region {}

    onWantedChanged: {
        if (root.wanted) {
            hide_anim.stop();
            root.visible = true;
            show_anim.restart();
        } else {
            show_anim.stop();
            hide_anim.restart();
        }
    }

    NumberAnimation {
        id: show_anim
        target: root
        property: "opacity_level"
        to: 1
        duration: 250
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: hide_anim
        NumberAnimation { target: root; property: "opacity_level"; to: 0; duration: 250; easing.type: Easing.InCubic }
        ScriptAction { script: root.visible = false }
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.strip_width
        height: root.strip_height
        opacity: root.opacity_level

        Row {
            anchors.left: parent.left
            anchors.top: parent.top
            spacing: 0

            Repeater {
                model: root.bar_count

                Rectangle {
                    required property int index
                    readonly property real level: CavaState.levels[index] || 0

                    width: root.strip_width / root.bar_count
                    height: 2 + level * (root.strip_height - 2)
                    color: Theme.theme_primary
                    opacity: 0.7 + 0.3 * level
                }
            }
        }
    }
}
