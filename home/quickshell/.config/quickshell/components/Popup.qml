// home/quickshell/.config/quickshell/components/Popup.qml
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: root

    property string popup_name: ""
    property real preferred_width: 260
    // Set while a native menu from this popup is open, so the focus grab doesn't close us.
    property bool suspend_grab: false

    implicitWidth: preferred_width
    default property alias content: content_scope.data

    color: "transparent"
    visible: Popups.open_name === root.popup_name && Popups.open_screen_name !== ""

    // The anchor is the island's body; its parent is the Island, which knows which end caps it has.
    readonly property var island: Popups.open_anchor ? Popups.open_anchor.parent : null
    readonly property bool island_cap_left: !!island && island.cap_left === true
    readonly property bool island_cap_right: !!island && island.cap_right === true
    // cap_right-only = a left island, flush with the screen's left edge; cap_left-only = a right island.
    readonly property string side: (island_cap_left && island_cap_right) ? "center" : island_cap_right ? "left" : island_cap_left ? "right" : "center"

    // A layer surface pinned to the screen edge: xdg popups landed a few px short of it.
    screen: Quickshell.screens.find(s => s.name === Popups.open_screen_name) || null
    anchors.top: true
    anchors.left: side === "left"
    anchors.right: side === "right"
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property real grow: 0
    readonly property real start_width: Popups.open_anchor ? Math.min(Popups.open_anchor.width, width) : width

    // Runs once per open: grows from the island's width and edge to full size, then stops.
    NumberAnimation {
        id: grow_anim
        target: root
        property: "grow"
        from: 0
        to: 1
        duration: 220
        easing.type: Easing.OutCubic
    }

    Item {
        id: reveal
        readonly property real w: root.start_width + (root.width - root.start_width) * root.grow
        width: w
        height: root.height * root.grow
        x: root.side === "right" ? root.width - w : root.side === "left" ? 0 : (root.width - w) / 2
        clip: true

        Item {
            x: -reveal.x
            width: root.width
            height: root.height

            // Reads as the island unfolding downward: its color, joined flush at the top.
            Rectangle {
                anchors.fill: parent
                color: Popups.open_color
                bottomLeftRadius: 10
                bottomRightRadius: 10
            }

            FocusScope {
                id: content_scope
                anchors.fill: parent
                focus: true

                Keys.onEscapePressed: Popups.close()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Q) {
                        Popups.close();
                        event.accepted = true;
                    }
                }
            }
        }
    }

    HyprlandFocusGrab {
        id: focus_grab
        windows: [root]
        onCleared: Popups.close()
    }

    // Grabbing before the backing surface is mapped is a no-op, so defer one tick.
    onSuspend_grabChanged: {
        focus_grab.active = root.visible && !root.suspend_grab;
        if (!root.suspend_grab && root.visible) content_scope.forceActiveFocus();
    }

    onVisibleChanged: {
        if (visible) {
            grow_anim.restart();
            content_scope.forceActiveFocus();
            Qt.callLater(() => focus_grab.active = root.visible && !root.suspend_grab);
        } else {
            focus_grab.active = false;
        }
    }
}
