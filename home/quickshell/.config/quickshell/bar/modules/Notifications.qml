// home/quickshell/.config/quickshell/bar/modules/Notifications.qml
import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"

Item {
    id: root

    property bool compact: false
    property string screen_name: ""
    property Item island: null
    property color island_color: Theme.bg_core
    // Set by a lualine section with a strong fill.
    property bool on_accent: false

    readonly property int unread: NotificationState.unread
    readonly property bool shown: true
    visible: shown
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    readonly property string tooltip_text: {
        const count = NotificationState.history.length + " notification" + (NotificationState.history.length === 1 ? "" : "s");
        return NotificationState.dnd ? count + "\nDo not disturb" : count;
    }

    onIslandChanged: if (root.island) Popups.register_default("notifications", root.island, root.island_color, root.screen_name, root)
    Component.onDestruction: Popups.unregister("notifications", root.screen_name, root)

    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: Style.bar_radius(4)
        color: root.on_accent ? Theme.ui_visual_bg : Style.bar_hover_bg
        opacity: hover_handler.hovered ? 0.5 : 0
    }

    RowLayout {
        id: row
        spacing: 4

        Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: glyph.implicitWidth + (count_text.visible ? count_text.implicitWidth * 0.6 : 0)
            implicitHeight: glyph.implicitHeight

            Text {
                id: glyph
                text: NotificationState.dnd ? "\u{f009b}" : "\u{f009a}"
                color: root.on_accent ? Theme.bg_crust : NotificationState.dnd ? Theme.fg_dim : Theme.theme_primary
                opacity: root.on_accent && NotificationState.dnd ? 0.55 : 1
                font.family: Style.bar_font_family
                style: Style.bar_text_style
                styleColor: Style.bar_glow_color
                font.pixelSize: Style.bar_glyph_size
            }

            Text {
                id: count_text
                visible: root.unread > 0
                x: glyph.implicitWidth - implicitWidth * 0.4
                y: -3
                text: root.unread > 99 ? "99+" : String(root.unread)
                color: glyph.color
                font.family: Style.bar_font_family
                font.pixelSize: Style.bar_font_size - 3
                font.bold: true
            }
        }
    }

    HoverHandler {
        id: hover_handler
        onHoveredChanged: {
            if (hovered) Tooltip.show(root, root.tooltip_text, "notifications");
            else Tooltip.hide(root);
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                NotificationState.toggle_dnd();
            } else {
                Popups.toggle("notifications", root.island, root.island_color, root.screen_name);
            }
        }
    }
}
