// home/quickshell/.config/quickshell/popups/PowerPopup.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../theme"
import "../services"

Popup {
    id: root

    popup_name: "power"
    implicitWidth: 180
    implicitHeight: confirm ? 60 : 148

    readonly property var actions: ["Lock", "Logout", "Reboot", "Power Off"]
    readonly property var glyph_colors: [Theme.fg_core, Theme.info, Theme.warning, Theme.theme_label]

    property int selected: 0
    property bool confirm: false

    readonly property bool is_open: Popups.open_name === "power"
    onIs_openChanged: if (is_open) {
        selected = 0;
        confirm = false;
    }

    function run(index) {
        if (index === 0) {
            Quickshell.execDetached(["sh", "-c", "~/.config/hypr/scripts/hyprlock-screenshot.lua"]);
        } else if (index === 1) {
            Quickshell.execDetached(["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch \"hl.dsp.exit()\""]);
        } else if (index === 2) {
            Quickshell.execDetached(["systemctl", "reboot"]);
        } else if (index === 3) {
            Quickshell.execDetached(["systemctl", "poweroff"]);
        }
        Popups.close();
    }

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        focus: true

        Keys.onPressed: event => {
            if (root.confirm) {
                if (event.key === Qt.Key_Y || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.run(root.selected);
                    event.accepted = true;
                } else if (event.key === Qt.Key_N || event.key === Qt.Key_Escape) {
                    root.confirm = false;
                    event.accepted = true;
                }
                return;
            }
            if (event.key === Qt.Key_J) {
                root.selected = (root.selected + 1) % root.actions.length;
                event.accepted = true;
            } else if (event.key === Qt.Key_K) {
                root.selected = (root.selected - 1 + root.actions.length) % root.actions.length;
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.confirm = true;
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 4
            visible: !root.confirm

            Repeater {
                model: root.actions

                Rectangle {
                    id: row
                    required property int index
                    required property string modelData

                    Layout.fillWidth: true
                    height: 28
                    radius: 6
                    color: index === root.selected ? Theme.bg_surface : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData
                        color: root.glyph_colors[row.index]
                        font.family: Theme.font_family
                        font.pixelSize: Theme.font_size
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.selected = row.index;
                            root.confirm = true;
                        }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.confirm
            text: root.actions[root.selected] + "? y/n"
            color: Theme.fg_core
            font.family: Theme.font_family
            font.pixelSize: Theme.font_size
        }
    }
}
