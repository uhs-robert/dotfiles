// home/quickshell/.config/quickshell/components/mgs2/SegText.qml
import QtQuick
import QtQuick.Shapes
import "../../theme"
import "../../lock/skins/mgs2/Art.js" as Art

// Text in the MGS2 menu face; cap_height is the glyph height in px.
Item {
    id: root

    property string text: ""
    property real cap_height: 16
    property color color: Style.text_fg
    property real stroke: 0.75
    property real gap: 3
    // Reserves the width of this text when it is wider, so changing digits do not move neighbours.
    property string floor_text: ""

    readonly property var glyph_art: Art.seg(root.text, root.gap, root.stroke)
    readonly property var floor_art: root.floor_text !== "" ? Art.seg(root.floor_text, root.gap, root.stroke) : null
    readonly property real k: root.cap_height / root.glyph_art.vh

    implicitWidth: Math.max(root.glyph_art.vw, root.floor_art ? root.floor_art.vw : 0) * root.k
    implicitHeight: root.cap_height

    Shape {
        width: root.glyph_art.vw
        height: root.glyph_art.vh
        scale: root.k
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.color
            strokeWidth: root.stroke
            capStyle: ShapePath.SquareCap
            joinStyle: ShapePath.MiterJoin
            PathSvg { path: root.glyph_art.d }
        }

        ShapePath {
            strokeWidth: -1
            fillColor: root.color
            PathSvg { path: root.glyph_art.fill }
        }
    }
}
