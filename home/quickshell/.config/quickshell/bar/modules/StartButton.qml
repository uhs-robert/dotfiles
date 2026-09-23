// home/quickshell/.config/quickshell/bar/modules/StartButton.qml
import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property bool compact: false

    implicitWidth: icon.implicitSize
    implicitHeight: icon.implicitSize

    IconImage {
        id: icon
        anchors.centerIn: parent
        implicitSize: root.compact ? 20 : 24
        source: Quickshell.iconPath("start-here-archlinux", "start-here")
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["sh", "-c", "~/.config/hypr/theme/switch.lua"]);
            } else {
                Quickshell.execDetached(["hyprctl", "dispatch", "LayerRules.exec_without_animation('rofi -show drun -theme ~/.config/rofi/themes/oasis-start.rasi')"]);
            }
        }
    }
}
