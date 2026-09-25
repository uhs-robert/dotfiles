// home/quickshell/.config/quickshell/components/nes/BlockMeter.qml
import QtQuick
import "../../theme"

// A signal meter of Mario ? blocks: one lit block per quarter of the value.
Row {
    id: root

    property real value: 0
    property int count: 4
    property int size: 12
    readonly property int lit: Math.ceil(Math.max(0, Math.min(1, root.value)) * root.count - 0.001)

    spacing: 2

    Repeater {
        model: root.count

        QBlock {
            required property int index
            width: root.size
            height: root.size
            kind: index < root.lit ? "q" : "empty"
            mark: root.size >= 12
        }
    }
}
