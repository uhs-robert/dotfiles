// home/quickshell/.config/quickshell/popups/weather/DayObjectives.qml
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../theme"

// The Daily window as a GoldenEye objective list: a lettered row per day, today in progress.
ColumnLayout {
    id: root

    property var days: []
    property int first_day: 0
    property int day_cursor: 0
    property real row_h: 40
    property var on_select: function (i) {}

    FontMetrics {
        id: row_metrics
        font.family: Style.font_family
        font.pixelSize: Style.font_size - 2
    }

    readonly property bool wide: root.width >= row_metrics.advanceWidth("a) MON  100°/100°  PRECIP 100%") + 16

    spacing: 2

    Repeater {
        model: root.days

        MenuRow {
            id: row
            required property var modelData
            required property int index
            readonly property int day_index: root.first_day + row.index
            readonly property bool is_selected: row.day_index === root.day_cursor
            readonly property string weekday: Qt.formatDate(new Date(row.modelData.date + "T00:00:00"), "ddd").toUpperCase()

            Layout.fillWidth: true
            Layout.preferredHeight: root.row_h
            selected: row.is_selected

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 8 + row.inset
                anchors.rightMargin: 6
                anchors.topMargin: 3
                anchors.bottomMargin: 3
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: String.fromCharCode(97 + row.day_index) + ") "
                        color: row.fg(Style.accent_color)
                        font.family: Style.font_family
                        font.pixelSize: Style.font_size - 2
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        elide: Text.ElideRight
                        text: row.weekday + "  " + Math.round(row.modelData.max) + "°/" + Math.round(row.modelData.min) + "°"
                        color: row.fg(row.is_selected ? Style.text_strong : Style.text_fg)
                        font.family: Style.font_family
                        font.pixelSize: Style.font_size - 2
                    }

                    Text {
                        text: (root.wide ? "PRECIP " : "") + row.modelData.pop + "%"
                        color: row.fg(Theme.info)
                        font.family: Style.font_family
                        font.pixelSize: Style.font_size - 2
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        elide: Text.ElideRight
                        text: row.modelData.cond
                        color: row.fg(Style.text_muted)
                        font.family: Style.font_family
                        font.pixelSize: Style.font_size - 5
                        font.capitalization: Font.AllUppercase
                    }

                    Text {
                        visible: row.day_index === 0
                        text: "IN PROGRESS"
                        color: row.fg(Style.accent_color)
                        font.family: Style.font_family
                        font.pixelSize: Style.font_size - 5
                        font.letterSpacing: 1
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.on_select(row.day_index)
            }
        }
    }
}
