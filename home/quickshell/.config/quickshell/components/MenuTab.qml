// home/quickshell/.config/quickshell/components/MenuTab.qml
import QtQuick
import QtQuick.Layouts
import "../theme"

// A tab or sub-view chip; tabs fill their row, chips size to the label.
Rectangle {
    id: root

    property string label: ""
    property bool active: false
    property int font_size: Style.font_size - 2
    property real base_radius: 4

    signal clicked()

    // Filling tabs share their row evenly, so they must not ask for the label's width.
    implicitWidth: root.Layout.fillWidth ? 0 : label_text.implicitWidth + 20
    implicitHeight: 24
    radius: Style.radius(root.base_radius)
    color: root.active ? Style.tab_active_bg : "transparent"

    Text {
        id: label_text
        anchors.centerIn: parent
        width: Math.min(implicitWidth, parent.width - 8)
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.label
        color: root.active ? Style.tab_active_fg : Style.tab_fg
        font.bold: root.active
        font.family: Style.font_family
        font.pixelSize: root.font_size
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
