// home/quickshell/.config/quickshell/components/ps1/BiosClock.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../../services"

// The PS1 BIOS clock screen: DATE and TIME fields on a glossy panel, ticking by the minute while shown.
BiosPanel {
    id: root

    property bool running: false
    readonly property date now: Timezones.shift(clock.date)

    lit: true
    implicitHeight: fields.implicitHeight + 14

    SystemClock {
        id: clock
        enabled: root.running
        precision: SystemClock.Minutes
    }

    RowLayout {
        id: fields
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: [["DATE", Qt.formatDate(root.now, "yyyy/MM/dd")], ["TIME", Qt.formatTime(root.now, "HH:mm")]]

            RowLayout {
                required property var modelData
                spacing: 5

                Text {
                    text: parent.modelData[0]
                    color: Theme.theme_primary_light
                    font.family: Style.font_family
                    font.pixelSize: Style.font_size - 5
                }

                Digits {
                    text: parent.modelData[1].replace(/\//g, ".")
                    size: Style.font_size - 3
                    color: Theme.fg_strong
                }
            }
        }
    }
}
