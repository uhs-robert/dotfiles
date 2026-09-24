// home/quickshell/.config/quickshell/popups/weather/WeaponSlots.qml
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../../services"

// Days as HL1 weapon-slot buckets numbered along the top; the selected one opens wider, rain chance is its ammo bar.
Item {
    id: root

    property var days: []
    property int first_day: 0
    property int day_cursor: 0
    property var on_select: function (i) {}

    readonly property real gap: 4
    readonly property real open_weight: 1.75
    readonly property int count: root.days.length
    readonly property real unit: root.count > 0 ? (root.width - root.gap * (root.count - 1)) / (root.count - 1 + root.open_weight) : 0
    readonly property color hl: Style.text_primary
    readonly property color hl_t: Style.text_muted

    implicitHeight: slots_row.childrenRect.height

    Row {
        id: slots_row
        spacing: root.gap

        Repeater {
            model: root.days

            Column {
                id: slot
                required property var modelData
                required property int index
                readonly property int day_index: root.first_day + slot.index
                readonly property bool open: slot.day_index === root.day_cursor

                width: Math.floor(root.unit * (slot.open ? root.open_weight : 1))
                spacing: 0

                Rectangle {
                    width: parent.width
                    height: 18
                    color: slot.open ? root.hl : "transparent"
                    border.width: slot.open ? 0 : 1
                    border.color: Style.hairline_dim

                    Text {
                        id: slot_number
                        width: 17
                        height: parent.height
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: String(slot.index + 1)
                        color: slot.open ? Theme.bg_crust : root.hl
                        font.family: Style.number_font
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Rectangle {
                        x: slot_number.width
                        width: 1
                        height: parent.height
                        color: slot.open ? Qt.alpha(Theme.bg_crust, 0.4) : Style.hairline_dim
                    }

                    Text {
                        x: slot_number.width + 5
                        width: parent.width - x - 3
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: (slot.open || slot.width >= 60 ? slot.modelData.weekday : Qt.formatDate(new Date(slot.modelData.date + "T00:00:00"), "ddd")).toUpperCase()
                        color: slot.open ? Theme.bg_crust : root.hl_t
                        font.family: Style.font_family
                        font.pixelSize: Style.font_size - 6
                        font.bold: true
                        font.letterSpacing: slot.open ? 1.3 : 0.5
                    }
                }

                Rectangle {
                    width: parent.width
                    height: bucket.implicitHeight + 13
                    color: slot.open ? Style.selection_bg : "transparent"
                    border.width: slot.open ? 1 : 0
                    border.color: Style.hairline

                    // Closed buckets hang open-topped from their number bar.
                    Repeater {
                        model: slot.open ? [] : [[0, 0, 1, 1], [1, 0, 1, 1], [0, 1, 1, 0]]

                        Rectangle {
                            required property var modelData
                            x: modelData[0] * (parent.width - 1)
                            y: modelData[1] * (parent.height - 1)
                            width: modelData[2] ? 1 : parent.width
                            height: modelData[3] ? parent.height : 1
                            color: Style.hairline_dim
                        }
                    }

                    ColumnLayout {
                        id: bucket
                        x: slot.open ? 7 : 5
                        y: 6
                        width: parent.width - x * 2
                        spacing: 3

                        RowLayout {
                            visible: slot.open
                            spacing: 7

                            DayIcon {
                                code: slot.modelData.code
                            }

                            Temps {
                                hi_size: 20
                                lo_size: 14
                                day: slot.modelData
                            }
                        }

                        Text {
                            visible: slot.open
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            text: slot.modelData.cond.toUpperCase()
                            color: root.hl
                            font.family: Style.font_family
                            font.pixelSize: Style.font_size - 6
                            font.bold: true
                            font.letterSpacing: 1.4
                        }

                        DayIcon {
                            visible: !slot.open
                            Layout.alignment: Qt.AlignHCenter
                            code: slot.modelData.code
                        }

                        Temps {
                            visible: !slot.open
                            Layout.alignment: Qt.AlignHCenter
                            hi_size: 13
                            lo_size: 13
                            day: slot.modelData
                        }

                        Stat {
                            visible: slot.open
                            label: "RAIN"
                            value: slot.modelData.pop + "%"
                            value_color: Theme.info
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4
                            color: Style.meter_off

                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(100, slot.modelData.pop)) / 100
                                height: parent.height
                                color: Theme.info
                            }
                        }

                        Text {
                            visible: !slot.open
                            Layout.alignment: Qt.AlignHCenter
                            text: slot.modelData.pop + "%"
                            color: Theme.info
                            font.family: Style.number_font
                            font.pixelSize: Style.font_size - 5
                            font.bold: true
                        }

                        Stat {
                            visible: slot.open
                            label: "WIND"
                            value: Math.round(slot.modelData.wind_speed_max) + " " + WeatherState.wind_unit()
                        }

                        Stat {
                            visible: slot.open
                            label: "UV"
                            value: slot.modelData.uv_max.toFixed(1)
                        }
                    }
                }

                TapHandler {
                    onTapped: root.on_select(slot.day_index)
                }
            }
        }
    }

    component DayIcon: Item {
        id: day_icon
        property int code: 0
        implicitWidth: 22
        implicitHeight: 22

        Image {
            id: icon_image
            anchors.fill: parent
            visible: false
            readonly property real dpr: QsWindow.window ? QsWindow.window.devicePixelRatio : 1
            sourceSize.width: Math.ceil(44 * dpr)
            sourceSize.height: Math.ceil(44 * dpr)
            source: WeatherState.icon_source(day_icon.code, true)
            smooth: true
        }

        MultiEffect {
            anchors.fill: parent
            source: icon_image
            colorization: 1
            colorizationColor: root.hl
        }
    }

    component Temps: RowLayout {
        id: temps
        property var day: null
        property int hi_size: 13
        property int lo_size: 13
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignBaseline
            text: temps.day ? Math.round(temps.day.max) + "°" : ""
            color: Theme.fg_strong
            font.family: Style.number_font
            font.pixelSize: temps.hi_size
            font.bold: true
        }

        Text {
            Layout.alignment: Qt.AlignBaseline
            text: temps.day ? Math.round(temps.day.min) + "°" : ""
            color: root.hl_t
            font.family: Style.number_font
            font.pixelSize: temps.lo_size
        }
    }

    component Stat: RowLayout {
        id: stat
        property string label: ""
        property string value: ""
        property color value_color: Theme.fg_strong
        Layout.fillWidth: true
        spacing: 4

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            elide: Text.ElideRight
            text: stat.label
            color: root.hl_t
            font.family: Style.font_family
            font.pixelSize: Style.font_size - 6
            font.bold: true
            font.letterSpacing: 1.5
        }

        Text {
            text: stat.value
            color: stat.value_color
            font.family: Style.number_font
            font.pixelSize: Style.font_size - 5
            font.bold: true
        }
    }
}
