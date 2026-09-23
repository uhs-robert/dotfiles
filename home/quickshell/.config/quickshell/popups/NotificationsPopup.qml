// home/quickshell/.config/quickshell/popups/NotificationsPopup.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../components"
import "../theme"
import "../services"

Popup {
    id: root

    popup_name: "notifications"
    preferred_width: 460
    implicitHeight: content.implicitHeight + 24

    readonly property int content_height: 420

    property int selected: 0
    property double last_g_ms: 0

    readonly property bool is_open: Popups.open_name === "notifications"
    onIs_openChanged: if (is_open) {
        root.selected = 0;
        NotificationState.mark_read();
    }

    readonly property int history_length: NotificationState.history.length
    onHistory_lengthChanged: root.selected = Math.max(0, Math.min(root.selected, NotificationState.history.length - 1))

    function move_selected(delta) {
        if (NotificationState.history.length === 0) return;
        root.selected = Math.max(0, Math.min(NotificationState.history.length - 1, root.selected + delta));
        entry_list.positionViewAtIndex(root.selected, ListView.Contain);
    }

    function go_first() {
        root.selected = 0;
        entry_list.positionViewAtIndex(root.selected, ListView.Contain);
    }

    function go_last() {
        root.selected = Math.max(0, NotificationState.history.length - 1);
        entry_list.positionViewAtIndex(root.selected, ListView.Contain);
    }

    function dismiss_selected() {
        const entry = NotificationState.history[root.selected];
        if (entry) NotificationState.dismiss(entry);
    }

    function invoke_selected() {
        const entry = NotificationState.history[root.selected];
        if (entry) NotificationState.invoke_default(entry);
    }

    function relative_time(ms) {
        const s = Math.max(0, Math.floor((Date.now() - ms) / 1000));
        if (s < 60) return "now";
        if (s < 3600) return Math.floor(s / 60) + "m";
        if (s < 86400) return Math.floor(s / 3600) + "h";
        return Math.floor(s / 86400) + "d";
    }

    function urgency_color(n) {
        if (!n) return Theme.fg_dim;
        if (n.urgency === NotificationUrgency.Critical) return Theme.error;
        if (n.urgency === NotificationUrgency.Low) return Theme.fg_dim;
        return Theme.theme_primary;
    }

    function handle_key(event) {
        if (event.key === Qt.Key_J) {
            root.move_selected(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_K) {
            root.move_selected(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_G) {
            if (event.modifiers & Qt.ShiftModifier) {
                root.go_last();
            } else {
                const now_ms = Date.now();
                if (now_ms - root.last_g_ms < 500) { root.go_first(); root.last_g_ms = 0; }
                else root.last_g_ms = now_ms;
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.invoke_selected();
            event.accepted = true;
        } else if ((event.key === Qt.Key_D && !(event.modifiers & Qt.ShiftModifier)) || event.key === Qt.Key_X) {
            root.dismiss_selected();
            event.accepted = true;
        } else if (event.key === Qt.Key_C && (event.modifiers & Qt.ShiftModifier)) {
            NotificationState.clear_all();
            event.accepted = true;
        } else if (event.key === Qt.Key_D && (event.modifiers & Qt.ShiftModifier)) {
            NotificationState.toggle_dnd();
            event.accepted = true;
        }
    }

    Item {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        implicitHeight: main_column.implicitHeight
        focus: true

        Keys.onPressed: event => root.handle_key(event)

        ColumnLayout {
            id: main_column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Notifications · " + NotificationState.history.length
                    color: Theme.fg_core
                    font.family: Theme.font_family
                    font.pixelSize: Theme.popup_font_size
                    font.bold: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    implicitWidth: dnd_label.implicitWidth + 20
                    implicitHeight: 22
                    radius: 11
                    color: NotificationState.dnd ? Theme.theme_primary : Theme.bg_surface

                    Text {
                        id: dnd_label
                        anchors.centerIn: parent
                        text: "Do not disturb"
                        color: NotificationState.dnd ? Theme.bg_core : Theme.fg_muted
                        font.family: Theme.font_family
                        font.pixelSize: Theme.popup_font_size - 4
                        font.bold: NotificationState.dnd
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: NotificationState.toggle_dnd()
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.content_height

                Text {
                    anchors.centerIn: parent
                    visible: NotificationState.history.length === 0
                    text: "No notifications"
                    color: Theme.fg_dim
                    font.family: Theme.font_family
                    font.pixelSize: Theme.popup_font_size - 1
                }

                ListView {
                    id: entry_list
                    anchors.fill: parent
                    visible: NotificationState.history.length > 0
                    clip: true
                    spacing: 4
                    model: NotificationState.history
                    currentIndex: root.selected

                    delegate: Rectangle {
                        id: entry_row
                        required property var modelData
                        required property int index

                        width: entry_list.width
                        height: 62
                        radius: 6
                        color: entry_row.index === root.selected ? Theme.bg_surface : "transparent"
                        border.width: 1
                        border.color: Theme.ui_border
                        opacity: entry_row.index === root.selected ? 1 : 0.85

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 3
                            radius: 1.5
                            color: root.urgency_color(entry_row.modelData.notification)
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 8
                            anchors.topMargin: 6
                            anchors.bottomMargin: 6
                            spacing: 8

                            Image {
                                Layout.alignment: Qt.AlignTop
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                visible: entry_row.modelData.notification && entry_row.modelData.notification.appIcon !== ""
                                source: entry_row.modelData.notification ? Quickshell.iconPath(entry_row.modelData.notification.appIcon, true) : ""
                                fillMode: Image.PreserveAspectFit
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        text: (entry_row.modelData.notification ? entry_row.modelData.notification.appName : "") + "  ·  " + root.relative_time(entry_row.modelData.time)
                                        color: Theme.fg_muted
                                        font.family: Theme.font_family
                                        font.pixelSize: Theme.popup_font_size - 4
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: entry_row.modelData.notification ? entry_row.modelData.notification.summary : ""
                                    color: Theme.fg_core
                                    font.bold: true
                                    font.family: Theme.font_family
                                    font.pixelSize: Theme.popup_font_size - 2
                                }

                                Text {
                                    Layout.fillWidth: true
                                    maximumLineCount: 2
                                    wrapMode: Text.Wrap
                                    elide: Text.ElideRight
                                    textFormat: entry_row.modelData.notification && entry_row.modelData.notification.body ? Text.RichText : Text.PlainText
                                    text: entry_row.modelData.notification ? entry_row.modelData.notification.body : ""
                                    color: Theme.fg_muted
                                    font.family: Theme.font_family
                                    font.pixelSize: Theme.popup_font_size - 4
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.selected = entry_row.index;
                                root.invoke_selected();
                            }
                        }
                    }
                }
            }

            Text {
                text: "j/k move · gg/G first/last · Enter open · d/x dismiss · C clear all · D dnd · q close"
                color: Theme.fg_dim
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size - 4
            }
        }
    }
}
