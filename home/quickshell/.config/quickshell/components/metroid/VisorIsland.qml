// home/quickshell/.config/quickshell/components/metroid/VisorIsland.qml
import QtQuick
import QtQuick.Shapes
import "../"
import "../../theme"

// A bar island cut like a piece of the Prime helmet frame; drawn once, nothing animates.
Item {
    id: root

    // "frame" (tapering sweeps), "combat" (notched brackets, tank ticks) or "scan" (pod ends with reticles).
    property string variant: "frame"
    property bool cap_left: false
    property bool cap_right: false
    property real cap: 0
    property color bg_color: Theme.bg_crust
    property real border_width: 1
    property color border_color: Theme.theme_primary

    readonly property real h: root.height
    readonly property real w: root.width
    readonly property real bx0: root.cap_left ? root.cap : 0
    readonly property real bx1: root.cap_right ? root.w - root.cap : root.w
    readonly property real cx: root.w / 2
    readonly property bool center: root.cap_left && root.cap_right
    readonly property color line: Theme.theme_primary
    readonly property color faint: Qt.alpha(Theme.theme_primary, 0.28)

    // A right cap in outward coords (u from the body end, v down), from the bottom edge to the top.
    function cap_points(i) {
        const c = root.cap, h = root.h;
        if (root.variant === "combat") return { start: [0, h - i], segs: [{ t: "L", p: [c * 0.42, h * 0.52] }, { t: "L", p: [c * 0.64, h * 0.52] }, { t: "L", p: [c - i, 0] }] };
        if (root.variant === "scan") {
            const rx = Math.max(0, c - i), ry = Math.max(0, h / 2 - i);
            return { start: [0, h - i], segs: [{ t: "A", rx: rx, ry: ry, p: [c - i, h / 2] }, { t: "A", rx: rx, ry: ry, p: [0, i] }] };
        }
        return { start: [0, h - i], segs: [{ t: "C", c1: [c * 0.5, h - i], c2: [c * 0.8, h * 0.45], p: [c - i, 0] }] };
    }

    function seg(s, to, fx, c1, c2) {
        if (s.t === "L") return " L " + fx(to[0]) + " " + to[1];
        if (s.t === "A") return " A " + s.rx + " " + s.ry + " 0 0 0 " + fx(to[0]) + " " + to[1];
        return " C " + fx(c1[0]) + " " + c1[1] + " " + fx(c2[0]) + " " + c2[1] + " " + fx(to[0]) + " " + to[1];
    }

    function outline(i, closed) {
        const cp = root.cap_points(i), n = cp.segs.length;
        const xl = u => root.bx0 - u, xr = u => root.bx1 + u;
        let d;
        if (root.cap_left) {
            const tip = cp.segs[n - 1].p;
            d = "M " + xl(tip[0]) + " " + tip[1];
            for (let k = n - 1; k >= 0; k--) {
                const s = cp.segs[k], prev = k > 0 ? cp.segs[k - 1].p : cp.start;
                d += root.seg(s, prev, xl, s.c2, s.c1);
            }
        } else {
            d = "M 0 " + (root.h - i);
        }
        d += " L " + root.bx1 + " " + (root.h - i);
        if (root.cap_right) for (const s of cp.segs) d += root.seg(s, s.p, xr, s.c1, s.c2);
        else d += " L " + root.w + " " + (root.h - i);
        return closed ? d + " L " + root.w + " 0 L 0 0 Z" : d;
    }

    // Short L brackets at the body's corners, like a lock-on around the clock.
    function brackets(inset, len) {
        const x0 = root.bx0 + inset, x1 = root.bx1 - inset, y0 = inset, y1 = root.h - inset - 2;
        return "M " + (x0 + len) + " " + y0 + " L " + x0 + " " + y0 + " L " + x0 + " " + (y0 + len)
            + " M " + (x1 - len) + " " + y0 + " L " + x1 + " " + y0 + " L " + x1 + " " + (y0 + len)
            + " M " + x0 + " " + (y1 - len) + " L " + x0 + " " + y1 + " L " + (x0 + len) + " " + y1
            + " M " + x1 + " " + (y1 - len) + " L " + x1 + " " + y1 + " L " + (x1 - len) + " " + y1;
    }

    // The center island's reticle marks at its bottom middle.
    readonly property string marks_path: {
        const h = root.h, cx = root.cx;
        if (!root.center) return "";
        if (root.variant === "frame") return "M " + (cx - 5) + " " + (h - 1) + " L " + cx + " " + (h - 6) + " L " + (cx + 5) + " " + (h - 1)
            + " M " + (cx - 14) + " " + h + " L " + (cx - 14) + " " + (h - 4) + " M " + (cx + 14) + " " + h + " L " + (cx + 14) + " " + (h - 4);
        if (root.variant === "combat") return "M " + cx + " " + (h - 2) + " L " + cx + " " + (h - 8) + " M " + (cx - 4) + " " + (h - 5) + " L " + (cx + 4) + " " + (h - 5);
        return "";
    }

    // Energy-tank squares (combat) or a dotted scan line (scan) along the bottom, split at the center mark.
    readonly property string rail_path: {
        const y = root.variant === "combat" ? root.h - root.border_width - 3.5 : root.h - 4;
        const a = root.bx0 + 6, b = root.bx1 - 6;
        if (root.center && root.variant === "combat") return "M " + a + " " + y + " L " + (root.cx - 12) + " " + y + " M " + (root.cx + 12) + " " + y + " L " + b + " " + y;
        return "M " + a + " " + y + " L " + b + " " + y;
    }

    readonly property string teeth_path: {
        const h = root.h, t = [];
        if (root.cap_left) t.push(root.bx0);
        if (root.cap_right) t.push(root.bx1);
        if (root.variant === "combat") return t.map(x => {
            const s = x === root.bx0 && root.cap_left ? -1 : 1, u0 = root.cap * 0.42, u1 = root.cap * 0.64, v = h * 0.52;
            return "M " + (x + s * u0) + " " + v + " L " + (x + s * u1) + " " + v + " L " + (x + s * u1) + " " + (v + 3) + " L " + (x + s * u0) + " " + (v + 3) + " Z";
        }).join(" ");
        if (root.variant === "frame") return t.map(x => "M " + (x - 3) + " " + h + " L " + x + " " + (h - 5) + " L " + (x + 3) + " " + h + " Z").join(" ");
        return "";
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillGradient: LinearGradient {
                x1: 0
                y1: 0
                x2: 0
                y2: root.h
                GradientStop { position: 0; color: Qt.alpha(Theme.ui_visual_bg, 0.75) }
                GradientStop { position: 1; color: root.bg_color }
            }
            PathSvg { path: root.outline(0, true) }
        }

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: root.cx
                centerY: root.h * 2.4
                focalX: root.cx
                focalY: root.h * 2.4
                centerRadius: Math.max(root.w * 0.6, root.h * 2)
                focalRadius: 0
                GradientStop { position: 0; color: Qt.alpha(Theme.theme_primary, 0.16) }
                GradientStop { position: 0.7; color: Qt.alpha(Theme.theme_primary, 0) }
            }
            PathSvg { path: root.outline(0, true) }
        }

        ShapePath {
            strokeWidth: root.border_width
            strokeColor: root.border_width > 0 ? root.border_color : "transparent"
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            joinStyle: ShapePath.MiterJoin
            PathSvg { path: root.outline(root.border_width / 2, false) }
        }

        ShapePath {
            strokeWidth: 1
            strokeColor: root.variant === "frame" ? root.faint : "transparent"
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathSvg { path: root.variant === "frame" ? root.outline(4, false) : "M 0 0" }
        }

        ShapePath {
            strokeWidth: 1
            strokeColor: root.marks_path !== "" ? Qt.alpha(root.line, 0.85) : "transparent"
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathSvg { path: root.marks_path || "M 0 0" }
        }

        ShapePath {
            strokeWidth: 1
            strokeColor: root.center && root.variant === "frame" ? Qt.alpha(root.line, 0.6) : "transparent"
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathSvg { path: root.center && root.variant === "frame" ? root.brackets(3, 5) : "M 0 0" }
        }

        ShapePath {
            strokeWidth: root.variant === "combat" ? 3 : 1
            strokeColor: root.variant === "combat" ? Qt.alpha(root.line, 0.32) : root.variant === "scan" ? Qt.alpha(root.line, 0.4) : "transparent"
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            strokeStyle: ShapePath.DashLine
            dashPattern: root.variant === "combat" ? [1, 1] : [1, 2]
            PathSvg { path: root.rail_path }
        }

        ShapePath {
            strokeWidth: -1
            fillColor: root.teeth_path !== "" ? Qt.alpha(root.line, 0.8) : "transparent"
            PathSvg { path: root.teeth_path || "M 0 0" }
        }
    }

    Repeater {
        model: root.variant === "scan" ? [root.cap_left ? root.bx0 - root.cap * 0.42 : -1, root.cap_right ? root.bx1 + root.cap * 0.42 : -1].filter(x => x >= 0) : []

        Reticle {
            required property real modelData
            width: 16
            height: 16
            x: modelData - width / 2
            y: (root.h - height) / 2
            color: Qt.alpha(Theme.theme_primary, 0.75)
            center_color: Theme.theme_primary_light
        }
    }
}
