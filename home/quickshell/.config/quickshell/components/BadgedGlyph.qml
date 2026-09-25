// home/quickshell/.config/quickshell/components/BadgedGlyph.qml
import QtQuick
import "../theme"

// A glyph with its count as a small superscript badge, top right. Reserves headroom above the
// glyph so the badge never pokes past the item's own top and clips against the bar surface.
Item {
    id: root

    property string glyph: ""
    property string count: ""
    property color tint: Theme.yellow
    // Pango rise in 1/1024pt, for a bobbing glyph (keeptabs' running/done icons).
    property real glyph_rise: 0
    property real glyph_opacity: 1

    readonly property alias glyph_item: glyph_text
    readonly property alias count_item: count_text

    readonly property real badge_size: Math.max(6, Style.bar_font_size - 3)
    // How far the badge rises above the glyph's own top, like the old fixed "y: -3" — now reserved
    // as real height instead of overflowing past the item's top edge.
    readonly property real badge_rise: 3

    implicitWidth: glyph_text.implicitWidth + (count_text.visible ? count_text.implicitWidth * 0.6 : 0)
    implicitHeight: glyph_text.implicitHeight + root.badge_rise

    Text {
        id: glyph_text
        y: root.badge_rise - root.glyph_rise / 1024
        text: root.glyph
        color: root.tint
        font.family: Style.bar_font_family
        style: Style.bar_text_style
        styleColor: Style.bar_glow_color
        font.pixelSize: Theme.glyph_size
        opacity: root.glyph_opacity
    }

    Text {
        id: count_text
        visible: root.count !== ""
        x: glyph_text.implicitWidth - implicitWidth * 0.4
        y: 0
        text: root.count
        color: root.tint
        font.family: Style.bar_font_family
        style: Style.bar_text_style
        styleColor: Style.bar_glow_color
        font.pixelSize: root.badge_size
        font.bold: true
    }
}
