// home/quickshell/.config/quickshell/components/oasis/Constellation.qml
import QtQuick
import QtQuick.Shapes
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../theme"
import "../../services"

// Workspaces as a low constellation: the focused star a sand sparkle, occupied ones lit, empty ones hollow, apps under their star.
Item {
    id: root

    // The Workspaces module, for its icon, name and window helpers.
    required property Item host
    property var workspaces: []
    property bool compact: false

    readonly property int glyph: compact ? 11 : 13
    readonly property int gap: 3
    readonly property int lead: 2
    readonly property color sand: Theme.theme_secondary
    readonly property var lifts: [2, 0, 3, 1, 4]

    function slot_width(k) {
        return Math.max(30, k * root.glyph + Math.max(0, k - 1) * root.gap + 12);
    }

    readonly property var slots: {
        const out = [];
        let x = root.lead;
        for (const w of root.workspaces) {
            const k = w.toplevels.values.length, wd = root.slot_width(k);
            out.push({ id: w.id, x: x, w: wd, cx: x + wd / 2, cy: 7 + root.lifts[Math.abs(w.id) % 5], k: k, focused: w.focused, active: w.active });
            x += wd;
        }
        return out;
    }

    implicitWidth: slots.length ? slots[slots.length - 1].x + slots[slots.length - 1].w + root.lead : 0
    implicitHeight: 34

    // A four-point sparkle of radius r at (x, y).
    function sparkle(x, y, r) {
        const k = r * 0.18;
        const p = (px, py) => (x + px).toFixed(2) + " " + (y + py).toFixed(2);
        return "M" + p(0, -r) + "Q" + p(k, -k) + " " + p(r, 0) + "Q" + p(k, k) + " " + p(0, r) + "Q" + p(-k, k) + " " + p(-r, 0) + "Q" + p(-k, -k) + " " + p(0, -r) + "Z";
    }

    function star_radius(s) {
        return s.focused ? 7.8 : s.k ? (s.active ? 5 : 4.2) : 1.8;
    }

    // A link between neighbouring stars, trimmed short of each so it never crosses them.
    function link(a, b) {
        const dx = b.cx - a.cx, dy = b.cy - a.cy, len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
        const ta = root.star_radius(a) + 3, tb = root.star_radius(b) + 3;
        if (len <= ta + tb) return "";
        const ux = dx / len, uy = dy / len;
        return "M" + (a.cx + ux * ta).toFixed(2) + " " + (a.cy + uy * ta).toFixed(2) + "L" + (b.cx - ux * tb).toFixed(2) + " " + (b.cy - uy * tb).toFixed(2);
    }

    // Solid links join two lit stars; any link touching an empty star is dashed.
    function links(solid) {
        let d = "";
        for (let i = 1; i < root.slots.length; i++) {
            const a = root.slots[i - 1], b = root.slots[i];
            if (((a.k > 0 || a.focused) && (b.k > 0 || b.focused)) === solid) d += root.link(a, b);
        }
        return d || "M0 0";
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 0.8
            strokeColor: Qt.alpha(Theme.theme_primary, 0.45)
            fillColor: "transparent"
            PathSvg { path: root.links(true) }
        }

        ShapePath {
            strokeWidth: 0.8
            strokeColor: Qt.alpha(Theme.theme_primary, 0.3)
            fillColor: "transparent"
            strokeStyle: ShapePath.DashLine
            dashPattern: [2, 3]
            PathSvg { path: root.links(false) }
        }

        ShapePath {
            strokeWidth: -1
            fillColor: Qt.alpha(root.sand, 0.08)
            PathSvg { path: root.slots.filter(s => s.focused).map(s => "M" + (s.cx - 8) + " " + s.cy + "a8 8 0 1 0 16 0a8 8 0 1 0 -16 0").join("") || "M0 0" }
        }

        ShapePath {
            strokeWidth: -1
            fillColor: Qt.alpha(root.sand, 0.14)
            PathSvg { path: root.slots.filter(s => s.focused).map(s => "M" + (s.cx - 4.5) + " " + s.cy + "a4.5 4.5 0 1 0 9 0a4.5 4.5 0 1 0 -9 0").join("") || "M0 0" }
        }

        ShapePath {
            strokeWidth: -1
            fillColor: root.sand
            PathSvg { path: root.slots.filter(s => s.focused).map(s => root.sparkle(s.cx, s.cy, 7.8)).join("") || "M0 0" }
        }

        ShapePath {
            strokeWidth: -1
            fillColor: Theme.fg_strong
            PathSvg { path: root.slots.filter(s => s.focused).map(s => "M" + (s.cx - 1.2) + " " + s.cy + "a1.2 1.2 0 1 0 2.4 0a1.2 1.2 0 1 0 -2.4 0").join("") || "M0 0" }
        }

        ShapePath {
            strokeWidth: -1
            fillColor: Theme.theme_secondary_strong
            PathSvg { path: root.slots.filter(s => !s.focused && s.active && s.k).map(s => root.sparkle(s.cx, s.cy, 5)).join("") || "M0 0" }
        }

        ShapePath {
            strokeWidth: -1
            fillColor: Theme.theme_primary_light
            PathSvg { path: root.slots.filter(s => !s.focused && !s.active && s.k).map(s => root.sparkle(s.cx, s.cy, 4.2)).join("") || "M0 0" }
        }

        ShapePath {
            strokeWidth: 1
            strokeColor: Theme.fg_dim
            fillColor: "transparent"
            PathSvg { path: root.slots.filter(s => !s.focused && !s.k).map(s => "M" + (s.cx - 1.8) + " " + s.cy + "a1.8 1.8 0 1 0 3.6 0a1.8 1.8 0 1 0 -3.6 0").join("") || "M0 0" }
        }
    }

    Repeater {
        model: root.workspaces

        Item {
            id: slot
            required property var modelData
            required property int index
            readonly property var info: root.slots[index] || { x: 0, w: 0, cx: 0, cy: 0, k: 0, focused: false }

            x: info.x
            width: info.w
            height: root.height

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = '" + slot.modelData.id + "' })")
            }

            HoverHandler {
                id: slot_hover
            }

            Text {
                x: slot.info.w / 2 + (slot.info.focused ? 8 : 5)
                y: slot.info.cy - implicitHeight + (slot.info.focused ? 2 : 4)
                text: String(slot.modelData.id)
                color: slot.info.focused ? root.sand : slot_hover.hovered ? Theme.fg_strong : slot.info.k ? Theme.fg_dim : Theme.fg_muted
                font.family: Style.bar_font_family
                font.pixelSize: 8
                font.weight: Font.Medium
                font.features: { "tnum": 1 }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.height - root.glyph - 3
                spacing: root.gap

                Repeater {
                    model: slot.modelData.toplevels.values

                    Item {
                        id: icon_item
                        required property var modelData

                        width: root.glyph
                        height: width
                        opacity: slot.info.focused || slot_hover.hovered ? 1 : 0.7

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: root.glyph
                            source: root.host.icon_for(root.host.class_of(icon_item.modelData))
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.LeftButton) {
                                    root.host.focus_toplevel(slot.modelData.id, icon_item.modelData.address);
                                } else if (mouse.button === Qt.MiddleButton) {
                                    root.host.close_toplevel(icon_item.modelData.address);
                                }
                            }
                        }

                        HoverHandler {
                            onHoveredChanged: {
                                if (hovered) Tooltip.show(icon_item, icon_item.modelData.title, root.host.name_of(icon_item.modelData));
                                else Tooltip.hide(icon_item);
                            }
                        }
                    }
                }
            }
        }
    }
}
