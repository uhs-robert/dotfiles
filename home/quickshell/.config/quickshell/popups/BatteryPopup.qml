// home/quickshell/.config/quickshell/popups/BatteryPopup.qml
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.UPower
import "../components"
import "../theme"
import "../services"

Popup {
    id: root

    popup_name: "battery"
    implicitWidth: 260
    implicitHeight: 20 + 20 + (root.time_label !== "" ? 18 : 0) + (root.rate > 0 ? 18 : 0) + 10 + (root.ppd_available ? root.profiles.length * 26 : 22) + 24

    readonly property var device: UPower.displayDevice
    readonly property bool has_battery: !!device && device.ready
    readonly property real percent: has_battery ? device.percentage * 100 : 0
    readonly property int state: has_battery ? device.state : UPowerDeviceState.Unknown
    readonly property real rate: has_battery ? device.changeRate : 0

    readonly property string state_label: {
        if (state === UPowerDeviceState.Charging || state === UPowerDeviceState.PendingCharge) return "Charging";
        if (state === UPowerDeviceState.FullyCharged) return "Full";
        return "Discharging";
    }

    function format_time(seconds) {
        if (seconds <= 0) return "";
        const h = Math.floor(seconds / 3600);
        const m = Math.round((seconds % 3600) / 60);
        return h > 0 ? (h + "h " + m + "m") : (m + "m");
    }

    readonly property string time_label: {
        if (has_battery && device.timeToEmpty > 0) return format_time(device.timeToEmpty) + " remaining";
        if (has_battery && device.timeToFull > 0) return format_time(device.timeToFull) + " until full";
        return "";
    }

    property bool ppd_available: false
    property int selected: 0

    readonly property var profiles: {
        const list = [
            { label: "Power Saver", value: PowerProfile.PowerSaver },
            { label: "Balanced", value: PowerProfile.Balanced },
        ];
        if (PowerProfiles.hasPerformanceProfile) list.push({ label: "Performance", value: PowerProfile.Performance });
        return list;
    }

    readonly property bool is_open: Popups.open_name === "battery"
    onIs_openChanged: if (is_open) {
        root.selected = 0;
        ppd_check_proc.running = true;
    }

    // busctl exits non-zero when the daemon is not D-Bus activatable.
    Process {
        id: ppd_check_proc
        command: ["busctl", "--system", "introspect", "org.freedesktop.UPower.PowerProfiles", "/org/freedesktop/UPower/PowerProfiles"]
        onExited: code => root.ppd_available = code === 0
    }

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        focus: true

        Keys.onPressed: event => {
            if (!root.ppd_available) return;
            if (event.key === Qt.Key_J) {
                root.selected = Math.min(root.profiles.length - 1, root.selected + 1);
                event.accepted = true;
            } else if (event.key === Qt.Key_K) {
                root.selected = Math.max(0, root.selected - 1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                PowerProfiles.profile = root.profiles[root.selected].value;
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 4

            Text {
                text: Math.round(root.percent) + "%"
                color: Theme.fg_strong
                font.family: Theme.font_family
                font.pixelSize: Theme.font_size + 4
            }

            Text {
                text: root.state_label
                color: Theme.fg_muted
                font.family: Theme.font_family
                font.pixelSize: Theme.font_size - 2
            }

            Text {
                visible: root.time_label !== ""
                text: root.time_label
                color: Theme.fg_muted
                font.family: Theme.font_family
                font.pixelSize: Theme.font_size - 2
            }

            Text {
                visible: root.rate > 0
                text: root.rate.toFixed(1) + " W"
                color: Theme.fg_muted
                font.family: Theme.font_family
                font.pixelSize: Theme.font_size - 2
            }

            Text {
                visible: !root.ppd_available
                Layout.topMargin: 6
                text: "power-profiles-daemon not running"
                color: Theme.fg_dim
                font.family: Theme.font_family
                font.pixelSize: Theme.font_size - 3
            }

            Repeater {
                model: root.ppd_available ? root.profiles : []

                Rectangle {
                    id: profile_row
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.topMargin: profile_row.index === 0 ? 6 : 0
                    height: 22
                    radius: 4
                    color: profile_row.index === root.selected ? Theme.bg_surface : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: profile_row.modelData.label
                            color: PowerProfiles.profile === profile_row.modelData.value ? Theme.theme_secondary : Theme.fg_core
                            font.family: Theme.font_family
                            font.pixelSize: Theme.font_size - 1
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.selected = profile_row.index;
                            PowerProfiles.profile = profile_row.modelData.value;
                        }
                    }
                }
            }
        }
    }
}
