// home/quickshell/.config/quickshell/bar/modules/StartButton.qml
import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../services"

Item {
    id: root

    property bool compact: false
    property Item island: null
    property color island_color: "transparent"

    implicitWidth: icon.implicitSize
    implicitHeight: icon.implicitSize

    IconImage {
        id: icon
        anchors.centerIn: parent
        implicitSize: root.compact ? 20 : 24
        source: Quickshell.iconPath("start-here-archlinux", "start-here")
    }

    Component.onCompleted: Popups.register_default("start", root.island, root.island_color)

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["sh", "-c", "~/.config/hypr/theme/switch.lua"]);
            } else {
                Popups.toggle("start", root.island, root.island_color);
            }
        }
    }
}
