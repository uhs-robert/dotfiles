// home/quickshell/.config/quickshell/components/snes/SnesKey.qml
import QtQuick
import "../../theme"
import "../KeyHints.js" as KeyHints

// A key hint as SNES buttons: mapped parts draw the button, the rest keep their key text, joined by "/".
Row {
    id: root

    property var parts: []
    property color text_color: Style.footer_key_fg
    property string font_family: Style.font_family
    property int font_size: Style.font_size - 4
    property int button_size: 13

    spacing: 2

    Repeater {
        model: root.parts

        Row {
            id: part
            required property var modelData
            required property int index
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            spacing: 2

            Text {
                visible: part.index > 0
                anchors.verticalCenter: parent.verticalCenter
                text: "/"
                color: root.text_color
                font.family: root.font_family
                font.pixelSize: root.font_size
            }

            SnesButton {
                visible: part.modelData.button !== ""
                anchors.verticalCenter: parent.verticalCenter
                kind: part.modelData.button
                size: root.button_size
            }

            Text {
                visible: part.modelData.button === ""
                anchors.verticalCenter: parent.verticalCenter
                text: KeyHints.with_glyphs(part.modelData.text)
                color: root.text_color
                font.family: root.font_family
                font.pixelSize: root.font_size
            }
        }
    }
}
