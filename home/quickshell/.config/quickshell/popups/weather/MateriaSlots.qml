// home/quickshell/.config/quickshell/popups/weather/MateriaSlots.qml
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../components"
import "../../theme"
import "../../services"
import "Materia.js" as Materia

// The Daily window as a weapon's materia slots: one socket per day, linked in pairs, with icon, HI, LO and RAIN rows below.
Item {
    id: root

    property var days: []
    property int first_day: 0
    property int day_cursor: 0
    property var on_select: function (i) {}

    readonly property real label_w: 40
    readonly property int n: Math.max(1, root.days.length)
    readonly property real col_w: (root.width - root.label_w) / root.n
    // Band and rows share out the full available height instead of centering at a fixed size.
    readonly property real band_h: Math.max(34, Math.min(70, root.height * 0.16))
    readonly property real row_h: Math.max(20, (root.height - root.band_h - 8) / root.rows.length)
    readonly property real table_h: root.band_h + 4 + root.row_h * root.rows.length
    readonly property real top_y: Math.max(0, (root.height - root.table_h) / 2)
    readonly property real socket_size: Math.max(24, Math.min(56, root.band_h * 0.75))
    readonly property real row_scale: Math.min(1.6, Math.max(1, root.row_h / 34))
    readonly property int sel: root.day_cursor - root.first_day
    readonly property var rows: [
        ["", d => d.weekday],
        ["", d => ""],
        ["HI", d => Math.round(d.max) + "°"],
        ["LO", d => Math.round(d.min) + "°"],
        ["RAIN", d => d.pop + "%"]
    ]

    readonly property var orb_colors: Materia.day_colors(root.days.map(d => d.date))

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
                width: root.socket_size
                height: root.socket_size
                radius: width / 2
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
                    width: root.socket_size * 0.67
                    height: width
                    glow: false
                    color: (Style.materia.days || {})[root.orb_colors[slot.index]] || "transparent"
                }
            }

            HandCursor {
                visible: slot.selected
                anchors.right: socket.left
                anchors.rightMargin: -3
                y: socket.y + socket.height * 0.2
                width: 18 * root.row_scale
                height: 11 * root.row_scale
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

                    Image {
                        visible: cell.index === 1
                        anchors.centerIn: parent
                        width: Math.min(48, root.row_h - 2)
                        height: width
                        readonly property real dpr: QsWindow.window ? QsWindow.window.devicePixelRatio : 1
                        sourceSize.width: Math.ceil(96 * dpr)
                        sourceSize.height: Math.ceil(96 * dpr)
                        source: visible ? WeatherState.icon_source(slot.modelData.code, true) : ""
                        smooth: true
                    }

                    Text {
                        visible: cell.index !== 1
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: cell.index === 4 ? -3 * root.row_scale : 0
                        width: Math.min(implicitWidth, cell.width - 4)
                        elide: Text.ElideRight
                        text: cell.modelData[1](slot.modelData)
                        color: cell.index === 2 || slot.selected && cell.index === 0 ? Theme.fg_strong : cell.index === 4 ? Style.text_fg : Theme.theme_primary_light
                        font.family: Style.font_family
                        font.pixelSize: Math.round((cell.index === 0 ? Style.font_size - 3 : Style.font_size - (cell.index === 4 ? 4 : 3)) * root.row_scale)
                        font.weight: cell.index === 2 ? Font.ExtraBold : Font.Bold
                    }

                    AtbBar {
                        visible: cell.index === 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2 * root.row_scale
                        width: Math.min(36 * root.row_scale, cell.width - 12)
                        height: 4 * root.row_scale
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
            y: root.top_y + root.band_h + 4 + index * root.row_h + (root.row_h - height) / 2 - (index === 4 ? 3 * root.row_scale : 0)
            text: modelData[0]
            color: Theme.theme_primary_light
            font.family: Style.font_family
            font.pixelSize: Math.round((Style.font_size - 5) * root.row_scale)
            font.weight: Font.ExtraBold
            font.letterSpacing: 1
        }
    }
}
