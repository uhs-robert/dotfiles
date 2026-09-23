// home/quickshell/.config/quickshell/popups/BrightnessPopup.qml
import QtQuick
import QtQuick.Layouts
import "../components"
import "../theme"
import "../services"

Popup {
    id: root

    popup_name: "brightness"
    implicitWidth: 260
    implicitHeight: Backlight.has_kbd ? 88 : 52

    property int selected: 0

    readonly property bool is_open: Popups.open_name === "brightness"
    onIs_openChanged: if (is_open) {
        root.selected = 0;
        Backlight.refresh();
    }

    // Sysfs brightness has no inotify; poll while the popup is visible.
    Timer {
        interval: 1000
        running: root.is_open
        repeat: true
        onTriggered: Backlight.refresh()
    }

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        focus: true

        Keys.onPressed: event => {
            const kbd_row = Backlight.has_kbd && root.selected === 1;
            if (event.key === Qt.Key_Tab && Backlight.has_kbd) {
                root.selected = root.selected === 0 ? 1 : 0;
                event.accepted = true;
            } else if (event.key === Qt.Key_L) {
                if (kbd_row) Backlight.kbd_bump(1); else Backlight.bump(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_H) {
                if (kbd_row) Backlight.kbd_bump(-1); else Backlight.bump(-1);
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰃠"
                    color: root.selected === 0 ? Theme.theme_primary : Theme.fg_dim
                    font.family: Theme.font_family
                    font.pixelSize: Theme.popup_font_size
                }

                Slider {
                    Layout.fillWidth: true
                    value: Backlight.percent / 100
                    onMoved: v => Backlight.set_percent(Math.round(v * 100))
                }

                Text {
                    Layout.preferredWidth: 32
                    text: Backlight.percent + "%"
                    color: Theme.fg_core
                    font.family: Theme.font_family
                    font.pixelSize: Theme.popup_font_size - 1
                }
            }

            RowLayout {
                visible: Backlight.has_kbd
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰌌"
                    color: root.selected === 1 ? Theme.theme_primary : Theme.fg_dim
                    font.family: Theme.font_family
                    font.pixelSize: Theme.popup_font_size
                }

                Slider {
                    Layout.fillWidth: true
                    value: Backlight.kbd_percent / 100
                    onMoved: v => Backlight.kbd_set_percent(Math.round(v * 100))
                }

                Text {
                    Layout.preferredWidth: 32
                    text: Backlight.kbd_percent + "%"
                    color: Theme.fg_core
                    font.family: Theme.font_family
                    font.pixelSize: Theme.popup_font_size - 1
                }
            }
        }
    }
}
