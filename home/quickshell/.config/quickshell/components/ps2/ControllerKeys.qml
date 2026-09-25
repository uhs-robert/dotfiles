// home/quickshell/.config/quickshell/components/ps2/ControllerKeys.qml
import QtQuick
import "../../theme"
import "../KeyHints.js" as KeyHints

// A hint key spoken as DualShock 2 buttons; keys without a button stay as text between them.
Row {
    id: root

    readonly property var st: Style.for_item(root)

    property string key: ""
    property real size: root.st.font_size - 1
    property color text_color: root.st.footer_key_fg
    readonly property var parts: KeyHints.controller_parts(root.key, "ps2")

    spacing: 2

    Repeater {
        model: root.parts

        Row {
            id: part
            required property var modelData
            required property int index
            spacing: 2

            Text {
                visible: part.index > 0
                anchors.verticalCenter: parent.verticalCenter
                text: "/"
                color: root.st.text_muted
                font.family: root.st.font_family
                font.pixelSize: root.size - 3
            }

            Ps2Button {
                visible: !!part.modelData.button
                anchors.verticalCenter: parent.verticalCenter
                button: part.modelData.button || "cross"
                size: root.size
            }

            Text {
                visible: !part.modelData.button
                anchors.verticalCenter: parent.verticalCenter
                text: part.modelData.text || ""
                color: root.text_color
                font.family: root.st.font_family
                font.pixelSize: root.size - 3
            }
        }
    }
}
