// home/quickshell/.config/quickshell/bar/modules/Brightness.qml
import QtQuick
import "../../theme"
import "../../services"

Item {
    id: root

    property bool compact: false
    property Item island: null
    property color island_color: Theme.bg_core

    visible: Backlight.has_device
    implicitWidth: Backlight.has_device ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    Component.onCompleted: Popups.register_default("brightness", root.island, root.island_color)

    Row {
        id: row
        spacing: 6

        Text {
            text: "󰃠"
            color: Theme.theme_primary
            font.family: Theme.font_family
            font.pixelSize: Theme.font_size
        }

        Text {
            text: Backlight.percent + "%"
            color: Theme.fg_core
            font.family: Theme.font_family
            font.pixelSize: Theme.font_size
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Popups.toggle("brightness", root.island, root.island_color)
        onWheel: wheel => Backlight.bump(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
