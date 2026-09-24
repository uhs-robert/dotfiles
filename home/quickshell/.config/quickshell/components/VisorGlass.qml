// home/quickshell/.config/quickshell/components/VisorGlass.qml
import QtQuick
import QtQuick.Shapes
import "../theme"

// A visor pane: rounded top, wide elliptical bottom, glass gradient, and a static arc just under the bottom edge.
Shape {
    id: root

    property real top_radius: Style.frame_radius
    property color border_color: Style.frame_border_color
    property real border_width: Math.max(1, Style.frame_border_width)
    property color arc_color: Qt.alpha(Theme.theme_primary, 0.4)

    readonly property real rt: Math.min(root.top_radius, root.width / 2, root.height / 2)
    readonly property real rx: Math.min(34, root.width / 4)
    readonly property real ry: Math.max(0, Math.min(46, (root.height - root.rt) * 0.6))

    visible: Style.frame_visor
    preferredRendererType: Shape.CurveRenderer

    function outline(i) {
        const w = root.width, h = root.height, t = Math.max(0, root.rt - i), x = Math.max(0, root.rx - i), y = Math.max(0, root.ry - i);
        return "M " + i + " " + (i + t)
            + " A " + t + " " + t + " 0 0 1 " + (i + t) + " " + i
            + " L " + (w - i - t) + " " + i
            + " A " + t + " " + t + " 0 0 1 " + (w - i) + " " + (i + t)
            + " L " + (w - i) + " " + (h - i - y)
            + " A " + x + " " + y + " 0 0 1 " + (w - i - x) + " " + (h - i)
            + " L " + (i + x) + " " + (h - i)
            + " A " + x + " " + y + " 0 0 1 " + i + " " + (h - i - y)
            + " Z";
    }

    function inside(px, py, m) {
        const w = root.width, h = root.height, x = root.rx - m, y = root.ry - m;
        if (px < m || px > w - m || py > h - m) return false;
        if (py < h - root.ry || x <= 0 || y <= 0) return true;
        const cx = px < root.rx ? root.rx : px > w - root.rx ? w - root.rx : px;
        const dx = (px - cx) / x, dy = (py - (h - root.ry)) / y;
        return dx * dx + dy * dy <= 1;
    }

    // Samples the top of an ellipse centred below the pane and keeps what lies inside it.
    readonly property var arc_points: {
        const w = root.width, h = root.height;
        if (w <= 0 || h <= 0) return [];
        const a = w * 0.56, b = 48, cy = h + b - Math.min(28, h * 0.25);
        const pts = [];
        for (let n = 0; n <= 96; n++) {
            const t = Math.PI + Math.PI * n / 96;
            const p = Qt.point(w / 2 + a * Math.cos(t), cy + b * Math.sin(t));
            if (root.inside(p.x, p.y, root.border_width + 1)) pts.push(p);
        }
        return pts;
    }

    ShapePath {
        strokeWidth: -1
        fillColor: Qt.alpha(Theme.bg_crust, 0.94)
        PathSvg { path: root.outline(0) }
    }

    ShapePath {
        strokeWidth: -1
        fillGradient: LinearGradient {
            x1: 0
            y1: 0
            x2: 0
            y2: root.height
            GradientStop { position: 0; color: Qt.alpha(Theme.ui_visual_bg, 0.55) }
            GradientStop { position: 1; color: Qt.alpha(Theme.ui_visual_bg, 0) }
        }
        PathSvg { path: root.outline(0) }
    }

    ShapePath {
        strokeWidth: -1
        fillGradient: RadialGradient {
            centerX: root.width / 2
            centerY: root.height * 1.3
            focalX: root.width / 2
            focalY: root.height * 1.3
            centerRadius: Math.max(root.width * 0.5, root.height * 0.9)
            focalRadius: 0
            GradientStop { position: 0; color: Qt.alpha(Theme.theme_primary, 0.2) }
            GradientStop { position: 0.6; color: Qt.alpha(Theme.theme_primary, 0) }
        }
        PathSvg { path: root.outline(0) }
    }

    ShapePath {
        strokeWidth: 2
        strokeColor: root.arc_points.length > 1 ? root.arc_color : "transparent"
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        PathPolyline { path: root.arc_points }
    }

    ShapePath {
        strokeWidth: root.border_width
        strokeColor: root.border_color
        fillColor: "transparent"
        PathSvg { path: root.outline(root.border_width / 2) }
    }
}
