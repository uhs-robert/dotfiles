// home/quickshell/.config/quickshell/services/LualineState.qml
pragma Singleton
import QtQuick
import Quickshell

// Per-screen fill of the first buffer, so the mode chip's arrow can run into it.
Singleton {
    id: root

    property var first_fill: ({})

    function set_first_fill(screen_name, color) {
        const next = Object.assign({}, root.first_fill);
        next[screen_name] = color;
        root.first_fill = next;
    }
}
