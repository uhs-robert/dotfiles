// home/quickshell/.config/quickshell/theme/Style.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string name: "default"
    readonly property var names: Object.keys(root.styles)

    readonly property var styles: ({
        "default": {
            font_family: Theme.font_family,
            font_size: Theme.popup_font_size,
            rounded: true,
            frame_follows_island: true,
            frame_color: Theme.bg_mantle,
            frame_radius: 10,
            frame_border_width: 0,
            frame_border_color: "transparent",
            accent_color: Theme.theme_primary,
            accent_height: 3,
            selection_bg: Theme.bg_surface,
            selection_inverse: false,
            selection_fg: Theme.bg_crust,
            tab_active_bg: Theme.bg_surface,
            tab_active_fg: Theme.theme_secondary,
            tab_fg: Theme.fg_muted,
            key_bg: Theme.bg_mantle,
            key_fg: Theme.fg_dim,
            key_border: Theme.ui_border,
            section_fg: Theme.fg_muted,
            section_rule: false,
            footer_fg: Theme.fg_dim,
            footer_rule: false,
            footer_rule_color: Theme.bg_surface,
            meter_on: Theme.theme_primary,
            meter_off: Theme.bg_surface,
            meter_hot: Theme.theme_label,
            meter_radius: 1
        },
        "terminal": {
            font_family: "JetBrainsMono Nerd Font",
            font_size: Theme.popup_font_size,
            rounded: false,
            frame_follows_island: false,
            frame_color: Theme.bg_crust,
            frame_radius: 0,
            frame_border_width: 0,
            frame_border_color: "transparent",
            accent_color: Theme.theme_secondary,
            accent_height: 3,
            selection_bg: Theme.theme_primary,
            selection_inverse: true,
            selection_fg: Theme.bg_crust,
            tab_active_bg: Theme.theme_secondary,
            tab_active_fg: Theme.bg_crust,
            tab_fg: Theme.fg_muted,
            key_bg: "transparent",
            key_fg: Theme.fg_muted,
            key_border: Theme.bg_surface,
            section_fg: Theme.fg_muted,
            section_rule: true,
            footer_fg: Theme.fg_muted,
            footer_rule: true,
            footer_rule_color: Theme.bg_surface,
            meter_on: Theme.theme_primary,
            meter_off: Theme.bg_surface,
            meter_hot: Theme.theme_label,
            meter_radius: 0
        }
    })

    readonly property var active: root.styles[root.name] || root.styles["default"]

    readonly property string font_family: root.active.font_family
    readonly property int font_size: root.active.font_size
    readonly property bool rounded: root.active.rounded
    readonly property bool frame_follows_island: root.active.frame_follows_island
    readonly property color frame_color: root.active.frame_color
    readonly property real frame_radius: root.active.frame_radius
    readonly property int frame_border_width: root.active.frame_border_width
    readonly property color frame_border_color: root.active.frame_border_color
    readonly property color accent_color: root.active.accent_color
    readonly property int accent_height: root.active.accent_height
    readonly property color selection_bg: root.active.selection_bg
    readonly property bool selection_inverse: root.active.selection_inverse
    readonly property color selection_fg: root.active.selection_fg
    readonly property color tab_active_bg: root.active.tab_active_bg
    readonly property color tab_active_fg: root.active.tab_active_fg
    readonly property color tab_fg: root.active.tab_fg
    readonly property color key_bg: root.active.key_bg
    readonly property color key_fg: root.active.key_fg
    readonly property color key_border: root.active.key_border
    readonly property color section_fg: root.active.section_fg
    readonly property bool section_rule: root.active.section_rule
    readonly property color footer_fg: root.active.footer_fg
    readonly property bool footer_rule: root.active.footer_rule
    readonly property color footer_rule_color: root.active.footer_rule_color
    readonly property color meter_on: root.active.meter_on
    readonly property color meter_off: root.active.meter_off
    readonly property color meter_hot: root.active.meter_hot
    readonly property real meter_radius: root.active.meter_radius

    // Corner radius for a shape that is rounded by `r` in the default look.
    function radius(r) {
        return root.rounded ? r : 0;
    }

    function set(style_name) {
        if (!(style_name in root.styles)) {
            console.warn("Style: unknown style " + style_name);
            return false;
        }
        root.name = style_name;
        state_file.setText(JSON.stringify({ style: style_name }));
        return true;
    }

    function cycle() {
        const i = root.names.indexOf(root.name);
        root.set(root.names[(i + 1) % root.names.length]);
    }

    readonly property string state_dir: {
        const xdg = Quickshell.env("XDG_STATE_HOME");
        return (xdg && xdg !== "" ? xdg : Quickshell.env("HOME") + "/.local/state") + "/quickshell";
    }

    Process {
        id: ensure_state_dir
        command: ["mkdir", "-p", root.state_dir]
    }

    FileView {
        id: state_file
        path: root.state_dir + "/style.json"
        printErrors: false
        blockLoading: true
        onLoaded: {
            try {
                const saved = JSON.parse(text()).style;
                if (typeof saved === "string" && saved in root.styles) root.name = saved;
            } catch (e) {
                console.warn("Style: invalid style.json (" + e + ")");
            }
        }
        onLoadFailed: error => {}
    }

    Component.onCompleted: {
        ensure_state_dir.running = true;
        state_file.reload();
    }
}
