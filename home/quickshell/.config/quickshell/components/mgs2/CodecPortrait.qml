// home/quickshell/.config/quickshell/components/mgs2/CodecPortrait.qml
import QtQuick
import Quickshell
import "../../theme"

// The caller's portrait: icon or image in a thin frame, palette-tinted and scanlined.
Rectangle {
    id: root

    property var notification: null
    property color frame_color: Qt.alpha(Theme.fg_core, 0.55)
    readonly property string source_url: root.notification ? (root.notification.image !== "" ? root.notification.image : root.notification.appIcon !== "" ? Quickshell.iconPath(root.notification.appIcon, true) : "") : ""

    color: Qt.alpha(Theme.bg_crust, 0.9)
    border.width: 1
    border.color: root.frame_color
    clip: true

    Image {
        anchors.fill: parent
        anchors.margins: 1
        visible: root.source_url !== ""
        source: root.source_url
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        fillMode: Image.PreserveAspectCrop
    }

    SegText {
        anchors.centerIn: parent
        visible: root.source_url === ""
        text: "?"
        cap_height: 12
        color: Qt.alpha(Theme.fg_core, 0.6)
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.theme_primary, 0.22)
    }

    Repeater {
        model: Math.ceil(root.height / 3)

        Rectangle {
            required property int index
            y: index * 3
            width: root.width
            height: 1
            color: Qt.alpha(Theme.bg_shadow, 0.5)
        }
    }
}
