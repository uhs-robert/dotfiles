// home/quickshell/.config/quickshell/bar/modules/StartButton.qml
import QtQuick
import Quickshell
import "../../theme"
import "../../services"

Item {
    id: root

    property bool compact: false
    property string screen_name: ""
    property Item island: null
    property color island_color: "transparent"

    // Styles with a start well seat a smaller logo in a recessed circle.
    readonly property bool well: Style.bar_start_well.a > 0
    readonly property int well_size: root.compact ? 22 : 26

    implicitWidth: root.well ? root.well_size : icon.implicitSize
    implicitHeight: root.well ? root.well_size : icon.implicitSize

    Rectangle {
        visible: root.well
        anchors.centerIn: parent
        width: root.well_size
        height: root.well_size
        radius: width / 2
        color: Style.bar_start_well
        border.width: 1
        border.color: Qt.alpha(Theme.bg_shadow, 0.3)
    }

    Rectangle {
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
        readonly property int implicitSize: root.well ? root.well_size - 8 : root.compact ? 26 : 30
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
