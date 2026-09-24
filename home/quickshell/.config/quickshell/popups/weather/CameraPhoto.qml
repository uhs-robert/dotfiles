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
    // Largest integer scale of the 24x18 photo that still fits this column.
    readonly property int pixel: Math.max(1, Math.min(3, Math.floor((root.width - 18) / 24)))

    Column {
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        spacing: 5

        Row {
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
            anchors.horizontalCenter: parent.horizontalCenter
            low: root.day ? root.day.min : 0
            high: root.day ? root.day.max : 0
            scale_min: root.scale_min
            scale_max: root.scale_max
            dot: root.pixel * 2
        }

        Row {
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
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.day ? root.day.pop + "%" : ""
            color: Style.shade_2
            font.family: Style.font_family
            font.pixelSize: Style.font_size
        }
    }
}
