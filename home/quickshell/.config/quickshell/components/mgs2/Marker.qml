// home/quickshell/.config/quickshell/components/mgs2/Marker.qml
import QtQuick
import "../../theme"

// The solid selection rectangle beside a menu row, sized from the row's cap height.
Rectangle {
    property real cap_height: 16

    width: Math.round(cap_height * 16 / 26)
    height: Math.round(cap_height * 13 / 26)
    color: Style.text_strong
}
