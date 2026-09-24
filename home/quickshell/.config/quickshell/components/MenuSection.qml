// home/quickshell/.config/quickshell/components/MenuSection.qml
import QtQuick
import "../theme"

Text {
    id: root

    property string label: ""

    width: (Style.section_rule || Style.section_fade.a > 0) && parent ? parent.width : implicitWidth
    clip: Style.section_rule
    text: Style.section_rule ? "── " + root.label + " " + "─".repeat(160) : root.label
    color: Style.section_fg
    font.family: Style.font_family
    font.pixelSize: Style.font_size - 3
    font.capitalization: Style.label_caps ? Font.AllUppercase : Font.MixedCase
    font.letterSpacing: Style.label_spacing

    Rectangle {
        visible: Style.section_fade.a > 0
        x: root.contentWidth + 8
        y: root.topPadding + Math.round(root.contentHeight / 2)
        width: Math.max(0, (root.width - x) * 0.7)
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Style.section_fade }
            GradientStop { position: 1; color: Qt.alpha(Style.section_fade, 0) }
        }
    }
}
