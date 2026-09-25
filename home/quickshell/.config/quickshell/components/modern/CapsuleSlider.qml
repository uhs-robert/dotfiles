// home/quickshell/.config/quickshell/components/modern/CapsuleSlider.qml
import QtQuick
import Quickshell.Services.Pipewire
import "../../theme"
import ".." as Shared

// A level as a tall capsule on a recessed well: the node's live wave fills it up to the level, with a marker at the level and a red tip past 90%.
Item {
    id: root

    property real value: 0
    property bool muted: false
    property string glyph: ""
    property string label: ""
    property bool selected: false
    property bool interactive: true
    property bool show_readout: true
    // A solid gradient fill instead of the wave, for small capsules like the OSD's.
    property bool solid: false
    // A static glow rising toward the level instead of the wave, for levels without audio.
    property bool glow: false
    // Live wave from this node; the monitor and the wave only run while peaks_on.
    property var node: null
    property bool peaks_on: false

    signal moved(real value)
    signal mute_clicked

    readonly property real level: Math.max(0, Math.min(1, root.value))
    readonly property real fill_width: root.width * root.level
    readonly property real radius: height / 2
    readonly property real pad: Math.round(height * 0.42)

    implicitHeight: Style.px(34)

    // Peaks on a 60 dB scale so quiet audio still moves the wave.
    function db_level(p) {
        return p > 0 ? Math.max(0, 1 + Math.log(p) / Math.LN10 * 20 / 60) : 0;
    }

    // Recent peaks, newest last; the wave samples them once per frame.
    property var history: []
    function sample(n) {
        const h = root.history.length >= n ? root.history.slice(root.history.length - n + 1) : root.history.slice();
        h.push(root.db_level(peak_monitor.peak));
        root.history = h;
        return h.length >= n ? h : new Array(n - h.length).fill(0).concat(h);
    }
    onPeaks_onChanged: if (!root.peaks_on) root.history = []

    PwNodePeakMonitor {
        id: peak_monitor
        node: root.peaks_on ? root.node : null
        enabled: root.peaks_on
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.darker(Style.tab_well, 1.25) }
            GradientStop { position: 1; color: Style.tab_well }
        }
        border.width: root.selected ? 1.5 : 1
        border.color: root.selected ? Theme.theme_primary : Style.frame_border_color
    }

    Rectangle {
        id: solid_fill
        visible: root.solid && root.fill_width > 0.5
        width: root.fill_width
        height: root.height
        radius: root.radius
        opacity: root.muted ? 0.4 : 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Style.selection_shade.a > 0 ? Style.selection_shade : Style.selection_bg }
            GradientStop { position: Math.min(1, root.width * 0.9 / Math.max(1, solid_fill.width)); color: Style.selection_bg }
            GradientStop { position: 1; color: root.level > 0.9 ? Theme.theme_label : Style.selection_bg }
        }
    }

    // The level region: a faint primary wash, the wave, and a red wash on the part past 90%.
    Item {
        id: wave_region
        visible: !root.solid
        x: root.radius * 0.5
        width: Math.max(0, root.fill_width - x)
        height: root.height
        clip: true
        opacity: root.muted ? 0.4 : 1

        Rectangle {
            x: -wave_region.x
            width: root.fill_width
            height: parent.height
            radius: root.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.alpha(Theme.theme_primary, 0.04) }
                GradientStop { position: root.glow ? 0.7 : 1; color: Qt.alpha(Theme.theme_primary, root.glow ? 0.2 : 0.14) }
                GradientStop { position: 1; color: root.glow ? Qt.alpha(Theme.theme_primary_light, 0.42) : Qt.alpha(Theme.theme_primary, 0.14) }
            }
        }

        // A soft light band along the middle, brightest at the level.
        Rectangle {
            visible: root.glow
            x: -wave_region.x
            y: root.height * 0.3
            width: root.fill_width
            height: root.height * 0.4
            radius: height / 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.alpha(Theme.theme_primary_light, 0) }
                GradientStop { position: 1; color: Qt.alpha(Theme.theme_primary_light, 0.28) }
            }
        }

        Shared.Waveform {
            visible: !root.glow
            y: root.height * 0.12
            width: parent.width
            height: root.height * 0.76
            sample: n => root.sample(n)
            gain: 1
            tint: Theme.theme_primary_light
            running: root.peaks_on && !root.solid && !root.glow
        }

        Rectangle {
            visible: root.level > 0.9
            x: root.width * 0.9 - wave_region.x
            width: Math.max(0, wave_region.width - x)
            height: parent.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.alpha(Theme.theme_label, 0) }
                GradientStop { position: 1; color: Qt.alpha(Theme.theme_label, 0.35) }
            }
        }
    }

    Rectangle {
        visible: !root.solid && root.level > 0
        x: Math.max(root.radius * 0.5, Math.min(root.width - root.radius * 0.5, root.fill_width)) - 1
        y: root.height * 0.2
        width: 2
        height: root.height * 0.6
        radius: 1
        color: root.level > 0.9 ? Theme.theme_label : Theme.theme_primary
        opacity: root.muted ? 0.4 : 1
    }

    Text {
        id: icon_text
        x: root.pad
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        color: Style.text_fg
        style: Text.Outline
        styleColor: Qt.alpha(Style.tab_well, 0.9)
        font.family: Theme.font_family
        font.pixelSize: Style.font_size + 1
    }

    Text {
        anchors.left: icon_text.right
        anchors.leftMargin: 8
        anchors.right: readout.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: root.label
        color: Style.text_fg
        style: Text.Outline
        styleColor: Qt.alpha(Style.tab_well, 0.9)
        font.family: Style.font_family
        font.pixelSize: Style.font_size - 1
        font.weight: Font.Medium
    }

    Text {
        id: readout
        visible: root.show_readout
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        anchors.verticalCenter: parent.verticalCenter
        text: root.muted ? "Muted" : Math.round(root.level * 100) + "%"
        color: Style.text_dim
        style: Text.Outline
        styleColor: Qt.alpha(Style.tab_well, 0.9)
        font.family: Style.number_font
        font.pixelSize: Style.font_size - 2
        font.features: { "tnum": 1 }
    }

    MouseArea {
        enabled: root.interactive
        anchors.fill: parent
        onPressed: mouse => root.moved(Math.max(0, Math.min(1, mouse.x / Math.max(1, root.width))))
        onPositionChanged: mouse => {
            if (pressed) root.moved(Math.max(0, Math.min(1, mouse.x / Math.max(1, root.width))));
        }
    }

    // The icon mutes, like the shared row's mute glyph.
    MouseArea {
        enabled: root.interactive && root.glyph !== ""
        width: root.pad * 2 + Style.font_size
        height: root.height
        onClicked: root.mute_clicked()
    }
}
