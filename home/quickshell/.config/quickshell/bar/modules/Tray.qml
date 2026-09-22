// home/quickshell/.config/quickshell/bar/modules/Tray.qml
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Row {
    id: root

    spacing: 10
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items.values

        Item {
            id: icon_root
            required property var modelData

            width: 16
            height: 16

            Image {
                anchors.fill: parent
                source: icon_root.modelData.icon
                smooth: true
            }

            QsMenuAnchor {
                id: menu_anchor
                anchor.item: icon_root
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
                menu: icon_root.modelData.menu
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        menu_anchor.open();
                    } else if (mouse.button === Qt.MiddleButton) {
                        icon_root.modelData.secondaryActivate();
                    } else if (icon_root.modelData.onlyMenu) {
                        menu_anchor.open();
                    } else {
                        icon_root.modelData.activate();
                    }
                }
                onWheel: wheel => icon_root.modelData.scroll(wheel.angleDelta.y, false)
            }
        }
    }
}
