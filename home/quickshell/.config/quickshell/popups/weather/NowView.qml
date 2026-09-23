// home/quickshell/.config/quickshell/popups/weather/NowView.qml
import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"

// Detail-tile grid for the current conditions. h/l have nothing to move here.
Item {
    id: root

    readonly property var current: WeatherState.current
    readonly property bool ready: WeatherState.has_data && !!current

    function fmt_temp(t) {
        return Math.round(t) + "°" + WeatherState.unit_symbol();
    }

    GridLayout {
        anchors.centerIn: parent
        width: parent.width
        columns: 4
        rowSpacing: 14
        columnSpacing: 8
        visible: root.ready

        // --- Feels like ---
        ColumnLayout {
            spacing: 2
            Text { text: "Feels like"; color: Theme.fg_muted; font.family: Theme.font_family; font.pixelSize: Theme.popup_font_size - 4 }
            Text {
                text: root.ready ? root.fmt_temp(root.current.feels) : "--"
                color: root.ready ? WeatherState.temp_color(root.current.feels) : Theme.fg_dim
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size + 2
                font.bold: true
            }
        }

        // --- Humidity ---
        ColumnLayout {
            spacing: 2
            Text { text: "Humidity"; color: Theme.fg_muted; font.family: Theme.font_family; font.pixelSize: Theme.popup_font_size - 4 }
            Text {
                text: root.ready ? root.current.humidity + "%" : "--"
                color: Theme.fg_core
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size + 2
                font.bold: true
            }
        }

        // --- Dew point ---
        ColumnLayout {
            spacing: 2
            Text { text: "Dew point"; color: Theme.fg_muted; font.family: Theme.font_family; font.pixelSize: Theme.popup_font_size - 4 }
            Text {
                text: root.ready ? root.fmt_temp(root.current.dew_point) : "--"
                color: Theme.fg_core
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size + 2
                font.bold: true
            }
        }

        // --- Wind ---
        ColumnLayout {
            spacing: 2
            Text { text: "Wind"; color: Theme.fg_muted; font.family: Theme.font_family; font.pixelSize: Theme.popup_font_size - 4 }
            RowLayout {
                spacing: 4
                Text {
                    text: "▲"
                    rotation: root.ready ? root.current.wind_dir : 0
                    color: Theme.cyan
                    font.pixelSize: Theme.popup_font_size - 3
                }
                Text {
                    text: root.ready ? Math.round(root.current.wind_speed) + " " + WeatherState.wind_unit() : "--"
                    color: Theme.fg_core
                    font.family: Theme.font_family
                    font.pixelSize: Theme.popup_font_size
                    font.bold: true
                }
            }
            Text {
                visible: root.ready
                text: root.ready ? "gusts " + Math.round(root.current.wind_gusts) + " · " + WeatherState.wind_dir_label(root.current.wind_dir) : ""
                color: Theme.fg_dim
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size - 4
            }
        }

        // --- Pressure ---
        ColumnLayout {
            spacing: 2
            Text { text: "Pressure"; color: Theme.fg_muted; font.family: Theme.font_family; font.pixelSize: Theme.popup_font_size - 4 }
            Text {
                text: root.ready ? WeatherState.pressure_display(root.current.pressure) : "--"
                color: Theme.fg_core
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size
                font.bold: true
            }
        }

        // --- Visibility ---
        ColumnLayout {
            spacing: 2
            Text { text: "Visibility"; color: Theme.fg_muted; font.family: Theme.font_family; font.pixelSize: Theme.popup_font_size - 4 }
            Text {
                text: root.ready ? WeatherState.visibility_display(root.current.visibility) : "--"
                color: Theme.fg_core
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size
                font.bold: true
            }
        }

        // --- UV index ---
        ColumnLayout {
            spacing: 2
            Text { text: "UV index"; color: Theme.fg_muted; font.family: Theme.font_family; font.pixelSize: Theme.popup_font_size - 4 }
            Text {
                text: root.ready ? root.current.uv_index.toFixed(1) : "--"
                color: root.ready ? WeatherState.uv_color(root.current.uv_index) : Theme.fg_dim
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size + 2
                font.bold: true
            }
            Text {
                visible: root.ready
                text: root.ready ? WeatherState.uv_band(root.current.uv_index).label : ""
                color: root.ready ? WeatherState.uv_color(root.current.uv_index) : Theme.fg_dim
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size - 4
            }
        }

        // --- Cloud cover ---
        ColumnLayout {
            spacing: 2
            Text { text: "Cloud cover"; color: Theme.fg_muted; font.family: Theme.font_family; font.pixelSize: Theme.popup_font_size - 4 }
            Text {
                text: root.ready ? root.current.cloud_cover + "%" : "--"
                color: Theme.fg_core
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size + 2
                font.bold: true
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !root.ready
        text: WeatherState.loading ? "Loading…" : "No data"
        color: Theme.fg_dim
        font.family: Theme.font_family
        font.pixelSize: Theme.popup_font_size - 1
    }
}
