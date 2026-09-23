// home/quickshell/.config/quickshell/components/MenuFrame.qml
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../theme"
import "../services"

PanelWindow {
    id: root

    property string popup_name: ""
    property real preferred_width: 260
    // Set while a native menu from this popup is open, so the focus grab doesn't close us.
    property bool suspend_grab: false

    default property alias content: content_scope.data

    readonly property bool wanted: Popups.open_name === root.popup_name && Popups.open_screen_name !== ""

    // Latched on open so the frame keeps its place and color while the close animation plays.
    property var held_anchor: null
    property string held_screen_name: ""
    property color held_color: Theme.bg_mantle

    property real island_x: 0
    property real island_w: 0
    property real island_h: 0
    property real body_x: 0
    property real body_w: 0
    property real cap_w: 0
    property bool cap_left: false
    property bool cap_right: false

    // Popups add this to their implicitHeight: content starts below the strip the island occupies.
    readonly property real strip_height: island_h

    // cap_right-only = a left island, flush with the screen's left edge; cap_left-only = a right island.
    readonly property string side: (cap_left && cap_right) ? "center" : cap_right ? "left" : cap_left ? "right" : "center"

    readonly property real screen_w: root.screen ? root.screen.width : root.width
    readonly property real panel_w: Math.min(screen_w, Math.max(preferred_width, island_w))
    readonly property real panel_h: Math.max(island_h, root.implicitHeight)
    readonly property real panel_x: side === "left" ? 0 : side === "right" ? screen_w - panel_w : Math.max(0, Math.min(screen_w - panel_w, island_x + (island_w - panel_w) / 2))

    property real morph: 0
    property real content_opacity: 0

    readonly property real cur_x: island_x + (panel_x - island_x) * morph
    readonly property real cur_w: island_w + (panel_w - island_w) * morph
    readonly property real cur_h: island_h + (panel_h - island_h) * morph
    readonly property real slant_l: cap_left ? cap_w * (1 - morph) : 0
    readonly property real slant_r: cap_right ? cap_w * (1 - morph) : 0
    readonly property real corner: Math.min(10 * morph, cur_h / 2)

    screen: Quickshell.screens.find(s => s.name === root.held_screen_name) || null
    anchors.top: true
    anchors.left: true
    anchors.right: true
    // Setting exclusiveZone would flip this back to Normal and push the frame below the bar.
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: false
    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.wanted && !root.suspend_grab ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand

    // The island body stays out of the mask so its clicks still reach the bar underneath.
    mask: Region {
        item: shape_bounds

        Region {
            x: Math.round(root.body_x)
            y: 0
            width: Math.round(root.body_w)
            height: Math.round(root.island_h)
            intersection: Intersection.Subtract
        }
    }

    function latch_island() {
        const body = root.held_anchor;
        const island = body ? body.parent : null;
        if (!island) {
            root.island_x = root.screen_w / 2;
            root.island_w = 0;
            root.island_h = 0;
            root.body_x = root.island_x;
            root.body_w = 0;
            root.cap_w = 0;
            root.cap_left = false;
            root.cap_right = false;
            return;
        }
        // The bar window spans the screen from 0,0, so its window coords are screen coords.
        const island_pos = island.mapToItem(null, 0, 0);
        const body_pos = body.mapToItem(null, 0, 0);
        root.island_x = island_pos.x;
        root.island_w = island.width;
        root.island_h = island.height;
        root.body_x = body_pos.x;
        root.body_w = body.width;
        root.cap_w = island.cap_width || 0;
        root.cap_left = island.cap_left === true;
        root.cap_right = island.cap_right === true;
    }

    onWantedChanged: {
        if (wanted) {
            close_anim.stop();
            if (!visible) {
                morph = 0;
                content_opacity = 0;
            }
            held_anchor = Popups.open_anchor;
            held_screen_name = Popups.open_screen_name;
            held_color = Popups.open_color;
            latch_island();
            visible = true;
            open_anim.restart();
            content_scope.forceActiveFocus();
            grab_ready = false;
            grab_retries = 0;
            grab_delay.restart();
        } else if (visible) {
            open_anim.stop();
            close_anim.restart();
        }
    }

    SequentialAnimation {
        id: open_anim
        NumberAnimation { target: root; property: "morph"; to: 1; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "content_opacity"; to: 1; duration: 120; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: close_anim
        NumberAnimation { target: root; property: "content_opacity"; to: 0; duration: 120; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "morph"; to: 0; duration: 160; easing.type: Easing.InCubic }
        ScriptAction {
            script: {
                root.visible = false;
                root.held_anchor = null;
            }
        }
    }

    Item {
        id: shape_bounds
        x: root.cur_x
        width: root.cur_w
        height: root.cur_h
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: root.held_color
            fillRule: ShapePath.OddEvenFill
            startX: root.cur_x
            startY: 0
            PathLine { x: root.cur_x + root.cur_w; y: 0 }
            PathLine { x: root.cur_x + root.cur_w - root.slant_r; y: root.cur_h - root.corner }
            PathArc { x: root.cur_x + root.cur_w - root.slant_r - root.corner; y: root.cur_h; radiusX: root.corner; radiusY: root.corner }
            PathLine { x: root.cur_x + root.slant_l + root.corner; y: root.cur_h }
            PathArc { x: root.cur_x + root.slant_l; y: root.cur_h - root.corner; radiusX: root.corner; radiusY: root.corner }
            PathLine { x: root.cur_x; y: 0 }

            // Hole over the island body so the bar's own modules show through; 1px short so no seam shows under it.
            PathMove { x: root.body_x; y: 0 }
            PathLine { x: root.body_x + root.body_w; y: 0 }
            PathLine { x: root.body_x + root.body_w; y: Math.max(0, root.island_h - 1) }
            PathLine { x: root.body_x; y: Math.max(0, root.island_h - 1) }
            PathLine { x: root.body_x; y: 0 }
        }
    }

    Item {
        x: root.panel_x
        y: root.island_h
        width: root.panel_w
        height: Math.max(0, root.panel_h - root.island_h)
        clip: true
        opacity: root.content_opacity

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
        if (root.wanted && root.grab_retries < 2 && Date.now() - root.grab_armed_ms < 300) {
            root.grab_retries += 1;
            root.grab_ready = false;
            grab_delay.restart();
            return;
        }
        Popups.close();
    }

    Loader {
        active: root.visible && root.wanted && root.grab_ready && !root.suspend_grab
        sourceComponent: HyprlandFocusGrab {
            active: true
            windows: [root]
            onCleared: root.grab_cleared()
        }
    }

    onSuspend_grabChanged: if (!root.suspend_grab && root.visible) content_scope.forceActiveFocus()
}
