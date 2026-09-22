// home/quickshell/.config/quickshell/bar/Bar.qml
import QtQuick
import "../theme"
import "../services"
import "modules"

Item {
    id: root

    property string screen_name: ""
    readonly property bool compact: screen_name.indexOf("eDP") === 0

    Island {
        id: left_island
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        bg_color: Theme.bg_core
        cap_right: true

        Text {
            text: "left"
            color: Theme.fg_core
            font.family: Theme.font_family
            font.pixelSize: Theme.font_size
        }
    }

    Island {
        id: center_island
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        bg_color: Theme.bg_mantle
        cap_left: true
        cap_right: true

        Component.onCompleted: Popups.register_default("clock", center_island.body_item, center_island.bg_color)
        onClicked: Popups.toggle("clock", center_island.body_item, center_island.bg_color)

        Clock {
            compact: root.compact
        }
    }

    Island {
        id: right_island
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        bg_color: Theme.bg_core
        cap_left: true

        Text {
            text: "right"
            color: Theme.fg_core
            font.family: Theme.font_family
            font.pixelSize: Theme.font_size
        }

        PowerButton {
            island: right_island.body_item
            island_color: right_island.bg_color
        }
    }
}
