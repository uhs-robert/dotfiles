// home/quickshell/.config/quickshell/bar/modules/Tray.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../../theme"
import "../../services"

Item {
    id: root

    property bool compact: false
    property string screen_name: ""
    property Item island: null
    property color island_color: Theme.bg_core

    readonly property int count: SystemTray.items.values.length
    readonly property string tooltip_text: root.count + " tray app" + (root.count === 1 ? "" : "s")

    visible: root.count > 0
    implicitWidth: root.visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    onIslandChanged: if (root.island) Popups.register_default("tray", root.island, root.island_color, root.screen_name)

    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: 4
        color: Theme.bg_surface
        opacity: hover_handler.hovered ? 0.5 : 0
    }

    RowLayout {
        id: row
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: ""
            color: Theme.theme_primary
            font.family: Theme.font_family
            font.pixelSize: Theme.glyph_size
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            visible: !root.compact
            text: root.count
            color: Theme.fg_core
            font.family: Theme.font_family
            font.pixelSize: Theme.font_size
        }
    }

    HoverHandler {
        id: hover_handler
        onHoveredChanged: {
            if (hovered) Tooltip.show(root, root.tooltip_text);
            else Tooltip.hide();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Popups.toggle("tray", root.island, root.island_color, root.screen_name)
    }
}
