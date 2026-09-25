// home/quickshell/.config/quickshell/components/oasis/SlantFrame.qml
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import "../../theme"

// An oasis panel: a flat top and a bottom cut to Style.oasis_frame, filled sky to night, with Style.oasis_foot's art along the foot.
Item {
    id: root

    property var st: Style.for_item(root)
    property string shape: root.st.oasis_frame
    property string foot: root.st.oasis_foot
    property color edge_color: root.st.frame_border_color
    property color fill_top: root.st.frame_shade.a > 0 ? root.st.frame_shade : root.st.frame_color
    property color fill_bottom: root.st.frame_color
    // Used only by the "round" shape.
    property real top_radius: 0
    property real bottom_radius: 0

    readonly property real bw: root.st.frame_border_width
    readonly property color sand: Theme.theme_secondary
    readonly property real w: root.width
    readonly property real h: root.height

    // [depth, width] of the bottom-left and bottom-right cuts; width / depth 0.5 is the bar islands' slant.
    readonly property var cuts: ({
            notch: [[18, 9], [18, 9]],
            taper: [[30, 15], [30, 15]],
            lean: [[10, 5], [36, 18]]
        })[root.shape] || [[0, 0], [0, 0]]

    function arc(cx, cy, r, a0, a1) {
        const pts = [];
        for (let k = 0; k <= 8; k++) {
            const a = a0 + (a1 - a0) * k / 8;
            pts.push(Qt.point(cx + r * Math.cos(a), cy + r * Math.sin(a)));
        }
        return pts;
    }

    // The bottom edge from its left end to its right end, for the box inset by i.
    function bottom_edge(i) {
        const x0 = i, x1 = root.w - i, y1 = root.h - i;
        if (root.shape === "round") {
            const r = Math.max(0, Math.min(root.bottom_radius - i, (x1 - x0) / 2, (y1 - i) / 2));
            return root.arc(x0 + r, y1 - r, r, Math.PI, Math.PI / 2).concat(root.arc(x1 - r, y1 - r, r, Math.PI / 2, 0));
        }
        if (root.shape === "keel") {
            const k = Math.min(7, root.h / 4), tw = Math.min((x1 - x0) * 0.36, 150), cx = root.w / 2;
            return [Qt.point(x0, y1 - k), Qt.point(cx - tw / 2 - k / 2, y1 - k), Qt.point(cx - tw / 2, y1), Qt.point(cx + tw / 2, y1), Qt.point(cx + tw / 2 + k / 2, y1 - k), Qt.point(x1, y1 - k)];
        }
        const cap = Math.max(1, root.h * 0.45);
        const side = c => {
            const d = Math.max(0, Math.min(c[0], cap) - i * 0.6);
            return [d, c[0] > 0 ? d * c[1] / c[0] : 0];
        };
        const l = side(root.cuts[0]), r = side(root.cuts[1]);
        return [Qt.point(x0, y1 - l[0]), Qt.point(x0 + l[1], y1), Qt.point(x1 - r[1], y1), Qt.point(x1, y1 - r[0])];
    }

    function top_edge(i) {
        const x0 = i, x1 = root.w - i;
        if (root.shape !== "round" || root.top_radius <= 0) return [Qt.point(x0, i), Qt.point(x1, i)];
        const r = Math.max(0, Math.min(root.top_radius - i, (x1 - x0) / 2, root.h / 2));
        return root.arc(x0 + r, i + r, r, Math.PI, Math.PI * 1.5).concat(root.arc(x1 - r, i + r, r, Math.PI * 1.5, Math.PI * 2));
    }

    function outline(i) {
        const pts = root.top_edge(i).concat(root.bottom_edge(i).reverse());
        pts.push(pts[0]);
        return pts;
    }

    // The height of the bottom edge pts at x.
    function floor_at(pts, x) {
        if (x <= pts[0].x) return pts[0].y;
        for (let k = 1; k < pts.length; k++) {
            if (x <= pts[k].x) {
                const a = pts[k - 1], b = pts[k];
                return b.x === a.x ? Math.min(a.y, b.y) : a.y + (b.y - a.y) * (x - a.x) / (b.x - a.x);
            }
        }
        return pts[pts.length - 1].y;
    }

    // A band between two bottom edges, for lines that follow the cuts.
    function band(i0, i1) {
        return root.bottom_edge(i0).concat(root.bottom_edge(i1).reverse());
    }

    readonly property real dune_height: 46
    // DuneFoot's contour on its 400 x 40 grid, clipped to the bottom edge.
    readonly property var dune_path: {
        if (root.foot !== "dune" || root.w <= 0) return [Qt.point(0, 0)];
        const segs = [[0, 26, 50, 12, 110, 12, 160, 22], [160, 22, 210, 32, 260, 38, 320, 22], [320, 22, 380, 6, 380, 14, 400, 18]];
        const sx = root.w / 400, sy = root.dune_height / 40, y0 = root.h - root.dune_height;
        const floor = root.bottom_edge(root.bw), pts = [];
        for (const s of segs) {
            for (let k = pts.length ? 1 : 0; k <= 16; k++) {
                const t = k / 16, u = 1 - t;
                const x = (u * u * u * s[0] + 3 * u * u * t * s[2] + 3 * u * t * t * s[4] + t * t * t * s[6]) * sx;
                const y = y0 + (u * u * u * s[1] + 3 * u * u * t * s[3] + 3 * u * t * t * s[5] + t * t * t * s[7]) * sy;
                const cx = Math.max(root.bw, Math.min(root.w - root.bw, x));
                pts.push(Qt.point(cx, Math.min(y, root.floor_at(floor, cx))));
            }
        }
        return pts.concat(floor.reverse());
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
                GradientStop { position: 0; color: root.fill_top }
                GradientStop { position: 1; color: root.fill_bottom }
            }
            PathPolyline { path: root.outline(0) }
        }

        ShapePath {
            strokeWidth: -1
            fillGradient: LinearGradient {
                x1: 0
                y1: root.h - (root.foot === "fade" ? 90 : 36)
                x2: 0
                y2: root.h
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Qt.alpha(root.sand, root.foot === "fade" ? 0.1 : 0.08) }
            }
            PathPolyline { path: root.foot === "horizon" || root.foot === "fade" ? root.outline(root.bw) : [] }
        }

        ShapePath {
            strokeWidth: -1
            fillGradient: LinearGradient {
                x1: 0
                y1: root.h - root.dune_height
                x2: 0
                y2: root.h
                GradientStop { position: 0; color: Qt.alpha(root.sand, 0.07) }
                GradientStop { position: 1; color: Qt.alpha(root.sand, 0.03) }
            }
            PathPolyline { path: root.foot === "dune" ? root.dune_path : [] }
        }

        ShapePath {
            strokeWidth: -1
            fillGradient: LinearGradient {
                x1: 0
                y1: 0
                x2: root.w
                y2: 0
                GradientStop { position: 0; color: Qt.alpha(root.sand, 0.1) }
                GradientStop { position: 0.3; color: Qt.alpha(root.sand, 0.55) }
                GradientStop { position: 0.7; color: Qt.alpha(root.sand, 0.55) }
                GradientStop { position: 1; color: Qt.alpha(root.sand, 0.1) }
            }
            PathPolyline { path: root.foot === "horizon" ? root.band(root.bw, root.bw + 1) : [] }
        }

        ShapePath {
            strokeWidth: root.bw > 0 ? root.bw : -1
            strokeColor: root.edge_color
            fillColor: "transparent"
            joinStyle: ShapePath.MiterJoin
            PathPolyline { path: root.outline(root.bw / 2) }
        }
    }
}
