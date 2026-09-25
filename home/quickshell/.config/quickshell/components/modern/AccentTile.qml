// home/quickshell/.config/quickshell/components/modern/AccentTile.qml
import QtQuick
import "../../theme"

// A rounded square in the selection gradient holding a glyph or an icon.
Rectangle {
    id: root

    property string glyph: ""
    property url icon: ""
    property bool dimmed: false
    property int size: 36

    implicitWidth: root.size
    implicitHeight: root.size
    radius: Math.round(root.size * 0.28)
    opacity: root.dimmed ? 0.55 : 1
    gradient: Gradient {
        GradientStop { position: 0; color: Style.selection_shade.a > 0 ? Style.selection_shade : Style.selection_bg }
        GradientStop { position: 1; color: Style.selection_bg }
    }

    Sheen {
        color_top: Style.sheen
        corner: root.radius
    }

    Text {
        visible: root.icon.toString() === ""
        anchors.centerIn: parent
        text: root.glyph
        color: Style.selection_fg
        font.family: Theme.font_family
        font.pixelSize: Math.round(root.size * 0.55)
    }

    Image {
        visible: root.icon.toString() !== ""
        anchors.centerIn: parent
        width: Math.round(root.size * 0.66)
        height: width
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        source: root.icon
        fillMode: Image.PreserveAspectFit
        smooth: true
    }
}
