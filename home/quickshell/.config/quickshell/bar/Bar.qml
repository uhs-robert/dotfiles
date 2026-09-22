// home/quickshell/.config/quickshell/bar/Bar.qml
import QtQuick

Item {
    id: root

    Island {
        id: left_island
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        bg_color: "#232634"
        cap_right: true

        Text {
            text: "left"
            color: "#cdd6f4"
            font.family: "\"Maple Mono NF\", \"JetBrainsMono Nerd Font\", monospace"
            font.pixelSize: 15
        }
    }

    Island {
        id: center_island
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        bg_color: "#181825"
        cap_left: true
        cap_right: true

        Text {
            text: "center"
            color: "#cdd6f4"
            font.family: "\"Maple Mono NF\", \"JetBrainsMono Nerd Font\", monospace"
            font.pixelSize: 15
        }
    }

    Island {
        id: right_island
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        bg_color: "#232634"
        cap_left: true

        Text {
            text: "right"
            color: "#cdd6f4"
            font.family: "\"Maple Mono NF\", \"JetBrainsMono Nerd Font\", monospace"
            font.pixelSize: 15
        }
    }
}
