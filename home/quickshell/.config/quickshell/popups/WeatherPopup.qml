// home/quickshell/.config/quickshell/popups/WeatherPopup.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../theme"
import "../services"
import "weather"

Popup {
    id: root

    popup_name: "weather"
    size_class: "large"
    preferred_width: 440
    body_height: content.implicitHeight + 24

    readonly property var base_tab_names: ["Daily", "Hourly", "Sun & Moon"]
    readonly property bool has_alerts: WeatherState.alerts.length > 0
    tabs: root.has_alerts ? root.base_tab_names.concat(["Alerts"]) : root.base_tab_names
    readonly property bool on_alerts_tab: root.has_alerts && root.current_tab === 3

    readonly property var daily_sub_names: ["Temp & Precip", "Wind", "UV", "Sunshine"]
    readonly property var hourly_sub_names: ["Temp", "Precip", "Wind", "UV", "Humid", "Air"]
    readonly property int air_sub: 5
    sub_views: root.current_tab === 0 ? root.daily_sub_names : root.current_tab === 1 ? root.hourly_sub_names : []
    jumps_enabled: true

    // None of this is reset on close: the popup lives for the whole qs session, only visibility toggles.
    property int daily_sub: 0
    property int hourly_sub: 0
    property int day_cursor: 0
    property int hour_cursor: 0
    property int alert_cursor: 0

    readonly property int content_height: Style.px(400)
    readonly property bool on_air: root.current_tab === 1 && root.hourly_sub === root.air_sub
    readonly property int air_hours: Math.min(24, WeatherState.aq_hours.length)

    FontMetrics {
        id: tab_metrics
        font.family: Style.font_family
        font.pixelSize: Style.font_size - 2
        font.bold: true
        font.capitalization: Style.tab_caps ? Font.AllUppercase : Font.MixedCase
        font.letterSpacing: Style.tab_caps ? Style.label_spacing : 0
    }

    FontMetrics {
        id: chip_metrics
        font.family: Style.font_family
        font.pixelSize: Style.font_size - 3
        font.bold: true
        font.capitalization: Style.tab_caps ? Font.AllUppercase : Font.MixedCase
        font.letterSpacing: Style.tab_caps ? Style.label_spacing : 0
    }

    FontMetrics {
        id: key_metrics
        font.family: Style.font_family
        font.pixelSize: Style.font_size - 5
        font.bold: true
    }

    // Mirrors MenuTab/KeyBadge sizing so rows can be split before the tabs exist.
    readonly property real tab_key_space: Style.tab_keys ? Math.max(key_metrics.height + 2, key_metrics.advanceWidth("9") + 8) * (1 + Style.slant) + 6 : 0
    // Reading .font re-runs the measurement when the style changes the metrics' font.
    readonly property var tab_needs: {
        const f = tab_metrics.font;
        return root.tabs.map(t => tab_metrics.advanceWidth(t) + 12 + root.tab_key_space);
    }

    function chip_needs(names) {
        const f = chip_metrics.font;
        return names.map(n => chip_metrics.advanceWidth(Style.chip_brackets ? "[" + n + "]" : n) + 20);
    }

    // Fewest balanced rows of consecutive indices whose widths fit `avail`.
    function split_rows(needs, avail, spacing) {
        const n = needs.length;
        for (let r = 1; r <= n; r++) {
            const per = Math.ceil(n / r);
            const rows = [];
            let fits = true;
            for (let i = 0; i < n; i += per) {
                const idx = [];
                let w = -spacing;
                for (let j = i; j < Math.min(n, i + per); j++) {
                    idx.push(j);
                    w += needs[j] + spacing;
                }
                if (w > avail) fits = false;
                rows.push(idx);
            }
            if (fits || per === 1) return rows;
        }
        return [];
    }

    readonly property var tab_rows: root.split_rows(root.tab_needs, main_column.width, 4)
    readonly property var chip_rows: root.split_rows(root.chip_needs(root.sub_views), main_column.width, 4)
    // Both chip sets reserve the same height so switching Daily/Hourly never resizes the popup.
    readonly property int chip_row_count: Math.max(root.split_rows(root.chip_needs(root.daily_sub_names), main_column.width, 4).length, root.split_rows(root.chip_needs(root.hourly_sub_names), main_column.width, 4).length)

    onCurrent_subChanged: {
        if (root.current_tab === 0) root.daily_sub = root.current_sub;
        else if (root.current_tab === 1) root.hourly_sub = root.current_sub;
    }
    onJump_first: root.go_now()
    onJump_last: root.go_end()

    readonly property bool is_open: Popups.open_name === "weather"
    onIs_openChanged: if (is_open) { WeatherState.refresh_if_due(); root.go_now(); }

    function move_day_cursor(dir, jump) {
        const n = Math.max(1, WeatherState.days.length);
        root.day_cursor = jump ? (dir < 0 ? 0 : n - 1) : Math.max(0, Math.min(n - 1, root.day_cursor + dir));
    }

    // Same hour, one day over: an index step of 24 is a good approximation even on a
    // partial first day (fewer than 24 hours before midnight).
    function shifted_hour_cursor(dir) {
        const hrs = WeatherState.hours;
        if (hrs.length === 0) return 0;
        return Math.max(0, Math.min(hrs.length - 1, root.hour_cursor + 24 * dir));
    }

    function move_hour_cursor(dir, jump, n, is_hourly_tab) {
        n = Math.max(1, n);
        if (jump) root.hour_cursor = is_hourly_tab ? root.shifted_hour_cursor(dir) : (dir < 0 ? 0 : n - 1);
        else root.hour_cursor = Math.max(0, Math.min(n - 1, root.hour_cursor + dir));
        if (is_hourly_tab && hourly_view) hourly_view.scroll_to_cursor();
    }

    function move_alert_cursor(dir, jump) {
        const n = Math.max(1, WeatherState.alerts.length);
        if (jump) {
            root.alert_cursor = dir < 0 ? 0 : n - 1;
        } else if (WeatherState.alerts.length > 1) {
            root.alert_cursor = Math.max(0, Math.min(n - 1, root.alert_cursor + dir));
        } else if (alerts_view) {
            alerts_view.scroll_detail(dir);
        }
    }

    function move_time(dir, jump) {
        if (root.current_tab === 0 || root.current_tab === 2) root.move_day_cursor(dir, jump);
        else if (root.on_air) root.move_hour_cursor(dir, jump, root.air_hours, false);
        else if (root.current_tab === 1) root.move_hour_cursor(dir, jump, WeatherState.hours.length, true);
        else if (root.on_alerts_tab) root.move_alert_cursor(dir, jump);
    }

    function go_now() {
        root.day_cursor = 0;
        root.hour_cursor = 0;
        root.alert_cursor = 0;
        if (hourly_view) hourly_view.scroll_to_cursor();
    }

    function go_end() {
        if (root.current_tab === 0 || root.current_tab === 2) {
            root.day_cursor = Math.max(0, WeatherState.days.length - 1);
        } else if (root.on_air) {
            root.hour_cursor = Math.max(0, root.air_hours - 1);
        } else if (root.current_tab === 1) {
            root.hour_cursor = Math.max(0, WeatherState.hours.length - 1);
            if (hourly_view) hourly_view.scroll_to_cursor();
        } else if (root.on_alerts_tab) {
            root.alert_cursor = Math.max(0, WeatherState.alerts.length - 1);
        }
    }

    function jump_to_hour_for_selected_day() {
        const day = WeatherState.days[root.day_cursor];
        if (!day) return;
        const hrs = WeatherState.hours;
        const target_hour = root.day_cursor === 0 ? WeatherState.location_now().getUTCHours() : 12;
        let idx = hrs.findIndex(h => h.date === day.date && h.hour === target_hour);
        if (idx === -1) idx = hrs.findIndex(h => h.date === day.date);
        if (idx === -1) idx = 0;
        root.hour_cursor = idx;
        root.set_tab(1);
        if (root.on_air) root.current_sub = 0;
        if (hourly_view) hourly_view.scroll_to_cursor();
    }

    function fmt_temp(t) {
        return Math.round(t) + "°" + WeatherState.unit_symbol();
    }

    function fmt_alert_time(iso) {
        return iso ? WeatherState.fmt_location_time(new Date(iso)) : "—";
    }

    function handle_key(event) {
        if (event.key === Qt.Key_A && root.has_alerts) {
            root.set_tab(root.tabs.length - 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_R) {
            WeatherState.refresh(true);
            event.accepted = true;
        } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.current_tab === 0) {
            root.jump_to_hour_for_selected_day();
            event.accepted = true;
        } else if (event.key === Qt.Key_H) {
            root.move_time(-1, !!(event.modifiers & Qt.ShiftModifier));
            event.accepted = true;
        } else if (event.key === Qt.Key_L) {
            root.move_time(1, !!(event.modifiers & Qt.ShiftModifier));
            event.accepted = true;
        } else if (root.on_alerts_tab && event.key === Qt.Key_J) {
            root.move_alert_cursor(1, false);
            event.accepted = true;
        } else if (root.on_alerts_tab && event.key === Qt.Key_K) {
            root.move_alert_cursor(-1, false);
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

        ColumnLayout {
            id: main_column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 8

            // --- Current conditions header, shown above every tab ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Image {
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72
                    readonly property real dpr: QsWindow.window ? QsWindow.window.devicePixelRatio : 1
                    source: WeatherState.has_data ? WeatherState.icon_source(WeatherState.current.code, WeatherState.current.is_day) : ""
                    visible: WeatherState.has_data
                    sourceSize.width: Math.ceil(144 * dpr)
                    sourceSize.height: Math.ceil(144 * dpr)
                    smooth: true
                }

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true

                    Text {
                        text: WeatherState.has_data ? root.fmt_temp(WeatherState.current.temp) : "--°"
                        color: WeatherState.has_data ? WeatherState.temp_color(WeatherState.current.temp) : Style.text_dim
                        font.family: Style.number_font
                        font.pixelSize: Style.font_size + 12
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: WeatherState.has_data ? WeatherState.current.cond : WeatherState.loading ? "Loading…" : "Unavailable: " + WeatherState.error
                        color: WeatherState.has_data || WeatherState.loading ? Theme.fg_core : Theme.warning
                        font.family: Style.font_family
                        font.pixelSize: Style.font_size + 1
                    }

                    Text {
                        visible: WeatherState.has_data
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: "Feels like " + (WeatherState.has_data ? root.fmt_temp(WeatherState.current.feels) : "")
                        color: Style.text_muted
                        font.family: Style.font_family
                        font.pixelSize: Style.font_size - 2
                    }

                    Text {
                        visible: WeatherState.location_name !== ""
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        text: WeatherState.location_name
                        color: Style.text_dim
                        font.family: Style.font_family
                        font.pixelSize: Style.font_size - 2
                    }
                }

                Text {
                    visible: WeatherState.stale
                    Layout.alignment: Qt.AlignTop
                    Layout.maximumWidth: main_column.width / 3
                    horizontalAlignment: Text.AlignRight
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    text: "Stale data" + (WeatherState.error ? ": " + WeatherState.error : "")
                    color: Theme.warning
                    font.family: Style.font_family
                    font.pixelSize: Style.font_size - 3
                }
            }

            // --- Active-alert banner ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.has_alerts ? 28 : 0
                visible: root.has_alerts
                radius: Style.radius(4)
                readonly property color alert_color: WeatherState.alerts.length > 0 ? WeatherState.alert_color(WeatherState.alerts[0].severity) : Style.text_dim
                color: Style.boxed_cards ? Qt.alpha(alert_color, 0.1) : Theme.bg_surface
                border.width: Style.boxed_cards ? 1 : 0
                border.color: alert_color

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 8
                        Layout.preferredHeight: 8
                        radius: Style.radius(4)
                        color: WeatherState.alerts.length > 0 ? WeatherState.alert_color(WeatherState.alerts[0].severity) : Style.text_dim
                    }

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: WeatherState.alerts.length > 0
                            ? WeatherState.alerts[0].event + " · until " + root.fmt_alert_time(WeatherState.alerts[0].ends) + (WeatherState.alerts.length > 1 ? "  +" + (WeatherState.alerts.length - 1) + " more" : "")
                            : ""
                        color: WeatherState.alerts.length > 0 ? WeatherState.alert_color(WeatherState.alerts[0].severity) : Theme.fg_core
                        font.family: Style.font_family
                        font.pixelSize: Style.font_size - 2
                        font.bold: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.set_tab(root.tabs.length - 1)
                }
            }

            // --- Tab rows: each tab asks for its label's width, wrapping only when a row cannot hold them ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: root.tab_rows

                    RowLayout {
                        id: tab_row
                        required property var modelData

                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: tab_row.modelData

                            MenuTab {
                                id: tab_chip
                                required property int modelData

                                Layout.fillWidth: true
                                Layout.preferredWidth: root.tab_needs[tab_chip.modelData] || 0
                                implicitHeight: Style.px(26)
                                label: root.tabs[tab_chip.modelData] || ""
                                active: tab_chip.modelData === root.current_tab
                                key: tab_chip.modelData < 9 ? String(tab_chip.modelData + 1) : ""
                                onClicked: root.set_tab(tab_chip.modelData)
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.content_height

                DailyView {
                    anchors.fill: parent
                    visible: root.current_tab === 0
                    day_cursor: root.day_cursor
                    sub: root.daily_sub
                    on_select: function (i) { root.day_cursor = i; }
                }

                HourlyView {
                    id: hourly_view
                    anchors.fill: parent
                    visible: root.current_tab === 1 && !root.on_air
                    hour_cursor: root.hour_cursor
                    sub: root.hourly_sub
                    on_select: function (i) { root.hour_cursor = i; }
                }

                AirView {
                    anchors.fill: parent
                    visible: root.on_air
                    hour_cursor: root.hour_cursor
                    on_select: function (i) { root.hour_cursor = i; }
                }

                SunMoonView {
                    anchors.fill: parent
                    visible: root.current_tab === 2
                    day_cursor: root.day_cursor
                }

                AlertsView {
                    id: alerts_view
                    anchors.fill: parent
                    visible: root.on_alerts_tab
                    alert_cursor: root.alert_cursor
                    on_select: function (i) { root.alert_cursor = i; }
                }
            }

            // --- Sub-view chips (Daily/Hourly) or the selected day (Sun & Moon), under the content ---
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(28, root.chip_row_count * Style.px(24) + (root.chip_row_count - 1) * 4)

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    visible: root.current_tab === 0 || root.current_tab === 1

                    Repeater {
                        model: root.chip_rows

                        RowLayout {
                            id: chip_row
                            required property var modelData

                            Layout.alignment: Qt.AlignHCenter
                            spacing: 4

                            Repeater {
                                model: chip_row.modelData

                                MenuTab {
                                    id: sub_chip
                                    required property int modelData

                                    base_radius: 12
                                    label: root.sub_views[sub_chip.modelData] || ""
                                    active: sub_chip.modelData === root.current_sub
                                    font_size: Style.font_size - 3
                                    onClicked: root.current_sub = sub_chip.modelData
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.current_tab === 2
                    readonly property var d: WeatherState.days[root.day_cursor]
                    text: d ? d.weekday + (d.weekday !== "Today" ? " (" + d.date.substr(5) + ")" : "") : ""
                    color: Style.text_muted
                    font.family: Style.font_family
                    font.pixelSize: Style.font_size - 3
                }
            }

            Text {
                text: WeatherState.updated > 0 ? "Updated " + WeatherState.format_hour(new Date(WeatherState.updated)) : "Never updated"
                color: Style.text_dim
                font.family: Style.font_family
                font.pixelSize: Style.font_size - 4
            }

            MenuFooter {
                Layout.fillWidth: true
                wrap: true
                text: "[ ] tabs · 1-" + root.tabs.length + " select · Tab view · h/l move · H/L jump · gg now · G end · r refresh" + (root.has_alerts ? " · a alerts" : "")
            }
        }
    }
}
