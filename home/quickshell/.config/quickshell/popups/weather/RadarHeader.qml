// home/quickshell/.config/quickshell/popups/weather/RadarHeader.qml
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../components/mgs2"
import "../../theme"
import "../../services"

// Current conditions as a Soliton Radar: caution on any alert, a jammed ALERT banner on severe ones.
RowLayout {
    id: root

    readonly property var cur: WeatherState.current
    readonly property bool has: WeatherState.has_data && !!root.cur
    readonly property var top_alert: WeatherState.alerts.length > 0 ? WeatherState.alerts[0] : null
    readonly property bool severe: !!root.top_alert && (root.top_alert.severity === "Extreme" || root.top_alert.severity === "Severe")
    readonly property string mode: !root.top_alert ? "normal" : root.severe ? "alert" : "caution"
    readonly property color tone: root.mode === "alert" ? Theme.error : root.mode === "caution" ? Theme.warning : Theme.theme_primary
    readonly property bool is_open: Popups.open_name === "weather"
    readonly property bool animate: root.is_open && Power.on_ac
    readonly property int aqi: WeatherState.aq_has_data && WeatherState.aq_current ? WeatherState.aq_current.aqi : -1
    readonly property var blip_hours: WeatherState.hours.slice(0, 12)
    readonly property int pop_max: root.blip_hours.reduce((m, h) => Math.max(m, h.pop), 0)
    readonly property real wind_max: WeatherState.settings.unit === "celsius" ? 60 : 40
    readonly property real box_w: Math.round(Math.max(110, Math.min(156, root.width * 0.42)))
    readonly property real strip_h: 14
    readonly property var compass: ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]

    readonly property var readouts: !root.has ? [] : [
        { label: "WND", value: Math.round(root.cur.wind_speed) + " " + root.bearing(root.cur.wind_dir), frac: -1, suffix: "" },
        { label: "HUM", value: String(root.cur.humidity), frac: root.cur.humidity / 100, suffix: "%" },
        { label: "UV", value: root.cur.uv_index.toFixed(1), frac: Math.min(1, root.cur.uv_index / 11), suffix: "" },
        { label: "AQI", value: root.aqi >= 0 ? String(root.aqi) : "--", frac: root.aqi >= 0 ? Math.min(1, root.aqi / 300) : -1, suffix: "" },
        { label: "PRECIP", value: String(root.pop_max), frac: root.pop_max / 100, suffix: "%" }
    ]

    function bearing(deg) {
        return root.compass[Math.round((((deg % 360) + 360) % 360) / 22.5) % 16];
    }

    spacing: 12

    Item {
        Layout.preferredWidth: root.box_w
        Layout.preferredHeight: Math.round(root.box_w * 0.82)
        Layout.alignment: Qt.AlignTop

        Column {
            anchors.fill: parent
            spacing: 2
            visible: root.mode !== "alert"

            Rectangle {
                visible: root.mode === "caution"
                width: parent.width
                height: root.strip_h
                color: Qt.alpha(root.tone, 0.85)

                SegText {
                    x: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: ".CAUTION"
                    cap_height: 9
                    stroke: 1.1
                    color: Theme.bg_crust
                }
            }

            RadarMap {
                width: parent.width
                height: parent.height - (root.mode === "caution" ? root.strip_h * 2 + 4 : 0)
                seed: WeatherState.location_name || "oasis"
                line_color: root.tone
                wind_dir: root.has ? root.cur.wind_dir : 0
                wind_frac: root.has ? Math.max(0.12, Math.min(1, root.cur.wind_speed / root.wind_max)) : 0.12
                contacts: root.blip_hours
                animate: root.animate
                contact_color: root.mode === "normal" ? Theme.theme_secondary : root.tone
            }

            Rectangle {
                visible: root.mode === "caution"
                width: parent.width
                height: root.strip_h
                color: Qt.alpha(root.tone, 0.15)
                border.width: 1
                border.color: Qt.alpha(root.tone, 0.6)

                SegText {
                    x: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: "RADAR : NORMAL"
                    cap_height: 7
                    color: root.tone
                }
            }
        }

        Rectangle {
            id: banner
            visible: root.mode === "alert"
            anchors.fill: parent
            color: Qt.tint(Qt.alpha(Theme.bg_crust, 0.9), Qt.alpha(root.tone, 0.12))
            border.width: 1
            border.color: Qt.alpha(root.tone, 0.7)

            Rectangle {
                id: banner_head
                x: 6
                y: 6
                width: parent.width - 12
                height: 26
                color: Qt.alpha(root.tone, 0.9)

                SegText {
                    anchors.centerIn: parent
                    text: ".ALERT"
                    cap_height: 14
                    stroke: 1.4
                    color: Theme.bg_crust
                }
            }

            Canvas {
                id: jam
                x: 6
                y: banner_head.y + banner_head.height + 5
                width: parent.width - 12
                height: 10
                onWidthChanged: requestPaint()
                Connections {
                    target: root
                    function onToneChanged() { jam.requestPaint(); }
                }

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = String(Qt.rgba(root.tone.r, root.tone.g, root.tone.b, 1));
                    ctx.globalAlpha = 0.75;
                    for (let x = -height; x < width; x += 10) {
                        ctx.beginPath();
                        ctx.moveTo(x, height);
                        ctx.lineTo(x + 5, height);
                        ctx.lineTo(x + 5 + height, 0);
                        ctx.lineTo(x + height, 0);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }

            Text {
                x: 6
                y: jam.y + jam.height + 6
                width: parent.width - 12
                height: parent.height - y - 6
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                text: root.top_alert ? (root.top_alert.headline || root.top_alert.event) : ""
                color: Style.text_fg
                font.family: Style.font_family
                font.pixelSize: Style.fs(-4)
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.alignment: Qt.AlignTop
        spacing: 4

        Row {
            spacing: 3

            SegText {
                text: root.has ? String(Math.round(root.cur.temp)) : "--"
                cap_height: 26
                stroke: 1
                color: root.has ? Style.text_strong : Style.text_dim
            }

            SegText {
                text: "\u00b0" + WeatherState.unit_symbol()
                cap_height: 10
                color: root.tone
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            elide: Text.ElideRight
            text: root.has ? root.cur.cond : WeatherState.loading ? "Acquiring" : "No signal"
            color: root.has || WeatherState.loading ? Style.text_fg : Theme.warning
            font.family: Style.font_family
            font.pixelSize: Style.fs(-2)
        }

        Text {
            visible: root.mode === "caution" && !!root.top_alert
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            elide: Text.ElideRight
            text: root.top_alert ? root.top_alert.event + (WeatherState.alerts.length > 1 ? "  +" + (WeatherState.alerts.length - 1) : "") : ""
            color: root.tone
            font.family: Style.font_family
            font.pixelSize: Style.fs(-4)
        }

        Repeater {
            model: root.readouts

            LifeBar {
                required property var modelData
                Layout.fillWidth: true
                label: modelData.label
                value: modelData.value
                suffix: modelData.suffix
                frac: modelData.frac
                color: root.tone
                tab_width: 46
            }
        }
    }
}
