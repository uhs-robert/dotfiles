// home/quickshell/.config/quickshell/components/WaitPulse.qml
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import "../theme"

// A one-shot "waiting for you" cue centred on this item's origin; `nudge` plays a shorter, fainter pass.
Item {
    id: root

    property string glyph: ""
    property color color: Theme.theme_primary
    property string font_family: Style.bar_font_family
    property int glyph_size: Theme.glyph_size
    property string mode: Style.wait_anim
    property bool nudge: false

    signal finished()

    // These redraw the glyph themselves, so the module hides the real one while they play.
    readonly property bool hides_glyph: root.mode === "rumble" || root.mode === "transmission"
    readonly property real strength: root.nudge ? 0.6 : 1
    readonly property real half: root.glyph_size / 2
    readonly property var durations: ({ bubble: [1200, 700], cursor: [1200, 600], pressanykey: [1400, 700], advance: [1400, 600], hand: [1200, 600], alert: [1000, 600], rumble: [1000, 450], transmission: [1200, 500], scan: [1300, 700], comms: [1200, 500], ping: [1400, 900], orders: [1400, 600] })
    readonly property int duration: (root.durations[root.mode] || root.durations.bubble)[root.nudge ? 1 : 0]
    property real elapsed
    readonly property real tail: 1 - root.phase(root.duration - 150, 150)
    // Distance from the origin to the window's top and bottom edges.
    property real room_up: 16
    property real room_down: 16
    readonly property real room: Math.min(root.room_up, root.room_down)

    function phase(start, length) {
        return Math.max(0, Math.min(1, (root.elapsed - start) / length));
    }

    function step(ms) {
        return Math.floor(root.elapsed / ms);
    }

    function out_quad(p) {
        return 1 - (1 - p) * (1 - p);
    }

    function out_back(p) {
        const c = 2.2;
        return 1 + (c + 1) * Math.pow(p - 1, 3) + c * Math.pow(p - 1, 2);
    }

    Component.onCompleted: {
        let top = root;
        while (top.parent) top = top.parent;
        const y = root.mapToItem(top, 0, 0).y;
        root.room_up = Math.max(8, y - 1);
        root.room_down = Math.max(8, top.height - y - 1);
    }

    NumberAnimation on elapsed {
        from: 0
        to: root.duration
        duration: root.duration
        onFinished: root.finished()
    }

    Loader {
        sourceComponent: ({ bubble: bubble_c, cursor: cursor_c, pressanykey: pressanykey_c, advance: advance_c, hand: hand_c, alert: alert_c, rumble: rumble_c, transmission: transmission_c, scan: scan_c, comms: comms_c, ping: ping_c, orders: orders_c })[root.mode] || bubble_c
    }

    Component {
        id: bubble_c

        Item {
            id: bubble
            readonly property real base: root.nudge ? 50 : 250
            x: root.half - 1
            y: Math.max(-root.room_up, -root.half - 7)
            width: 17
            height: 10
            transformOrigin: Item.BottomLeft
            scale: root.nudge ? 1 : root.out_back(root.phase(0, 220))
            opacity: root.tail * (root.nudge ? 0.75 : 1)

            Rectangle {
                anchors.fill: parent
                radius: 4
                color: Theme.bg_core
                border.color: root.color
                border.width: 1
            }

            Shape {
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: Theme.bg_core
                    strokeColor: root.color
                    strokeWidth: 1
                    startX: 3
                    startY: bubble.height - 1.5
                    PathLine { x: 1; y: bubble.height + 3 }
                    PathLine { x: 7; y: bubble.height - 1.5 }
                }
            }

            Repeater {
                model: 3

                Rectangle {
                    required property int index
                    x: 3.5 + index * 4
                    y: 4 - (root.nudge ? 1.5 : 2.5) * Math.sin(Math.PI * root.phase(bubble.base + index * 120, 300))
                    width: 2
                    height: 2
                    radius: 1
                    color: root.color
                }
            }
        }
    }

    Component {
        id: cursor_c

        Text {
            x: root.half + 2
            y: -height / 2
            text: "▌"
            color: Theme.theme_cursor
            font.family: root.font_family
            font.pixelSize: root.glyph_size
            opacity: root.strength
            visible: root.step(150) % 2 === 0
        }
    }

    Component {
        id: pressanykey_c

        Item {
            readonly property int frame: root.step(50)
            readonly property bool lit: frame >= 8 || [1, 0, 1, 1, 0, 1, 0, 1][frame] === 1

            Rectangle {
                x: -root.half - 2
                y: label.y - 1
                width: label.x + label.width + 3 - x
                height: label.height + 2
                radius: 2
                color: root.color
                opacity: root.nudge ? 0 : 0.35 * (1 - root.phase(0, 350))
            }

            Text {
                id: label
                x: root.half + 4
                y: -height / 2
                text: "PRESS ANY KEY"
                color: root.color
                font.family: "VT323"
                font.pixelSize: 13
                style: Style.bar_text_style
                styleColor: Style.bar_glow_color
                visible: parent.lit
                opacity: root.tail * root.strength
            }
        }
    }

    Component {
        id: advance_c

        Item {
            x: Math.round(root.half - 2)
            y: Math.round(Math.min(root.room_down - 7, root.half - 4 + (root.step(200) % 2 ? 2 : 0)))
            opacity: root.strength

            Repeater {
                model: 5

                Rectangle {
                    required property int index
                    x: index
                    y: index
                    width: 9 - 2 * index
                    height: 1
                    color: Style.bar_fg
                }
            }
        }
    }

    Component {
        id: hand_c

        Item {
            readonly property var fills: [[0, 2, 5, 5], [5, 1, 6, 2], [5, 4, 3, 1], [5, 6, 2, 1], [1, 1, 3, 1]]
            x: -Math.round(root.half) - 13 + (root.step(150) % 2 ? 2 : 0)
            y: -4
            opacity: root.strength

            Repeater {
                model: parent.fills

                Rectangle {
                    required property var modelData
                    x: modelData[0] - 1
                    y: modelData[1] - 1
                    width: modelData[2] + 2
                    height: modelData[3] + 2
                    color: Theme.bg_shadow
                }
            }

            Repeater {
                model: parent.fills

                Rectangle {
                    required property var modelData
                    x: modelData[0]
                    y: modelData[1]
                    width: modelData[2]
                    height: modelData[3]
                    color: Theme.fg_strong
                }
            }
        }
    }

    Component {
        id: alert_c

        Text {
            readonly property real p: root.phase(0, 180)
            readonly property real peak: root.nudge ? 1.2 : 1.5
            x: root.half - width / 2 - 1
            y: Math.max(-root.room_up, -root.half - height * 0.6)
            text: "!"
            color: Theme.theme_label
            font.family: root.font_family
            font.pixelSize: 13
            font.bold: true
            style: Text.Outline
            styleColor: Theme.bg_shadow
            transformOrigin: Item.Bottom
            scale: p < 0.6 ? peak * p / 0.6 : peak - (peak - 1) * (p - 0.6) / 0.4
            opacity: root.strength
        }
    }

    Component {
        id: rumble_c

        Text {
            readonly property var bursts: root.nudge ? [[0, 420]] : [[0, 380], [560, 940]]
            readonly property bool shaking: bursts.some(b => root.elapsed >= b[0] && root.elapsed < b[1])
            x: -width / 2 + (shaking ? (root.step(35) % 2 ? 1 : -1) * (root.nudge ? 1 : 2) : 0)
            y: -height / 2
            text: root.glyph
            color: root.color
            font.family: root.font_family
            font.pixelSize: root.glyph_size
            style: Style.bar_text_style
            styleColor: Style.bar_glow_color
        }
    }

    Component {
        id: transmission_c

        Item {
            readonly property int frame: root.step(100)
            readonly property int blinks: root.nudge ? 2 : 5

            Text {
                x: -width / 2
                y: -height / 2
                text: root.glyph
                color: root.color
                font.family: root.font_family
                font.pixelSize: root.glyph_size
                style: Style.bar_text_style
                styleColor: Style.bar_glow_color
                visible: parent.frame % 2 === 1 || parent.frame >= parent.blinks * 2
            }

            Repeater {
                model: root.nudge ? 0 : 3

                Rectangle {
                    required property int index
                    x: Math.round(root.half) + 2 + index * 3
                    y: 5 - height
                    width: 2
                    height: 3 + 2 * index
                    color: root.color
                    visible: root.step(100) >= index * 2 + 1
                }
            }
        }
    }

    Component {
        id: scan_c

        Item {
            readonly property real w: root.glyph_size + 6 + (root.nudge ? 4 : 10) * (1 - root.out_quad(root.phase(0, 350)))
            readonly property real h: Math.min(w, 2 * root.room - 2)
            opacity: root.tail * root.strength * (root.elapsed < 350 ? 1 : 0.55 + 0.45 * Math.cos((root.elapsed - 350) / 300 * 2 * Math.PI))

            CornerBrackets {
                x: -parent.w / 2
                y: -parent.h / 2
                width: parent.w
                height: parent.h
                color: root.color
                inset: 0
                arm: 4
                thickness: 1.5
                all_corners: true
            }

            Text {
                visible: !root.nudge
                x: parent.w / 2 + 2
                y: parent.h / 2 - height + 1
                text: "SCAN"
                color: root.color
                font.family: Style.mono_font
                font.pixelSize: 8
            }
        }
    }

    Component {
        id: comms_c

        Item {
            readonly property real w: root.glyph_size + 6
            readonly property real h: Math.min(w, 2 * root.room - 2)
            opacity: root.tail * root.strength

            CornerBrackets {
                x: -parent.w / 2
                y: -parent.h / 2
                width: parent.w
                height: parent.h
                color: Theme.theme_label
                inset: 0
                arm: 5
                thickness: 1.5
                all_corners: true
                visible: root.step(120) % 2 === 0
            }

            Text {
                visible: !root.nudge
                x: parent.w / 2 + 2
                y: parent.h / 2 - height + 1
                text: "COMMS"
                color: Theme.theme_label
                font.family: Style.mono_font
                font.pixelSize: 8
            }
        }
    }

    component Ring: ShapePath {
        id: ring
        property int delay
        property bool live: true
        readonly property real p: root.phase(delay, root.nudge ? 800 : 1000)
        readonly property real grow: root.out_quad(p)
        fillColor: "transparent"
        strokeColor: Qt.alpha(root.color, live && p > 0 && p < 1 ? 0.8 * root.strength * (1 - p) : 0)
        strokeWidth: 1

        PathAngleArc {
            centerX: 80
            centerY: 40
            radiusX: root.half + root.glyph_size * 1.4 * ring.grow
            radiusY: Math.min(root.half + root.glyph_size * 0.6 * ring.grow, root.room - 1)
            startAngle: 0
            sweepAngle: 360
        }
    }

    Component {
        id: ping_c

        Shape {
            x: -80
            y: -40
            width: 160
            height: 80
            preferredRendererType: Shape.CurveRenderer

            Ring { delay: 0 }
            Ring { delay: 350; live: !root.nudge }
        }
    }

    Component {
        id: orders_c

        Item {
            readonly property int frame: root.step(140)
            readonly property bool lit: frame % 2 === 0 && frame < (root.nudge ? 2 : 6)
            readonly property color amber: Theme.bright_yellow

            Rectangle {
                visible: parent.lit
                x: -root.half - 3
                y: -height / 2
                width: root.glyph_size + 6
                height: Math.min(root.glyph_size + 4, 2 * root.room - 2)
                radius: 3
                color: Qt.alpha(parent.amber, 0.35 * root.strength)
                border.color: parent.amber
                border.width: 1
            }

            Text {
                id: orders_label
                visible: !root.nudge
                x: root.half + 4
                y: -height + 2
                text: "AWAITING ORDERS"
                color: parent.amber
                font.family: Style.mono_font
                font.pixelSize: 8
                opacity: root.tail
            }

            Hazard {
                visible: parent.lit
                x: root.half + 4
                y: 4
                width: root.nudge ? 20 : orders_label.width
                height: 4
                stripe: Style.hazard.a > 0 ? Style.hazard : parent.amber
                tile: 6
                line: 2
            }
        }
    }
}
