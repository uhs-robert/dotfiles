// home/quickshell/.config/quickshell/popups/MediaPopup.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import "../components"
import "../theme"
import "../services"
import "notifications" as Notifications

Popup {
    id: root

    popup_name: "media"
    preferred_width: 520
    implicitHeight: content.implicitHeight + 24

    readonly property var player: MediaState.active
    readonly property var players: MediaState.players

    readonly property bool is_open: Popups.open_name === "media"
    onIs_openChanged: MediaState.tracking = root.is_open

    function fmt_time(seconds) {
        const s = Math.max(0, Math.floor(seconds || 0));
        const m = Math.floor(s / 60);
        const r = s % 60;
        return m + ":" + (r < 10 ? "0" + r : "" + r);
    }

    function player_index(p) {
        return root.players.indexOf(p);
    }

    function step_player(delta) {
        if (root.players.length === 0) return;
        const idx = root.player_index(root.player);
        const next_idx = (idx + delta + root.players.length) % root.players.length;
        MediaState.select(root.players[next_idx]);
    }

    function seek_ratio(ratio) {
        if (!root.player || !root.player.canSeek || !root.player.positionSupported) return;
        const length = root.player.length || 0;
        root.player.position = Math.max(0, Math.min(length, ratio * length));
    }

    function handle_key(event) {
        if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
            root.step_player(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab) {
            root.step_player(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            MediaState.toggle();
            event.accepted = true;
        } else if (event.key === Qt.Key_H) {
            if (event.modifiers & Qt.ShiftModifier) MediaState.previous();
            else MediaState.seek_by(-5);
            event.accepted = true;
        } else if (event.key === Qt.Key_L) {
            if (event.modifiers & Qt.ShiftModifier) MediaState.next();
            else MediaState.seek_by(5);
            event.accepted = true;
        }
    }

    Item {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        implicitHeight: main_column.implicitHeight
        focus: true

        Keys.onPressed: event => root.handle_key(event)
        Keys.onTabPressed: event => root.handle_key(event)
        Keys.onBacktabPressed: event => root.handle_key(event)

        ColumnLayout {
            id: main_column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 10

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 178

                RowLayout {
                    anchors.fill: parent
                    spacing: 14

                    Item {
                        id: art_container
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 160
                        Layout.alignment: Qt.AlignTop

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: Theme.bg_surface
                            visible: !art_image.has_art || art_image.status !== Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !art_image.has_art || art_image.status !== Image.Ready
                            text: "\u{f001}"
                            color: Theme.fg_dim
                            font.family: Theme.font_family
                            font.pixelSize: 48
                        }

                        Rectangle {
                            id: art_mask
                            anchors.fill: parent
                            radius: 12
                            visible: false
                        }

                        Image {
                            id: art_image
                            readonly property bool has_art: !!root.player && root.player.trackArtUrl !== ""
                            anchors.fill: parent
                            visible: false
                            source: root.player ? root.player.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            layer.enabled: false
                        }

                        MultiEffect {
                            anchors.fill: parent
                            visible: art_image.has_art && art_image.status === Image.Ready
                            source: art_image
                            maskEnabled: true
                            maskSource: art_mask
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            elide: Text.ElideRight
                            text: root.player ? (root.player.trackTitle || "Unknown title") : "Nothing playing"
                            color: Theme.fg_core
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size + 4
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            elide: Text.ElideRight
                            visible: root.player && root.player.trackArtist !== ""
                            text: root.player ? root.player.trackArtist : ""
                            color: Theme.fg_muted
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            elide: Text.ElideRight
                            visible: root.player && root.player.trackAlbum !== ""
                            text: root.player ? root.player.trackAlbum : ""
                            color: Theme.fg_dim
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 2
                        }

                        Item { Layout.fillHeight: true }

                        // --- Progress bar: click or drag to seek ---
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 4
                                radius: 2
                                color: Theme.bg_surface
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: {
                                    if (!root.player || !root.player.length) return 0;
                                    return parent.width * Math.max(0, Math.min(1, root.player.position / root.player.length));
                                }
                                height: 4
                                radius: 2
                                color: Theme.theme_primary
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: !!root.player && root.player.canSeek && root.player.positionSupported
                                onPressed: mouse => root.seek_ratio(mouse.x / width)
                                onPositionChanged: mouse => { if (pressed) root.seek_ratio(Math.max(0, Math.min(1, mouse.x / width))); }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: root.player ? root.fmt_time(root.player.position) : "0:00"
                                color: Theme.fg_dim
                                font.family: Theme.font_family
                                font.pixelSize: Theme.popup_font_size - 4
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: root.player ? root.fmt_time(root.player.length) : "0:00"
                                color: Theme.fg_dim
                                font.family: Theme.font_family
                                font.pixelSize: Theme.popup_font_size - 4
                            }
                        }
                    }
                }
            }

            // --- Transport controls ---
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                Notifications.HeaderButton {
                    icon: "\u{f048}"
                    enabled: !!root.player && root.player.canGoPrevious
                    opacity: enabled ? 1 : 0.4
                    onActivated: MediaState.previous()
                }

                Notifications.HeaderButton {
                    icon: root.player && root.player.isPlaying ? "\u{f04c}" : "\u{f04b}"
                    enabled: !!root.player && root.player.canTogglePlaying
                    opacity: enabled ? 1 : 0.4
                    onActivated: MediaState.toggle()
                }

                Notifications.HeaderButton {
                    icon: "\u{f051}"
                    enabled: !!root.player && root.player.canGoNext
                    opacity: enabled ? 1 : 0.4
                    onActivated: MediaState.next()
                }
            }

            // --- Player picker pills, one per player ---
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.players.length > 1 ? 28 : 0
                visible: root.players.length > 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: root.players

                        Rectangle {
                            id: player_chip
                            required property var modelData
                            readonly property bool active: modelData === root.player

                            implicitWidth: chip_label.implicitWidth + 20
                            implicitHeight: 24
                            radius: 12
                            color: player_chip.active ? Theme.bg_surface : "transparent"

                            Text {
                                id: chip_label
                                anchors.centerIn: parent
                                text: player_chip.modelData.identity || "Player"
                                color: player_chip.active ? Theme.theme_secondary : Theme.fg_muted
                                font.bold: player_chip.active
                                font.family: Theme.font_family
                                font.pixelSize: Theme.popup_font_size - 3
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: MediaState.select(player_chip.modelData)
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                elide: Text.ElideRight
                text: "Tab switches player · space play/pause · h/l seek -5/+5s · H/L prev/next track · q close"
                color: Theme.fg_dim
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size - 4
            }
        }
    }
}
