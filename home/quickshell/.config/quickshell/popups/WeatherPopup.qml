// home/quickshell/.config/quickshell/popups/WeatherPopup.qml
import QtQuick
import QtQuick.Layouts
import "../components"
import "../theme"
import "../services"

Popup {
    id: root

    popup_name: "weather"
    preferred_width: 380
    implicitHeight: content.implicitHeight + 24

    readonly property var tab_names: ["Daily", "Hourly", "Sun & Moon", "Precip"]
    // Not reset on close: this Item lives for the whole qs session, only visibility toggles.
    property int current_tab: 0

    readonly property bool is_open: Popups.open_name === "weather"
    onIs_openChanged: if (is_open) WeatherState.refresh(false)

    function set_tab(i) {
        root.current_tab = Math.max(0, Math.min(root.tab_names.length - 1, i));
    }

    function step_tab(delta) {
        root.current_tab = (root.current_tab + delta + root.tab_names.length) % root.tab_names.length;
    }

    function fmt_temp(t) {
        return Math.round(t) + "°" + WeatherState.unit_symbol();
    }

    Item {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        implicitHeight: main_column.implicitHeight
        focus: true

        Keys.onPressed: event => {
            if (event.key >= Qt.Key_1 && event.key <= Qt.Key_4) {
                root.set_tab(event.key - Qt.Key_1);
                event.accepted = true;
            } else if (event.key === Qt.Key_H || event.key === Qt.Key_BracketLeft) {
                root.step_tab(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_L || event.key === Qt.Key_BracketRight) {
                root.step_tab(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_R) {
                WeatherState.refresh(true);
                event.accepted = true;
            } else if (event.key === Qt.Key_J && root.current_tab === 1) {
                hourly_view.contentY = Math.min(Math.max(0, hourly_view.contentHeight - hourly_view.height), hourly_view.contentY + 28);
                event.accepted = true;
            } else if (event.key === Qt.Key_K && root.current_tab === 1) {
                hourly_view.contentY = Math.max(0, hourly_view.contentY - 28);
                event.accepted = true;
            }
        }

        ColumnLayout {
            id: main_column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 8

            // --- Current conditions header, shown above every tab ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Image {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    source: WeatherState.has_data ? WeatherState.icon_source(WeatherState.current.code, WeatherState.current.is_day) : ""
                    visible: WeatherState.has_data
                    sourceSize.width: 88
                    sourceSize.height: 88
                    smooth: true
                }

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true

                    Text {
                        text: WeatherState.has_data ? root.fmt_temp(WeatherState.current.temp) : "--°"
                        color: WeatherState.has_data ? WeatherState.temp_color(WeatherState.current.temp) : Theme.fg_dim
                        font.family: Theme.font_family
                        font.pixelSize: Theme.popup_font_size + 6
                        font.bold: true
                    }

                    Text {
                        text: WeatherState.has_data ? WeatherState.current.cond : "Loading…"
                        color: Theme.fg_core
                        font.family: Theme.font_family
                        font.pixelSize: Theme.popup_font_size - 1
                    }

                    Text {
                        visible: WeatherState.has_data
                        text: "Feels like " + (WeatherState.has_data ? root.fmt_temp(WeatherState.current.feels) : "")
                        color: Theme.fg_muted
                        font.family: Theme.font_family
                        font.pixelSize: Theme.popup_font_size - 3
                    }

                    Text {
                        visible: WeatherState.location_name !== ""
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        text: WeatherState.location_name
                        color: Theme.fg_dim
                        font.family: Theme.font_family
                        font.pixelSize: Theme.popup_font_size - 3
                    }
                }
            }

            Text {
                visible: WeatherState.stale
                text: "Stale data" + (WeatherState.error ? ": " + WeatherState.error : "")
                color: Theme.warning
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size - 3
            }

            // --- Tab row ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: root.tab_names

                    Rectangle {
                        id: tab_chip
                        required property string modelData
                        required property int index

                        Layout.fillWidth: true
                        height: 24
                        radius: 4
                        color: tab_chip.index === root.current_tab ? Theme.bg_surface : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: tab_chip.modelData
                            color: tab_chip.index === root.current_tab ? Theme.theme_secondary : Theme.fg_muted
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 3
                            font.bold: tab_chip.index === root.current_tab
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.set_tab(tab_chip.index)
                        }
                    }
                }
            }

            // --- Daily tab ---
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.current_tab === 0
                spacing: 2

                Repeater {
                    model: visible ? WeatherState.days : []

                    RowLayout {
                        id: day_row
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        height: 26
                        spacing: 6

                        Text {
                            Layout.preferredWidth: 72
                            text: day_row.modelData.weekday
                            color: day_row.index === 0 ? Theme.theme_secondary : Theme.fg_core
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 2
                        }

                        Image {
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            source: WeatherState.icon_source(day_row.modelData.code, true)
                            sourceSize.width: 36
                            sourceSize.height: 36
                            smooth: true
                        }

                        Text {
                            Layout.preferredWidth: 34
                            horizontalAlignment: Text.AlignRight
                            text: root.fmt_temp(day_row.modelData.max)
                            color: WeatherState.temp_color(day_row.modelData.max)
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 2
                        }

                        Text {
                            Layout.preferredWidth: 34
                            horizontalAlignment: Text.AlignRight
                            text: root.fmt_temp(day_row.modelData.min)
                            color: WeatherState.temp_color(day_row.modelData.min)
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 2
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            text: day_row.modelData.pop + "%"
                            color: WeatherState.pop_color(day_row.modelData.pop)
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 3
                        }
                    }
                }
            }

            // --- Hourly tab ---
            ListView {
                id: hourly_view
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                visible: root.current_tab === 1
                clip: true
                model: visible ? root.hourly_rows : []

                delegate: Item {
                    id: hour_delegate
                    required property var modelData

                    width: hourly_view.width
                    height: hour_delegate.modelData.kind === "separator" ? 20 : 24

                    Text {
                        visible: hour_delegate.modelData.kind === "separator"
                        text: hour_delegate.modelData.label
                        color: Theme.fg_muted
                        font.family: Theme.font_family
                        font.pixelSize: Theme.popup_font_size - 4
                        font.bold: true
                    }

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        visible: hour_delegate.modelData.kind === "row"
                        spacing: 6

                        Text {
                            Layout.preferredWidth: 44
                            text: hour_delegate.modelData.kind === "row" ? WeatherState.format_hour(new Date(hour_delegate.modelData.data.dt)) : ""
                            color: Theme.fg_core
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 3
                        }

                        Image {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            source: hour_delegate.modelData.kind === "row" ? WeatherState.icon_source(hour_delegate.modelData.data.code, hour_delegate.modelData.data.is_day) : ""
                            sourceSize.width: 32
                            sourceSize.height: 32
                            smooth: true
                        }

                        Text {
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                            text: hour_delegate.modelData.kind === "row" ? root.fmt_temp(hour_delegate.modelData.data.temp) : ""
                            color: hour_delegate.modelData.kind === "row" ? WeatherState.temp_color(hour_delegate.modelData.data.temp) : Theme.fg_core
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 3
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            text: hour_delegate.modelData.kind === "row" ? hour_delegate.modelData.data.pop + "%" : ""
                            color: hour_delegate.modelData.kind === "row" ? WeatherState.pop_color(hour_delegate.modelData.data.pop) : Theme.fg_core
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 3
                        }
                    }
                }
            }

            // --- Sun and Moon tab ---
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.current_tab === 2
                spacing: 6

                Canvas {
                    id: sun_canvas
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90
                    visible: root.current_tab === 2

                    Timer {
                        interval: 60000
                        running: sun_canvas.visible
                        repeat: true
                        onTriggered: sun_canvas.requestPaint()
                    }

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const w = width, h = height;
                        const cx = w / 2, cy = h - 14, r = Math.min(w / 2 - 16, h - 24);

                        ctx.strokeStyle = Theme.fg_muted;
                        ctx.lineWidth = 2;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, Math.PI, 0, false);
                        ctx.stroke();

                        ctx.strokeStyle = Theme.fg_dim;
                        ctx.beginPath();
                        ctx.moveTo(cx - r - 10, cy);
                        ctx.lineTo(cx + r + 10, cy);
                        ctx.stroke();

                        const frac = root.sun_fraction();
                        if (frac !== null) {
                            const angle = Math.PI - frac * Math.PI;
                            const px = cx + r * Math.cos(angle);
                            const py = cy - r * Math.sin(angle);
                            ctx.fillStyle = Theme.yellow;
                            ctx.beginPath();
                            ctx.arc(px, py, 5, 0, 2 * Math.PI);
                            ctx.fill();
                        }
                    }

                    Connections {
                        target: WeatherState
                        function onSunriseChanged() { sun_canvas.requestPaint(); }
                        function onSunsetChanged() { sun_canvas.requestPaint(); }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        spacing: 0
                        Image {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            source: WeatherState.sun_rise_icon
                            sourceSize.width: 40
                            sourceSize.height: 40
                        }
                        Text {
                            text: "Rise " + (WeatherState.sunrise || "—")
                            color: Theme.fg_core
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 2
                        }
                    }

                    ColumnLayout {
                        spacing: 0
                        Image {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            source: WeatherState.sun_set_icon
                            sourceSize.width: 40
                            sourceSize.height: 40
                        }
                        Text {
                            text: "Set " + (WeatherState.sunset || "—")
                            color: Theme.fg_core
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 2
                        }
                    }

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        Text {
                            text: "Day length"
                            color: Theme.fg_muted
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 4
                        }
                        Text {
                            text: root.day_length()
                            color: Theme.fg_core
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 2
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 8

                    Image {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        source: WeatherState.has_data ? WeatherState.moon_icon_source(WeatherState.moon.phase) : ""
                        visible: WeatherState.has_data
                        sourceSize.width: 52
                        sourceSize.height: 52
                    }

                    Text {
                        text: WeatherState.has_data ? WeatherState.moon.name : ""
                        color: Theme.fg_core
                        font.family: Theme.font_family
                        font.pixelSize: Theme.popup_font_size - 1
                    }
                }

                Text {
                    Layout.topMargin: 4
                    text: "Upcoming"
                    color: Theme.fg_muted
                    font.family: Theme.font_family
                    font.pixelSize: Theme.popup_font_size - 4
                    font.bold: true
                }

                Repeater {
                    model: root.current_tab === 2 ? WeatherState.days.slice(0, 5) : []

                    RowLayout {
                        id: astro_row
                        required property var modelData

                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            Layout.preferredWidth: 60
                            text: astro_row.modelData.weekday
                            color: Theme.fg_core
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 3
                        }

                        Text {
                            Layout.fillWidth: true
                            text: (astro_row.modelData.sunrise || "—") + "  –  " + (astro_row.modelData.sunset || "—")
                            color: Theme.fg_muted
                            font.family: Theme.font_family
                            font.pixelSize: Theme.popup_font_size - 3
                        }
                    }
                }
            }

            // --- Precipitation tab ---
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.current_tab === 3
                spacing: 4

                Canvas {
                    id: precip_canvas
                    Layout.fillWidth: true
                    Layout.preferredHeight: 160
                    visible: root.current_tab === 3

                    readonly property var slice: WeatherState.hours.slice(0, 12)

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const w = width, h = height;
                        const rows = precip_canvas.slice;
                        if (rows.length === 0) return;

                        const margin_bottom = 28;
                        const margin_top = 20;
                        const chart_h = h - margin_bottom - margin_top;
                        const col_w = w / rows.length;

                        ctx.strokeStyle = Theme.fg_muted;
                        ctx.lineWidth = 1;
                        ctx.beginPath();
                        ctx.moveTo(0, margin_top + chart_h);
                        ctx.lineTo(w, margin_top + chart_h);
                        ctx.stroke();

                        ctx.font = (Theme.popup_font_size - 5) + "px " + Theme.font_family;
                        ctx.textAlign = "center";

                        for (let i = 0; i < rows.length; i++) {
                            const row = rows[i];
                            const bar_w = Math.max(4, col_w * 0.5);
                            const bar_h = (Math.max(0, Math.min(100, row.pop)) / 100) * chart_h;
                            const x = i * col_w + (col_w - bar_w) / 2;
                            const y = margin_top + chart_h - bar_h;

                            ctx.fillStyle = WeatherState.pop_color(row.pop);
                            ctx.fillRect(x, y, bar_w, bar_h);

                            ctx.fillStyle = Theme.fg_dim;
                            ctx.fillText(row.pop + "%", i * col_w + col_w / 2, y - 4 < margin_top ? margin_top : y - 4);

                            ctx.fillStyle = Theme.fg_muted;
                            ctx.fillText(WeatherState.format_hour(new Date(row.dt)), i * col_w + col_w / 2, h - margin_bottom + 12);

                            ctx.fillStyle = Theme.blue;
                            ctx.fillText(row.precip.toFixed(row.precip < 1 ? 2 : 1), i * col_w + col_w / 2, margin_top - 6);
                        }
                    }

                    Connections {
                        target: WeatherState
                        function onHoursChanged() { precip_canvas.requestPaint(); }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Bars: chance of precipitation · Numbers: amount (" + (WeatherState.settings.unit === "celsius" ? "mm" : "in") + ")"
                    color: Theme.fg_dim
                    font.family: Theme.font_family
                    font.pixelSize: Theme.popup_font_size - 4
                }
            }

            Text {
                Layout.topMargin: 4
                text: WeatherState.updated > 0 ? "Updated " + WeatherState.format_hour(new Date(WeatherState.updated)) : "Never updated"
                color: Theme.fg_dim
                font.family: Theme.font_family
                font.pixelSize: Theme.popup_font_size - 4
            }
        }
    }

    // --- Derived helpers for the Sun and Moon tab ---

    readonly property var hourly_rows: {
        const rows = [];
        let last_date = null;
        const today_str = Qt.formatDate(new Date(), "yyyy-MM-dd");
        for (const h of WeatherState.hours) {
            if (h.date !== last_date) {
                const label = h.date === today_str ? "Today" : Qt.formatDate(new Date(h.date + "T00:00:00"), "dddd, MMM d");
                rows.push({ kind: "separator", label: label });
                last_date = h.date;
            }
            rows.push({ kind: "row", data: h });
        }
        return rows;
    }

    function parse_hm_today(hm) {
        if (!hm) return null;
        const parts = hm.split(":");
        if (parts.length !== 2) return null;
        const now = new Date();
        return new Date(now.getFullYear(), now.getMonth(), now.getDate(), parseInt(parts[0], 10), parseInt(parts[1], 10));
    }

    function sun_fraction() {
        const rise = root.parse_hm_today(WeatherState.sunrise);
        const set = root.parse_hm_today(WeatherState.sunset);
        if (!rise || !set || set <= rise) return null;
        const now = new Date();
        if (now < rise || now > set) return null;
        return (now - rise) / (set - rise);
    }

    function day_length() {
        const rise = root.parse_hm_today(WeatherState.sunrise);
        const set = root.parse_hm_today(WeatherState.sunset);
        if (!rise || !set || set <= rise) return "—";
        const mins = Math.round((set - rise) / 60000);
        return Math.floor(mins / 60) + "h " + (mins % 60) + "m";
    }
}
