// home/quickshell/.config/quickshell/components/mgs2/LifeBar.qml
import QtQuick
import QtQuick.Layouts
import "../../theme"

// A label tab, a thin gauge and a value; a negative frac drops the gauge.
RowLayout {
    id: root

    property string label: ""
    property string value: ""
    property string suffix: ""
    property real frac: -1
    property real cap_height: 8
    property color color: Style.text_fg
    property real tab_width: 44

    spacing: 5

    Rectangle {
        Layout.preferredWidth: root.tab_width
        Layout.preferredHeight: root.cap_height + 4
        color: Qt.alpha(root.color, 0.85)

        SegText {
            anchors.centerIn: parent
            text: root.label
            cap_height: root.cap_height
            color: Theme.bg_crust
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 6
        visible: root.frac >= 0

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(root.color, 0.1)
            border.width: 1
            border.color: Qt.alpha(root.color, 0.6)
        }

        Rectangle {
            x: 2
            y: 2
            width: Math.max(0, Math.min(1, root.frac)) * (parent.width - 4)
            height: parent.height - 4
            color: root.color
        }
    }

    Item {
        Layout.fillWidth: root.frac < 0
    }

    Row {
        spacing: 2

        SegText {
            text: root.value
            cap_height: root.cap_height
            color: root.color
            floor_text: "000"
        }

        SegText {
            visible: root.suffix !== ""
            text: root.suffix
            cap_height: root.cap_height
            color: root.color
        }
    }
}
