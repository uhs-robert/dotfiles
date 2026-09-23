// home/quickshell/.config/quickshell/bar/BarWindow.qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

// Full screen and never resized (per-frame resizes jitter); the mask limits input to what is drawn.
PanelWindow {
    id: root

    property var rule: null
    property string screen_name: ""
    readonly property real center_width: bar.center_width
    readonly property bool expanded: bar.expanded

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Setting exclusiveZone would flip this back to Normal; BarReserve holds the space instead.
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    // Exclusive only for a moment: an already-mapped surface flipped to OnDemand never receives focus, and a lasting Exclusive blocks clicks elsewhere.
    property int focus_mode: WlrKeyboardFocus.None
    WlrLayershell.keyboardFocus: root.focus_mode

    onExpandedChanged: {
        if (root.expanded) {
            root.focus_mode = WlrKeyboardFocus.Exclusive;
            focus_release.restart();
        } else {
            focus_release.stop();
            root.focus_mode = WlrKeyboardFocus.None;
        }
    }

    Timer {
        id: focus_release
        interval: 80
        onTriggered: if (root.expanded) root.focus_mode = WlrKeyboardFocus.OnDemand
    }

    // While a panel is open the whole screen takes input, so a press outside it closes it.
    mask: Region {
        width: root.width
        height: root.expanded ? root.height : bar.bar_height

        Region {
            x: bar.mask_x
            width: bar.mask_width
            height: bar.mask_height
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.expanded
        acceptedButtons: Qt.AllButtons
        onPressed: Popups.close()
    }

    Bar {
        id: bar
        anchors.fill: parent
        screen_name: root.screen_name
        rule: root.rule
    }
}
