// home/quickshell/.config/quickshell/popups/weather/TowerColumn.qml
import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"

// One day as a PS2 boot-screen tower: a translucent prism as tall as the day's high, its label, range and rain chance beneath.
Item {
    id: root

    property var day: ({})
    property bool selected: false
    property real scale_min: 0
    property real scale_max: 1
    property real labels_h: 60

    readonly property real area_h: Math.max(20, root.height - root.labels_h)
    readonly property real tower_h: root.area_h * (0.12 + 0.78 * root.frac(root.day.max || 0))
    readonly property real lo_y: root.area_h * (0.12 + 0.78 * root.frac(root.day.min || 0))
    readonly property real tower_w: Math.max(14, Math.min(34, root.width * 0.46))

    function frac(v) {
        return Math.max(0, Math.min(1, (v - root.scale_min) / Math.max(0.01, root.scale_max - root.scale_min)));
    }

    Item {
        id: tower
        x: (root.width - root.tower_w) / 2
        y: root.area_h - root.tower_h
        width: root.tower_w
        height: root.tower_h
        opacity: root.selected ? 1 : 0.55

        Behavior on opacity {
            NumberAnimation {
                duration: 160
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -5
            anchors.bottomMargin: 0
            radius: 6
            color: Qt.alpha(Theme.theme_primary, root.selected ? 0.24 : 0.08)
        }

        Rectangle {
            anchors.fill: parent
            radius: 2
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.alpha(Theme.theme_primary_light, 0.7) }
                GradientStop { position: 0.3; color: Qt.alpha(Theme.theme_primary_strong, 0.55) }
                GradientStop { position: 1; color: Qt.alpha(Theme.theme_primary_strong, 0.2) }
            }
        }

        Rectangle {
            anchors.right: parent.right
            width: parent.width * 0.38
            height: parent.height
            radius: 2
            color: Qt.alpha(Theme.bg_shadow, 0.28)
        }

        Rectangle {
            width: parent.width
            height: 2
            radius: 1
            color: Qt.alpha(Theme.fg_strong, root.selected ? 0.9 : 0.55)
        }

        Rectangle {
            anchors.bottom: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width + 6
            height: 10
            radius: 5
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Qt.alpha(Theme.theme_primary_light, root.selected ? 0.35 : 0.15) }
            }
        }

        Rectangle {
            y: Math.min(parent.height - 1, root.lo_y > 0 ? root.tower_h - root.lo_y : parent.height - 1)
            x: 2
            width: parent.width - 4
            height: 1
            color: Qt.alpha(Theme.fg_strong, 0.4)
        }

        Rectangle {
            anchors.top: parent.bottom
            width: parent.width
            height: Math.min(18, parent.height * 0.3)
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.alpha(Theme.theme_primary_strong, 0.3) }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.labels_h
        spacing: 0

        Item {
            Layout.fillHeight: true
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.day.weekday || ""
            color: root.selected ? Theme.fg_strong : Theme.theme_primary_light
            font.family: Style.font_family
            font.pixelSize: Style.font_size - 2
            font.weight: root.selected ? Font.Medium : Font.Light
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            textFormat: Text.StyledText
            text: root.day.max !== undefined ? "<font color=\"" + Theme.fg_strong + "\">" + Math.round(root.day.max) + "°</font> <font color=\"" + Style.text_muted + "\">" + Math.round(root.day.min) + "°</font>" : ""
            font.family: Style.font_family
            font.pixelSize: Style.font_size - 3
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: (root.day.pop || 0) + "%"
            color: Theme.info
            font.family: Style.font_family
            font.pixelSize: Style.font_size - 4
        }
    }
}
