// home/quickshell/.config/quickshell/components/ControllerBadge.qml
import QtQuick
import "../theme"
import "ps1" as Ps1

// A key drawn as its controller buttons (KeyHints.controller_parts), text parts left as plain key text.
Row {
    id: root

    property string controller: ""
    property var parts: []
    property real size: 16
    property color text_color: Style.key_fg
    property string font_family: Style.mono_font
    property real font_size: Style.font_size - 5

    spacing: 2

    Repeater {
        model: root.parts

        Loader {
            required property var modelData
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            sourceComponent: !modelData.button ? text_part : root.controller === "ps1" ? ps1_part : null
            onLoaded: if (modelData.button) item.button = modelData.button; else item.text = modelData.text
        }
    }

    Component {
        id: text_part

        Text {
            color: root.text_color
            font.family: root.font_family
            font.pixelSize: root.font_size
        }
    }

    Component {
        id: ps1_part

        Ps1.Ps1Button {
            size: root.size
        }
    }
}
