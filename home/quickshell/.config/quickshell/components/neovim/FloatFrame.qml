// home/quickshell/.config/quickshell/components/neovim/FloatFrame.qml
import QtQuick
import "../../theme"

// A Neovim floating window: FloatBorder round the frame, the title as a chip set into the top border, a status in the border at the right.
Item {
    id: root

    property var st: Style
    property string title: ""
    property string status: ""
    property real chip_height: 20
    property real radius: root.st.frame_radius
    readonly property real border_y: Math.round(root.chip_height / 2)

    function title_case(t) {
        return t === "" ? "" : t.charAt(0).toUpperCase() + t.slice(1).toLowerCase();
    }

    Rectangle {
        y: root.border_y
        width: root.width
        height: Math.max(0, root.height - root.border_y)
        radius: root.radius
        color: root.st.frame_color
        border.width: root.st.frame_border_width
        border.color: root.st.frame_border_color
    }

    // Breaks the border line around the chip.
    Rectangle {
        visible: chip.visible
        x: chip.x - 4
        y: root.border_y - 1
        width: chip.width + 8
        height: root.st.frame_border_width + 2
        color: root.st.frame_color
    }

    Rectangle {
        id: chip
        visible: root.title !== ""
        x: 12
        width: chip_text.implicitWidth + 14
        height: root.chip_height
        radius: 3
        color: root.st.title_bg

        Text {
            id: chip_text
            anchors.centerIn: parent
            text: root.title_case(root.title)
            color: root.st.title_fg
            font.family: root.st.title_font_family
            font.pixelSize: root.st.font_size - 2
            font.bold: true
        }
    }

    Rectangle {
        visible: root.status !== "" && x > chip.x + chip.width + 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        y: root.border_y - height / 2
        width: status_text.implicitWidth + 10
        height: status_text.implicitHeight
        color: root.st.frame_color

        Text {
            id: status_text
            anchors.centerIn: parent
            text: root.status
            color: root.st.text_dim
            font.family: root.st.font_family
            font.pixelSize: root.st.font_size - 3
        }
    }
}
