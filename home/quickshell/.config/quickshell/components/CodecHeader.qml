// home/quickshell/.config/quickshell/components/CodecHeader.qml
import QtQuick
import QtQuick.Effects
import "../theme"

// A codec screen header: a PTT tag, a boxed frequency readout and the title.
Item {
    id: root

    property string title: ""
    // Picks the frequency, so each popup keeps its own channel.
    property string seed: root.title

    readonly property string frequency: {
        let h = 7;
        for (let i = 0; i < root.seed.length; i++) h = (h * 31 + root.seed.charCodeAt(i)) % 20011;
        return (140 + (h % 200) / 100).toFixed(2);
    }

    implicitWidth: row.implicitWidth + 20
    implicitHeight: row.implicitHeight + 10

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: ptt_text.implicitWidth + 8
            height: ptt_text.implicitHeight
            radius: 2
            color: "transparent"
            border.width: 1
            border.color: Theme.theme_primary_light

            Text {
                id: ptt_text
                anchors.centerIn: parent
                text: "PTT"
                color: Theme.theme_primary_light
                font.family: Style.font_family
                font.pixelSize: Style.font_size - 5
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: freq_text.implicitWidth + 16
            height: freq_text.implicitHeight
            color: Style.title_bg
            border.width: 1
            border.color: Theme.theme_primary

            MultiEffect {
                anchors.fill: freq_text
                source: freq_text
                blurEnabled: true
                blur: 0.6
                blurMax: 16
                colorization: 1
                colorizationColor: Theme.theme_primary
            }

            Text {
                id: freq_text
                anchors.centerIn: parent
                layer.enabled: true
                text: root.frequency
                color: Theme.theme_primary
                font.family: Style.font_family
                font.pixelSize: Style.font_size + 8
                font.letterSpacing: 1
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            color: Theme.theme_primary_light
            font.family: Style.font_family
            font.pixelSize: Style.font_size - 3
            font.letterSpacing: 2
        }
    }
}
