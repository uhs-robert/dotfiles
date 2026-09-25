// home/quickshell/.config/quickshell/components/modern/CapsuleSlider.qml
import QtQuick
import Quickshell.Services.Pipewire
import "../../theme"

// A level as a tall capsule: a recessed well, a primary fill from the left with a red tip past 90%, and the icon, label and readout inside.
Item {
    id: root

    property real value: 0
    property bool muted: false
    property string glyph: ""
    property string label: ""
    property bool selected: false
    property bool interactive: true
    property bool show_readout: true
    // Live peaks from this node; the monitor only runs while peaks_on.
    property var node: null
    property bool peaks_on: false

    signal moved(real value)
    signal mute_clicked

    readonly property real level: Math.max(0, Math.min(1, root.value))
    readonly property real fill_width: root.width * root.level
    readonly property real radius: height / 2
    readonly property real pad: Math.round(height * 0.42)

    implicitHeight: Style.px(34)

    // Peaks on a 60 dB scale so quiet audio still moves the line.
    function db_level(p) {
        return p > 0 ? Math.max(0, 1 + Math.log(p) / Math.LN10 * 20 / 60) : 0;
    }

    PwNodePeakMonitor {
        id: peak_monitor
        node: root.peaks_on ? root.node : null
        enabled: root.peaks_on
        onPeakChanged: {
            const l = root.db_level(peak_monitor.peak);
            if (l >= peak_line.hold) {
                peak_line.hold = l;
                peak_line.held_at = Date.now();
            }
        }
    }

    Rectangle {
        id: well
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
        id: fill
        visible: root.fill_width > 0.5
        width: root.fill_width
        height: root.height
        radius: root.radius
        opacity: root.muted ? 0.4 : 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Style.selection_shade.a > 0 ? Style.selection_shade : Style.selection_bg }
            GradientStop { position: Math.min(1, root.width * 0.9 / Math.max(1, fill.width)); color: Style.selection_bg }
            GradientStop { position: 1; color: root.level > 0.9 ? Theme.theme_label : Style.selection_bg }
        }
    }

    Item {
        id: peak_line
        property real hold: 0
        property double held_at: 0
        readonly property real now_level: root.peaks_on ? root.db_level(peak_monitor.peak) : 0
        visible: root.peaks_on
        anchors.fill: parent
        anchors.leftMargin: root.radius * 0.6
        anchors.rightMargin: root.radius * 0.6

        Rectangle {
            y: parent.height - 5
            width: parent.width * peak_line.now_level
            height: 2
            radius: 1
            color: Qt.alpha(Theme.fg_strong, 0.3)
        }

        // Darker where it runs over the fill, so it reads on both.
        Item {
            width: Math.max(0, fill.width - peak_line.x)
            height: parent.height
            clip: true

            Rectangle {
                y: peak_line.height - 5
                width: peak_line.width * peak_line.now_level
                height: 2
                radius: 1
                color: Qt.alpha(Style.selection_fg, 0.45)
            }
        }

        Rectangle {
            visible: peak_line.hold > 0.02
            x: Math.max(0, parent.width * peak_line.hold - 2)
            y: parent.height - 7
            width: 2
            height: 6
            radius: 1
            color: peak_line.x + x < fill.width ? Qt.alpha(Style.selection_fg, 0.6) : Qt.alpha(Theme.fg_strong, 0.5)
        }

        // Holds the peak briefly, then lets it fall; stops once it reaches the floor.
        Timer {
            interval: 50
            repeat: true
            running: root.peaks_on && peak_line.hold > 0
            onTriggered: if (Date.now() - peak_line.held_at > 700) peak_line.hold = Math.max(0, peak_line.hold - 0.03)
        }
    }

    Component {
        id: content_row

        Item {
            property color ink: Style.text_fg
            property color ink_dim: Style.text_dim

            Text {
                id: icon_text
                x: root.pad
                anchors.verticalCenter: parent.verticalCenter
                text: root.glyph
                color: parent.ink
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
                color: parent.ink
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
                color: parent.ink_dim
                font.family: Style.number_font
                font.pixelSize: Style.font_size - 2
                font.features: { "tnum": 1 }
            }
        }
    }

    Loader {
        active: root.glyph !== "" || root.label !== "" || root.show_readout
        anchors.fill: parent
        sourceComponent: content_row
    }

    // The same content in the fill's ink, clipped to the fill so it changes colour where the fill passes.
    Item {
        visible: fill.visible && !root.muted
        width: Math.min(root.width, fill.width)
        height: root.height
        clip: true

        Loader {
            active: root.glyph !== "" || root.label !== "" || root.show_readout
            width: root.width
            height: root.height
            sourceComponent: content_row
            onLoaded: {
                item.ink = Style.selection_fg;
                item.ink_dim = Qt.alpha(Style.selection_fg, 0.75);
            }
        }
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
