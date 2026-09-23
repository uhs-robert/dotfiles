// home/quickshell/.config/quickshell/bar/BarWindow.qml
import QtQuick
import Quickshell
import Quickshell.Hyprland
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
    WlrLayershell.keyboardFocus: root.expanded ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        width: root.width
        height: bar.bar_height

        Region {
            x: bar.mask_x
            width: bar.mask_width
            height: bar.mask_height
        }
    }

    Bar {
        id: bar
        anchors.fill: parent
        screen_name: root.screen_name
        rule: root.rule
    }

    onExpandedChanged: {
        root.grab_ready = false;
        if (!root.expanded) return;
        root.grab_retries = 0;
        grab_delay.restart();
    }

    // Armed a beat after opening: on a quick reopen Hyprland hasn't moved keyboard focus back yet and clears a grab taken at once.
    property bool grab_ready: false
    property int grab_retries: 0
    property double grab_armed_ms: 0
    Timer {
        id: grab_delay
        interval: 60
        onTriggered: {
            root.grab_armed_ms = Date.now();
            root.grab_ready = true;
        }
    }

    // A clear right after arming means focus hadn't returned yet, so re-arm instead of closing.
    function grab_cleared() {
        if (root.expanded && root.grab_retries < 2 && Date.now() - root.grab_armed_ms < 300) {
            root.grab_retries += 1;
            root.grab_ready = false;
            grab_delay.restart();
            return;
        }
        Popups.close();
    }

    Loader {
        active: root.expanded && root.grab_ready
        sourceComponent: HyprlandFocusGrab {
            active: true
            windows: [root]
            onCleared: root.grab_cleared()
        }
    }
}
