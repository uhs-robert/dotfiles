// home/quickshell/.config/quickshell/components/mgs2/RadarMap.qml
import QtQuick
import QtQuick.Shapes
import "../../theme"

// A Soliton Radar box: seeded floor plan, the wind as a vision cone, hourly contacts around the player dot.
Item {
    id: root

    property string seed: ""
    property color line_color: Theme.theme_primary
    property real wind_dir: 0
    property real wind_frac: 0.3
    property var contacts: []
    property bool animate: false
    property color contact_color: Theme.theme_secondary

    readonly property real cx: root.width / 2
    readonly property real cy: root.height / 2
    readonly property real cone_len: Math.min(root.width, root.height) * (0.3 + 0.2 * root.wind_frac)
    readonly property real cone_half: (38 - 14 * root.wind_frac) * Math.PI / 180
    readonly property real wind_rad: root.wind_dir * Math.PI / 180

    function pt(a, len) {
        return Qt.point(root.cx + Math.sin(a) * len, root.cy - Math.cos(a) * len);
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.tint(Qt.alpha(Theme.bg_crust, 0.9), Qt.alpha(root.line_color, 0.1))
        border.width: 1
        border.color: Qt.alpha(root.line_color, 0.6)
    }

    Canvas {
        id: plan
        anchors.fill: parent
        anchors.margins: 1
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: root
            function onSeedChanged() { plan.requestPaint(); }
            function onLine_colorChanged() { plan.requestPaint(); }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            let s = 0;
            for (let i = 0; i < root.seed.length; i++) s = (s * 31 + root.seed.charCodeAt(i)) >>> 0;
            const rnd = () => {
                s = (s + 0x6D2B79F5) >>> 0;
                let t = s;
                t = Math.imul(t ^ (t >>> 15), t | 1);
                t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
                return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
            };
            const cols = 8;
            const rows = 6;
            const cw = width / cols;
            const ch = height / rows;
            ctx.strokeStyle = String(Qt.rgba(root.line_color.r, root.line_color.g, root.line_color.b, 1));
            ctx.lineWidth = 1;
            ctx.globalAlpha = 0.75;
            ctx.beginPath();
            for (let n = 0; n < 11; n++) {
                const gw = 1 + Math.floor(rnd() * 3);
                const gh = 1 + Math.floor(rnd() * 2);
                const gx = Math.floor(rnd() * (cols - gw + 1));
                const gy = Math.floor(rnd() * (rows - gh + 1));
                const x0 = Math.round(gx * cw) + 3.5;
                const y0 = Math.round(gy * ch) + 3.5;
                const x1 = Math.round((gx + gw) * cw) - 3.5;
                const y1 = Math.round((gy + gh) * ch) - 3.5;
                const cut = 4 + Math.floor(rnd() * 5);
                const corner = rnd() < 0.45 ? Math.floor(rnd() * 4) : -1;
                const p = [[x0, y0], [x1, y0], [x1, y1], [x0, y1]];
                ctx.moveTo(corner === 0 ? x0 + cut : x0, y0);
                for (let k = 1; k <= 4; k++) {
                    const q = p[k % 4];
                    if (corner === k % 4) {
                        const prev = p[k - 1];
                        const nxt = p[(k + 1) % 4];
                        const dx = Math.sign(prev[0] - q[0]);
                        const dy = Math.sign(prev[1] - q[1]);
                        ctx.lineTo(q[0] + dx * cut, q[1] + dy * cut);
                        ctx.lineTo(q[0] + Math.sign(nxt[0] - q[0]) * cut, q[1] + Math.sign(nxt[1] - q[1]) * cut);
                    } else {
                        ctx.lineTo(q[0], q[1]);
                    }
                }
            }
            for (let n = 0; n < 3; n++) {
                const horiz = rnd() < 0.5;
                const a = Math.round(rnd() * (horiz ? rows : cols)) * (horiz ? ch : cw);
                const b0 = rnd() * (horiz ? width : height) * 0.5;
                const b1 = b0 + (horiz ? width : height) * (0.25 + rnd() * 0.3);
                const v = Math.max(1.5, Math.min((horiz ? height : width) - 1.5, Math.round(a) + 0.5));
                ctx.moveTo(horiz ? b0 : v, horiz ? v : b0);
                ctx.lineTo(horiz ? b1 : v, horiz ? v : b1);
            }
            ctx.stroke();
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Qt.alpha(root.line_color, 0.22)
            strokeColor: Qt.alpha(root.line_color, 0.55)
            strokeWidth: 1
            startX: root.cx
            startY: root.cy
            PathLine { x: root.pt(root.wind_rad - root.cone_half, root.cone_len).x; y: root.pt(root.wind_rad - root.cone_half, root.cone_len).y }
            PathArc {
                x: root.pt(root.wind_rad + root.cone_half, root.cone_len).x
                y: root.pt(root.wind_rad + root.cone_half, root.cone_len).y
                radiusX: root.cone_len
                radiusY: root.cone_len
            }
            PathLine { x: root.cx; y: root.cy }
        }
    }

    Repeater {
        model: root.contacts

        Rectangle {
            required property var modelData
            required property int index
            readonly property real a: (index + 0.5) * 30 * Math.PI / 180
            readonly property real p: Math.max(0, Math.min(100, modelData.pop)) / 100
            width: Math.round(2 + p * 4)
            height: width
            x: root.cx + Math.sin(a) * root.width * 0.4 - width / 2
            y: root.cy - Math.cos(a) * root.height * 0.38 - height / 2
            color: root.contact_color
            opacity: 0.25 + p * 0.75
        }
    }

    Rectangle {
        id: player
        x: root.cx - 2
        y: root.cy - 2
        width: 4
        height: 4
        color: Theme.fg_core
        SequentialAnimation on opacity {
            running: root.animate
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 700 }
            NumberAnimation { to: 1; duration: 700 }
        }
    }

    Rectangle {
        id: scan
        visible: root.animate
        x: 1
        width: root.width - 2
        height: 1
        color: Qt.alpha(root.line_color, 0.35)
        NumberAnimation on y {
            running: root.animate
            loops: Animation.Infinite
            from: 1
            to: root.height - 2
            duration: 4200
        }
    }
}
