// home/quickshell/.config/quickshell/popups/weather/CameraPhoto.qml
import QtQuick
import "../../components"
import "../../theme"
import "PixelArt.js" as PixelArt

// One day as a framed Game Boy Camera photo with its hi/lo dot bar, temperatures and rain chance.
Item {
    id: root

    property var day: null
    property int day_index: 0
    property bool selected: false
    property real scale_min: 0
    property real scale_max: 1

    // Rough label/temp/pop row height, used only to budget the sprite scale; the real gap is filled below.
    readonly property real text_row_h: Style.font_size + 6
    readonly property int width_pixel: Math.max(1, Math.floor((root.width - 18) / 24))
    readonly property int height_pixel: Math.max(1, Math.floor((root.height - 3 * root.text_row_h - 38) / 20))
    // Largest integer scale of the 24x18 photo that fits both the column width and the available height.
    readonly property int pixel: Math.max(1, Math.min(6, Math.min(root.width_pixel, root.height_pixel)))

    // Space left over after the photo, dot bar and labels take their natural size, spread across the gaps between them.
    readonly property real content_h: label_row.height + photo_box.height + dot_bar.height + temp_row.height + pop_text.height
    readonly property real fill_spacing: Math.max(3, (root.height - root.content_h) / 4)

    Column {
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        spacing: root.fill_spacing

        Row {
            id: label_row
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2

            Text {
                visible: root.selected
                text: "▶"
                color: Style.shade_3
                font.family: Style.font_family
                font.pixelSize: Style.font_size
            }

            Text {
                text: root.day ? (root.day_index === 0 ? "TODAY" : root.day.weekday.toUpperCase()) : ""
                color: root.selected ? Style.shade_3 : Style.shade_2
                font.family: Style.font_family
                font.pixelSize: Style.font_size
            }
        }

        Item {
            id: photo_box
            anchors.horizontalCenter: parent.horizontalCenter
            width: photo.width + 18
            height: photo.height + 18

            PixelBox {
                anchors.fill: parent
                fill: Style.shade_3
                rings: root.selected ? [Style.shade_0, Style.shade_3, Style.shade_0] : ["transparent", Style.shade_2, Style.shade_0]
            }

            PixelSprite {
                id: photo
                x: 9
                y: 9
                pixel: root.pixel
                rows: root.day ? PixelArt.photo(root.day.code, root.day_index) : []
            }
        }

        DotBar {
            id: dot_bar
            anchors.horizontalCenter: parent.horizontalCenter
            low: root.day ? root.day.min : 0
            high: root.day ? root.day.max : 0
            scale_min: root.scale_min
            scale_max: root.scale_max
            dot: root.pixel * 2
        }

        Row {
            id: temp_row
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4

            PixelTemp {
                value: root.day ? root.day.max : 0
                color: Style.shade_3
                font_size: Style.font_size
            }

            PixelTemp {
                value: root.day ? root.day.min : 0
                color: Style.shade_2
                font_size: Style.font_size
            }
        }

        Text {
            id: pop_text
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.day ? root.day.pop + "%" : ""
            color: Style.shade_2
            font.family: Style.font_family
            font.pixelSize: Style.font_size
        }
    }
}
