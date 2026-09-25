// home/quickshell/.config/quickshell/components/ps1/SaveCard.qml
import QtQuick
import QtQuick.Shapes
import "../../theme"

// A bevelled memory card save slot; the selected one takes a primary face and a static glow, an empty one sinks.
Item {
    id: root

    property bool selected: false
    property bool empty: false

    readonly property color face_top: root.selected ? Qt.tint(Theme.ui_visual_bg, Qt.alpha(Theme.theme_primary, 0.6)) : root.empty ? Qt.alpha(Theme.bg_shadow, 0.55) : Theme.bg_surface
    readonly property color face_end: root.selected ? Theme.ui_visual_bg : root.empty ? Qt.alpha(Theme.bg_shadow, 0.55) : Theme.bg_mantle
    readonly property color bevel_light: root.selected ? Theme.theme_primary_light : root.empty ? Theme.bg_shadow : Qt.alpha(Theme.theme_primary_light, 0.3)
    readonly property color bevel_dark: root.selected ? Theme.theme_primary_strong : root.empty ? Qt.alpha(Theme.fg_dim, 0.22) : Theme.bg_shadow
    readonly property color ring: root.selected ? Theme.theme_primary_light : Qt.alpha(Theme.fg_dim, root.empty ? 0.28 : 0.55)

    Rectangle {
        visible: root.selected
        anchors.fill: parent
        anchors.margins: -5
        radius: 6
        color: Qt.alpha(Theme.theme_primary, 0.12)
    }

    Rectangle {
        visible: root.selected
        anchors.fill: parent
        anchors.margins: -3
        radius: 4
        color: Qt.alpha(Theme.theme_primary, 0.22)
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: 3
        color: "transparent"
        border.width: 1
        border.color: root.ring
    }

    Rectangle {
        anchors.fill: parent
        radius: 2
        gradient: Gradient {
            GradientStop { position: 0; color: root.face_top }
            GradientStop { position: 1; color: root.face_end }
        }
    }

    Rectangle { x: 1; y: 0; width: parent.width - 2; height: 1; color: root.bevel_light }
    Rectangle { x: 0; y: 1; width: 1; height: parent.height - 2; color: root.bevel_light }
    Rectangle { x: 1; y: parent.height - 1; width: parent.width - 2; height: 1; color: root.bevel_dark }
    Rectangle { x: parent.width - 1; y: 1; width: 1; height: parent.height - 2; color: root.bevel_dark }

    Shape {
        visible: root.empty
        anchors.centerIn: parent
        width: 12
        height: 12

        ShapePath {
            strokeColor: Qt.alpha(Theme.fg_dim, 0.45)
            strokeWidth: 1
            strokeStyle: ShapePath.DashLine
            dashPattern: [2, 2]
            fillColor: "transparent"
            PathSvg { path: "M0.5 0.5H11.5V11.5H0.5Z" }
        }
    }
}
