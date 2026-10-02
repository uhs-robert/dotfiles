// home/quickshell/.config/quickshell/components/mgs2/Head.qml
import QtQuick
import "../../theme"

// A heading in the menu face with a rule under it exactly as wide as the text.
Item {
    id: root

    property string text: ""
    property real cap_height: 14
    property color color: Style.text_fg
    property color rule_color: Qt.alpha(Theme.fg_core, 0.7)
    property real rule_gap: Math.round(root.cap_height * 0.4)

    implicitWidth: seg.implicitWidth
    implicitHeight: root.cap_height + root.rule_gap + 1.5

    SegText {
        id: seg
        text: root.text
        cap_height: root.cap_height
        color: root.color
    }

    Rectangle {
        y: root.cap_height + root.rule_gap
        width: root.width
        height: 1.5
        color: root.rule_color
    }
}
