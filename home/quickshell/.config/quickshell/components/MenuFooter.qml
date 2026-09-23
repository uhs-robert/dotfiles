// home/quickshell/.config/quickshell/components/MenuFooter.qml
import QtQuick
import QtQuick.Layouts
import "../theme"

// The key hint line under a popup; some styles rule it off with a dashed line.
Item {
    id: root

    property string text: ""
    readonly property int rule_gap: Style.footer_rule ? 5 : 0

    Layout.minimumWidth: 0
    implicitWidth: hint.implicitWidth
    implicitHeight: hint.implicitHeight + root.rule_gap

    Row {
        visible: Style.footer_rule
        width: parent.width
        spacing: 3
        clip: true

        Repeater {
            model: Style.footer_rule ? Math.ceil(root.width / 7) : 0

            Rectangle {
                width: 4
                height: 1
                color: Style.footer_rule_color
            }
        }
    }

    Text {
        id: hint
        y: root.rule_gap
        width: parent.width
        elide: Text.ElideRight
        text: root.text
        color: Style.footer_fg
        font.family: Style.font_family
        font.pixelSize: Style.font_size - 4
    }
}
