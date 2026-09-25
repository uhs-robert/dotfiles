// home/quickshell/.config/quickshell/services/LualineState.qml
pragma Singleton
import QtQuick
import Quickshell

// Per-screen fills of the first and last buffers, so the chip's arrow and the island's end cap can join them.
Singleton {
    id: root

    property var first_fill: ({})
    property var last_fill: ({})

    function set_first_fill(screen_name, color) {
        const next = Object.assign({}, root.first_fill);
        next[screen_name] = color;
        root.first_fill = next;
    }

    function set_last_fill(screen_name, color) {
        const next = Object.assign({}, root.last_fill);
        next[screen_name] = color;
        root.last_fill = next;
    }
}
