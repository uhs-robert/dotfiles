// home/quickshell/.config/quickshell/components/oasis/HorizonOsd.qml
import QtQuick
import QtQuick.Layouts
import "../../theme"

// The oasis OSD: an icon in a well, the level in light numerals, and 20 horizon segments with a sand sun at the level.
ColumnLayout {
    id: root

    property real level: 0
    property int percent: 0
    property bool muted: false
    property string glyph: ""
    property string label: ""
    property string detail: ""

    readonly property color sand: Theme.theme_secondary
    readonly property int count: 20
    readonly property int lit: Math.round(Math.max(0, Math.min(1, root.level)) * root.count)

    spacing: Style.px(10)

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.px(10)

        Rectangle {
            Layout.preferredWidth: Style.px(34)
            Layout.preferredHeight: Style.px(34)
            radius: 10
            color: Qt.alpha(Theme.bg_crust, 0.55)

            Text {
                anchors.centerIn: parent
                text: root.glyph
                color: root.sand
                opacity: root.muted ? 0.5 : 1
                font.family: Theme.font_family
                font.pixelSize: Style.px(18)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 1

            Text {
                text: root.label
                color: Theme.fg_strong
                font.family: Style.font_family
                font.pixelSize: Style.font_size + 1
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                visible: root.detail !== ""
                elide: Text.ElideRight
                text: root.detail
                color: Theme.fg_dim
                font.family: Style.font_family
                font.pixelSize: Style.font_size - 3
            }
        }

        Row {
            Layout.alignment: Qt.AlignBottom
            spacing: 2

            Text {
                id: numeral
                text: String(root.percent)
                color: root.muted ? Theme.fg_dim : Theme.fg_strong
                font.family: Style.number_font
                font.pixelSize: Style.px(38)
                font.weight: Font.Light
                font.letterSpacing: -1
                font.features: { "tnum": 1 }
            }

            Text {
                anchors.baseline: numeral.baseline
                text: "%"
                color: Theme.fg_dim
                font.family: Style.number_font
                font.pixelSize: Style.font_size
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        Layout.preferredWidth: Style.px(284)
        Layout.preferredHeight: 16
        opacity: root.muted ? 0.4 : 1

        Row {
            id: segments
            readonly property real seg_w: (width - spacing * (root.count - 1)) / root.count
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 2

            Repeater {
                model: root.count

                Rectangle {
                    required property int index
                    readonly property bool on: index < root.lit

                    width: segments.seg_w
                    height: on ? 3 : 2
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 1.5
                    color: !on ? Qt.alpha(Theme.theme_primary, 0.3) : index >= root.count * 0.9 ? Theme.theme_label : Qt.tint(Theme.theme_primary_strong, Qt.alpha(root.sand, index / (root.count - 1)))
                }
            }
        }

        Rectangle {
            readonly property real at: root.lit > 0 ? (root.lit * (segments.seg_w + segments.spacing) - segments.spacing) : 0
            x: at - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            radius: 10
            color: Qt.alpha(root.sand, 0.18)

            Rectangle {
                anchors.centerIn: parent
                width: 12
                height: 12
                radius: 6
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.fg_strong }
                    GradientStop { position: 0.6; color: root.sand }
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        Layout.topMargin: -6
        Layout.preferredHeight: scale_zero.implicitHeight

        Text {
            id: scale_zero
            text: "0"
            color: Theme.fg_muted
            font.family: Style.number_font
            font.pixelSize: Style.font_size - 5
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "50"
            color: Theme.fg_muted
            font: scale_zero.font
        }

        Text {
            anchors.right: parent.right
            text: "100"
            color: Theme.fg_muted
            font: scale_zero.font
        }
    }
}
