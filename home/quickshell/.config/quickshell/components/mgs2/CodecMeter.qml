// home/quickshell/.config/quickshell/components/mgs2/CodecMeter.qml
import QtQuick
import "../../theme"
import "../../services"

// Stacked signal bars, wide at the top stepping down to a narrow column; cue steps them in once.
Item {
    id: root

    property int bar_count: 6
    property int strength: 5
    property real bar_height: 3
    property real bar_gap: 1
    property color on_color: Theme.theme_primary
    property bool cue: false
    property int lit: root.strength

    readonly property var steps: [1, 1, 0.78, 0.56, 0.34, 0.34]

    implicitWidth: 26
    implicitHeight: root.bar_count * root.bar_height + (root.bar_count - 1) * root.bar_gap

    Component.onCompleted: {
        if (root.cue && Power.on_ac && root.visible) step_in.start();
    }

    NumberAnimation {
        id: step_in
        target: root
        property: "lit"
        from: 0
        to: root.strength
        duration: 90 * root.strength
        paused: !root.visible
    }

    Repeater {
        model: root.bar_count

        Rectangle {
            required property int index
            y: index * (root.bar_height + root.bar_gap)
            width: Math.max(2, Math.round(root.width * root.steps[Math.min(index, root.steps.length - 1)]))
            height: root.bar_height
            color: root.index_lit(index) ? root.on_color : Qt.alpha(Theme.fg_core, 0.14)
        }
    }

    function index_lit(i) {
        return i >= root.bar_count - root.lit;
    }
}
