// home/quickshell/.config/quickshell/components/neovim/LualineSection.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../../theme"

// One lualine section of bar modules: a fill, an arrow in from the previous section, thin separators between components.
Item {
    id: root

    property var entries: []
    // Called with (item, entry) once a module loads.
    property var wire: null
    property color fill: Style.bar_side_bg
    // The previous section's fill behind the lead arrow; transparent draws none.
    property color lead_bg: "transparent"
    property bool separators: true
    property int first_shown: -1
    readonly property bool shown: root.first_shown >= 0
    readonly property real arrow: root.lead_bg.a > 0 ? Math.round(root.height * 0.4) : 0

    function recount() {
        let first = -1;
        for (let i = 0; i < cells.count; i++) {
            const cell = cells.itemAt(i);
            if (cell && cell.wanted) {
                first = i;
                break;
            }
        }
        root.first_shown = first;
    }

    visible: root.shown
    implicitWidth: root.arrow + Math.ceil(row.implicitWidth) + 20

    Shape {
        visible: root.arrow > 0
        width: root.arrow + 1
        height: root.height
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: root.lead_bg
            PathRectangle { width: root.arrow; height: root.height }
        }

        ShapePath {
            strokeWidth: -1
            fillColor: root.fill
            PathPolyline {
                path: [Qt.point(root.arrow, 0), Qt.point(root.arrow + 1, 0), Qt.point(root.arrow + 1, root.height), Qt.point(root.arrow, root.height), Qt.point(0, root.height / 2), Qt.point(root.arrow, 0)]
            }
        }
    }

    Rectangle {
        x: root.arrow
        width: root.width - root.arrow
        height: root.height
        color: root.fill
    }

    RowLayout {
        id: row
        x: root.arrow + 10
        height: root.height
        spacing: root.separators ? 9 : 11

        Repeater {
            id: cells
            model: root.entries
            onItemAdded: Qt.callLater(root.recount)
            onItemRemoved: Qt.callLater(root.recount)

            RowLayout {
                id: cell
                required property var modelData
                required property int index
                // A module's own `shown`, not `visible`: a hidden section would report every child hidden.
                readonly property bool wanted: !loader.item || loader.item.shown === undefined || loader.item.shown

                visible: cell.wanted
                spacing: 9
                onWantedChanged: Qt.callLater(root.recount)

                Shape {
                    visible: root.separators && cell.index > root.first_shown
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 6
                    implicitHeight: 16
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: 1.2
                        strokeColor: Style.text_muted
                        fillColor: "transparent"
                        startX: 5
                        startY: 1
                        PathLine { x: 1; y: 8 }
                        PathLine { x: 5; y: 15 }
                    }
                }

                Loader {
                    id: loader
                    Layout.alignment: Qt.AlignVCenter
                    sourceComponent: cell.modelData.component
                    onLoaded: if (root.wire) root.wire(item, cell.modelData)
                }
            }
        }
    }
}
