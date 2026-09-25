// home/quickshell/.config/quickshell/components/oasis/DuneLine.qml
import QtQuick
import QtQuick.Shapes

// A dune contour divider: two wavy 1px lines, fading out to the right or at both ends.
Shape {
    id: root

    property color color: "transparent"
    // "right" fades from the left end out; "both" fades in and out.
    property string fade: "right"

    height: 9
    preferredRendererType: Shape.CurveRenderer

    readonly property bool both: root.fade === "both"

    // One period of each wave as cubic segments [x0, y0, c1x, c1y, c2x, c2y, x1, y1] on a 96 x 9 grid.
    readonly property var upper: [[0, 3, 16, 0.8, 32, 0.8, 48, 3], [48, 3, 64, 5.2, 80, 5.2, 96, 3]]
    readonly property var lower: [[0, 7, 20, 5.4, 36, 5.4, 52, 7.2], [52, 7.2, 68, 9, 82, 8.2, 96, 7]]

    // The wave repeated across the width as a band 1px thick, so it can take a fill gradient.
    function band(segs) {
        const n = Math.max(1, Math.ceil(root.width / 96));
        const pt = (x, y, dy) => x.toFixed(2) + " " + (y + dy).toFixed(2);
        const all = [];
        for (let i = 0; i < n; i++) for (const s of segs) all.push(s.map((v, j) => j % 2 === 0 ? v + i * 96 : v));
        let d = "M" + pt(all[0][0], all[0][1], -0.5);
        for (const s of all) d += "C" + pt(s[2], s[3], -0.5) + " " + pt(s[4], s[5], -0.5) + " " + pt(s[6], s[7], -0.5);
        const last = all[all.length - 1];
        d += "L" + pt(last[6], last[7], 0.5);
        for (let i = all.length - 1; i >= 0; i--) {
            const s = all[i];
            d += "C" + pt(s[4], s[5], 0.5) + " " + pt(s[2], s[3], 0.5) + " " + pt(s[0], s[1], 0.5);
        }
        return d + "Z";
    }

    readonly property string upper_path: root.width > 0 ? root.band(root.upper) : "M0 0"
    readonly property string lower_path: root.width > 0 ? root.band(root.lower) : "M0 0"

    ShapePath {
        strokeWidth: -1
        fillGradient: LinearGradient {
            x1: 0
            y1: 0
            x2: root.width
            y2: 0
            GradientStop { position: 0; color: root.both ? "transparent" : root.color }
            GradientStop { position: root.both ? 0.18 : 0.35; color: root.both ? root.color : Qt.alpha(root.color, root.color.a * 0.7) }
            GradientStop { position: root.both ? 0.82 : 0.7; color: root.both ? root.color : Qt.alpha(root.color, root.color.a * 0.4) }
            GradientStop { position: 1; color: "transparent" }
        }
        PathSvg { path: root.upper_path }
    }

    ShapePath {
        strokeWidth: -1
        fillGradient: LinearGradient {
            x1: 0
            y1: 0
            x2: root.width
            y2: 0
            GradientStop { position: 0; color: root.both ? "transparent" : Qt.alpha(root.color, root.color.a * 0.45) }
            GradientStop { position: root.both ? 0.18 : 0.35; color: Qt.alpha(root.color, root.color.a * (root.both ? 0.45 : 0.32)) }
            GradientStop { position: root.both ? 0.82 : 0.7; color: Qt.alpha(root.color, root.color.a * (root.both ? 0.45 : 0.18)) }
            GradientStop { position: 1; color: "transparent" }
        }
        PathSvg { path: root.lower_path }
    }
}
