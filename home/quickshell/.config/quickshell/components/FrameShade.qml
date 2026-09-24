// home/quickshell/.config/quickshell/components/FrameShade.qml
import QtQuick
import QtQuick.Shapes
import "../theme"

// The style's frame shade into frame_color, diagonal or vertical; it also paints chamfered frames.
Item {
    id: root

    property real bottom_radius: 0
    property real top_radius: 0
    property real chamfer: 0
    readonly property color start_color: Style.frame_shade.a > 0 ? Style.frame_shade : Style.frame_color

    visible: Style.frame_shade.a > 0 || root.chamfer > 0

    Shape {
        visible: root.chamfer <= 0
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillGradient: LinearGradient {
                x1: 0
                y1: 0
                x2: Style.shade_vertical ? 0 : root.width
                y2: root.height
                GradientStop { position: 0; color: root.start_color }
                GradientStop { position: 1; color: Style.frame_color }
            }
            PathRectangle {
                width: root.width
                height: root.height
                topLeftRadius: root.top_radius
                topRightRadius: root.top_radius
                bottomLeftRadius: root.bottom_radius
                bottomRightRadius: root.bottom_radius
            }
        }
    }

    Shape {
        visible: root.chamfer > 0
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillGradient: LinearGradient {
                x1: 0
                y1: 0
                x2: Style.shade_vertical ? 0 : root.width
                y2: root.height
                GradientStop { position: 0; color: root.start_color }
                GradientStop { position: 1; color: Style.frame_color }
            }
            PathPolyline {
                path: {
                    const w = root.width, h = root.height, c = Math.min(root.chamfer, h / 2, w / 2);
                    return [Qt.point(0, 0), Qt.point(w, 0), Qt.point(w, h - c), Qt.point(w - c, h), Qt.point(c, h), Qt.point(0, h - c), Qt.point(0, 0)];
                }
            }
        }
    }
}
