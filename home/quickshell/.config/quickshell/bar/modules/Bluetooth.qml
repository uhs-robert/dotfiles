// home/quickshell/.config/quickshell/bar/modules/Bluetooth.qml
import QtQuick
import Quickshell
import Quickshell.Bluetooth as QsBt
import "../../theme"
import "../../services"

Item {
    id: root

    property bool compact: false
    property Item island: null
    property color island_color: Theme.bg_core

    readonly property var adapter: QsBt.Bluetooth.defaultAdapter
    readonly property bool has_adapter: !!adapter
    readonly property bool blocked: has_adapter && adapter.state === QsBt.BluetoothAdapterState.Blocked
    readonly property var connected_devices: has_adapter ? adapter.devices.values.filter(d => d.connected) : []
    readonly property bool any_connected: connected_devices.length > 0

    visible: has_adapter
    implicitWidth: has_adapter ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    readonly property string glyph: root.blocked ? "󰂲" : "󰂯"

    readonly property color glyph_color: {
        if (!root.has_adapter || root.blocked || !root.adapter.enabled) return Theme.fg_dim;
        if (root.any_connected) return Theme.theme_primary;
        return Theme.fg_core;
    }

    Component.onCompleted: Popups.register_default("bluetooth", root.island, root.island_color)

    Row {
        id: row
        spacing: 6

        Text {
            text: root.glyph
            color: root.glyph_color
            font.family: Theme.font_family
            font.pixelSize: Theme.font_size
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["blueman-manager"]);
            } else {
                Popups.toggle("bluetooth", root.island, root.island_color);
            }
        }
    }
}
