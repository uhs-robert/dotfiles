pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../services"
import "Kinds.js" as Kinds

// Announces a one-shot transition when the saved style changes; previews never reach saved_name.
Singleton {
    id: root

    signal play(string kind)

    property bool armed: false
    property string last_style: ""

    function request(name, force) {
        if (!force && !Power.on_ac) return;
        root.play(Kinds.kind_for(name));
    }

    Connections {
        target: Style
        function onSaved_nameChanged() {
            const name = Style.saved_name;
            const changed = name !== root.last_style;
            root.last_style = name;
            if (root.armed && changed) root.request(name, false);
        }
    }

    // Skips the saved style loading at startup or on a config reload.
    Timer {
        running: true
        interval: 3000
        onTriggered: {
            root.last_style = Style.saved_name;
            root.armed = true;
        }
    }

    IpcHandler {
        target: "transition"

        // Plays a kind or a style's transition on every bar, on battery too.
        function play(name: string): void {
            root.request(name, true);
        }
    }
}
