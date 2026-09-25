// home/quickshell/.config/quickshell/bar/modules/StartButton.qml
import QtQuick
import Quickshell
import "../../theme"
import "../../services"
import "../../components/neovim" as Neovim

Item {
    id: root

    property bool compact: false
    property string screen_name: ""
    property Item island: null
    property color island_color: "transparent"

    // Lualine: the button is the HyprVim mode chip, full bar height.
    readonly property bool lualine: Style.bar_lualine
    implicitWidth: root.lualine && chip_loader.item ? chip_loader.item.implicitWidth : icon.implicitSize
    implicitHeight: root.lualine ? (root.island ? root.island.height : 30) : icon.implicitSize

    Loader {
        id: chip_loader
        active: root.lualine
        anchors.fill: parent
        sourceComponent: Neovim.ModeChip {
            hovered: hover_handler.hovered
        }
    }

    Rectangle {
        visible: !root.lualine
        anchors.fill: parent
        anchors.margins: -6
        radius: Style.bar_radius(4)
        color: Style.bar_hover_bg
        opacity: hover_handler.hovered ? 0.5 : 0
    }

    HoverHandler {
        id: hover_handler
    }

    // Load the SVG file directly: the icon provider returns a small raster that blurs when scaled.
    Image {
        id: icon
        visible: !root.lualine
        readonly property int implicitSize: root.compact ? 26 : 30
        readonly property real dpr: QsWindow.window ? QsWindow.window.devicePixelRatio : 1

        anchors.centerIn: parent
        width: implicitSize
        height: implicitSize
        sourceSize.width: Math.ceil(implicitSize * dpr)
        sourceSize.height: Math.ceil(implicitSize * dpr)
        source: status === Image.Error ? Quickshell.iconPath("start-here-archlinux", "start-here") : "file:///usr/share/icons/Papirus/64x64/apps/start-here-archlinux.svg"
        smooth: true
        mipmap: true
    }

    onIslandChanged: if (root.island) {
        Popups.register_default("start", root.island, root.island_color, root.screen_name, root);
        Popups.register_default("style", root.island, root.island_color, root.screen_name, root, "start");
    }
    Component.onDestruction: {
        Popups.unregister("start", root.screen_name, root);
        Popups.unregister("style", root.screen_name, root);
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["sh", "-c", "~/.config/hypr/theme/switch.lua"]);
            } else {
                Popups.toggle("start", root.island, root.island_color, root.screen_name);
            }
        }
    }
}
