// home/quickshell/.config/quickshell/components/neovim/BufferLine.qml
import QtQuick
import QtQuick.Shapes
import Quickshell.Hyprland
import "../../theme"
import "../../services"
import ".."
import "Modes.js" as Modes

// Workspaces as lualine buffers: number and app icons, the focused one a full-height visual-bg segment with arrow edges.
Item {
    id: root

    // The Workspaces module, for its icon, name and window helpers.
    required property Item host
    property var workspaces: []
    property bool compact: false
    property int bar_height: 30

    readonly property int glyph: root.compact ? 14 : 16
    readonly property int arrow: Math.round(root.bar_height * 0.4)
    readonly property color accent: Modes.color(SubmapState.submap_name, Theme, SubmapState.submap_color)

    implicitWidth: row.implicitWidth + 4
    implicitHeight: root.bar_height

    Row {
        id: row
        height: root.height

        Repeater {
            model: root.workspaces

            Row {
                id: slot
                required property var modelData
                required property int index
                readonly property var toplevels: slot.modelData.toplevels.values
                readonly property bool empty: slot.toplevels.length === 0
                readonly property bool focused: slot.modelData.focused
                readonly property bool after_focused: slot.index > 0 && !!root.workspaces[slot.index - 1] && root.workspaces[slot.index - 1].focused

                height: row.height

                // The focused buffer's arrows stand in for the separators on both sides of it.
                Item {
                    visible: slot.index > 0 && !slot.focused && !slot.after_focused
                    width: 10
                    height: slot.height

                    Shape {
                        anchors.centerIn: parent
                        width: 6
                        height: 16
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            strokeWidth: 1.2
                            strokeColor: Style.text_muted
                            fillColor: "transparent"
                            startX: 1
                            startY: 1
                            PathLine { x: 5; y: 8 }
                            PathLine { x: 1; y: 15 }
                        }
                    }
                }

                Shape {
                    visible: slot.focused && slot.index > 0
                    width: root.arrow + 1
                    height: slot.height
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: -1
                        fillColor: Theme.ui_visual_bg
                        PathPolyline {
                            path: [Qt.point(0, 0), Qt.point(root.arrow + 1, 0), Qt.point(root.arrow + 1, slot.height), Qt.point(0, slot.height), Qt.point(root.arrow, slot.height / 2), Qt.point(0, 0)]
                        }
                    }
                }

                Rectangle {
                    id: buffer
                    width: content.implicitWidth + 16
                    height: slot.height
                    color: slot.focused ? Theme.ui_visual_bg : buffer_hover.hovered ? Qt.alpha(Theme.ui_visual_bg, 0.5) : "transparent"

                    HoverHandler {
                        id: buffer_hover
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = '" + slot.modelData.id + "' })")
                    }

                    Row {
                        id: content
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            rightPadding: slot.empty ? 0 : 2
                            text: String(slot.modelData.id)
                            color: slot.focused ? root.accent : slot.modelData.active ? Theme.theme_primary : slot.empty ? Style.text_muted : Style.text_dim
                            font.family: Style.bar_font_family
                            font.pixelSize: Style.bar_font_size
                            font.bold: true
                        }

                        Repeater {
                            model: slot.toplevels

                            WorkspaceIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                host: root.host
                                workspace_id: slot.modelData.id
                                glyph: root.glyph
                                icon_opacity: slot.focused || slot.modelData.active ? 1 : 0.7
                                width: root.glyph + 2
                                height: root.glyph + 2
                            }
                        }
                    }
                }

                Shape {
                    visible: slot.focused
                    width: root.arrow
                    height: slot.height
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: -1
                        fillColor: Theme.ui_visual_bg
                        PathPolyline {
                            path: [Qt.point(-1, 0), Qt.point(0, 0), Qt.point(root.arrow, slot.height / 2), Qt.point(0, slot.height), Qt.point(-1, slot.height), Qt.point(-1, 0)]
                        }
                    }
                }
            }
        }
    }
}
