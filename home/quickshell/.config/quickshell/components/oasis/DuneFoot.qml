// home/quickshell/.config/quickshell/components/oasis/DuneFoot.qml
import QtQuick
import QtQuick.Shapes

// A faint sand dune along the bottom of a panel, following its rounded bottom corners.
Shape {
    id: root

    property color color: "transparent"
    property real bottom_radius: 0

    // Fixed, so the path never feeds back through the Shape's implicit size.
    readonly property real foot: 46

    visible: root.color.a > 0
    height: root.foot
    preferredRendererType: Shape.CurveRenderer

    readonly property string dune_path: {
        const w = root.width, h = root.foot, sx = w / 400, sy = h / 40;
        const r = Math.min(root.bottom_radius, h / 2, w / 2);
        const p = (x, y) => (x * sx).toFixed(2) + " " + (y * sy).toFixed(2);
        return "M" + p(0, 26) + "C" + p(50, 12) + " " + p(110, 12) + " " + p(160, 22) + "C" + p(210, 32) + " " + p(260, 38) + " " + p(320, 22)
            + "C" + p(380, 6) + " " + p(380, 14) + " " + p(400, 18) + "L" + w + " " + (h - r) + "Q" + w + " " + h + " " + (w - r) + " " + h
            + "L" + r + " " + h + "Q0 " + h + " 0 " + (h - r) + "Z";
    }

    ShapePath {
        strokeWidth: -1
        fillGradient: LinearGradient {
            x1: 0
            y1: 0
            x2: 0
            y2: root.foot
            GradientStop { position: 0; color: root.color }
            GradientStop { position: 1; color: Qt.alpha(root.color, root.color.a * 0.4) }
        }
        PathSvg { path: root.dune_path }
    }
}
