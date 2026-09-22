// home/quickshell/.config/quickshell/bar/modules/Workspaces.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../theme"

Item {
    id: root

    property string screen_name: ""
    property bool compact: false

    readonly property int icon_size: compact ? 16 : 19

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    readonly property var workspace_list: {
        const list = Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor && w.monitor.name === root.screen_name);
        list.sort((a, b) => a.id - b.id);
        return list;
    }

    function icon_for(cls) {
        const entry = DesktopEntries.heuristicLookup(cls);
        return Quickshell.iconPath(entry ? entry.icon : cls, "application-x-executable");
    }

    function class_of(toplevel) {
        if (toplevel.wayland && toplevel.wayland.appId) return toplevel.wayland.appId;
        return (toplevel.lastIpcObject && toplevel.lastIpcObject.class) || "";
    }

    // Mirrors hypr-focus-workspaces.lua: focus the workspace then the window, holding cursor:no_warps.
    function focus_toplevel(ws_id, address) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = '" + ws_id + "' })");
        const cmd = "already=$(hyprctl getoption cursor:no_warps -j | grep -o '\"bool\": *true'); " +
            "if [ -z \"$already\" ]; then hyprctl eval \"hl.config({ cursor = { no_warps = true } })\" >/dev/null 2>&1; fi; " +
            "hyprctl dispatch \"hl.dsp.focus({ window = 'address:0x" + address + "' })\"; " +
            "if [ -z \"$already\" ]; then hyprctl eval \"hl.config({ cursor = { no_warps = false } })\" >/dev/null 2>&1; fi";
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    function close_toplevel(address) {
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.close({ address = '0x" + address + "' })"]);
    }

    // The workspace/toplevel models can lag behind these events; nudge a resync.
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (["openwindow", "closewindow", "movewindow", "workspace", "focusedmon"].includes(event.name)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            Hyprland.dispatch("hl.dsp.focus({ workspace = '" + (wheel.angleDelta.y > 0 ? "e-1" : "e+1") + "' })");
        }
    }

    Row {
        id: row
        spacing: root.compact ? 4 : 8

        Repeater {
            model: root.workspace_list

            RowLayout {
                id: ws_row
                required property var modelData

                spacing: root.compact ? 2 : 4

                Text {
                    text: ws_row.modelData.id
                    color: ws_row.modelData.active ? Theme.theme_secondary : Theme.theme_primary
                    font.family: Theme.font_family
                    font.pixelSize: Theme.font_size

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = '" + ws_row.modelData.id + "' })")
                    }
                }

                Repeater {
                    model: ws_row.modelData.toplevels.values

                    Rectangle {
                        id: icon_bg
                        required property var modelData

                        width: root.icon_size + 4
                        height: root.icon_size + 4
                        radius: 4
                        color: modelData.activated ? Theme.bg_surface : "transparent"

                        Image {
                            anchors.centerIn: parent
                            width: root.icon_size
                            height: root.icon_size
                            source: root.icon_for(root.class_of(icon_bg.modelData))
                            smooth: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.LeftButton) {
                                    root.focus_toplevel(ws_row.modelData.id, icon_bg.modelData.address);
                                } else if (mouse.button === Qt.MiddleButton) {
                                    root.close_toplevel(icon_bg.modelData.address);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
