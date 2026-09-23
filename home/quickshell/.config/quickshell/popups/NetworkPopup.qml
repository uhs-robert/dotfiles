// home/quickshell/.config/quickshell/popups/NetworkPopup.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "../components"
import "../theme"
import "../services"

Popup {
    id: root

    popup_name: "network"
    fallback_width: 300
    implicitHeight: 300

    readonly property var wifi_device: {
        for (const d of Networking.devices.values) if (d.type === DeviceType.Wifi) return d;
        return null;
    }

    readonly property var wired_device: {
        for (const d of Networking.devices.values) if (d.type === DeviceType.Wired) return d;
        return null;
    }

    readonly property var active_wifi_network: {
        if (!root.wifi_device) return null;
        for (const n of root.wifi_device.networks.values) if (n.connected) return n;
        return null;
    }

    readonly property var wifi_glyphs: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

    function signal_glyph(strength) {
        if (strength <= 0.2) return root.wifi_glyphs[0];
        if (strength <= 0.4) return root.wifi_glyphs[1];
        if (strength <= 0.6) return root.wifi_glyphs[2];
        if (strength <= 0.8) return root.wifi_glyphs[3];
        return root.wifi_glyphs[4];
    }

    // Dedupe scan results by SSID, keeping the strongest signal, sorted best-first.
    function build_network_list() {
        if (!root.wifi_device) return [];
        const by_name = {};
        for (const n of root.wifi_device.networks.values) {
            if (!by_name[n.name] || n.signalStrength > by_name[n.name].signalStrength) by_name[n.name] = n;
        }
        return Object.values(by_name).sort((a, b) => b.signalStrength - a.signalStrength);
    }

    readonly property var wifi_networks: root.build_network_list()
    readonly property var nav_rows: root.wifi_networks.concat([{ advanced: true }])

    property int selected: 0
    property bool forget_confirm: false
    property bool password_mode: false
    property var password_target: null
    property string password_text: ""
    property bool password_visible: false
    property string status_text: ""

    readonly property bool is_open: Popups.open_name === "network"
    onIs_openChanged: if (is_open) {
        root.selected = 0;
        root.forget_confirm = false;
        root.password_mode = false;
        root.status_text = "";
        root.start_scan();
    }
    onNav_rowsChanged: if (root.selected >= root.nav_rows.length) root.selected = Math.max(0, root.nav_rows.length - 1);

    function start_scan() {
        if (root.wifi_device) root.wifi_device.scannerEnabled = true;
        scan_timer.restart();
    }

    // Scanning burns radio power; only run it briefly around an explicit open/rescan.
    Timer {
        id: scan_timer
        interval: 8000
        onTriggered: if (root.wifi_device) root.wifi_device.scannerEnabled = false
    }

    Connections {
        target: root.password_target
        function onConnectionFailed(reason) {
            root.status_text = ConnectionFailReason.toString(reason);
        }
        function onConnectedChanged() {
            if (root.password_target && root.password_target.connected) {
                root.status_text = "Connected";
                root.password_mode = false;
            }
        }
    }

    function connect_to(network) {
        if (!network) return;
        if (network.connected) {
            network.disconnect();
            return;
        }
        if (network.known || network.security === WifiSecurityType.Open) {
            root.status_text = "Connecting…";
            network.connect();
        } else {
            root.password_target = network;
            root.password_mode = true;
            root.password_text = "";
            root.password_visible = false;
            root.status_text = "";
        }
    }

    function submit_password() {
        if (!root.password_target) return;
        root.status_text = "Connecting…";
        root.password_target.connectWithPsk(root.password_text);
        root.password_text = "";
    }

    function cancel_password() {
        root.password_mode = false;
        root.password_text = "";
        root.password_target = null;
        root.status_text = "";
    }

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        focus: true

        Keys.onPressed: event => {
            if (root.password_mode) return;

            if (root.forget_confirm) {
                if (event.key === Qt.Key_Y) {
                    const row = root.nav_rows[root.selected];
                    if (row && !row.advanced) row.forget();
                    root.forget_confirm = false;
                } else if (event.key === Qt.Key_N || event.key === Qt.Key_Escape) {
                    root.forget_confirm = false;
                }
                event.accepted = true;
                return;
            }

            const row = root.nav_rows[root.selected];
            if (event.key === Qt.Key_J) {
                root.selected = Math.min(root.nav_rows.length - 1, root.selected + 1);
                event.accepted = true;
            } else if (event.key === Qt.Key_K) {
                root.selected = Math.max(0, root.selected - 1);
                event.accepted = true;
            } else if (event.key === Qt.Key_W) {
                Networking.wifiEnabled = !Networking.wifiEnabled;
                event.accepted = true;
            } else if (event.key === Qt.Key_R) {
                root.start_scan();
                event.accepted = true;
            } else if (event.key === Qt.Key_F && row && !row.advanced && row.known) {
                root.forget_confirm = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (row && row.advanced) Quickshell.execDetached(["nm-connection-editor"]);
                else root.connect_to(row);
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 6
            visible: !root.password_mode

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Wi-Fi"
                    color: Theme.fg_strong
                    font.family: Theme.font_family
                    font.pixelSize: Theme.popup_font_size - 1
                }

                Text {
                    text: Networking.wifiEnabled ? "On" : "Off"
                    color: Networking.wifiEnabled ? Theme.theme_primary : Theme.fg_dim
                    font.family: Theme.font_family
                    font.pixelSize: Theme.popup_font_size - 2
                }
            }

            Text {
                visible: !!root.active_wifi_network
                text: root.active_wifi_network
                    ? root.active_wifi_network.name + "  " + Math.round(root.active_wifi_network.signalStrength * 100) + "%"
                        + (root.wifi_device && root.wifi_device.address ? "  " + root.wifi_device.address : "")
                    : ""
                color: Theme.theme_secondary
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size - 2
            }

            Text {
                visible: !!root.wired_device && root.wired_device.connected
                text: root.wired_device ? "Wired: " + root.wired_device.name + (root.wired_device.address ? "  " + root.wired_device.address : "") : ""
                color: Theme.theme_secondary
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size - 2
            }

            Text {
                visible: root.status_text !== ""
                text: root.status_text
                color: Theme.fg_muted
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size - 3
            }

            Text {
                visible: root.forget_confirm
                text: "Forget this network? y/n"
                color: Theme.error
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size - 2
            }

            Repeater {
                model: root.nav_rows

                Rectangle {
                    id: net_row
                    required property var modelData
                    required property int index

                    readonly property bool is_advanced: !!net_row.modelData.advanced

                    Layout.fillWidth: true
                    height: 24
                    radius: 4
                    color: net_row.index === root.selected ? Theme.bg_surface : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 6

                        Text {
                            visible: !net_row.is_advanced
                            text: root.signal_glyph(net_row.modelData.signalStrength || 0)
                            color: net_row.modelData.connected ? Theme.theme_primary : Theme.fg_core
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 1
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: net_row.is_advanced ? "Advanced…" : net_row.modelData.name
                            color: net_row.modelData.connected ? Theme.theme_secondary : Theme.fg_core
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 1
                        }

                        Text {
                            visible: !net_row.is_advanced && net_row.modelData.security !== WifiSecurityType.Open
                            text: ""
                            color: Theme.fg_muted
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 2
                        }

                        Text {
                            visible: !net_row.is_advanced && net_row.modelData.known
                            text: ""
                            color: Theme.fg_muted
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 2
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.selected = net_row.index;
                            root.forget_confirm = false;
                            if (net_row.is_advanced) Quickshell.execDetached(["nm-connection-editor"]);
                            else root.connect_to(net_row.modelData);
                        }
                    }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 8
            visible: root.password_mode

            Text {
                text: root.password_target ? "Password for " + root.password_target.name : ""
                color: Theme.fg_strong
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size - 1
            }

            Rectangle {
                Layout.fillWidth: true
                height: 26
                radius: 4
                color: Theme.bg_surface

                TextInput {
                    id: password_input
                    anchors.fill: parent
                    anchors.margins: 6
                    focus: root.password_mode
                    echoMode: root.password_visible ? TextInput.Normal : TextInput.Password
                    color: Theme.fg_core
                    font.family: Theme.font_family
                    font.pixelSize: Theme.popup_font_size - 1
                    text: root.password_text
                    onTextChanged: root.password_text = text

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Tab) {
                            root.password_visible = !root.password_visible;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.submit_password();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            root.cancel_password();
                            event.accepted = true;
                        }
                    }
                }
            }

            Text {
                text: "Tab: show/hide  Enter: connect  Esc: cancel"
                color: Theme.fg_dim
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size - 3
            }

            Text {
                visible: root.status_text !== ""
                text: root.status_text
                color: Theme.fg_muted
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size - 3
            }
        }
    }
}
