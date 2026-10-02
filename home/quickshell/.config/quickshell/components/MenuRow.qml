// home/quickshell/.config/quickshell/components/MenuRow.qml
import QtQuick
import "../theme"
import "../services"
import "mgs2" as Mgs2
import "mgs2/MarkerMemory.js" as Memory

Rectangle {
    id: root

    readonly property var st: Style.for_item(root)

    property bool selected: false
    // False for read-only rows, which never dim.
    property bool selectable: true
    // A data row turns the style's accent when selected.
    property bool data_row: false
    readonly property bool accent_active: root.selected && root.data_row && root.st.row_accent_selected.a > 0
    property real marker_travel: 0
    property real base_radius: 4
    // A slot number a style with a row gutter shows; -1 for none.
    property int slot: -1
    // Room reserved at the left for the style's cursor marker; rows add it to their left margin.
    readonly property real inset: root.st.row_gutter ? 32 : root.st.hand_cursor ? 24 : root.st.seg_marker ? row_marker.width + 12 : root.st.row_cursor !== "" ? cursor_text.implicitWidth + 4 : 0
    // The row's shortcut, drawn as a badge at the right by styles that show row keys.
    property string key: ""
    readonly property bool show_key: root.st.row_keys && root.key !== ""
    readonly property real key_space: (root.show_key ? key_badge.width + 6 : 0)

    radius: Style.radius(root.base_radius)
    color: root.selected && !root.st.fade_fills ? root.st.selection_bg : "transparent"
    border.width: root.selected && root.st.selection_border.a > 0 ? 1 : 0
    border.color: root.st.selection_border

    // A soft static halo behind the selected row.
    Repeater {
        model: root.selected && root.st.selection_glow.a > 0 ? [2, 4, 6] : []

        Rectangle {
            required property int modelData
            z: -1
            anchors.fill: parent
            anchors.margins: -modelData
            radius: root.radius + modelData
            color: Qt.alpha(root.st.selection_glow, root.st.selection_glow.a * (0.5 - modelData * 0.06))
        }
    }

    // Styles with an inverse selection repaint the row's text and glyphs in one color.
    function fg(c) {
        if (root.accent_active) return root.st.row_accent_selected;
        if (root.selected && root.st.selection_inverse) return root.st.selection_fg;
        if (root.st.row_dim_unselected) {
            if (root.selected) return Qt.colorEqual(c, root.st.text_fg) ? root.st.text_strong : c;
            if (root.selectable && (Qt.colorEqual(c, root.st.text_fg) || Qt.colorEqual(c, root.st.text_strong))) return Qt.tint(root.st.text_dim, Qt.alpha(root.st.text_fg, 0.3));
        }
        return c;
    }

    onSelectedChanged: {
        if (!root.selected || !root.st.seg_marker) return;
        const from = Memory.owner === root.parent ? Memory.y - root.y : 0;
        Memory.owner = root.parent;
        Memory.y = root.y;
        marker_slide.stop();
        root.marker_travel = 0;
        if (from !== 0 && root.visible && Power.on_ac) {
            root.marker_travel = from;
            marker_slide.start();
        }
    }

    onVisibleChanged: {
        if (!root.visible && Memory.owner === root.parent) Memory.owner = null;
    }

    NumberAnimation {
        id: marker_slide
        target: root
        property: "marker_travel"
        to: 0
        duration: 90
        easing.type: Easing.Linear
    }

    FadeFill {
        visible: root.selected && root.st.fade_fills
        fill: root.st.selection_bg
        radius: root.st.selection_edge.a > 0 ? root.radius : 0
    }

    Rectangle {
        visible: root.selected && root.st.selection_shade.a > 0
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0; color: root.st.selection_shade }
            GradientStop { position: 1; color: root.st.selection_bg }
        }

        Sheen {
            color_top: root.st.sheen
            corner: parent.radius
        }
    }

    DashedOutline {
        visible: root.selected && root.st.selection_outline.a > 0
        anchors.fill: parent
        anchors.margins: 1
        color: root.st.selection_outline
    }

    LockBrackets {
        shown: root.selected
    }

    Rectangle {
        visible: root.selected && root.st.selection_bar
        width: 2
        height: parent.height
        color: root.st.caret_color
    }

    Rectangle {
        visible: root.selected && root.st.selection_edge.a > 0
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: Math.max(6, parent.height - 14)
        topRightRadius: 3
        bottomRightRadius: 3
        color: root.st.selection_edge
    }

    Rectangle {
        visible: root.selected && root.st.selection_rule.a > 0
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: root.st.selection_rule
    }

    Text {
        visible: root.st.row_gutter
        x: 6
        width: 20
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        text: root.key !== "" ? root.key : root.slot >= 0 ? String(root.slot) : ""
        color: root.selected ? root.st.text_accent : root.st.text_muted
        font.family: root.st.mono_font
        font.pixelSize: root.st.fs(-3)
        font.bold: root.selected
    }

    Text {
        id: cursor_text
        visible: root.selected && root.st.row_cursor !== "" && !root.st.seg_marker && Style.caret_phase
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        text: root.st.row_cursor
        color: root.st.caret_color
        font.family: root.st.mono_font
        font.pixelSize: root.st.fs(-1)
        font.bold: true
    }

    Mgs2.Marker {
        id: row_marker
        visible: root.selected && root.st.seg_marker
        cap_height: root.st.fs(0) * 1.1
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.marker_travel
    }

    HandCursor {
        visible: root.selected && root.st.hand_cursor
        x: 3
        anchors.verticalCenter: parent.verticalCenter
        width: 19
        height: 12
    }

    KeyBadge {
        id: key_badge
        visible: root.show_key
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        key: root.key
        on_fill: root.selected && root.st.selection_inverse
    }
}
