// home/quickshell/.config/quickshell/services/Timezones.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Clock zones cycled with [ and ] in the calendar; "" is the system zone.
    property var zones: ["", "America/Los_Angeles", "America/Denver"]

    property int index: 0
    readonly property string zone: zones[index] || ""
    readonly property bool is_local: zone === ""
    property int offset_min: 0
    property string abbrev: ""

    function cycle(step) {
        index = (index + step + zones.length) % zones.length;
    }

    // Shifts a local Date so its local getters read as wall time in the selected zone.
    function shift(d) {
        if (is_local) return d;
        return new Date(d.getTime() + (offset_min + d.getTimezoneOffset()) * 60000);
    }

    function refresh() {
        if (is_local) return;
        offset_proc.command = ["sh", "-c", "TZ=\"$1\" date +'%z %Z'", "sh", zone];
        offset_proc.running = true;
    }

    onZoneChanged: refresh()

    Process {
        id: offset_proc
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ");
                if (parts.length < 2) return;
                const sign = parts[0][0] === "-" ? -1 : 1;
                root.offset_min = sign * (parseInt(parts[0].substr(1, 2)) * 60 + parseInt(parts[0].substr(3, 2)));
                root.abbrev = parts[1];
            }
        }
    }

    // DST can flip the offset on the hour.
    SystemClock {
        id: hour_clock
        precision: SystemClock.Hours
        enabled: !root.is_local
        onDateChanged: root.refresh()
    }
}
