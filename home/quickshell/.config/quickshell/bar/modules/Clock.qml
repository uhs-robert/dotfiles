// home/quickshell/.config/quickshell/bar/modules/Clock.qml
import QtQuick
import Quickshell
import "../../theme"
import "../../services"
import "../../components/modern" as Modern

Row {
    id: root

    property bool compact: false
    // Set by the bar when its oasis horizon art sits behind this clock; it needs room for the palm and sky.
    property bool horizon: false
    readonly property date date: clock.date
    spacing: 6
    leftPadding: root.horizon ? 24 : 0
    rightPadding: root.horizon ? 22 : 0
    transform: Translate { y: root.horizon ? -4 : 0 }

    SystemClock {
        id: clock
        precision: root.compact ? SystemClock.Minutes : SystemClock.Seconds
    }

    function pad2(n) {
        return n < 10 ? "0" + n : "" + n;
    }

    // Styles with a clock chip draw the digits on it and the zone beside it.
    readonly property bool chip: Style.bar_clock_bg.a > 0
    readonly property bool capsule: Style.bar_clock_layout === "capsule"
    // Lualine: bold digits, the zone and date dimmed after them.
    readonly property bool lualine: Style.bar_lualine
    readonly property string digits_text: {
        const d = Timezones.shift(clock.date);
        const hm = pad2(d.getHours() % 12 || 12) + ":" + pad2(d.getMinutes());
        return root.compact ? hm : hm + ":" + pad2(d.getSeconds());
    }
    readonly property string zone_text: root.compact ? "" : Timezones.is_local ? Qt.formatDateTime(Timezones.shift(clock.date), "t") : Timezones.abbrev
    readonly property string time_text: root.zone_text === "" ? root.digits_text : root.digits_text + " " + root.zone_text

    // A Mario HUD line: TIME and WORLD captions, the date as month-day.
    readonly property bool hud: Style.console_views === "nes"
    readonly property string date_text: root.hud ? Qt.formatDateTime(Timezones.shift(clock.date), "M-d") : Qt.formatDateTime(Timezones.shift(clock.date), "ddd MMM dd")

    // Proportional fonts would resize the island every tick; tabular digits and a width floor hold it still.
    TextMetrics {
        id: time_metrics
        text: (root.capsule ? root.digits_text : time_label.text).replace(/\d/g, "0")
        font: root.capsule && capsule_loader.item ? capsule_loader.item.time_font : time_label.font
    }

    Loader {
        id: capsule_loader
        active: root.capsule
        visible: active
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: Modern.CapsuleClock {
            time_text: root.digits_text
            zone_text: root.zone_text
            date_text: root.date_text
            compact: root.compact
            time_floor: time_metrics.advanceWidth
        }
    }

    Text {
        visible: Style.bar_clock_brackets.a > 0 && !root.capsule
        anchors.verticalCenter: parent.verticalCenter
        text: "["
        color: Style.bar_clock_brackets
        font: time_label.font
    }

    Text {
        visible: root.lualine
        anchors.verticalCenter: parent.verticalCenter
        text: "\u{f017}"
        color: Theme.theme_primary
        font.family: Style.bar_font_family
        font.pixelSize: Style.bar_font_size
    }

    Text {
        visible: root.hud && !root.capsule
        anchors.verticalCenter: parent.verticalCenter
        text: "TIME"
        color: Theme.theme_primary
        font.family: Style.bar_font_family
        font.pixelSize: Style.bar_font_size
    }

    Rectangle {
        visible: !root.capsule
        readonly property real pad: root.chip ? 5 : 0
        anchors.verticalCenter: parent.verticalCenter
        width: time_label.width + pad * 2
        height: time_label.height + pad
        radius: 3
        color: root.chip ? Style.bar_clock_bg : "transparent"

        Text {
            id: time_label
            x: parent.pad
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(implicitWidth, Math.ceil(time_metrics.advanceWidth))
            text: root.chip || root.lualine ? root.digits_text : root.time_text
            color: root.chip || root.lualine ? Style.bar_clock_fg : Style.bar_fg
            font.family: root.chip ? Style.bar_clock_font : Style.bar_font_family
            font.features: { "tnum": 1 }
            font.weight: root.lualine ? Font.Bold : root.horizon ? Font.DemiBold : Font.Normal
            style: root.chip ? Text.Normal : Style.bar_text_style
            styleColor: Style.bar_glow_color
            font.pixelSize: root.chip ? Style.bar_font_size + 2 : Style.bar_font_size
            font.capitalization: Style.bar_capitalization
            font.letterSpacing: root.chip ? 0 : Style.bar_letter_spacing
        }
    }

    Text {
        visible: (root.chip || root.lualine) && root.zone_text !== "" && !root.capsule
        anchors.verticalCenter: parent.verticalCenter
        text: root.zone_text
        color: root.lualine ? Style.text_dim : Style.bar_fg
        font.family: Style.bar_font_family
        style: Style.bar_text_style
        styleColor: Style.bar_glow_color
        font.pixelSize: Style.bar_font_size
        font.capitalization: Style.bar_capitalization
        font.letterSpacing: Style.bar_letter_spacing
    }

    Text {
        visible: !root.compact && !root.horizon && !root.capsule
        anchors.verticalCenter: parent.verticalCenter
        text: root.hud ? " WORLD" : root.lualine ? "\u00b7" : "|"
        color: root.lualine ? Style.text_dim : Theme.theme_primary
        font.family: Style.bar_font_family
        style: Style.bar_text_style
        styleColor: Style.bar_glow_color
        font.pixelSize: Style.bar_font_size
        font.capitalization: Style.bar_capitalization
        font.letterSpacing: Style.bar_letter_spacing
    }

    Text {
        visible: !root.compact && !root.capsule
        anchors.verticalCenter: parent.verticalCenter
        text: root.date_text
        color: root.lualine ? Style.text_dim : Style.bar_fg
        font.family: Style.bar_font_family
        style: Style.bar_text_style
        styleColor: Style.bar_glow_color
        font.pixelSize: Style.bar_font_size
        font.capitalization: Style.bar_capitalization
        font.letterSpacing: Style.bar_letter_spacing
    }

    Text {
        visible: Style.bar_clock_brackets.a > 0 && !root.capsule
        anchors.verticalCenter: parent.verticalCenter
        text: "]"
        color: Style.bar_clock_brackets
        font: time_label.font
    }
}
