// home/quickshell/.config/quickshell/components/mgs2/CodecCard.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../../theme"
import "Seg.js" as Seg

// A notification as an MGS2 codec call: portrait, meter and frequency in a thin box, the spoken line below.
Item {
    id: root

    property var notification: null
    property string app_name: ""
    property string summary: ""
    property string body: ""
    property string age: ""
    property bool compact: false
    property bool critical: false
    property bool low: false
    property bool selected: false
    property bool unread: false
    property bool closable: false
    property bool cue: false
    property int body_lines: 3

    signal close_requested()

    readonly property real box_h: root.compact ? 34 : 42
    readonly property real over: root.compact ? 4 : 5
    readonly property real head_h: root.box_h + root.over * 2
    readonly property real portrait_w: root.compact ? 32 : 40
    readonly property color frame: root.critical ? Theme.error : root.selected ? Theme.fg_strong : Qt.alpha(Theme.fg_core, 0.55)
    readonly property color meter_color: root.critical ? Theme.error : root.low ? Theme.fg_dim : Theme.theme_primary
    readonly property string app_upper: root.app_name.toUpperCase()
    readonly property bool app_in_set: Seg.supported(root.app_name)
    readonly property string freq: {
        let h = 0;
        for (let i = 0; i < root.app_name.length; i++) h = (h * 31 + root.app_name.charCodeAt(i)) % 200;
        return ((14000 + h) / 100).toFixed(2);
    }

    implicitHeight: root.head_h + 4 + text_box.implicitHeight

    Rectangle {
        id: head_box
        y: root.over
        width: root.width
        height: root.box_h
        color: Qt.alpha(Theme.bg_crust, 0.7)
        border.width: 1
        border.color: root.frame
    }

    Repeater {
        model: 4

        Rectangle {
            required property int index
            x: index % 2 === 0 ? 0 : root.width - 1
            y: index < 2 ? root.over - 3 : root.over + root.box_h
            width: 1
            height: 3
            color: root.frame
        }
    }

    CodecPortrait {
        x: 6
        width: root.portrait_w
        height: root.head_h
        notification: root.notification
        frame_color: root.frame
    }

    RowLayout {
        x: 6 + root.portrait_w + 10
        y: root.over + 4
        width: root.width - x - 22
        height: root.box_h - 8
        spacing: 8

        CodecMeter {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: root.compact ? 20 : 26
            bar_count: root.compact ? 5 : 6
            strength: root.critical ? (root.compact ? 5 : 6) : root.low ? 3 : 5
            on_color: root.meter_color
            cue: root.cue
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            spacing: 2

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                clip: true

                SegText {
                    id: ptt_text
                    text: "PTT"
                    cap_height: 6
                    color: Qt.alpha(Theme.fg_core, 0.7)
                }

                SegText {
                    visible: root.app_in_set
                    x: ptt_text.width + 8
                    text: root.app_upper
                    cap_height: 6
                    color: Qt.alpha(Theme.fg_core, 0.7)
                    width: Math.max(0, Math.min(implicitWidth, parent.width - x))
                    clip: true
                }

                Text {
                    visible: !root.app_in_set
                    x: ptt_text.width + 8
                    width: Math.max(0, parent.width - x)
                    elide: Text.ElideRight
                    text: root.app_name
                    color: Qt.alpha(Theme.fg_core, 0.7)
                    font.family: Style.font_family
                    font.pixelSize: 8
                }
            }

            SegText {
                text: root.freq
                cap_height: root.compact ? 12 : 14
                floor_text: "141.88"
                color: root.critical ? Theme.error : Theme.fg_strong
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 6

                Row {
                    visible: parent.width >= mem_text.width + 9 + tune_row.width + 8
                    spacing: 3

                    Shape {
                        width: 5
                        height: 6
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            strokeWidth: -1
                            fillColor: Qt.alpha(Theme.fg_core, 0.7)
                            startX: 0
                            startY: 1
                            PathLine { x: 5; y: 1 }
                            PathLine { x: 2.5; y: 5 }
                        }
                    }

                    SegText {
                        id: mem_text
                        text: "MEM."
                        cap_height: 6
                        color: Qt.alpha(Theme.fg_core, 0.7)
                    }
                }

                SegText {
                    id: tune_row
                    anchors.right: parent.right
                    visible: parent.width >= width
                    text: "< TUNE >"
                    cap_height: 6
                    color: Qt.alpha(Theme.fg_core, 0.7)
                }
            }
        }
    }

    Rectangle {
        visible: root.unread
        x: root.width - 11
        y: root.over + 5
        width: 5
        height: 5
        color: Theme.theme_primary
    }

    SegText {
        visible: root.closable
        x: root.width - 14
        y: root.over + 5
        text: "X"
        cap_height: 7
        color: Qt.alpha(Theme.fg_core, 0.7)

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            onClicked: root.close_requested()
        }
    }

    Rectangle {
        id: text_box
        y: root.head_h + 4
        width: root.width
        implicitHeight: lines.implicitHeight + 14
        height: implicitHeight
        color: Qt.alpha(Theme.bg_crust, 0.7)
        border.width: 1
        border.color: root.frame

        ColumnLayout {
            id: lines
            x: 8
            y: 7
            width: parent.width - 16
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    elide: Text.ElideRight
                    text: root.summary
                    color: Theme.fg_strong
                    font.bold: true
                    font.family: Style.font_family
                    font.pixelSize: Style.font_size
                }

                SegText {
                    Layout.alignment: Qt.AlignVCenter
                    visible: root.age !== ""
                    text: root.age.toUpperCase()
                    cap_height: 6
                    color: Qt.alpha(Theme.fg_core, 0.7)
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                visible: root.body !== ""
                maximumLineCount: root.body_lines
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                textFormat: Text.StyledText
                text: root.body
                color: Theme.fg_core
                font.family: Style.font_family
                font.pixelSize: Style.font_size
            }
        }
    }
}
