// home/quickshell/.config/quickshell/components/oasis/StarRule.qml
pragma ComponentBehavior: Bound
import QtQuick
import "../../theme"

// A footer rule as a thin row of stars: fixed pseudo-random dots, a few brighter in sand, fading at both ends.
Item {
    id: root

    readonly property color sand: Theme.theme_secondary
    readonly property int step: 7

    height: 5

    Repeater {
        model: Math.max(0, Math.floor(root.width / root.step))

        Rectangle {
            id: star
            required property int index
            readonly property real hash: Math.abs(Math.sin(star.index * 12.9898 + 4.1414) * 43758.5453) % 1
            readonly property bool bright: star.hash > 0.88
            readonly property real edge: Math.min(1, Math.min(star.x, root.width - star.x) / (root.width * 0.18))
            x: star.index * root.step + star.hash * (root.step - 2)
            y: Math.round(star.hash * 7919 % 1 * (root.height - height))
            width: star.bright ? 2 : 1
            height: width
            radius: star.bright ? 1 : 0
            color: star.bright ? root.sand : Theme.theme_primary_light
            opacity: star.edge * (star.bright ? 0.9 : 0.25 + star.hash * 0.5)
        }
    }
}
