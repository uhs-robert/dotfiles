// home/quickshell/.config/quickshell/bar/modules/Submap.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../theme"

Rectangle {
    id: root

    property string submap_name: ""

    // Keyed by the `name =` field in hypr/keymaps/submaps/*/init.lua.
    readonly property var color_map: ({
        "Leader": Theme.theme_secondary,
        "Applications": Theme.blue,
        "Go": Theme.cyan,
        "System": Theme.bright_red,
        "Delete": Theme.red,
        "Notifications": Theme.magenta,
        "Screenshot": Theme.bright_blue,
        "Windows": Theme.theme_primary,
        "Groups": Theme.bright_cyan,
        "Cursor": Theme.bright_yellow,
        "Quick Click": Theme.bright_yellow,
        "Resize": Theme.blue,
        "Move": Theme.bright_green,
        "Zoom": Theme.bright_magenta,
        "Marks": Theme.yellow,
        "Monitors": Theme.cyan,
    })

    readonly property color submap_color: color_map[submap_name] || Theme.theme_secondary

    visible: submap_name !== ""
    implicitWidth: label.implicitWidth + 16
    Layout.fillHeight: true
    color: submap_color

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "submap") root.submap_name = event.data;
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.submap_name
        color: Theme.bg_core
        font.family: Theme.font_family
        font.pixelSize: Theme.font_size
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Hyprland.dispatch("hl.dsp.submap('reset')")
    }
}
