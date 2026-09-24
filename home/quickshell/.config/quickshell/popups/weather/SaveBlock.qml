// home/quickshell/.config/quickshell/popups/weather/SaveBlock.qml
import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"

// One day as a PS1 memory card save: the block, then weekday, high/low and precip chance; the selected save lifts.
Item {
    id: root

    property var day: ({})
    property bool selected: false

    readonly property real block_size: Math.max(24, Math.min(64, root.width - 6))

    ColumnLayout {
        id: stack
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        y: (root.height - stack.implicitHeight) / 2 - (root.selected ? 6 : 0)
        spacing: 3

        Behavior on y {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutQuad
            }
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.block_size
            Layout.preferredHeight: root.block_size

            Rectangle {
                visible: root.selected
                x: 3
                y: 9
                width: parent.width
                height: parent.height
                radius: 3
                color: Qt.alpha(Theme.bg_shadow, 0.7)
            }

            SaveIcon {
                anchors.fill: parent
                size: root.block_size
                code: root.day.code !== undefined ? root.day.code : -1
                lit: root.selected
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 4
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.day.weekday || ""
            color: root.selected ? Style.text_strong : Theme.theme_primary_light
            font.family: Style.font_family
            font.pixelSize: Style.font_size - 5
            font.capitalization: Font.AllUppercase
            style: Text.Raised
            styleColor: Style.text_shadow
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: Math.round(root.day.max) + "°/" + Math.round(root.day.min) + "°"
            color: root.selected ? Style.text_strong : Style.text_fg
            font.family: Style.font_family
            font.pixelSize: Style.font_size - 5
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.day.pop + "%"
            color: Theme.blue
            font.family: Style.font_family
            font.pixelSize: Style.font_size - 5
        }
    }
}
