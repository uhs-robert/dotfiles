// home/quickshell/.config/quickshell/popups/weather/MateriaSlots.qml
pragma ComponentBehavior: Bound
import QtQuick
import "../../components"
import "../../theme"
import "../../services"
import "Materia.js" as Materia

// The Daily window as a weapon's materia slots: one socket per day, linked in pairs, with HI, LO and RAIN rows below.
Item {
    id: root

    property var days: []
    property int first_day: 0
    property int day_cursor: 0
    property var on_select: function (i) {}

    readonly property real label_w: 40
    readonly property int n: Math.max(1, root.days.length)
    readonly property real col_w: (root.width - root.label_w) / root.n
    readonly property real band_h: 34
    readonly property real row_h: Math.max(20, Math.min(34, (root.height - root.band_h - 8) / 4))
    readonly property real table_h: root.band_h + 4 + root.row_h * 4
    readonly property real top_y: Math.max(0, (root.height - root.table_h) / 2)
    readonly property int sel: root.day_cursor - root.first_day
    readonly property var rows: [
        ["", d => d.weekday],
        ["HI", d => Math.round(d.max) + "°"],
        ["LO", d => Math.round(d.min) + "°"],
        ["RAIN", d => d.pop + "%"]
    ]

    function col_x(i) {
        return root.label_w + i * root.col_w;
    }

    Rectangle {
        visible: root.sel >= 0 && root.sel < root.days.length
        x: root.col_x(root.sel)
        y: root.top_y
        width: root.col_w
        height: root.table_h
        radius: 4
        color: Qt.alpha(Theme.fg_strong, 0.07)
    }

    Rectangle {
        id: band
        x: root.label_w
        y: root.top_y
        width: root.col_w * root.days.length
        height: root.band_h
        radius: root.band_h / 2
        color: Qt.alpha(Theme.bg_crust, 0.7)
        border.width: 1
        border.color: Theme.fg_muted
    }

    // Links sockets 0-1, 2-3 and so on, like paired slots on a weapon.
    Repeater {
        model: Math.floor(root.days.length / 2)

        Rectangle {
            required property int index
            x: root.col_x(index * 2) + root.col_w / 2
            y: root.top_y + root.band_h / 2 - 3
            width: root.col_w
            height: 6
            color: Style.frame_border_color

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 2
                color: Qt.alpha(Theme.bg_crust, 0.4)
            }
        }
    }

    Repeater {
        model: root.days

        Item {
            id: slot
            required property var modelData
            required property int index
            readonly property bool selected: slot.index === root.sel

            x: root.col_x(slot.index)
            y: root.top_y
            width: root.col_w
            height: root.table_h

            Rectangle {
                id: socket
                x: (slot.width - width) / 2
                y: (root.band_h - height) / 2
                width: 24
                height: 24
                radius: 12
                color: Theme.bg_crust
                border.width: 2
                border.color: Style.frame_border_color

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.fg_muted
                }

                MateriaOrb {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    glow: false
                    color: Materia.color(Style.materia, WeatherState.weather_color_keys, slot.modelData.code)
                }
            }

            HandCursor {
                visible: slot.selected
                anchors.right: socket.left
                anchors.rightMargin: -3
                y: socket.y + 5
                width: 18
                height: 11
            }

            Repeater {
                model: root.rows

                Item {
                    id: cell
                    required property var modelData
                    required property int index
                    y: root.band_h + 4 + cell.index * root.row_h
                    width: slot.width
                    height: root.row_h

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: cell.index === 3 ? -3 : 0
                        width: Math.min(implicitWidth, cell.width - 4)
                        elide: Text.ElideRight
                        text: cell.modelData[1](slot.modelData)
                        color: cell.index === 1 || slot.selected && cell.index === 0 ? Theme.fg_strong : cell.index === 3 ? Style.text_fg : Theme.theme_primary_light
                        font.family: Style.font_family
                        font.pixelSize: cell.index === 0 ? Style.font_size - 3 : Style.font_size - (cell.index === 3 ? 4 : 3)
                        font.weight: cell.index === 1 ? Font.ExtraBold : Font.Bold
                    }

                    AtbBar {
                        visible: cell.index === 3
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        width: Math.min(36, cell.width - 12)
                        height: 4
                        value: slot.modelData.pop / 100
                        fill_color: Theme.info
                        shade_color: Qt.tint(Theme.info, Qt.alpha(Theme.fg_strong, 0.55))
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.on_select(root.first_day + slot.index)
            }
        }
    }

    Repeater {
        model: root.rows

        Text {
            required property var modelData
            required property int index
            x: 0
            y: root.top_y + root.band_h + 4 + index * root.row_h + (root.row_h - height) / 2 - (index === 3 ? 3 : 0)
            text: modelData[0]
            color: Theme.theme_primary_light
            font.family: Style.font_family
            font.pixelSize: Style.font_size - 5
            font.weight: Font.ExtraBold
            font.letterSpacing: 1
        }
    }
}
