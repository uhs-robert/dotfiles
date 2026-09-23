// home/quickshell/.config/quickshell/bar/BarReserve.qml
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property int reserve_height: 0

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Math.max(1, root.reserve_height)
    exclusiveZone: root.reserve_height
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "quickshell-reserve"
}
