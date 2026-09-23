// home/quickshell/.config/quickshell/popups/weather/SunMoonView.qml
import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"

// Sun arc for the selected day (today shows the current-position dot), plus moon phase,
// moonrise/moonset and the next full moon date. h/l move the selected-day cursor.
Item {
    id: root

    property int day_cursor: 0

    readonly property var day: WeatherState.days[Math.max(0, Math.min(WeatherState.days.length - 1, root.day_cursor))]
    readonly property bool is_today: root.day_cursor === 0

    readonly property var moon_times: root.day ? WeatherState.moon_times_for_date(root.day.date) : ({ rise: null, set: null })
    readonly property real moon_phase: root.day ? WeatherState.moon_phase_for_date(root.day.date) : 0
    readonly property string next_full: root.day ? WeatherState.next_full_moon_label(root.day.date) : ""

    function hm_minutes(hm) {
        if (!hm) return null;
        const parts = hm.split(":");
        if (parts.length !== 2) return null;
        return parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10);
    }

    function sun_fraction() {
        if (!root.is_today) return null;
        const rise = root.hm_minutes(root.day ? root.day.sunrise : "");
        const set = root.hm_minutes(root.day ? root.day.sunset : "");
        if (rise === null || set === null || set <= rise) return null;
        const loc = WeatherState.location_now();
        const now = loc.getUTCHours() * 60 + loc.getUTCMinutes();
        if (now < rise || now > set) return null;
        return (now - rise) / (set - rise);
    }

    function day_length() {
        const rise = root.hm_minutes(root.day ? root.day.sunrise : "");
        const set = root.hm_minutes(root.day ? root.day.sunset : "");
        if (rise === null || set === null || set <= rise) return "—";
        const mins = set - rise;
        return Math.floor(mins / 60) + "h " + (mins % 60) + "m";
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Canvas {
            id: sun_canvas
            Layout.fillWidth: true
            Layout.preferredHeight: 150

            Timer {
                interval: 60000
                running: root.is_today
                repeat: true
                onTriggered: sun_canvas.requestPaint()
            }

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const w = width, h = height;
                const cx = w / 2, cy = h - 30, r = Math.min(w / 2 - 20, h - 44);

                ctx.strokeStyle = Theme.fg_muted;
                ctx.lineWidth = 3;
                ctx.beginPath();
                ctx.arc(cx, cy, r, Math.PI, 0, false);
                ctx.stroke();

                ctx.strokeStyle = Theme.fg_dim;
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.moveTo(cx - r - 16, cy);
                ctx.lineTo(cx + r + 16, cy);
                ctx.stroke();

                ctx.font = (Theme.popup_font_size + 4) + "px " + Theme.font_family;
                ctx.fillStyle = Theme.fg_core;
                ctx.textAlign = "left";
                ctx.fillText(root.day ? (root.day.sunrise || "—") : "—", cx - r - 16, cy + 24);
                ctx.textAlign = "right";
                ctx.fillText(root.day ? (root.day.sunset || "—") : "—", cx + r + 16, cy + 24);

                const frac = root.sun_fraction();
                if (frac !== null) {
                    const angle = Math.PI - frac * Math.PI;
                    const px = cx + r * Math.cos(angle);
                    const py = cy - r * Math.sin(angle);
                    ctx.fillStyle = Theme.yellow;
                    ctx.beginPath();
                    ctx.arc(px, py, 8, 0, 2 * Math.PI);
                    ctx.fill();
                }
            }

            Connections {
                target: root
                function onDayChanged() { sun_canvas.requestPaint(); }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 24

            RowLayout {
                spacing: 6
                Image { Layout.preferredWidth: 28; Layout.preferredHeight: 28; source: WeatherState.sun_rise_icon; sourceSize.width: 56; sourceSize.height: 56 }
                Text {
                    text: "Rise " + (root.day ? (root.day.sunrise || "—") : "—")
                    color: Theme.fg_core
                    font.family: Theme.font_family
                    font.pixelSize: Theme.popup_font_size
                }
            }

            RowLayout {
                spacing: 6
                Image { Layout.preferredWidth: 28; Layout.preferredHeight: 28; source: WeatherState.sun_set_icon; sourceSize.width: 56; sourceSize.height: 56 }
                Text {
                    text: "Set " + (root.day ? (root.day.sunset || "—") : "—")
                    color: Theme.fg_core
                    font.family: Theme.font_family
                    font.pixelSize: Theme.popup_font_size
                }
            }

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text { text: "Day length"; color: Theme.fg_muted; font.family: Theme.font_family; font.pixelSize: Theme.popup_font_size - 3 }
                Text { text: root.day_length(); color: Theme.fg_core; font.family: Theme.font_family; font.pixelSize: Theme.popup_font_size }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 14

            Image {
                Layout.preferredWidth: 110
                Layout.preferredHeight: 110
                source: WeatherState.moon_icon_source(root.moon_phase)
                sourceSize.width: 220
                sourceSize.height: 220
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                Text {
                    text: WeatherState.moon_name(root.moon_phase)
                    color: Theme.fg_core
                    font.family: Theme.font_family
                    font.pixelSize: Theme.popup_font_size + 2
                    font.bold: true
                }

                Text {
                    text: "Moonrise " + (root.moon_times.rise || "—") + (root.moon_times.set ? "  ·  Moonset " + root.moon_times.set : "")
                    color: Theme.fg_muted
                    font.family: Theme.font_family
                    font.pixelSize: Theme.popup_font_size - 2
                }

                Text {
                    text: "Full moon " + root.next_full
                    color: Theme.fg_dim
                    font.family: Theme.font_family
                    font.pixelSize: Theme.popup_font_size - 2
                }
            }
        }
    }
}
