// home/quickshell/.config/quickshell/bar/Island.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../services"

Item {
    id: root

    property color bg_color: "#232634"
    property bool cap_left: false
    property bool cap_right: false
    property int rest_height: 30
    property real max_width: 0
    property string screen_name: ""
    // Popup name -> Component of an item declaring preferred_width, implicitHeight and optionally is_open.
    property var panel_map: ({})
    default property alias content: layout.children

    readonly property alias body_item: body
    readonly property int cap_width: rest_height / 2
    readonly property real rest_body_width: Math.ceil(layout.implicitWidth) + 16
    readonly property real rest_width: rest_body_width + (cap_left ? cap_width : 0) + (cap_right ? cap_width : 0)

    readonly property string open_panel: Popups.open_anchor === body && Popups.open_screen_name === root.screen_name && !!root.panel_map[Popups.open_name] ? Popups.open_name : ""
    readonly property bool expanded: open_panel !== ""

    // Latched so the panel stays loaded and sized while the island shrinks back.
    property string held_panel: ""
    property Item held_item: null

    // cap_right-only is a left island, flush with the screen edge; it grows away from that edge.
    readonly property real grow_align: (cap_left && cap_right) ? 0.5 : cap_right ? 0 : cap_left ? 1 : 0.5
    readonly property real panel_width: held_item ? Math.min(max_width > 0 ? max_width : Infinity, Math.max(held_item.preferred_width || 0, rest_width)) : rest_width
    readonly property real panel_height: held_item ? Math.max(rest_height, held_item.implicitHeight) : rest_height

    property real morph: expanded ? 1 : 0
    Behavior on morph {
        NumberAnimation { duration: 380; easing.type: Easing.OutCubic }
    }

    property real corner: expanded ? 10 : 0
    Behavior on corner {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    readonly property real shown_cap: cap_width * (1 - morph)

    signal clicked

    width: rest_width + (panel_width - rest_width) * morph
    height: rest_height + (panel_height - rest_height) * morph
    z: morph > 0 ? 1 : 0

    onOpen_panelChanged: {
        if (root.open_panel === "") return;
        root.held_panel = root.open_panel;
        panel_scope.forceActiveFocus();
    }
    onExpandedChanged: root.release_if_collapsed()
    onMorphChanged: root.release_if_collapsed()

    function release_if_collapsed() {
        if (!root.expanded && root.morph === 0) root.held_panel = "";
    }

    Rectangle {
        id: body

        x: root.cap_left ? root.shown_cap : 0
        width: root.width - (root.cap_left ? root.shown_cap : 0) - (root.cap_right ? root.shown_cap : 0)
        height: root.height
        color: root.bg_color
        bottomLeftRadius: root.corner
        bottomRightRadius: root.corner

        // Declared before the layout so module MouseAreas stack above it.
        // Also soaks up presses on an open panel, so the bar's close-on-press area under it never sees them.
        MouseArea {
            anchors.fill: parent
            onClicked: if (root.morph === 0) root.clicked()
        }

        RowLayout {
            id: layout
            x: 8
            height: root.rest_height
            spacing: 16
            enabled: !root.expanded
            opacity: root.expanded ? 0 : 1

            Behavior on opacity {
                NumberAnimation { duration: root.expanded ? 110 : 200; easing.type: Easing.OutCubic }
            }
        }

        FocusScope {
            id: panel_scope
            anchors.fill: parent
            clip: true
            visible: root.held_panel !== ""
            opacity: root.expanded ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: root.expanded ? 200 : 110; easing.type: Easing.OutCubic }
            }

            Keys.onEscapePressed: Popups.close()
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Q) {
                    Popups.close();
                    event.accepted = true;
                }
            }

            Repeater {
                model: Object.keys(root.panel_map)

                // Stays loaded after the first open so a panel keeps its state between opens.
                Loader {
                    id: panel_loader
                    required property string modelData
                    readonly property bool held: root.held_panel === panel_loader.modelData
                    property bool used: false

                    sourceComponent: root.panel_map[panel_loader.modelData]
                    active: panel_loader.used
                    visible: panel_loader.held
                    focus: panel_loader.held
                    x: (panel_scope.width - width) * root.grow_align
                    width: root.panel_width
                    height: item ? item.implicitHeight : 0

                    function sync_held() {
                        if (panel_loader.held && panel_loader.item) root.held_item = panel_loader.item;
                        else if (root.held_item && root.held_item === panel_loader.item) root.held_item = null;
                    }

                    onHeldChanged: {
                        if (panel_loader.held) panel_loader.used = true;
                        panel_loader.sync_held();
                    }
                    onItemChanged: panel_loader.sync_held()
                    onLoaded: {
                        panel_loader.item.focus = true;
                        if (panel_loader.item.hasOwnProperty("is_open")) panel_loader.item.is_open = Qt.binding(() => root.expanded && panel_loader.held);
                    }
                }
            }
        }
    }

    // Caps overlap the body by 1px so fractional scaling (1.6 on the laptop) leaves no seam.
    Shape {
        visible: root.cap_left && root.shown_cap > 0
        width: root.shown_cap + 1
        height: root.rest_height
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: root.bg_color
            startX: 0
            startY: 0
            PathLine { x: root.shown_cap + 1; y: 0 }
            PathLine { x: root.shown_cap + 1; y: root.rest_height }
            PathLine { x: root.shown_cap; y: root.rest_height }
            PathLine { x: 0; y: 0 }
        }
    }

    Shape {
        visible: root.cap_right && root.shown_cap > 0
        x: root.width - root.shown_cap - 1
        width: root.shown_cap + 1
        height: root.rest_height
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: root.bg_color
            startX: 0
            startY: 0
            PathLine { x: root.shown_cap + 1; y: 0 }
            PathLine { x: 1; y: root.rest_height }
            PathLine { x: 0; y: root.rest_height }
            PathLine { x: 0; y: 0 }
        }
    }
}
