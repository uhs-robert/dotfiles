// home/quickshell/.config/quickshell/popups/TrayPopup.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../components"
import "../theme"
import "../services"

Popup {
    id: root

    popup_name: "tray"
    implicitWidth: 240
    implicitHeight: Math.max(1, SystemTray.items.values.length) * 26 + 24

    readonly property var items: SystemTray.items.values

    property int selected: 0
    onItemsChanged: if (selected >= items.length) selected = Math.max(0, items.length - 1);

    readonly property bool is_open: Popups.open_name === "tray"
    onIs_openChanged: if (is_open) root.selected = 0

    // Anchored to the bar's tray island (not a popup row), so it survives us closing the popup below.
    QsMenuAnchor {
        id: menu_anchor
    }

    function activate_row(item_data) {
        if (!item_data) return;
        if (item_data.onlyMenu) {
            root.open_menu(item_data);
            return;
        }
        item_data.activate();
        Popups.close();
    }

    // Native app menus and our own focus-grabbed popup both want focus; hand off by
    // closing the popup first and re-anchoring the menu to the still-live tray island.
    function open_menu(item_data) {
        if (!item_data || !item_data.menu) return;
        if (menu_anchor.visible && menu_anchor.menu === item_data.menu) {
            menu_anchor.close();
            return;
        }
        const island_item = Popups.open_anchor;
        if (!island_item) return;
        Popups.close();
        menu_anchor.anchor.item = island_item;
        menu_anchor.anchor.edges = Edges.Bottom;
        menu_anchor.anchor.gravity = Edges.Bottom;
        menu_anchor.menu = item_data.menu;
        Qt.callLater(() => menu_anchor.open());
    }

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        focus: true

        Keys.onPressed: event => {
            const item_data = root.items[root.selected];
            if (event.key === Qt.Key_J) {
                root.selected = Math.min(root.items.length - 1, root.selected + 1);
                event.accepted = true;
            } else if (event.key === Qt.Key_K) {
                root.selected = Math.max(0, root.selected - 1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.activate_row(item_data);
                event.accepted = true;
            } else if (event.key === Qt.Key_M || event.key === Qt.Key_L) {
                root.open_menu(item_data);
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 2

            Text {
                visible: root.items.length === 0
                text: "No tray apps"
                color: Theme.fg_dim
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size - 2
            }

            Repeater {
                model: root.items

                Rectangle {
                    id: item_row
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    height: 26
                    radius: 4
                    color: item_row.index === root.selected ? Theme.bg_surface : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 8

                        IconImage {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            implicitSize: 16
                            source: item_row.modelData.icon
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: item_row.modelData.tooltipTitle || item_row.modelData.title || item_row.modelData.id
                            color: Theme.fg_core
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 1
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: mouse => {
                            root.selected = item_row.index;
                            if (mouse.button === Qt.RightButton) {
                                root.open_menu(item_row.modelData);
                            } else if (mouse.button === Qt.MiddleButton) {
                                item_row.modelData.secondaryActivate();
                                Popups.close();
                            } else {
                                root.activate_row(item_row.modelData);
                            }
                        }
                    }
                }
            }
        }
    }
}
