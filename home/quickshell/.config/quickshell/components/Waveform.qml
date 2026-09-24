// home/quickshell/.config/quickshell/components/Waveform.qml
import QtQuick
import "../theme"
import "../services"

// Mirrored bars of recent voxtype mic levels, newest on the right.
Item {
    id: root

    // Polls VoxtypeAudio only while true.
    property bool running: false
    property int bar_count: 30
    // Bars from this level up take the hot color.
    property real hot_from: 0.9
    property var levels: []
    readonly property int gap: 2
    readonly property real bar_width: Math.max(2, (width - gap * (bar_count - 1)) / bar_count)

    implicitWidth: bar_count * 3 + gap * (bar_count - 1)
    implicitHeight: Style.px(18)

    Timer {
        interval: 33
        repeat: true
        running: root.running
        triggeredOnStart: true
        onTriggered: root.levels = VoxtypeAudio.columns(root.bar_count)
    }

    Row {
        height: root.height
        spacing: root.gap

        Repeater {
            model: root.bar_count

            Rectangle {
                id: bar
                required property int index
                readonly property real level: root.levels[bar.index] || 0
                readonly property bool lit: bar.level > 0.02
                readonly property bool is_hot: bar.level >= root.hot_from

                y: Math.round((root.height - bar.height) / 2)
                width: root.bar_width
                height: Math.max(2, Math.round(bar.level * root.height))
                radius: Math.min(Style.meter_radius, bar.width / 2)
                color: !bar.lit ? Style.meter_off : bar.is_hot ? Style.meter_hot : Style.meter_on

                Rectangle {
                    visible: bar.lit && !bar.is_hot && Style.meter_shade.a > 0
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0; color: Style.meter_shade }
                        GradientStop { position: 0.6; color: Qt.alpha(Style.meter_shade, 0) }
                    }
                }
            }
        }
    }
}
