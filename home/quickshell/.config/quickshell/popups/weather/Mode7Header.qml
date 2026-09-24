// home/quickshell/.config/quickshell/popups/weather/Mode7Header.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../../services"

// A SNES title card: the temperature and condition over a sky gradient that meets a strip of Mode 7 floor.
Rectangle {
    id: root

    readonly property var cur: WeatherState.current
    readonly property bool has: WeatherState.has_data && !!root.cur
    readonly property bool roomy: root.width >= 330
    readonly property int ground_h: 16

    implicitHeight: title.implicitHeight + 20 + root.ground_h
    radius: Style.radius(4)
    clip: true
    border.width: 2
    border.color: Theme.theme_primary
    gradient: Gradient {
        GradientStop { position: 0; color: Qt.tint(Theme.bg_crust, Qt.alpha(Theme.theme_primary, 0.55)) }
        GradientStop { position: 0.75; color: Qt.tint(Theme.bg_mantle, Qt.alpha(Theme.theme_secondary, 0.22)) }
        GradientStop { position: 1; color: Theme.bg_crust }
    }

    Mode7Floor {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 2
        height: root.ground_h
    }

    RowLayout {
        id: title
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 10
        spacing: 10

        Image {
            visible: root.roomy && root.has
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            Layout.alignment: Qt.AlignVCenter
            readonly property real dpr: QsWindow.window ? QsWindow.window.devicePixelRatio : 1
            source: root.has ? WeatherState.icon_source(root.cur.code, root.cur.is_day) : ""
            sourceSize.width: Math.ceil(88 * dpr)
            sourceSize.height: Math.ceil(88 * dpr)
            smooth: true
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.has ? Math.round(root.cur.temp) + "°" : "--°"
            color: root.has ? Theme.theme_secondary : Style.text_dim
            font.family: Style.font_family
            font.pixelSize: Style.font_size * 2 + 8
            style: Text.Raised
            styleColor: Style.text_shadow
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.has ? root.cur.cond : WeatherState.loading ? "Loading" : "No signal"
                color: root.has || WeatherState.loading ? Style.text_strong : Theme.warning
                font.family: Style.font_family
                font.pixelSize: Style.font_size - 2
                font.capitalization: Font.AllUppercase
                style: Text.Raised
                styleColor: Style.text_shadow
            }

            Text {
                visible: root.has
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.has ? "Feels " + Math.round(root.cur.feels) + "°  Hum " + root.cur.humidity + "%" : ""
                color: Theme.theme_primary_light
                font.family: Style.font_family
                font.pixelSize: Style.font_size - 6
            }

            Text {
                visible: WeatherState.location_name !== "" || WeatherState.stale
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: WeatherState.stale ? "Stale data" + (WeatherState.error ? ": " + WeatherState.error : "") : WeatherState.location_name
                color: WeatherState.stale ? Theme.warning : Style.text_muted
                font.family: Style.font_family
                font.pixelSize: Style.font_size - 6
            }
        }
    }
}
