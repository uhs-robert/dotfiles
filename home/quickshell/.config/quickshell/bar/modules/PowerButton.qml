// home/quickshell/.config/quickshell/bar/modules/PowerButton.qml
import QtQuick
import "../../theme"
import "../../services"

Text {
    id: root

    property Item island: null
    property color island_color: Theme.bg_core

    text: ""
    color: Theme.fg_core
    font.family: Theme.font_family
    font.pixelSize: Theme.font_size

    Component.onCompleted: Popups.register_default("power", root.island, root.island_color)

    MouseArea {
        anchors.fill: parent
        onClicked: Popups.toggle("power", root.island, root.island_color)
    }
}
