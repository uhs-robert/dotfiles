// home/quickshell/.config/quickshell/components/DonePulse.qml
pragma ComponentBehavior: Bound
import QtQuick
import "../theme"

// A one-shot celebration centred on this item's origin: the glyph pops with a ring and hearts float up.
Item {
    id: root

    property string glyph: ""
    property color color: Theme.theme_primary
    property string font_family: Style.bar_font_family
    property int glyph_size: Theme.glyph_size
    // hearts, pixel (stepped, integer motion) or lcd (the glyph blinks, nothing floats).
    property string mode: Style.done_anim
    // How far the hearts climb; defaults to the window's top edge.
    property real rise: 12

    signal finished()

    readonly property bool pixel: root.mode === "pixel"
    readonly property bool lcd: root.mode === "lcd"
    readonly property int duration: root.lcd ? 900 : 1100
    property real elapsed
    readonly property real t: root.pixel ? Math.floor(root.elapsed / 80) * 80 : root.elapsed

    function phase(start, length) {
        return Math.max(0, Math.min(1, (root.t - start) / length));
    }

    function out_quad(p) {
        return root.pixel ? p : 1 - (1 - p) * (1 - p);
    }

    function out_back(p) {
        if (root.pixel) return p;
        const c = 2.2;
        return 1 + (c + 1) * Math.pow(p - 1, 3) + c * Math.pow(p - 1, 2);
    }

    function snap(v) {
        return root.pixel ? Math.round(v) : v;
    }

    readonly property real pop_scale: {
        const p = root.phase(0, 450);
        if (root.lcd || p <= 0 || p >= 1) return 1;
        if (p < 1 / 3) return 1 + 0.4 * root.out_quad(p * 3);
        return 1.4 - 0.4 * root.out_back((p - 1 / 3) * 1.5);
    }

    Component.onCompleted: root.rise = Math.max(8, root.mapToItem(null, 0, 0).y - 4)

    NumberAnimation on elapsed {
        from: 0
        to: root.duration
        duration: root.duration
        onFinished: root.finished()
    }

    Rectangle {
        readonly property real p: root.phase(0, 600)
        visible: !root.lcd && p > 0 && p < 1
        width: root.pixel ? 2 * Math.round(root.glyph_size * (0.45 + 0.4 * p)) : root.glyph_size * (0.9 + 0.8 * root.out_quad(p))
        height: width
        x: -width / 2
        y: -height / 2
        radius: root.pixel ? 0 : width / 2
        color: "transparent"
        border.width: root.pixel ? 2 : 1.5
        border.color: root.color
        opacity: root.pixel ? Math.ceil((1 - p) * 3) / 5 : 0.6 * (1 - p)
    }

    Repeater {
        model: root.lcd ? [] : [{ dx: -7, delay: 120 }, { dx: 7, delay: 260 }, { dx: 0, delay: 400 }]

        Item {
            id: heart
            required property var modelData
            readonly property real p: root.phase(heart.modelData.delay, 700)
            readonly property real fade: p < 0.15 ? p / 0.15 : 1 - (p - 0.15) / 0.85

            visible: p > 0 && p < 1
            width: root.pixel ? 7 : heart_glyph.implicitWidth
            height: root.pixel ? 6 : heart_glyph.implicitHeight
            x: root.snap(-width / 2 + heart.modelData.dx * p + 1.5 * Math.sin(p * 2 * Math.PI))
            y: root.snap(-height / 2 - 4 - (root.rise - 4) * root.out_quad(p))
            scale: root.pixel ? 1 : 0.7 + 0.3 * p
            opacity: root.pixel ? Math.ceil(fade * 4) / 4 : fade

            Text {
                id: heart_glyph
                visible: !root.pixel
                text: String.fromCodePoint(0xF02D1)
                color: root.color
                font.family: root.font_family
                font.pixelSize: 9
            }

            Repeater {
                model: root.pixel ? [[1, 0, 2], [4, 0, 2], [0, 1, 7], [0, 2, 7], [1, 3, 5], [2, 4, 3], [3, 5, 1]] : []

                Rectangle {
                    required property var modelData
                    x: modelData[0]
                    y: modelData[1]
                    width: modelData[2]
                    height: 1
                    color: root.color
                }
            }
        }
    }

    Text {
        x: -width / 2
        y: -height / 2
        text: root.glyph
        color: root.color
        font.family: root.font_family
        font.pixelSize: root.glyph_size
        style: Style.bar_text_style
        styleColor: Style.bar_glow_color
        scale: root.pop_scale
        visible: !root.lcd || root.t >= 900 || Math.floor(root.t / 150) % 2 === 1
    }
}
